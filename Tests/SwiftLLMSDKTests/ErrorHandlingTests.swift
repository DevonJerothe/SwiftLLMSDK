import Foundation
import Testing
@testable import SwiftLLMSDK

@Test func parsesKoboldHTTPError() throws {
    let data = Data("""
    {
      "detail": {
        "msg": "Server is busy; please try again later.",
        "type": "service_unavailable"
      }
    }
    """.utf8)

    let error = LLMErrorParser.parseHTTPError(provider: .kobold, statusCode: 503, data: data)

    #expect(error.provider == .kobold)
    #expect(error.source == .http)
    #expect(error.message == "Server is busy; please try again later.")
    #expect(error.providerType == "service_unavailable")
    #expect(error.category == .unavailable)
    #expect(error.httpStatusCode == 503)
}

@Test func parsesOpenAIStyleHTTPErrorWithNumericCode() throws {
    let data = Data("""
    {
      "error": {
        "message": "Rate limit reached.",
        "type": "rate_limit_exceeded",
        "code": 429
      }
    }
    """.utf8)

    let error = LLMErrorParser.parseHTTPError(
        provider: .openAICompatible,
        statusCode: 429,
        data: data
    )

    #expect(error.provider == .openAICompatible)
    #expect(error.message == "Rate limit reached.")
    #expect(error.providerCode == "429")
    #expect(error.providerType == "rate_limit_exceeded")
    #expect(error.category == .rateLimit)
}

@Test func parsesOpenAIStyleHTTPErrorWithStringCode() throws {
    let data = Data("""
    {
      "error": {
        "message": "Context length exceeded.",
        "type": "invalid_request_error",
        "code": "context_length_exceeded"
      }
    }
    """.utf8)

    let error = LLMErrorParser.parseHTTPError(
        provider: .openAICompatible,
        statusCode: 400,
        data: data
    )

    #expect(error.providerCode == "context_length_exceeded")
    #expect(error.providerType == "invalid_request_error")
    #expect(error.category == .contextLength)
}

@Test func parsesOpenRouterHTTPError() throws {
    let data = Data("""
    {
      "error": {
        "code": 429,
        "message": "You have exceeded your rate limit.",
        "metadata": {
          "error_type": "rate_limit_exceeded"
        }
      }
    }
    """.utf8)

    let error = LLMErrorParser.parseHTTPError(provider: .openRouter, statusCode: 429, data: data)

    #expect(error.provider == .openRouter)
    #expect(error.providerCode == "429")
    #expect(error.providerType == "rate_limit_exceeded")
    #expect(error.category == .rateLimit)
}

@Test func parsesOpenRouterQuotaError() throws {
    let data = Data("""
    {
      "error": {
        "code": 402,
        "message": "Insufficient credits.",
        "metadata": {
          "error_type": "insufficient_quota"
        }
      }
    }
    """.utf8)

    let error = LLMErrorParser.parseHTTPError(provider: .openRouter, statusCode: 402, data: data)

    #expect(error.category == .quotaExceeded)
    #expect(error.message == "Insufficient credits.")
}

@Test func malformedJSONFallsBackToStatusCategoryAndRawBody() throws {
    let data = Data(#"{ "error":"#.utf8)

    let error = LLMErrorParser.parseHTTPError(provider: .openRouter, statusCode: 500, data: data)

    #expect(error.category == .serverError)
    #expect(error.rawBody == #"{ "error":"#)
    #expect(error.message == #"{ "error":"#)
}

@Test func plainTextServerErrorUsesBodyAsMessage() throws {
    let data = Data("upstream unavailable".utf8)

    let error = LLMErrorParser.parseHTTPError(provider: .openAICompatible, statusCode: 503, data: data)

    #expect(error.message == "upstream unavailable")
    #expect(error.rawBody == "upstream unavailable")
    #expect(error.category == .unavailable)
}

@Test func openRouterSendMessageMapsHTTPErrorToLLMError() async throws {
    let session = MockURLProtocol.makeSession(key: "Bearer openrouter-http-test") { request in
        let response = try mockResponse(
            for: request,
            statusCode: 429,
            contentType: "application/json"
        )
        let data = Data("""
        {
          "error": {
            "code": 429,
            "message": "Rate limited",
            "metadata": {
              "error_type": "rate_limit_exceeded"
            }
          }
        }
        """.utf8)
        return (response, data)
    }

    let api = OpenRouterAPI(urlSession: session, selectedModel: "openai/gpt-4o-mini", apiKey: "openrouter-http-test")
    let builder = OpenRouterRequestBuilder(
        model: "openai/gpt-4o-mini",
        messages: [RequestBodyMessages(role: .user, message: "Hello")]
    )

    let result = await api.sendMessage(builder: builder)

    guard case .failure(.llmError(let error)) = result else {
        Issue.record("Expected .failure(.llmError), got \(result)")
        return
    }

    #expect(error.provider == .openRouter)
    #expect(error.source == .http)
    #expect(error.httpStatusCode == 429)
    #expect(error.category == .rateLimit)
    #expect(error.providerType == "rate_limit_exceeded")
    #expect(error.rawBody?.contains("Rate limited") == true)
}

@Test func koboldSendMessageMapsHTTPErrorToLLMError() async throws {
    let session = MockURLProtocol.makeSession(key: "http://localhost:5001/api/v1/generate") { request in
        let response = try mockResponse(
            for: request,
            statusCode: 503,
            contentType: "application/json"
        )
        let data = Data("""
        {
          "detail": {
            "msg": "Server is busy; please try again later.",
            "type": "service_unavailable"
          }
        }
        """.utf8)
        return (response, data)
    }

    let api = KoboldAPI(urlSession: session, host: "localhost", port: 5001)
    let builder = KoboldRequestBuilder(prompt: "Hello")

    let result = await api.sendMessage(builder: builder)

    guard case .failure(.llmError(let error)) = result else {
        Issue.record("Expected .failure(.llmError), got \(result)")
        return
    }

    #expect(error.provider == .kobold)
    #expect(error.category == .unavailable)
    #expect(error.message == "Server is busy; please try again later.")
}

@Test func transportFailureMapsToNetworkCategory() async throws {
    let session = MockURLProtocol.makeSession(key: "Bearer transport-test") { _ in
        throw URLError(.notConnectedToInternet)
    }

    let api = OpenAPI(
        urlSession: session,
        baseURL: "https://example.com",
        selectedModel: "gpt-4o-mini",
        apiKey: "transport-test"
    )
    let builder = ChatCompletionRequestBuilder(
        model: "gpt-4o-mini",
        messages: [RequestBodyMessages(role: .user, message: "Hello")]
    )

    let result = await api.sendMessage(builder: builder)

    guard case .failure(.llmError(let error)) = result else {
        Issue.record("Expected .failure(.llmError), got \(result)")
        return
    }

    #expect(error.provider == .openAICompatible)
    #expect(error.source == .transport)
    #expect(error.category == .networkError)
}

@Test func openRouterStreamEmitsFinalModelResponseForSSEError() async throws {
    let streamBody = """
    data: {"choices":[{"delta":{"content":"Hello"}}]}
    data: {"error":{"code":429,"message":"Rate limited","metadata":{"error_type":"rate_limit_exceeded"}}}

    """

    let session = MockURLProtocol.makeSession(key: "Bearer openrouter-stream-test") { request in
        let response = try mockResponse(
            for: request,
            statusCode: 200,
            contentType: "text/event-stream"
        )
        return (response, Data(streamBody.utf8))
    }

    let api = OpenRouterAPI(urlSession: session, selectedModel: "openai/gpt-4o-mini", apiKey: "openrouter-stream-test")
    let builder = OpenRouterRequestBuilder(
        model: "openai/gpt-4o-mini",
        messages: [RequestBodyMessages(role: .user, message: "Hello")]
    )

    let results = await collect(api.streamMessage(builder: builder))

    #expect(results.count == 2)

    guard case .success(let partial) = results.first else {
        Issue.record("Expected first stream value to be a partial success")
        return
    }
    #expect(partial.text == "Hello")
    #expect(partial.deltaText == "Hello")
    #expect(partial.error == nil)

    guard case .success(let final) = results.last else {
        Issue.record("Expected final stream value to be an error ModelResponse")
        return
    }
    #expect(final.text == "Hello")
    #expect(final.streaming == false)
    #expect(final.disconnect == true)
    #expect(final.error?.provider == .openRouter)
    #expect(final.error?.category == .rateLimit)
}

@Test func openAICompatibleStreamDetectsNamedErrorEvent() async throws {
    let streamBody = """
    event: error
    data: {"error":{"message":"Context length exceeded","type":"invalid_request_error","code":"context_length_exceeded"}}

    """

    let session = MockURLProtocol.makeSession(key: "Bearer openai-stream-test") { request in
        let response = try mockResponse(
            for: request,
            statusCode: 200,
            contentType: "text/event-stream"
        )
        return (response, Data(streamBody.utf8))
    }

    let api = OpenAPI(
        urlSession: session,
        baseURL: "https://example.com",
        selectedModel: "gpt-4o-mini",
        apiKey: "openai-stream-test"
    )
    let builder = ChatCompletionRequestBuilder(
        model: "gpt-4o-mini",
        messages: [RequestBodyMessages(role: .user, message: "Hello")]
    )

    let results = await collect(api.streamMessage(builder: builder))

    #expect(results.count == 1)
    guard case .success(let final) = results.first else {
        Issue.record("Expected final stream value to be an error ModelResponse")
        return
    }

    #expect(final.error?.provider == .openAICompatible)
    #expect(final.error?.category == .contextLength)
    #expect(final.disconnect == true)
}

@Test func malformedStreamPayloadEmitsDecodingErrorModelResponse() async throws {
    let session = MockURLProtocol.makeSession(key: "Bearer malformed-stream-test") { request in
        let response = try mockResponse(
            for: request,
            statusCode: 200,
            contentType: "text/event-stream"
        )
        return (response, Data("data: {\"choices\":\n".utf8))
    }

    let api = OpenRouterAPI(urlSession: session, selectedModel: "openai/gpt-4o-mini", apiKey: "malformed-stream-test")
    let builder = OpenRouterRequestBuilder(
        model: "openai/gpt-4o-mini",
        messages: [RequestBodyMessages(role: .user, message: "Hello")]
    )

    let results = await collect(api.streamMessage(builder: builder))

    #expect(results.count == 1)
    guard case .success(let final) = results.first else {
        Issue.record("Expected final stream value to be an error ModelResponse")
        return
    }

    #expect(final.error?.category == .decodingError)
    #expect(final.error?.rawEvent == #"{"choices":"#)
    #expect(final.disconnect == true)
}

@Test func openAICompatibleConnectionUsesMinimalChatCompletionProbe() async throws {
    let session = MockURLProtocol.makeSession(key: "Bearer openai-connect-test") { request in
        #expect(request.url?.path == "/chat/completions")
        #expect(request.httpMethod == "POST")

        let bodyData = try #require(requestBodyData(for: request))
        let json = try #require(JSONSerialization.jsonObject(with: bodyData) as? [String: Any])
        let messages = try #require(json["messages"] as? [[String: Any]])

        #expect(json["model"] as? String == "gpt-4o-mini")
        #expect(json["max_tokens"] as? Int == 1)
        #expect(json["stream"] as? Bool == false)
        #expect(json["temperature"] == nil)
        #expect(json["reasoning"] == nil)
        #expect(messages.count == 1)
        #expect(messages.first?["role"] as? String == "user")
        #expect(messages.first?["content"] as? String == "ping")

        let response = try mockResponse(
            for: request,
            statusCode: 200,
            contentType: "application/json"
        )
        let data = Data("""
        {
          "id": "chatcmpl-connect",
          "model": "gpt-4o-mini",
          "choices": [
            {
              "index": 0,
              "message": { "role": "assistant", "content": "p" },
              "finish_reason": "stop"
            }
          ]
        }
        """.utf8)
        return (response, data)
    }

    let api = OpenAPI(
        urlSession: session,
        baseURL: "https://example.com",
        selectedModel: "gpt-4o-mini",
        apiKey: "openai-connect-test"
    )
    let manager = APIManager(forService: api)

    let result = await manager.checkConnection()

    guard case .success(let check) = result else {
        Issue.record("Expected successful connection check, got \(result)")
        return
    }

    #expect(check.provider == .openAICompatible)
    #expect(check.verification == .chatCompletion)
    #expect(check.endpoint == "/chat/completions")
    #expect(check.model == "gpt-4o-mini")
    #expect(check.isChatReady)
}

@Test func openRouterConnectionProbeOmitsReasoningFields() async throws {
    let session = MockURLProtocol.makeSession(key: "Bearer openrouter-connect-test") { request in
        #expect(request.url?.path == "/api/v1/chat/completions")

        let bodyData = try #require(requestBodyData(for: request))
        let json = try #require(JSONSerialization.jsonObject(with: bodyData) as? [String: Any])

        #expect(json["model"] as? String == "openai/gpt-4o-mini")
        #expect(json["max_tokens"] as? Int == 1)
        #expect(json["stream"] as? Bool == false)
        #expect(json["reasoning"] == nil)
        #expect(json["reasoning_effort"] == nil)

        let response = try mockResponse(
            for: request,
            statusCode: 200,
            contentType: "application/json"
        )
        let data = Data("""
        {
          "id": "gen-connect",
          "model": "openai/gpt-4o-mini",
          "choices": [
            {
              "index": 0,
              "message": { "role": "assistant", "content": "p" },
              "finish_reason": "stop"
            }
          ]
        }
        """.utf8)
        return (response, data)
    }

    let api = OpenRouterAPI(
        urlSession: session,
        selectedModel: "openai/gpt-4o-mini",
        apiKey: "openrouter-connect-test"
    )
    let manager = APIManager(forService: api)

    let result = await manager.connect()

    guard case .success(let model) = result else {
        Issue.record("Expected successful connect, got \(result)")
        return
    }

    #expect(model == "openai/gpt-4o-mini")
}

@Test func koboldConnectionCheckUsesMetadataEndpoint() async throws {
    let session = MockURLProtocol.makeSession(key: "http://localhost:5001/api/v1/model") { request in
        #expect(request.url?.path == "/api/v1/model")
        #expect(request.httpMethod == "GET")
        #expect(request.httpBody == nil)

        let response = try mockResponse(
            for: request,
            statusCode: 200,
            contentType: "application/json"
        )
        return (response, Data(#"{ "result": "local-model.gguf" }"#.utf8))
    }

    let api = KoboldAPI(urlSession: session, host: "localhost", port: 5001)
    let manager = APIManager(forService: api)

    let result = await manager.checkConnection()

    guard case .success(let check) = result else {
        Issue.record("Expected successful connection check, got \(result)")
        return
    }

    #expect(check.provider == .kobold)
    #expect(check.verification == .serviceMetadata)
    #expect(check.endpoint == "/api/v1/model")
    #expect(check.model == "local-model.gguf")
    #expect(!check.isChatReady)
}

private func collect(_ stream: AsyncStream<Result<ModelResponse, APIError>>) async -> [Result<ModelResponse, APIError>] {
    var results: [Result<ModelResponse, APIError>] = []
    for await result in stream {
        results.append(result)
    }
    return results
}

private func mockResponse(
    for request: URLRequest,
    statusCode: Int,
    contentType: String
) throws -> HTTPURLResponse {
    let url = try #require(request.url)
    return try #require(HTTPURLResponse(
        url: url,
        statusCode: statusCode,
        httpVersion: nil,
        headerFields: ["Content-Type": contentType]
    ))
}

private func requestBodyData(for request: URLRequest) -> Data? {
    if let httpBody = request.httpBody {
        return httpBody
    }

    guard let stream = request.httpBodyStream else {
        return nil
    }

    stream.open()
    defer { stream.close() }

    var data = Data()
    let bufferSize = 1024
    let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferSize)
    defer { buffer.deallocate() }

    while stream.hasBytesAvailable {
        let read = stream.read(buffer, maxLength: bufferSize)
        if read < 0 {
            return nil
        }
        if read == 0 {
            break
        }
        data.append(buffer, count: read)
    }

    return data
}

private final class MockURLProtocol: URLProtocol, @unchecked Sendable {
    typealias Handler = @Sendable (URLRequest) throws -> (HTTPURLResponse, Data)

    nonisolated(unsafe) private static var handlers: [String: Handler] = [:]
    private static let handlersLock = NSLock()

    static func makeSession(key: String, handler: @escaping Handler) -> URLSession {
        handlersLock.lock()
        handlers[key] = handler
        handlersLock.unlock()
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockURLProtocol.self]
        return URLSession(configuration: configuration)
    }

    override class func canInit(with request: URLRequest) -> Bool {
        true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        let key = request.value(forHTTPHeaderField: "Authorization") ?? request.url?.absoluteString
        Self.handlersLock.lock()
        let handler = key.flatMap { Self.handlers[$0] }
        Self.handlersLock.unlock()

        guard let handler else {
            client?.urlProtocol(self, didFailWithError: URLError(.unknown))
            return
        }

        do {
            let (response, data) = try handler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}
}
