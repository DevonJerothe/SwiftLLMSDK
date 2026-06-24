import Foundation

public enum OpenRouterReasoningEffort: String, Codable {
    case none = "none"
    case low = "low"
    case medium = "medium"
    case high = "high"
}

public class ChatCompletionRequest: Codable {
    public var model: String
    public var messages: [ChatCompletionMessage]? 
    public var stop: [String]?
    public var temperature: Double?
    public var topP: Double?
    public var minP: Double?
    public var topA: Double?
    public var topK: Double?
    public var maxTokens: Int?
    public var repetitionPenalty: Double?
    public var stream: Bool?
    public var presencePenalty: Double?
    public var frequencyPenalty: Double?
    public var seed: Int?
    public var reasoning: OpenRouterReasoning?
    public var reasoningEffort: OpenRouterReasoningEffort?

    public init(
        model: String,
        messages: [ChatCompletionMessage]? = nil,
        stop: [String]? = nil,
        temperature: Double? = nil,
        topP: Double? = nil,
        minP: Double? = nil,
        topA: Double? = nil,
        topK: Double? = nil,
        maxTokens: Int? = nil,
        repetitionPenalty: Double? = nil,
        stream: Bool? = nil,
        presencePenalty: Double? = nil,
        frequencyPenalty: Double? = nil,
        seed: Int? = nil,
        excludeReasoning: Bool? = false, 
        reasoningEffort: OpenRouterReasoningEffort? = .medium
    ) {
        self.model = model
        self.messages = messages
        self.stop = stop
        self.temperature = temperature
        self.topP = topP
        self.minP = minP
        self.topA = topA
        self.topK = topK
        self.maxTokens = maxTokens
        self.repetitionPenalty = repetitionPenalty
        self.stream = stream
        self.presencePenalty = presencePenalty
        self.frequencyPenalty = frequencyPenalty
        self.seed = seed
        self.reasoningEffort = reasoningEffort

        if reasoningEffort != nil || excludeReasoning != nil {
            self.reasoning = OpenRouterReasoning(
                effort: reasoningEffort,
                exclude: excludeReasoning
            )
        }
    }
}

public struct OpenRouterReasoning: Codable {
    public var effort: OpenRouterReasoningEffort? 
    public var maxTokens: Int? 
    public var exclude: Bool?

    public init(
        effort: OpenRouterReasoningEffort? = .medium,
        maxTokens: Int? = nil,
        exclude: Bool? = nil
    ) {
        self.effort = effort
        self.maxTokens = maxTokens
        self.exclude = exclude
    }
}

public struct ChatCompletionMessage: Codable {
    public var role: String
    public var content: ChatCompletionMessageContent

    public init(role: String, content: String) {
        self.role = role 
        self.content = .string(content)
    }

    public init(role: String, parts: [ChatCompletionMessageContentPart]) {
        self.role = role
        self.content = .parts(parts)
    }
}

public enum ChatCompletionMessageContent: Codable {
    case string(String)
    case parts([ChatCompletionMessageContentPart])

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let parts = try? container.decode([ChatCompletionMessageContentPart].self) {
            self = .parts(parts)
        } else if let text = try? container.decode(String.self) {
            self = .string(text)
        } else {
            throw DecodingError.typeMismatch(ChatCompletionMessageContent.self, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Expected string or parts"))
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
            case .string(let text):
                try container.encode(text)
            case .parts(let parts):
                try container.encode(parts)
        }
    }
}

public struct ChatCompletionMessageContentPart: Codable {
    public var type: String
    public var text: String?
    public var imageUrl: ImageURLPart?
}

public struct ImageURLPart: Codable {
    public var url: String?
}

extension ChatCompletionRequest {
    public func toJSON() -> String {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        let requestData = try! encoder.encode(self)
        return String(data: requestData, encoding: .utf8)!
    }
}

@available(*, deprecated, renamed: "ChatCompletionRequest")
public typealias OpenRouterPromptModel = ChatCompletionRequest

@available(*, deprecated, renamed: "ChatCompletionMessage")
public typealias OpenRouterMessage = ChatCompletionMessage

@available(*, deprecated, renamed: "ChatCompletionMessageContent")
public typealias OpenRouterMessageContent = ChatCompletionMessageContent

@available(*, deprecated, renamed: "ChatCompletionMessageContentPart")
public typealias OpenRouterMessageContentParts = ChatCompletionMessageContentPart
