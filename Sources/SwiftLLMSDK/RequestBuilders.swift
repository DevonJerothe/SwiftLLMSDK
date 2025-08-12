import Foundation

/// Protocol for provider-specific request builders that can produce an Encodable request model.
public protocol EncodableRequestBuilder {
    associatedtype RequestModel: Encodable
    func build() -> RequestModel
}

// MARK: - OpenRouter
public struct OpenRouterRequestBuilder: EncodableRequestBuilder {
    public typealias RequestModel = OpenRouterPromptModel

    // Required
    public var model: String
    public var messages: [RequestBodyMessages]

    // Optional tuning
    public var stop: [String]?
    public var temperature: Double?
    public var topP: Double?
    public var minP: Double?
    public var topA: Double?
    public var topK: Double?
    public var maxTokens: Int?
    public var repetitionPenalty: Double?
    public var frequencyPenalty: Double?
    public var presencePenalty: Double?
    public var stream: Bool? = nil

    // System context
    public var systemPromptTemplate: String?
    public var characterDescription: String?
    public var characterPersonality: String?
    public var characterScenario: String?

    public init(
        model: String,
        messages: [RequestBodyMessages] = [],
        stop: [String]? = nil,
        temperature: Double? = nil,
        topP: Double? = nil,
        minP: Double? = nil,
        topA: Double? = nil,
        topK: Double? = nil,
        maxTokens: Int? = nil,
        repetitionPenalty: Double? = nil,
        frequencyPenalty: Double? = nil,
        presencePenalty: Double? = nil,
        stream: Bool? = nil,
        systemPromptTemplate: String? = nil,
        characterDescription: String? = nil,
        characterPersonality: String? = nil,
        characterScenario: String? = nil
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
        self.frequencyPenalty = frequencyPenalty
        self.presencePenalty = presencePenalty
        self.stream = stream
        self.systemPromptTemplate = systemPromptTemplate
        self.characterDescription = characterDescription
        self.characterPersonality = characterPersonality
        self.characterScenario = characterScenario
    }

    public func build() -> OpenRouterPromptModel {
        var systemMessages: [OpenRouterMessage] = []
        if let systemPromptTemplate {
            systemMessages.append(OpenRouterMessage(role: "system", content: systemPromptTemplate))
        }
        if let characterDescription {
            systemMessages.append(OpenRouterMessage(role: "system", content: characterDescription))
        }
        if let characterPersonality {
            systemMessages.append(OpenRouterMessage(role: "system", content: characterPersonality))
        }
        if let characterScenario {
            systemMessages.append(OpenRouterMessage(role: "system", content: characterScenario))
        }

        let chatMessages: [OpenRouterMessage] = messages.map { OpenRouterMessage(role: $0.role.rawValue, content: $0.message) }
        let openRouterMessages = systemMessages + chatMessages

        return OpenRouterPromptModel(
            model: model,
            messages: openRouterMessages,
            stop: stop,
            temperature: temperature,
            topP: topP,
            minP: minP,
            topA: topA,
            topK: topK,
            maxTokens: maxTokens,
            repetitionPenalty: repetitionPenalty,
            stream: stream,
            presencePenalty: presencePenalty,
            frequencyPenalty: frequencyPenalty
        )
    }
}

// MARK: - Kobold
public struct KoboldRequestBuilder: EncodableRequestBuilder {
    public typealias RequestModel = KoboldPromptModel

    // Required
    public var prompt: String

    // Optional
    public var memory: String?
    public var maxContextLength: Int?
    public var maxLength: Int?
    public var temperature: Double?
    public var tfs: Int?
    public var topA: Double?
    public var topK: Double?
    public var topP: Double?
    public var minP: Double?
    public var typical: Int?
    public var repetitionPenalty: Double?
    public var repetitionRange: Int?
    public var repetitionSlope: Double?
    public var stopSequence: [String]?
    public var trimStop: Bool?
    public var samplerOrder: [Int]?
    public var promptTemplate: String?

    public init(
        prompt: String,
        memory: String? = nil,
        maxContextLength: Int? = 4096,
        maxLength: Int? = 240,
        temperature: Double? = 0.75,
        tfs: Int? = 1,
        topA: Double? = 0.92,
        topK: Double? = 100,
        topP: Double? = 0.92,
        minP: Double? = 0,
        typical: Int? = 1,
        repetitionPenalty: Double? = 1.07,
        repetitionRange: Int? = 360,
        repetitionSlope: Double? = 0.7,
        stopSequence: [String]? = ["\nUser:", "\nBot:"],
        trimStop: Bool? = true,
        samplerOrder: [Int]? = [6, 0, 1, 3, 4, 2, 5],
        promptTemplate: String? = nil
    ) {
        self.prompt = prompt
        self.memory = memory
        self.maxContextLength = maxContextLength
        self.maxLength = maxLength
        self.temperature = temperature
        self.tfs = tfs
        self.topA = topA
        self.topK = topK
        self.topP = topP
        self.minP = minP
        self.typical = typical
        self.repetitionPenalty = repetitionPenalty
        self.repetitionRange = repetitionRange
        self.repetitionSlope = repetitionSlope
        self.stopSequence = stopSequence
        self.trimStop = trimStop
        self.samplerOrder = samplerOrder
        self.promptTemplate = promptTemplate
    }

    public func build() -> KoboldPromptModel {
        KoboldPromptModel(
            maxContextLength: maxContextLength,
            maxLength: maxLength,
            prompt: prompt,
            repPen: repetitionPenalty,
            repPenRange: repetitionRange,
            repPenSlope: repetitionSlope,
            temperature: temperature,
            tfs: tfs,
            topA: topA,
            topK: topK,
            topP: topP,
            minP: minP,
            typical: typical,
            memory: memory,
            stopSequence: stopSequence,
            trimStop: trimStop,
            samplerOrder: samplerOrder,
            promptTemplate: promptTemplate
        )
    }
}


