import Foundation

public enum OpenRouterMessageRole: String, Codable {
    case system = "system" // this would be the system prompt
    case developer = "developer"
    case user = "user"
    case assistant = "assistant" // this would be the prompt
    case tool = "tool"
}

/// A base model for building the request body for the selected API. 
/// TODO: We should improve the initialization of this class to use a builder pattern so that 
/// seperation of concerns is maintained. If we know we are building for Kobold we should dont care 
/// about the OpenRouter properties and vice versa. 
public class RequestBodyBuilder {
    // Character Card Info
    // This is used to set up the system prompt when using chat completion, otherwise its all added to the memory
    public var characterDescription: String? 
    public var characterPersonality: String? 
    public var characterScenario: String? 

    // OpenRouter - Chat Completion
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
