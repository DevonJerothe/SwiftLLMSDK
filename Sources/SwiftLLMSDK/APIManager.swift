import Foundation

/// manager class to handle API calls to different services. 
/// Kobold has to be "unique" and have a completely different API so we cant return OpenAI compliant responses....
public class APIManager<T: LanguageModelService> {
    private let api: T

    public init(forService api: T) {
        self.api = api
    }

    public func sendMessage(promptModel: RequestBodyBuilder) async -> Result<T.ResponseType, APIError> {
        let result = await api.sendMessage(promptModel: promptModel)

        switch result {
        case .success(let response):
            return .success(response)
        case .failure(let error):
            return .failure(error)
        }
    }
}

extension APIManager where T: OpenRouterBase {
    public func connect() async -> Result<String, APIError> {
        guard let api = api as? OpenRouterAPI else {
            return .failure(.invalidService)
        }

        return await api.checkAPIKey()
    }
}

extension APIManager where T: KoboldAPIBase {
    public func connect() async -> Result<String, APIError> {
        guard let api = api as? KoboldAPI else {
            return .failure(.invalidService)
        }

        return await api.getModel()
    }
}

/// Protocol for our responses. Again this has an associated type.. we may not need it now that we are using a generic APIManger and service level PAT 
/// for now this makes sure that if the app needs it, we have the raw API response available. 
public protocol ModelResponse {
    associatedtype ResponseContent: Codable

    var role: String? { get }
    var text: String? { get }
    var responseTokens: Int? { get }
    var promptTokens: Int? { get }
    var responseContent: ResponseContent { get }
}