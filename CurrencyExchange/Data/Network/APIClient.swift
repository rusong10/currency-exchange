import Foundation
import Alamofire

enum NetworkError: Error {
    case requestFailed(Error)
    case invalidResponse
    case decodingFailed(Error)
    case serverError(String)
    case noInternet
    
    var localizedDescription: String {
        switch self {
        case .requestFailed(let error):
            return "Request failed: \(error.localizedDescription)"
        case .invalidResponse:
            return "Invalid response from server"
        case .decodingFailed(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        case .serverError(let message):
            return "Server error: \(message)"
        case .noInternet:
            return "No internet connection"
        }
    }
}

class APIClient {
    static let shared = APIClient()
    
    private init() {}
    
    func request<T: Decodable>(endpoint: APIEndpoint, completion: @escaping (Result<T, NetworkError>) -> Void) {
        // Check for internet connection
        if !NetworkReachabilityManager()!.isReachable {
            completion(.failure(.noInternet))
            return
        }
        
        AF.request(endpoint.url,
                  method: .get,
                  parameters: endpoint.parameters)
            .validate()
            .responseDecodable(of: T.self) { response in
                switch response.result {
                case .success(let value):
                    completion(.success(value))
                case .failure(let error):
                    // Try to decode error response
                    if let data = response.data {
                        do {
                            let errorResponse = try JSONDecoder().decode(ErrorResponse.self, from: data)
                            completion(.failure(.serverError(errorResponse.error.message)))
                        } catch {
                            completion(.failure(.decodingFailed(error)))
                        }
                    } else {
                        completion(.failure(.requestFailed(error)))
                    }
                }
            }
    }
}
