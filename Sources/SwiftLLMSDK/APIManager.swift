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

    public func sendMessage(builder: OpenRouterRequestBuilder) async -> Result<
        ModelResponse, APIError
    > {
        guard let api = api as? OpenRouterAPI else {
            return .failure(.invalidService)
        }
        return await api.sendMessage(builder: builder)
    }

    public func streamMessage(builder: OpenRouterRequestBuilder) -> AsyncStream<
        Result<ModelResponse, APIError>
    > {
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

// MARK: - OpenAI-Compatible Functions
extension APIManager where T: OpenAPIBase {
    public func connect() async -> Result<String, APIError> {
        guard let api = api as? OpenAPI else {
            return .failure(.invalidService)
        }

        do {
            let models = try await api.getModels().get()
            if let selectedModel = api.selectedModel,
                let model = models.first(where: { $0.id == selectedModel })
            {
                return .success(model.id)
            } else {
                return .failure(.invalidService)
            }
        } catch (let error) {
            return .failure(error)
        }
    }

    public func sendMessage(builder: ChatCompletionRequestBuilder) async -> Result<
        ModelResponse, APIError
    > {
        guard let api = api as? OpenAPI else {
            return .failure(.invalidService)
        }

        return await api.sendMessage(builder: builder)
    }

    public func streamMessage(builder: ChatCompletionRequestBuilder) -> AsyncStream<
        Result<ModelResponse, APIError>
    > {
        guard let api = api as? OpenAPI else {
            return AsyncStream { continuation in
                continuation.yield(.failure(.invalidService))
                continuation.finish()
            }
        }

        return api.streamMessage(builder: builder)
    }

    public func getAvailableModels() async -> Result<[OpenAIModel], APIError> {
        guard let api = api as? OpenAPI else {
            return .failure(.invalidService)
        }

        return await api.getModels()
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

    public func streamMessage(builder: KoboldRequestBuilder) -> AsyncStream<
        Result<ModelResponse, APIError>
    > {
        guard let api = api as? KoboldAPI else {
            return AsyncStream { continuation in
                continuation.yield(.failure(.invalidService))
                continuation.finish()
            }
        }
        return api.streamMessage(builder: builder)
    }

    public func sendMessage(builder: KoboldRequestBuilder) async -> Result<ModelResponse, APIError>
    {
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
    public var deltaText: String?
    public var reasoning: String?
    public var deltaReasoning: String?
    public var responseTokens: Int?
    public var promptTokens: Int?
    public var streaming: Bool?
    /// True while the model is still emitting reasoning ("thinking") deltas and
    /// has not yet begun streaming response content. Toggles to false once the
    /// first content delta arrives (or when the stream finishes). Only applies
    /// to OpenRouter/OpenAI-compatible APIs until chat completion is added for Kobold
    public var isThinking: Bool = false
    public var disconnect: Bool = false
    public var rawResponse: Codable?

    public init<T: Codable>(
        role: String? = "assistant",
        text: String? = nil,
        deltaText: String? = nil,
        reasoning: String? = nil,
        deltaReasoning: String? = nil,
        responseTokens: Int? = nil,
        promptTokens: Int? = nil,
        streaming: Bool? = false,
        isThinking: Bool = false,
        disconnect: Bool = false,
        rawResponse: T
    ) {
        self.role = role
        self.text = text
        self.deltaText = deltaText
        self.reasoning = reasoning
        self.deltaReasoning = deltaReasoning
        self.responseTokens = responseTokens
        self.promptTokens = promptTokens
        self.streaming = streaming
        self.isThinking = isThinking
        self.disconnect = disconnect
        self.rawResponse = rawResponse
    }

    // Init for non generic responses.. pretty much errors
    public init(
        role: String? = "assistant",
        text: String? = nil,
        deltaText: String? = nil,
        reasoning: String? = nil,
        deltaReasoning: String? = nil,
        responseTokens: Int? = nil,
        promptTokens: Int? = nil,
        streaming: Bool? = false,
        isThinking: Bool = false,
        disconnect: Bool = false
    ) {
        self.role = role
        self.text = text
        self.deltaText = deltaText
        self.reasoning = reasoning
        self.deltaReasoning = deltaReasoning
        self.responseTokens = responseTokens
        self.promptTokens = promptTokens
        self.streaming = streaming
        self.isThinking = isThinking
        self.disconnect = disconnect
        self.rawResponse = nil
    }

    /// Attempts to cast the rawResponse back to its original type
    /// - Returns: The original response type if casting succeeds, nil otherwise
    public func getRawResponse<T: Codable>() -> T? {
        return rawResponse as? T
    }
}
