import Foundation 

public class OpenRouterModelList: Codable {
    public let data: [OpenRouterModel]

    public init(data: [OpenRouterModel]) {
        self.data = data
    }
}

public class OpenRouterModel: Codable {
    public let id: String
    public let huggingFaceId: String?
    public let name: String
    public let created: Double
    public let description: String
    public let contextLength: Int?
    public let architecture: Architecture
    public let pricing: Pricing
    public let topProvider: TopProvider
    public let perRequestLimits: PerRequestLimits?
    public let supportedParameters: [String]?

    enum CodingKeys: String, CodingKey {
        case id
        case huggingFaceId = "hugging_face_id"
        case name
        case created
        case description
        case contextLength = "context_length"
        case architecture
        case pricing
        case topProvider = "top_provider"
        case perRequestLimits = "per_request_limits"
        case supportedParameters = "supported_parameters"
    }

    public init(
        id: String,
        huggingFaceId: String? = nil,
        name: String,
        created: Double,
        description: String,
        contextLength: Int? = nil,
        architecture: Architecture,
        pricing: Pricing,
        topProvider: TopProvider,
        perRequestLimits: PerRequestLimits? = nil,
        supportedParameters: [String]? = nil
    ) {
        self.id = id
        self.huggingFaceId = huggingFaceId
        self.name = name
        self.created = created
        self.description = description
        self.contextLength = contextLength
        self.architecture = architecture
        self.pricing = pricing
        self.topProvider = topProvider
        self.perRequestLimits = perRequestLimits
        self.supportedParameters = supportedParameters
    }
}

public class Architecture: Codable {
    public let modality: String?
    public let inputModalities: [String]
    public let outputModalities: [String]
    public let tokenizer: String
    public let instructType: String?

    enum CodingKeys: String, CodingKey {
        case modality
        case inputModalities = "input_modalities"
        case outputModalities = "output_modalities"
        case tokenizer
        case instructType = "instruct_type"
    }

    public init(
        modality: String? = nil,
        inputModalities: [String],
        outputModalities: [String],
        tokenizer: String,
        instructType: String? = nil
    ) {
        self.modality = modality
        self.inputModalities = inputModalities
        self.outputModalities = outputModalities
        self.tokenizer = tokenizer
        self.instructType = instructType
    }
}

public class TopProvider: Codable {
    public let contextLength: Int?
    public let maxCompletionTokens: Int?
    public let isModerated: Bool 

    enum CodingKeys: String, CodingKey {
        case contextLength = "context_length"
        case maxCompletionTokens = "max_completion_tokens"
        case isModerated = "is_moderated"
    }

    public init(
        contextLength: Int? = nil,
        maxCompletionTokens: Int? = nil,
        isModerated: Bool
    ) {
        self.contextLength = contextLength
        self.maxCompletionTokens = maxCompletionTokens
        self.isModerated = isModerated
    }
}

public class Pricing: Codable {
    public let prompt: String? 
    public let completion: String?
    public let request: String? 
    public let image: String?
    public let webSearch: String?
    public let internalReasoning: String?

    enum CodingKeys: String, CodingKey {
        case prompt
        case completion
        case request
        case image
        case webSearch = "web_search"
        case internalReasoning = "internal_reasoning"
    }

    public init(
        prompt: String? = nil,
        completion: String? = nil,
        request: String? = nil,
        image: String? = nil,
        webSearch: String? = nil,
        internalReasoning: String? = nil
    ) {
        self.prompt = prompt
        self.completion = completion
        self.request = request
        self.image = image
        self.webSearch = webSearch
        self.internalReasoning = internalReasoning
    }
}

public class PerRequestLimits: Codable {
    // This can be null in the JSON, so we'll make it a simple optional type
    // If you need specific structure, adjust based on actual non-null examples
    
    public init() {
        // Empty init for when it's null
    }
}
