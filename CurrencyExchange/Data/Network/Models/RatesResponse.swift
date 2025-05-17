import Foundation

struct RatesResponse: Codable {
    let success: Bool
    let timestamp: Int
    let base: String
    let date: String
    let rates: [String: Double]
}

struct ErrorResponse: Codable {
    let success: Bool
    let error: APIError
}

struct APIError: Codable {
    let code: String
    let message: String
}
