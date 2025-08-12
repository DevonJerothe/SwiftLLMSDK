import Foundation

public protocol OpenRouterBase {
    var selectedModel: String? { get }
    func getAvailableModels() async -> Result<[OpenRouterModel], APIError>
}

public struct OpenRouterAPI: LanguageModelService, OpenRouterBase {
    // public typealias ResponseType = OpenRouterResponse

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
    
    public func sendMessage(promptModel: RequestBodyBuilder) async -> Result<ModelResponse, APIError> {
        let openRouterRequest = promptModel.buildOpenRouterBody()
        let openRouterRequestData = openRouterRequest.toJSON().data(using: .utf8)

        let result = await sendRequest(for: OpenRouterAPIResponse.self, path: "/chat/completions", method: "POST", requestBody: openRouterRequestData) 

        switch result {
        case .success(let response):
            return .success(response.toModelResponse())
        case .failure(let error):
            return .failure(error)
        }
    }

    // Overload: send using provider-specific builder
    public func sendMessage(builder: OpenRouterRequestBuilder) async -> Result<ModelResponse, APIError> {
        let openRouterRequest = builder.build()
        let openRouterRequestData = openRouterRequest.toJSON().data(using: .utf8)

        let result = await sendRequest(
            for: OpenRouterAPIResponse.self,
            path: "/chat/completions",
            method: "POST",
            requestBody: openRouterRequestData
        )

        switch result {
        case .success(let response):
            return .success(response.toModelResponse())
        case .failure(let error):
            return .failure(error)
        }
    }

    // MARK: - Streaming
    // Returns an AsyncStream emitting partial ModelResponse updates and a final value.
    public func streamMessage(builder: OpenRouterRequestBuilder) -> AsyncStream<Result<ModelResponse, APIError>> {
        var requestBuilder = builder
        requestBuilder.stream = true
        let requestModel = requestBuilder.build()

        let urlString = baseURL + "/chat/completions"
        let timeout = timeoutInterval
        let authKey = apiKey
        let session = urlSession

        let (stream, continuation) = AsyncStream<Result<ModelResponse, APIError>>.makeStream()

        guard let url = URL(string: urlString) else {
            continuation.yield(.failure(.invalidURL))
            continuation.finish()
            return stream
        }

        var request = URLRequest(url: url, timeoutInterval: timeout)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("JAX AI", forHTTPHeaderField: "X-Title")
        request.setValue("https://jax-ai-com.l.ink/", forHTTPHeaderField: "HTTP-Referer")
        if let authKey {
            request.setValue("Bearer \(authKey)", forHTTPHeaderField: "Authorization")
        }
        request.httpBody = requestModel.toJSON().data(using: .utf8)

        Task.detached(priority: .medium) {
            do {
                let (bytes, response) = try await session.bytes(for: request)
                guard let httpResponse = response as? HTTPURLResponse else {
                    continuation.yield(.failure(.invalidResponse))
                    continuation.finish()
                    return
                }
                guard (200...299).contains(httpResponse.statusCode) else {
                    continuation.yield(.failure(.serverError(code: httpResponse.statusCode)))
                    continuation.finish()
                    return
                }

                var accumulatedText = ""
                for try await line in bytes.lines {
                    // SSE lines typically start with "data: "
                    guard line.hasPrefix("data:") else { continue }
                    let payload = line.dropFirst(5).trimmingCharacters(in: .whitespaces)
                    if payload == "[DONE]" {
                        let final = ModelResponse(role: "assistant", text: accumulatedText, responseTokens: nil, promptTokens: nil, rawResponse: OpenRouterAPIResponse())
                        continuation.yield(.success(final))
                        continuation.finish()
                        break
                    }

                    if let jsonData = payload.data(using: .utf8) {
                        do {
                            let decoder = JSONDecoder()
                            let chunk = try decoder.decode(OpenRouterStreamChunk.self, from: jsonData)
                            let deltaText = chunk.choices?.first?.delta?.content ?? ""
                            if !deltaText.isEmpty {
                                accumulatedText += deltaText
                                let partial = ModelResponse(role: chunk.choices?.first?.delta?.role ?? "assistant", text: accumulatedText, responseTokens: nil, promptTokens: nil, rawResponse: chunk)
                                continuation.yield(.success(partial))
                            }
                        } catch {
                            // Ignore non-JSON keepalives or unknown fragments
                            continue
                        }
                    }
                }
            } catch let error as URLError where error.code == .timedOut {
                continuation.yield(.failure(.timeout))
                continuation.finish()
            } catch {
                continuation.yield(.failure(.invalidData))
                continuation.finish()
            }
        }

        return stream
    }

    // TODO: Update this to return the actual Key info. May be useful for monitoring usage ect. 
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
