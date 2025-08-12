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
        await getInt(endpoint: "/api/v1/config/max_context_length")
    }

    public func getMaxLength() async -> Result<Int, APIError> {
        await getInt(endpoint: "/api/v1/config/max_length")
    }

    public func getVersion() async -> Result<String, APIError> {
        await getString(endpoint: "/api/v1/info/version")
    }

    public func getModel() async -> Result<String, APIError> {
        await getString(endpoint: "/api/v1/model")
    }

    public func sendMessage(promptModel: RequestBodyBuilder) async -> Result<ModelResponse, APIError> {
        let koboldRequest = promptModel.buildKoboldBody()
        let koboldRequestData = koboldRequest.toJSON().data(using: .utf8)

        let result = await sendRequest(for: KoboldAPIResponse.self, path: "/api/v1/generate", method: "POST", requestBody: koboldRequestData)

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
}