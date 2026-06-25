import Foundation

public protocol OpenAPIBase {
    var selectedModel: String? { get }
    func getModels() async -> Result<[OpenAIModel], APIError>
}

public struct OpenAPI: LanguageModelService, OpenAPIBase {

    public var urlSession: URLSession
    public var baseURL: String
    public var timeoutInterval: TimeInterval

    public var selectedModel: String?
    public var apiKey: String?

    public init(
        urlSession: URLSession = URLSession.shared, 
        timeoutInterval: TimeInterval = 60.0,
        baseURL: String, 
        selectedModel: String, 
        apiKey: String? = nil
    ) {
        self.urlSession = urlSession
        self.timeoutInterval = timeoutInterval
        self.baseURL = baseURL
        self.selectedModel = selectedModel
        self.apiKey = apiKey
    }

    public func sendMessage(builder: ChatCompletionRequestBuilder) async -> Result<ModelResponse, APIError> {
        let request = builder.build()
        let requestData = request.toJSON().data(using: .utf8)

        let result = await sendRequest(
            for: ChatCompletionResponse.self,
            provider: .openAICompatible,
            path: "/chat/completions",
            method: "POST",
            requestBody: requestData
        )

        switch result {
        case .success(let response):
            return .success(response.toModelResponse())
        case .failure(let error):
            return .failure(error)
        }
    }

    public func streamMessage(builder: ChatCompletionRequestBuilder) -> AsyncStream<Result<ModelResponse, APIError>> {
        var requestBuilder = builder
        requestBuilder.stream = true
        let request = requestBuilder.build()

        return sendStreamedRequest(
            provider: .openAICompatible,
            path: "/chat/completions",
            method: "POST",
            requestBody: request.toJSON().data(using: .utf8)
        )
    }

    public func getModels() async -> Result<[OpenAIModel], APIError> {
        let models = await sendRequest(
            for: OpenAIModelList.self, 
            provider: .openAICompatible,
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
