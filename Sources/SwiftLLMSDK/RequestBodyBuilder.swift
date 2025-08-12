import Foundation

public enum OpenRouterMessageRole: String, Codable {
    case system = "system"
    case developer = "developer"
    case user = "user"
    case assistant = "assistant"
    case tool = "tool"
}

/// RequestBodyBuilder centralizes prompt parameters for multiple providers
/// (e.g., OpenRouter chat and KoboldCPP text generation). Use the provider-
/// specific convenience initializers to populate only the relevant fields.
public class RequestBodyBuilder {
    // Character Card Info
    // This is used to set up the system prompt when using chat completion, otherwise its all added to the memory
    public var characterDescription: String? 
    public var characterPersonality: String? 
    public var characterScenario: String? 

    // OpenRouter - chat completion
    public var selectedModel: String
    public var frequencyPen: Double?
    public var presencePen: Double?

    // Kobold
    public var typical: Int? 
    public var memory: String? 
    public var trimStop: Bool?
    public var repatitionRange: Int?
    public var repatitionSlope: Double?
    public var tfs: Int?
    public var samplerOrder: [Int]?

    // Shared
    public var messages: [RequestBodyMessages]
    public var prompt: String? 
    public var maxContextLength: Int?
    public var promptTemplate: String? 
    public var stopSequence: [String]?
    public var temperature: Double?
    public var topP: Double?
    public var minP: Double?
    public var topA: Double?
    public var topK: Double?
    public var maxLength: Int?
    public var repatitionPen: Double?

    // Correctly spelled synonyms (non-breaking) for repetition* values
    // Prefer these in new call sites; they forward to existing properties.
    public var repetitionPenalty: Double? {
        get { repatitionPen }
        set { repatitionPen = newValue }
    }
    public var repetitionRange: Int? {
        get { repatitionRange }
        set { repatitionRange = newValue }
    }
    public var repetitionSlope: Double? {
        get { repatitionSlope }
        set { repatitionSlope = newValue }
    }

    public init(
        selectedModel: String = "openai/gpt-4o-mini",
        messages: [RequestBodyMessages] = [],
        memory: String? = nil,
        prompt: String? = nil,
        maxContextLength: Int = 4096,
        maxLength: Int = 240,
        temperature: Double = 0.75,
        topP: Double = 0.92,
        minP: Double = 0,
        topA: Double = 0.92,
        topK: Double = 100,
        stopSequence: [String] = ["\nUser:", "\nAssistant:"],
        trimStop: Bool = true,
        samplerOrder: [Int] = [6, 0, 1, 3, 4, 2, 5],
        frequencyPen: Double = 0,
        presencePen: Double = 0, 
        repatitionRange: Int = 360,
        repatitionSlope: Double = 0.7,
        tfs: Int = 1,
        repatitionPen: Double = 1.07,
        typical: Int = 1,
        promptTemplate: String? = nil, 
        characterDescription: String? = nil,
        characterPersonality: String? = nil,
        characterScenario: String? = nil
    ) {
        self.selectedModel = selectedModel
        self.messages = messages
        self.memory = memory
        self.prompt = prompt
        self.maxContextLength = maxContextLength
        self.maxLength = maxLength
        self.temperature = temperature
        self.topP = topP
        self.minP = minP
        self.topA = topA
        self.topK = topK
        self.stopSequence = stopSequence
        self.trimStop = trimStop
        self.samplerOrder = samplerOrder
        self.frequencyPen = frequencyPen
        self.presencePen = presencePen
        self.repatitionRange = repatitionRange
        self.repatitionSlope = repatitionSlope
        self.tfs = tfs
        self.repatitionPen = repatitionPen
        self.typical = typical
        self.promptTemplate = promptTemplate
        self.characterDescription = characterDescription
        self.characterPersonality = characterPersonality
        self.characterScenario = characterScenario
    }

    // MARK: - Provider-specific convenience initializers

    /// OpenRouter-focused initializer that sets only OpenRouter-relevant fields.
    /// Kobold-specific fields are left nil/unused.
    public convenience init(
        forOpenRouterModel model: String,
        messages: [RequestBodyMessages] = [],
        temperature: Double = 0.75,
        topP: Double = 0.92,
        minP: Double = 0,
        topA: Double = 0.92,
        topK: Double = 100,
        maxTokens: Int = 240,
        repetitionPenalty: Double = 1.07,
        frequencyPenalty: Double = 0,
        presencePenalty: Double = 0,
        stop: [String] = ["\nUser:", "\nAssistant:"],
        systemPromptTemplate: String? = nil,
        characterDescription: String? = nil,
        characterPersonality: String? = nil,
        characterScenario: String? = nil
    ) {
        self.init(
            selectedModel: model,
            messages: messages,
            memory: nil,
            prompt: nil,
            maxContextLength: 4096,
            maxLength: maxTokens,
            temperature: temperature,
            topP: topP,
            minP: minP,
            topA: topA,
            topK: topK,
            stopSequence: stop,
            trimStop: true,
            samplerOrder: [6, 0, 1, 3, 4, 2, 5],
            frequencyPen: frequencyPenalty,
            presencePen: presencePenalty,
            repatitionRange: 360,
            repatitionSlope: 0.7,
            tfs: 1,
            repatitionPen: repetitionPenalty,
            typical: 1,
            promptTemplate: systemPromptTemplate,
            characterDescription: characterDescription,
            characterPersonality: characterPersonality,
            characterScenario: characterScenario
        )
    }

    /// Kobold-focused initializer that sets only Kobold-relevant fields.
    /// OpenRouter-specific fields are populated but unused by Kobold.
    public convenience init(
        forKoboldWithPrompt prompt: String,
        memory: String? = nil,
        maxContextLength: Int = 4096,
        maxLength: Int = 240,
        temperature: Double = 0.75,
        tfs: Int = 1,
        topA: Double = 0.92,
        topK: Double = 100,
        topP: Double = 0.92,
        minP: Double = 0,
        typical: Int = 1,
        repetitionPenalty: Double = 1.07,
        repetitionRange: Int = 360,
        repetitionSlope: Double = 0.7,
        stopSequence: [String] = ["\nUser:", "\nBot:"],
        trimStop: Bool = true,
        samplerOrder: [Int] = [6, 0, 1, 3, 4, 2, 5],
        promptTemplate: String? = nil
    ) {
        self.init(
            selectedModel: "",
            messages: [],
            memory: memory,
            prompt: prompt,
            maxContextLength: maxContextLength,
            maxLength: maxLength,
            temperature: temperature,
            topP: topP,
            minP: minP,
            topA: topA,
            topK: topK,
            stopSequence: stopSequence,
            trimStop: trimStop,
            samplerOrder: samplerOrder,
            frequencyPen: nil ?? 0,
            presencePen: nil ?? 0,
            repatitionRange: repetitionRange,
            repatitionSlope: repetitionSlope,
            tfs: tfs,
            repatitionPen: repetitionPenalty,
            typical: typical,
            promptTemplate: promptTemplate,
            characterDescription: nil,
            characterPersonality: nil,
            characterScenario: nil
        )
    }

    public func buildOpenRouterBody() -> OpenRouterPromptModel {
        // build system messages from our character card info
        var systemMessages: [OpenRouterMessage] = []
        if let systemPrompt = self.promptTemplate {
            systemMessages.append(OpenRouterMessage(role: "system", content: systemPrompt))
        }
        if let description = self.characterDescription {
            systemMessages.append(OpenRouterMessage(role: "system", content: description))
        }
        if let personality = self.characterPersonality {
            systemMessages.append(OpenRouterMessage(role: "system", content: personality))
        }
        if let scenario = self.characterScenario {
            systemMessages.append(OpenRouterMessage(role: "system", content: scenario))
        }
        
        // build chat messages from our user / character messages
        let chatMessages = messages.map { message in
            return OpenRouterMessage(role: message.role.rawValue, content: message.message)
        }

        // combine system and chat messages
        let openRouterMessages = systemMessages + chatMessages

        let openRouterModel = OpenRouterPromptModel(
            model: self.selectedModel,
            messages: openRouterMessages,
            stop: self.stopSequence,
            temperature: self.temperature,
            topP: self.topP,
            minP: self.minP,
            topA: self.topA,
            topK: self.topK,
            maxTokens: self.maxLength,
            repetitionPenalty: self.repatitionPen,
            presencePenalty: self.presencePen,
            frequencyPenalty: self.frequencyPen
        )
        return openRouterModel
    }

    public func buildKoboldBody() -> KoboldPromptModel {
        /// Kobold uses two properties `memory` and `prompt` all system prompt instructions should
        /// be added to the `memory` field and messages should be added to `prompt` along with their stop sequence
        /// if prompt is passed to the model we should assume this already contains the messages. 
        let koboldPrompt = self.prompt

        let koboldPromptModel = KoboldPromptModel(
            maxContextLength: self.maxContextLength, 
            maxLength: self.maxLength, 
            prompt: koboldPrompt ?? "",
            repPen: self.repatitionPen,
            repPenRange: self.repatitionRange,
            repPenSlope: self.repatitionSlope,
            temperature: self.temperature,
            tfs: self.tfs,
            topA: self.topA,
            topK: self.topK,
            topP: self.topP,
            minP: self.minP,
            typical: self.typical,
            memory: self.memory,
            stopSequence: self.stopSequence,
            trimStop: self.trimStop,
            samplerOrder: self.samplerOrder,
            promptTemplate: self.promptTemplate  
        ) 
        return koboldPromptModel
    }
}

public class RequestBodyMessages {
    public var role: OpenRouterMessageRole
    public var message: String

    public init(role: OpenRouterMessageRole, message: String) {
        self.role = role
        self.message = message
    }
}
