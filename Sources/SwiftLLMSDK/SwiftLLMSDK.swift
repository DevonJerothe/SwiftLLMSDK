import Foundation

public protocol LanguageModelService {
    // associatedtype ResponseType: ModelResponse

    var urlSession: URLSession { get}
    var baseURL: String { get }
    var timeoutInterval: TimeInterval { get }
    var apiKey: String? { get}
}

extension LanguageModelService {

    func sendStreamedRequest(
        forAPI: LanguageModelService.Type,
        path: String,
        method: String,
        requestBody: Data? = nil
    ) -> AsyncStream<Result<ModelResponse, APIError>> {

        let (stream, continuation) = AsyncStream<Result<ModelResponse, APIError>>.makeStream()

        guard let baseURL = URL(string: baseURL + path) else {
            continuation.yield(.failure(.invalidURL))
            continuation.finish()
            return stream
        }

        var request = URLRequest(url: baseURL, timeoutInterval: timeoutInterval)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("JAX AI", forHTTPHeaderField: "X-Title")
        request.setValue("https://jax-ai-com.l.ink/", forHTTPHeaderField: "HTTP-Referer")
        
        if let apiKey {
            request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        }

        if let requestBody {
            request.httpBody = requestBody
        }

        Task.detached(priority: .medium) {
            do {
                let (bytes, response) = try await URLSession.shared.bytes(for: request) 
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
                    guard line.hasPrefix("data:") else { continue}
                    let payload = line.dropFirst(5).trimmingCharacters(in: .whitespaces)

                    // We need to handle the different types of responses here. 
                    // OpenRouter indicates the end of the response with [DONE]
                    if payload == "[DONE]" {
                        let final = ModelResponse(role: "assistant", text: accumulatedText, responseTokens: nil, promptTokens: nil, streaming: false, rawResponse: OpenRouterAPIResponse())
                        continuation.yield(.success(final))
                        continuation.finish()
                        break
                    }
                    if let jsonData = payload.data(using: .utf8) {
                        // Handle the different response types based on the model type 
                        let decoder = JSONDecoder() 
                        if let _ = forAPI as? OpenRouterAPI.Type {
                            let chunk = try decoder.decode(OpenRouterStreamChunk.self, from: jsonData)
                            let deltaText = chunk.choices?.first?.delta?.content ?? ""
                            if !deltaText.isEmpty {
                                accumulatedText += deltaText
                                let partial = ModelResponse(role: chunk.choices?.first?.delta?.role ?? "assistant", text: accumulatedText, responseTokens: nil, promptTokens: nil, streaming: true, rawResponse: chunk)
                                continuation.yield(.success(partial))
                            }
                        } else if let _ = forAPI as? KoboldAPI.Type {                    
                            let chunk: KoboldStreamChunk = try decoder.decode(KoboldStreamChunk.self, from: jsonData)
                            let deltaText = chunk.token ?? ""

                            // Check if the response is done 
                            if chunk.finishReason == "stop" || chunk.finishReason == "length" {
                                accumulatedText += deltaText
                                let final = ModelResponse(role: "assistant", text: accumulatedText, responseTokens: nil, promptTokens: nil, streaming: false, rawResponse: OpenRouterAPIResponse())
                                continuation.yield(.success(final))
                                continuation.finish()
                                break
                            }

                            if !deltaText.isEmpty {
                                accumulatedText += deltaText
                                let partial = ModelResponse(role: "assistant", text: accumulatedText, responseTokens: nil, promptTokens: nil, streaming: true, rawResponse: chunk)
                                continuation.yield(.success(partial))
                            }
                        }
                    }
                }
            } catch let error as URLError where error.code == .timedOut {
                continuation.yield(.failure(.timeout))
                continuation.finish()
            } catch ( _ ) {
                continuation.yield(.failure(.invalidData))
                continuation.finish()
                return
            }
        }

        return stream
    }

    func sendRequest<T: Decodable>(
        for: T.Type,
        path: String,
        method: String,
        requestBody: Data? = nil
    ) async -> Result<T, APIError> {
        guard let baseURL = URL(string: baseURL + path) else {
            return .failure(.invalidURL)
        }

        do {
            // Create the request
            var request = URLRequest(url: baseURL, timeoutInterval: timeoutInterval)
            request.httpMethod = method
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue("JAX AI", forHTTPHeaderField: "X-Title")
            request.setValue("https://jax-ai-com.l.ink/", forHTTPHeaderField: "HTTP-Referer")

            // Set the API key if available
            if let apiKey {
                request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
            }

            // Set the request body if provided
            if let requestBody {
                request.httpBody = requestBody
            }
            
            // Send the request
            let (data, response) = try await urlSession.data(for: request)
            
            // Check response status
            guard let httpResponse = response as? HTTPURLResponse else {
                return .failure(.invalidResponse)
            }
            
            // Check for successful status code (200-299)
            if !(200...299).contains(httpResponse.statusCode) {
                return .failure(.serverError(code: httpResponse.statusCode))
            }
            
            // Decode the response
            let decoder = JSONDecoder()
            // TODO: Make sure all models are manually using coding keys
            // decoder.keyDecodingStrategy = .convertFromSnakeCase

            
            do {
                let decodedResponse = try decoder.decode(T.self, from: data)
                return .success(decodedResponse)
            } catch {
                return .failure(.decodingError)
            }
        } catch let error as URLError where error.code == .timedOut {
            return .failure(.timeout) // Handle timeout error
        } catch {
            return .failure(.invalidData)
        }
    }

    func getInt(endpoint: String) async -> Result<Int, APIError> {
        guard let baseURL = URL(string: baseURL + endpoint) else {
            return .failure(.invalidURL)
        }

        do {
            var request = URLRequest(url: baseURL, timeoutInterval: timeoutInterval)
            request.httpMethod = "GET"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")

            let (data, response) = try await urlSession.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                return .failure(.invalidResponse)
            }

            if !(200...299).contains(httpResponse.statusCode) {
                return .failure(.serverError(code: httpResponse.statusCode))
            }

            do {
                let decoder = JSONDecoder()
                let intResponse = try decoder.decode(IntResponse.self, from: data)
                return .success(intResponse.value)
            } catch {
                return .failure(.decodingError)
            }

        } catch let error as URLError where error.code == .timedOut {
            return .failure(.timeout) // Handle timeout error
        } catch {
            return .failure(.invalidData)
        }
    }

    func getString(endpoint: String) async -> Result<String, APIError> {
        guard let baseURL = URL(string: baseURL + endpoint) else {
            return .failure(.invalidURL)
        }

        do {
            var request = URLRequest(url: baseURL, timeoutInterval: timeoutInterval)
            request.httpMethod = "GET"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")

            let (data, response) = try await urlSession.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                return .failure(.invalidResponse)
            }

            if !(200...299).contains(httpResponse.statusCode) {
                return .failure(.serverError(code: httpResponse.statusCode))
            }

            do {
                let decoder = JSONDecoder()
                let stringResponse = try decoder.decode(StringResponse.self, from: data)
                return .success(stringResponse.result)
            } catch {
                return .failure(.decodingError)
            }
        } catch let error as URLError where error.code == .timedOut {
            return .failure(.timeout) // Handle timeout error
        } catch {
            return .failure(.invalidData)
        }
    }
}

