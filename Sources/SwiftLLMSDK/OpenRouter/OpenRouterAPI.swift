import Foundation

public protocol OpenRouterBase {
    var selectedModel: String? { get }
    func getAvailableModels() async -> Result<[OpenRouterModel], APIError>
}

public struct OpenRouterAPI: LanguageModelService, OpenRouterBase {
    public typealias ResponseType = OpenRouterResponse

    public var urlSession: URLSession
    public var baseURL: String
    public var timeoutInterval: TimeInterval

    public var selectedModel: String?
    public var apiKey: String?

    public init(
        urlSession: URLSession = URLSession.shared, 
        timeoutInterval: TimeInterval = 60.0, 
        selectedModel: String? = nil,
        apiKey: String? = nil
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

    public func checkAPIKey() async -> Result<String, APIError> {
        let result = await sendRequest(for: OpenRouterAPIKeyResponse.self, path: "/key", method: "GET")
        
        switch result {
        case .success(let response):
            if let label = response.data?.label {
                return .success(label)
            } else {
                return .failure(.invalidResponse)
            }
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
