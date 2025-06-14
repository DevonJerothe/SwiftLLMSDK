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

    public func sendMessage(promptModel: RequestBodyBuilder) async -> Result<ModelResponse, APIError> {
        let result = await api.sendMessage(promptModel: promptModel)

        switch result {
        case .success(let response):
            return .success(response)
        case .failure(let error):
            return .failure(error)
        }
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
}

public protocol ResponseModel {
    var role: String? { get }
    var text: String? { get }
    var responseTokens: Int? { get }
    var promptTokens: Int? { get }
}

public struct ModelResponse: ResponseModel {
    public var role: String?
    public var text: String?
    public var responseTokens: Int?
    public var promptTokens: Int?
    public var rawResponse: Codable
    
    public init<T: Codable>(
        role: String? = "assistant",
        text: String? = nil,
        responseTokens: Int? = nil,
        promptTokens: Int? = nil,
        rawResponse: T
    ) {
        self.role = role
        self.text = text
        self.responseTokens = responseTokens
        self.promptTokens = promptTokens
        self.rawResponse = rawResponse
    }
    
    /// Attempts to cast the rawResponse back to its original type
    /// - Returns: The original response type if casting succeeds, nil otherwise
    public func getRawResponse<T: Codable>() -> T? {
        return rawResponse as? T
    }
}
