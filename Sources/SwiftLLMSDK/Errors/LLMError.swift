import Foundation

public enum LLMProvider: String, Codable, Equatable, Sendable {
    case kobold
    case openRouter
    case openAICompatible
    case unknown
}

public enum LLMErrorSource: String, Codable, Equatable, Sendable {
    case http
    case streamEvent
    case transport
    case decoding
    case cancellation
    case sdk
}

public enum LLMErrorCategory: String, Codable, Equatable, Sendable {
    case authentication
    case authorization
    case rateLimit
    case quotaExceeded
    case contextLength
    case invalidRequest
    case serverError
    case networkError
    case decodingError
    case cancelled
    case unavailable
    case timeout
    case unknown
}

public struct LLMError: Codable, Equatable, Sendable {
    public var message: String
    public var provider: LLMProvider
    public var source: LLMErrorSource
    public var category: LLMErrorCategory
    public var httpStatusCode: Int?
    public var providerCode: String?
    public var providerType: String?
    public var rawBody: String?
    public var rawEvent: String?

    public init(
        message: String,
        provider: LLMProvider,
        source: LLMErrorSource,
        category: LLMErrorCategory,
        httpStatusCode: Int? = nil,
        providerCode: String? = nil,
        providerType: String? = nil,
        rawBody: String? = nil,
        rawEvent: String? = nil
    ) {
        self.message = message
        self.provider = provider
        self.source = source
        self.category = category
        self.httpStatusCode = httpStatusCode
        self.providerCode = providerCode
        self.providerType = providerType
        self.rawBody = rawBody
        self.rawEvent = rawEvent
    }
}

