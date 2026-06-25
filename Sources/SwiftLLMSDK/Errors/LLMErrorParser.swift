import Foundation

enum LLMErrorParser {
    private static let rawPayloadLimit = 16 * 1024

    static func parseHTTPError(
        provider: LLMProvider,
        statusCode: Int,
        data: Data
    ) -> LLMError {
        let rawBody = boundedString(from: data)
        let parsed = parseProviderPayload(rawBody)
        let message = parsed.message ?? fallbackMessage(rawPayload: rawBody, statusCode: statusCode)
        let category = category(
            statusCode: statusCode,
            providerCode: parsed.providerCode,
            providerType: parsed.providerType,
            message: message
        )

        return LLMError(
            message: message,
            provider: provider,
            source: .http,
            category: category,
            httpStatusCode: statusCode,
            providerCode: parsed.providerCode,
            providerType: parsed.providerType,
            rawBody: rawBody,
            rawEvent: nil
        )
    }

    static func parseStreamEventError(
        provider: LLMProvider,
        payload: String,
        statusCode: Int? = nil,
        isErrorEvent: Bool = false
    ) -> LLMError? {
        let rawEvent = boundedString(payload)
        let parsed = parseProviderPayload(rawEvent)

        guard isErrorEvent || parsed.hasRecognizedErrorShape else {
            return nil
        }

        let message = parsed.message ?? fallbackMessage(rawPayload: rawEvent, statusCode: statusCode)
        let category = category(
            statusCode: statusCode,
            providerCode: parsed.providerCode,
            providerType: parsed.providerType,
            message: message
        )

        return LLMError(
            message: message,
            provider: provider,
            source: .streamEvent,
            category: category,
            httpStatusCode: statusCode,
            providerCode: parsed.providerCode,
            providerType: parsed.providerType,
            rawBody: nil,
            rawEvent: rawEvent
        )
    }

    static func transportError(provider: LLMProvider, error: Error) -> LLMError {
        if error is CancellationError {
            return cancelledError(provider: provider)
        }

        if let urlError = error as? URLError {
            switch urlError.code {
            case .cancelled:
                return cancelledError(provider: provider)
            case .timedOut:
                return LLMError(
                    message: "The request timed out.",
                    provider: provider,
                    source: .transport,
                    category: .timeout
                )
            default:
                return LLMError(
                    message: urlError.localizedDescription,
                    provider: provider,
                    source: .transport,
                    category: .networkError
                )
            }
        }

        return LLMError(
            message: error.localizedDescription,
            provider: provider,
            source: .transport,
            category: .networkError
        )
    }

    static func decodingError(
        provider: LLMProvider,
        rawBody: String? = nil,
        rawEvent: String? = nil
    ) -> LLMError {
        LLMError(
            message: "The provider returned a response that could not be decoded.",
            provider: provider,
            source: .decoding,
            category: .decodingError,
            rawBody: boundedString(rawBody),
            rawEvent: boundedString(rawEvent)
        )
    }

    private static func cancelledError(provider: LLMProvider) -> LLMError {
        LLMError(
            message: "The request was cancelled.",
            provider: provider,
            source: .cancellation,
            category: .cancelled
        )
    }

    private static func parseProviderPayload(_ rawPayload: String?) -> ParsedProviderError {
        guard
            let rawPayload,
            let data = rawPayload.data(using: .utf8),
            let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        else {
            return ParsedProviderError()
        }

        if let detail = json["detail"] as? [String: Any] {
            return ParsedProviderError(
                message: stringValue(detail["msg"]) ?? stringValue(detail["message"]),
                providerCode: stringValue(detail["code"]),
                providerType: stringValue(detail["type"]),
                hasRecognizedErrorShape: true
            )
        }

        if let detail = stringValue(json["detail"]) {
            return ParsedProviderError(
                message: detail,
                hasRecognizedErrorShape: true
            )
        }

        if let error = json["error"] as? [String: Any] {
            let metadata = error["metadata"] as? [String: Any]
            let providerType =
                stringValue(metadata?["error_type"])
                ?? stringValue(error["type"])

            return ParsedProviderError(
                message: stringValue(error["message"]) ?? stringValue(error["error"]),
                providerCode: stringValue(error["code"]),
                providerType: providerType,
                hasRecognizedErrorShape: true
            )
        }

        if let error = stringValue(json["error"]) {
            return ParsedProviderError(
                message: error,
                hasRecognizedErrorShape: true
            )
        }

        return ParsedProviderError(
            message: stringValue(json["message"]),
            providerCode: stringValue(json["code"]),
            providerType: stringValue(json["type"]),
            hasRecognizedErrorShape: json["message"] != nil || json["code"] != nil || json["type"] != nil
        )
    }

    private static func category(
        statusCode: Int?,
        providerCode: String?,
        providerType: String?,
        message: String?
    ) -> LLMErrorCategory {
        let signal = [providerType, providerCode, message]
            .compactMap { $0?.lowercased() }
            .joined(separator: " ")

        if containsAny(signal, ["context_length", "max_context", "token_limit", "too_many_tokens", "context length"]) {
            return .contextLength
        }
        if containsAny(signal, ["quota", "insufficient_quota", "credits", "balance"]) {
            return .quotaExceeded
        }
        if containsAny(signal, ["rate_limit", "rate limit", "too_many_requests"]) {
            return .rateLimit
        }
        if containsAny(signal, ["invalid_api_key", "invalid_token", "authentication"]) {
            return .authentication
        }
        if containsAny(signal, ["permission", "forbidden", "unauthorized"]) {
            return .authorization
        }
        if containsAny(signal, ["invalid_request", "validation", "bad_request"]) {
            return .invalidRequest
        }
        if containsAny(signal, ["service_unavailable", "overloaded", "server_busy", "busy", "unavailable"]) {
            return .unavailable
        }
        if containsAny(signal, ["server_error", "internal_error"]) {
            return .serverError
        }

        guard let statusCode else {
            return .unknown
        }

        switch statusCode {
        case 400, 422:
            return .invalidRequest
        case 401:
            return .authentication
        case 403:
            return .authorization
        case 408:
            return .timeout
        case 413:
            return .contextLength
        case 429:
            return .rateLimit
        case 503:
            return .unavailable
        case 500...599:
            return .serverError
        default:
            return .unknown
        }
    }

    private static func containsAny(_ signal: String, _ needles: [String]) -> Bool {
        needles.contains { signal.contains($0) }
    }

    private static func fallbackMessage(rawPayload: String?, statusCode: Int?) -> String {
        if let rawPayload, !rawPayload.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return rawPayload.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        if let statusCode {
            return "The provider returned HTTP \(statusCode)."
        }
        return "The provider returned an error."
    }

    static func boundedString(from data: Data) -> String? {
        boundedString(String(data: data, encoding: .utf8))
    }

    static func boundedString(_ string: String?) -> String? {
        guard let string else { return nil }
        if string.count <= rawPayloadLimit {
            return string
        }
        let endIndex = string.index(string.startIndex, offsetBy: rawPayloadLimit)
        return String(string[..<endIndex])
    }

    private static func stringValue(_ value: Any?) -> String? {
        switch value {
        case let value as String:
            return value
        case let value as Int:
            return String(value)
        case let value as Double:
            if value.rounded() == value {
                return String(Int(value))
            }
            return String(value)
        case let value as NSNumber:
            return value.stringValue
        default:
            return nil
        }
    }
}

private struct ParsedProviderError {
    var message: String?
    var providerCode: String?
    var providerType: String?
    var hasRecognizedErrorShape: Bool = false
}
