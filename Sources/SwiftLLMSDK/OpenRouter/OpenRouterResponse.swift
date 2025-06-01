import Foundation

public class OpenRouterResponse {
    public var responseContent: OpenRouterAPIResponse

    public var text: String?
    public var responseTokens: Int?
    public var promptTokens: Int?
    public var role: String?

    public init(
        role: String = "assistant",
        text: String? = "",
        responseTokens: Int? = nil,
        promptTokens: Int? = nil,
        responseContent: OpenRouterAPIResponse
    ) {
        self.text = text
        self.responseTokens = responseTokens
        self.promptTokens = promptTokens
        self.role = role
        self.responseContent = responseContent
    }    
}

// MARK: - API Response Model
public class OpenRouterAPIResponse: Codable {
    var id: String? 
    var provider: String? 
    var model: String?
    var object: String?
    var created: Int?
    var systemFingerprint: String? 
    var usage: OpenRouterUsage?
    var choices: [OpenRouterChoice]?
}

public class OpenRouterUsage: Codable {
    var promptTokens: Int?
    var completionTokens: Int?
    var totalTokens: Int?
}

public class OpenRouterChoice: Codable {
    var finishReason: String?
    var nativeFinishReason: String?
    var index: Int?
    var message: OpenRouterAPIMessage?
}

public class OpenRouterAPIMessage: Codable {
    var role: String? 
    var content: String? 
    var refusal: Bool?
    var reasoning: String? 
}

extension OpenRouterAPIResponse {
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
}
