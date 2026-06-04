import Foundation

public class OpenRouterResponse {
    public var responseContent: ChatCompletionResponse

    public var text: String?
    public var responseTokens: Int?
    public var promptTokens: Int?
    public var role: String?

    public init(
        role: String = "assistant",
        text: String? = "",
        responseTokens: Int? = nil,
        promptTokens: Int? = nil,
        responseContent: ChatCompletionResponse
    ) {
        self.text = text
        self.responseTokens = responseTokens
        self.promptTokens = promptTokens
        self.role = role
        self.responseContent = responseContent
    }    
}

// MARK: - API Response Model
public class ChatCompletionResponse: Codable {
    public var id: String? 
    public var provider: String? 
    public var model: String?
    public var object: String?
    public var created: Int?
    public var systemFingerprint: String? 
    public var usage: ChatCompletionUsage?
    public var choices: [ChatCompletionChoice]?

    enum CodingKeys: String, CodingKey {
        case id
        case provider
        case model
        case object
        case created
        case systemFingerprint = "system_fingerprint"
        case usage
        case choices
    }
}

public class ChatCompletionUsage: Codable {
    public var promptTokens: Int?
    public var completionTokens: Int?
    public var totalTokens: Int?

    enum CodingKeys: String, CodingKey {
        case promptTokens = "prompt_tokens"
        case completionTokens = "completion_tokens"
        case totalTokens = "total_tokens"
    }
}

public class ChatCompletionChoice: Codable {
    public var finishReason: String?
    public var nativeFinishReason: String?
    public var index: Int?
    public var message: ChatCompletionResponseMessage?

    enum CodingKeys: String, CodingKey {
        case finishReason = "finish_reason"
        case nativeFinishReason = "native_finish_reason"
        case index
        case message
    }
}

public class ChatCompletionResponseMessage: Codable {
    public var role: String? 
    public var content: String? 
    public var refusal: Bool?
    public var reasoning: String? 
}

extension ChatCompletionResponse {
    public func toJSON() -> String {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        let requestData = try! encoder.encode(self)
        return String(data: requestData, encoding: .utf8)!
    }

    public func toOpenRouterResponse() -> OpenRouterResponse {
        let result = choices?.first
        return OpenRouterResponse(
            role: result?.message?.role ?? "assistant",
            text: result?.message?.content,
            responseTokens: usage?.completionTokens,
            promptTokens: usage?.promptTokens,
            responseContent: self
        )
    }

    public func toModelResponse() -> ModelResponse {
        return ModelResponse(
            role: choices?.first?.message?.role ?? "assistant",
            text: choices?.first?.message?.content,
            responseTokens: usage?.completionTokens,
            promptTokens: usage?.promptTokens,
            rawResponse: self
        )
    }
}

// MARK: - Streaming (SSE) Chunk Models
public class ChatCompletionStreamChunk: Codable, @unchecked Sendable {
    public var id: String?
    public var provider: String?
    public var model: String?
    public var object: String?
    public var created: Int?
    public var choices: [ChatCompletionStreamChoice]?
    public var usage: ChatCompletionUsage?
}

public class ChatCompletionStreamChoice: Codable, @unchecked Sendable {
    public var index: Int?
    public var delta: ChatCompletionStreamDelta?
    public var finishReason: String?
    public var nativeFinishReason: String?

    enum CodingKeys: String, CodingKey {
        case index
        case delta
        case finishReason = "finish_reason"
        case nativeFinishReason = "native_finish_reason"
    }
}

public class ChatCompletionStreamDelta: Codable, @unchecked Sendable {
    public var role: String?
    public var content: String?
    public var reasoning: String?
    public var reasoningDetails: [ChatCompletionReasoningDetail]?

    enum CodingKeys: String, CodingKey {
        case role
        case content
        case reasoning
        case reasoningDetails = "reasoning_details"
    }
}

public class ChatCompletionReasoningDetail: Codable, @unchecked Sendable {
    public var type: String?
    public var text: String?
    public var format: String?
    public var index: Int?
}

// MARK: - OpenRouter API Key Response
public class OpenRouterAPIKeyResponse: Codable {
    var data: OpenRouterAPIKeyData?
}

public class OpenRouterAPIKeyData: Codable {
    var label: String 
    var usage: Double
    var isFreeTier: Bool
    var isProvisioningKey: Bool
    var limit: Double?
    var limitRemaining: Double? 
    var rateLimit: OpenRouterRateLimit?
    
    enum CodingKeys: String, CodingKey {
        case label
        case usage
        case isFreeTier = "is_free_tier"
        case isProvisioningKey = "is_provisioning_key"
        case limit
        case limitRemaining = "limit_remaining"
        case rateLimit = "rate_limit"
    }
}

public class OpenRouterRateLimit: Codable {
    var requests: Int
    var interval: String
}

@available(*, deprecated, renamed: "ChatCompletionResponse")
public typealias OpenRouterAPIResponse = ChatCompletionResponse

@available(*, deprecated, renamed: "ChatCompletionUsage")
public typealias OpenRouterUsage = ChatCompletionUsage

@available(*, deprecated, renamed: "ChatCompletionChoice")
public typealias OpenRouterChoice = ChatCompletionChoice

@available(*, deprecated, renamed: "ChatCompletionResponseMessage")
public typealias OpenRouterAPIMessage = ChatCompletionResponseMessage

@available(*, deprecated, renamed: "ChatCompletionStreamChunk")
public typealias OpenRouterStreamChunk = ChatCompletionStreamChunk

@available(*, deprecated, renamed: "ChatCompletionStreamChoice")
public typealias OpenRouterStreamChoice = ChatCompletionStreamChoice

@available(*, deprecated, renamed: "ChatCompletionStreamDelta")
public typealias OpenRouterStreamDelta = ChatCompletionStreamDelta

@available(*, deprecated, renamed: "ChatCompletionReasoningDetail")
public typealias OpenRouterReasoningDetail = ChatCompletionReasoningDetail
