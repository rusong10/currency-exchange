import UIKit

enum AppError: Error {
    case network(String)
    case dataFetch(String)
    case conversion(String)
    case unknown
    
    var message: String {
        switch self {
        case .network(let message):
            return "Network Error: \(message)"
        case .dataFetch(let message):
            return "Data Error: \(message)"
        case .conversion(let message):
            return "Conversion Error: \(message)"
        case .unknown:
            return "An unknown error occurred. Please try again."
        }
    }
}

class ErrorHandler {
    static func handle(_ error: Error, in viewController: UIViewController, retryAction: (() -> Void)? = nil) {
        let message: String
        
        if let appError = error as? AppError {
            message = appError.message
        } else if let networkError = error as? NetworkError {
            switch networkError {
            case .noInternet:
                message = "No internet connection. Please check your connection and try again."
            case .requestFailed:
                message = "Failed to connect to the server. Please try again later."
            case .invalidResponse:
                message = "Received an invalid response from the server."
            case .decodingFailed:
                message = "Failed to process the server response."
            case .serverError(let errorMessage):
                message = "Server error: \(errorMessage)"
            }
        } else {
            message = error.localizedDescription
        }
        
        let alert = UIAlertController(
            title: "Error",
            message: message,
            preferredStyle: .alert
        )
        
        if let retry = retryAction {
            alert.addAction(UIAlertAction(title: "Retry", style: .default) { _ in
                retry()
            })
        }
        
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        
        viewController.present(alert, animated: true)
    }
}
