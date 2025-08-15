//
//  APIManager.swift
//  SwiftLLMSDK
//
//  Copyright (c) 2025 Devon Jerothe
//  Licensed under MIT License
//

import Foundation

/// manager class to handle API calls to different services. 
/// Kobold has to be "unique" and have a completely different API so we cant return OpenAI compliant responses....
public class APIManager<T: LanguageModelService> {
    private let api: T

    public init(forService api: T) {
        self.api = api
    }
}

// MARK: - OpenRouter Functions
extension APIManager where T: OpenRouterBase {
    public func connect() async -> Result<String, APIError> {
        guard let api = api as? OpenRouterAPI else {
            return .failure(.invalidService)
        }

        return await api.checkAPIKey()
    }

    public func sendMessage(builder: OpenRouterRequestBuilder) async -> Result<ModelResponse, APIError> {
        guard let api = api as? OpenRouterAPI else {
            return .failure(.invalidService)
        }
        return await api.sendMessage(builder: builder)
    }

    public func streamMessage(builder: OpenRouterRequestBuilder) -> AsyncStream<Result<ModelResponse, APIError>> {
        guard let api = api as? OpenRouterAPI else {
            return AsyncStream { continuation in
                continuation.yield(.failure(.invalidService))
                continuation.finish()
            }
        }
        return api.streamMessage(builder: builder)
    }

    public func getAvailableModels() async -> Result<[OpenRouterModel], APIError> {
        guard let api = api as? OpenRouterAPI else {
            return .failure(.invalidService)
        }

        return await api.getAvailableModels()
    }
}

// MARK: - Kobold Functions
extension APIManager where T: KoboldAPIBase {
    public func connect() async -> Result<String, APIError> {
        guard let api = api as? KoboldAPI else {
            return .failure(.invalidService)
        }

        return await api.getModel()
    }

    public func countTokens(text: String) async -> Result<Int, APIError> {
        guard let api = api as? KoboldAPI else {
            return .failure(.invalidService)
        }

        return await api.countTokens(text: text)
    }

    public func getMaxContextLength() async -> Result<Int, APIError> {
        guard let api = api as? KoboldAPI else {
            return .failure(.invalidService)
        }

        return await api.getMaxContextLength()
    }

    public func streamMessage(builder: KoboldRequestBuilder) -> AsyncStream<Result<ModelResponse, APIError>> {
        guard let api = api as? KoboldAPI else {
            return AsyncStream { continuation in
                continuation.yield(.failure(.invalidService))
                continuation.finish()
            }
        }
        return api.streamMessage(builder: builder)
    }

    public func sendMessage(builder: KoboldRequestBuilder) async -> Result<ModelResponse, APIError> {
        guard let api = api as? KoboldAPI else {
            return .failure(.invalidService)
        }
        return await api.sendMessage(builder: builder)
    }
}

public protocol ResponseModel {
    var role: String? { get }
    var text: String? { get }
    var responseTokens: Int? { get }
    var promptTokens: Int? { get }
}

public struct ModelResponse: ResponseModel, @unchecked Sendable {
    public var role: String?
    public var text: String?
    public var responseTokens: Int?
    public var promptTokens: Int?
    public var streaming: Bool?
    public var disconnect: Bool = false
    public var rawResponse: Codable?
    
    public init<T: Codable>(
        role: String? = "assistant",
        text: String? = nil,
        responseTokens: Int? = nil,
        promptTokens: Int? = nil,
        streaming: Bool? = false,
        disconnect: Bool = false,
        rawResponse: T
    ) {
        self.role = role
        self.text = text
        self.responseTokens = responseTokens
        self.promptTokens = promptTokens
        self.streaming = streaming
        self.disconnect = disconnect
        self.rawResponse = rawResponse
    }

    // Init for non generic responses.. pretty much errors 
    public init(
        role: String? = "assistant",
        text: String? = nil,
        responseTokens: Int? = nil,
        promptTokens: Int? = nil,
        streaming: Bool? = false,
        disconnect: Bool = false
    ) {
        self.role = role
        self.text = text
        self.responseTokens = responseTokens
        self.promptTokens = promptTokens
        self.streaming = streaming
        self.disconnect = disconnect
        self.rawResponse = nil
    }
    
    /// Attempts to cast the rawResponse back to its original type
    /// - Returns: The original response type if casting succeeds, nil otherwise
    public func getRawResponse<T: Codable>() -> T? {
        return rawResponse as? T
    }
}
