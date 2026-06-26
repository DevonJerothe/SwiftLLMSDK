import Foundation

public enum ConnectionVerification: String, Codable, Sendable {
    case serviceMetadata
    case chatCompletion
}

public struct ConnectionCheckResult: Codable, Sendable {
    public let provider: LLMProvider
    public let verification: ConnectionVerification
    public let endpoint: String
    public let model: String?
    public let message: String

    public var isChatReady: Bool {
        verification == .chatCompletion
    }

    public init(
        provider: LLMProvider,
        verification: ConnectionVerification,
        endpoint: String,
        model: String?,
        message: String
    ) {
        self.provider = provider
        self.verification = verification
        self.endpoint = endpoint
        self.model = model
        self.message = message
    }
}
