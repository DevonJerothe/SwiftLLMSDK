import Foundation

public enum APIError: Error, LocalizedError {
    case invalidURL
    case invalidResponse
    case invalidData
    case decodingError
    case timeout
    case serverError(code: Int)
    case invalidService
    case unsupportedURLImport

    public var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .invalidResponse:
            return "Invalid response"
        case .invalidData:
            return "Invalid data"
        case .decodingError:
            return "Decoding error"
        case .timeout:
            return "Timeout"
        case .serverError(code: let code):
            return "Server error (\(code))"
        case .invalidService:
            return "Invalid service type"
        case .unsupportedURLImport:
            return "Unsupported URL import"
        }
    }
}
