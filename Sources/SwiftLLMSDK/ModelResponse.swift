import Foundation

public protocol ModelResponse {
    var role: String? { get }
    var text: String? { get }
    var responseTokens: Int? { get }
    var promptTokens: Int? { get }
}