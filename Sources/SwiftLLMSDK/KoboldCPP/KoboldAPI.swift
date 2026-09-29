import Foundation

public protocol KoboldAPIBase {
    func getModel() async -> Result<String, APIError>
    func getMaxLength() async -> Result<Int, APIError>
    func getVersion() async -> Result<String, APIError>
}

public struct KoboldAPI: LanguageModelService, KoboldAPIBase {
    // public typealias ResponseType = KoboldResponse
    
    public var urlSession: URLSession
    public var baseURL: String
    public var timeoutInterval: TimeInterval
    public var apiKey: String? = nil

    public init(urlSession: URLSession = URLSession.shared, host: String, port: Int, timeoutInterval: TimeInterval = 120.0) {
        self.urlSession = urlSession
        self.baseURL = "http://\(host):\(port)"
        self.timeoutInterval = timeoutInterval
    }

    public func getMaxContextLength() async -> Result<Int, APIError> {
        await getInt(endpoint: "/api/extra/true_max_context_length", provider: .kobold)
    }

    public func getMaxLength() async -> Result<Int, APIError> {
        await getInt(endpoint: "/api/v1/config/max_length", provider: .kobold)
    }

    public func getVersion() async -> Result<String, APIError> {
        await getString(endpoint: "/api/v1/info/version", provider: .kobold)
    }

    public func getModel() async -> Result<String, APIError> {
        await getString(endpoint: "/api/v1/model", provider: .kobold)
    }

    public func checkConnection() async -> Result<ConnectionCheckResult, APIError> {
        let result = await getModel()

        switch result {
        case .success(let model):
            return .success(ConnectionCheckResult(
                provider: .kobold,
                verification: .serviceMetadata,
                endpoint: "/api/v1/model",
                model: model,
                message: "Model metadata probe succeeded."
            ))
        case .failure(let error):
            return .failure(error)
        }
    }

    public func countTokens(text: String) async -> Result<Int, APIError> {
        let requestBody = [
            "prompt": text
        ]

        guard let jsonData = try? JSONSerialization.data(withJSONObject: requestBody, options: []) else {
            return .failure(.invalidData)
        }

        let result = await sendRequest(
            for: IntResponse.self,
            provider: .kobold,
            path: "/api/extra/tokencount", 
            method: "POST", 
            requestBody: jsonData
        )

        switch result {
        case .success(let response):
            return .success(response.value)
        case .failure(let error):
            return .failure(error)
        }
    }

    public func streamMessage(builder: KoboldRequestBuilder) -> AsyncStream<Result<ModelResponse, APIError>> {
        let requestModel = builder.build()

        return sendStreamedRequest(
            provider: .kobold,
            path: "/api/extra/generate/stream",
            method: "POST",
            requestBody: requestModel.toJSON().data(using: .utf8)
        )
    }

    /// Uses KoboldCPP's OpenAI-compatible endpoint for structured chat and
    /// tool-calling requests.
    public func streamMessage(builder: ChatCompletionRequestBuilder) -> AsyncStream<Result<ModelResponse, APIError>> {
        var requestBuilder = builder
        requestBuilder.stream = true
        let requestModel = requestBuilder.build()

        return sendStreamedRequest(
            provider: .kobold,
            path: "/v1/chat/completions",
            method: "POST",
            requestBody: requestModel.toJSON().data(using: .utf8),
            wireFormat: .chatCompletions
        )
    }

    public func sendMessage(promptModel: RequestBodyBuilder) async -> Result<ModelResponse, APIError> {
        let koboldRequest = promptModel.buildKoboldBody()
        let koboldRequestData = koboldRequest.toJSON().data(using: .utf8)

        let result = await sendRequest(for: KoboldAPIResponse.self, provider: .kobold, path: "/api/v1/generate", method: "POST", requestBody: koboldRequestData)

        switch result {
        case .success(let response):
            return .success(response.toModelResponse())
        case .failure(let error):
            return .failure(error)
        }
    }

    // Overload: send using provider-specific builder
    public func sendMessage(builder: KoboldRequestBuilder) async -> Result<ModelResponse, APIError> {
        let koboldRequest = builder.build()
        let koboldRequestData = koboldRequest.toJSON().data(using: .utf8)

        let result = await sendRequest(
            for: KoboldAPIResponse.self,
            provider: .kobold,
            path: "/api/v1/generate",
            method: "POST",
            requestBody: koboldRequestData
        )

        switch result {
        case .success(let response):
            return .success(response.toModelResponse())
        case .failure(let error):
            return .failure(error)
        }
    }

    /// Uses KoboldCPP's OpenAI-compatible endpoint for structured chat and
    /// tool-calling requests. Raw prompt requests continue to use
    /// `KoboldRequestBuilder` and `/api/v1/generate`.
    public func sendMessage(builder: ChatCompletionRequestBuilder) async -> Result<ModelResponse, APIError> {
        let request = builder.build()
        let result = await sendRequest(
            for: ChatCompletionResponse.self,
            provider: .kobold,
            path: "/v1/chat/completions",
            method: "POST",
            requestBody: request.toJSON().data(using: .utf8)
        )

        switch result {
        case .success(let response):
            return .success(response.toModelResponse())
        case .failure(let error):
            return .failure(error)
        }
    }
}
