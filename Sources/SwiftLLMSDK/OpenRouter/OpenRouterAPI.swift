import Foundation

public protocol OpenRouterBase: LanguageModelService {
    var selectedModel: String { get }
    //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
    // func getAvailableModels() async -> Result<[String], APIError>
    // func getCredits() async -> Result<Int, APIError>
}

public struct OpenRouterAPI: OpenRouterBase {
    public typealias ResponseType = OpenRouterResponse

    public var urlSession: URLSession
    public var baseURL: String
    public var timeoutInterval: TimeInterval

    public var selectedModel: String
    public var apiKey: String?

    public init(
        urlSession: URLSession = URLSession.shared, 
        timeoutInterval: TimeInterval = 60.0, 
        selectedModel: String,
        apiKey: String
    ) {
        self.urlSession = urlSession
        self.baseURL = "https://openrouter.ai/api/v1"
        self.timeoutInterval = timeoutInterval
        self.selectedModel = selectedModel
        self.apiKey = apiKey
    }
    
    public func sendMessage(promptModel: RequestBodyBuilder) async -> Result<OpenRouterResponse, APIError> {
        let openRouterRequest = promptModel.buildOpenRouterBody()
        let openRouterRequestData = openRouterRequest.toJSON().data(using: .utf8)

        let result = await sendRequest(for: OpenRouterAPIResponse.self, path: "/chat/completions", method: "POST", requestBody: openRouterRequestData) 

        switch result {
        case .success(let response):
            return .success(response.toOpenRouterResponse())
        case .failure(let error):
            return .failure(error)
        }
    }

    public func getAvailableModels() async -> Result<[OpenRouterModel], APIError> {

        let models = await sendRequest(
            for: OpenRouterModelList.self,
            path: "/models",
            method: "GET"
        ) 

        switch models {
        case .success(let modelList):
            return .success(modelList.data)
        case .failure(let error):
            return .failure(error)
        }   
    }
}
