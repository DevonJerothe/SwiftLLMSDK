import Foundation 

public class OpenRouterModelList: Codable {
    let data: [OpenRouterModel]

    init(data: [OpenRouterModel]) {
        self.data = data
    }
}

public class OpenRouterModel: Codable {
    let id: String
    let name: String
    let created: Double
    let description: String
    let architecture: Architecture
    let topProvider: TopProvider
    let pricing: Pricing
    let contextLength: Double?
    let perRequestLimits: PerRequestLimits?

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case created
        case description
        case architecture
        case topProvider = "top_provider"
        case pricing
        case contextLength = "context_length"
        case perRequestLimits = "per_request_limits"
    }

    init(
        id: String,
        name: String,
        created: Double,
        description: String,
        architecture: Architecture,
        topProvider: TopProvider,
        pricing: Pricing,
        contextLength: Double? = nil,
        perRequestLimits: PerRequestLimits? = nil
    ) {
        self.id = id
        self.name = name
        self.created = created
        self.description = description
        self.architecture = architecture
        self.topProvider = topProvider
        self.pricing = pricing
        self.contextLength = contextLength
        self.perRequestLimits = perRequestLimits
    }
}

public class Architecture: Codable {
    let inputModalities: [String]
    let outputModalities: [String]
    let tokenizer: String
    let instructType: String?

    enum CodingKeys: String, CodingKey {
        case inputModalities = "input_modalities"
        case outputModalities = "output_modalities"
        case instructType = "instruct_type"
        case tokenizer
    }

    init(inputModalities: [String], outputModalities: [String], tokenizer: String, instructType: String? = nil) {
        self.inputModalities = inputModalities
        self.outputModalities = outputModalities
        self.tokenizer = tokenizer
        self.instructType = instructType
    }
}

public class TopProvider: Codable {
    let isModerated: Bool 
    let contextLength: Double?
    let maxCompletionTokens: Double?

    enum CodingKeys: String, CodingKey {
        case isModerated = "is_moderated"
        case contextLength = "context_length"
        case maxCompletionTokens = "max_completion_tokens"
    }

    init(isModerated: Bool, contextLength: Double? = nil, maxCompletionTokens: Double? = nil) {
        self.isModerated = isModerated
        self.contextLength = contextLength
        self.maxCompletionTokens = maxCompletionTokens
    }
}

public class Pricing: Codable {
    let prompt: String 
    let completion: String
    let image: String
    let request: String 
    let inputCacheRead: String 
    let inputChacheWrite: String 
    let webSearch: String
    let internalReasoning: String

    enum CodingKeys: String, CodingKey {
        case prompt
        case completion
        case image
        case request
        case inputCacheRead = "input_cache_read"
        case inputChacheWrite = "input_cache_write"
        case webSearch = "web_search"
        case internalReasoning = "internal_reasoning"
    }

    init(
        prompt: String,
        completion: String,
        image: String,
        request: String,
        inputCacheRead: String,
        inputChacheWrite: String,
        webSearch: String,
        internalReasoning: String
    ) {
        self.prompt = prompt
        self.completion = completion
        self.image = image
        self.request = request
        self.inputCacheRead = inputCacheRead
        self.inputChacheWrite = inputChacheWrite
        self.webSearch = webSearch
        self.internalReasoning = internalReasoning
    }
}

public class PerRequestLimits: Codable {
    let key: String 

    enum CodingKeys: String, CodingKey {
        case key
    }

    init(key: String) {
        self.key = key
    }
}