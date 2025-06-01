import Foundation

public class KoboldResponse {
    public var responseContent: KoboldAPIResponse

    public var text: String?
    public var responseTokens: Int?
    public var promptTokens: Int?
    public var role: String?

    public init(
        role: String = "assistant",
        text: String? = "",
        responseTokens: Int? = nil,
        promptTokens: Int? = nil, 
        responseContent: KoboldAPIResponse
    ) {
        self.text = text
        self.responseTokens = responseTokens
        self.promptTokens = promptTokens
        self.role = role
        self.responseContent = responseContent
    }
}

// MARK: - API Response Model
public class KoboldAPIResponse: Codable {
    var results: [ResultArray]
}

public class ResultArray: Codable {
    var text: String?
    var promptTokens: Int?
    var completionTokens: Int?
}

public struct IntResponse: Decodable {
    let value: Int
}

public struct StringResponse: Decodable {
    let result: String
}

// TODO: Fix the force unwrapping here. We should handle any errors gracefully
extension KoboldAPIResponse {
    func toJSON() -> String {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        let requestData = try! encoder.encode(self)
        return String(data: requestData, encoding: .utf8)!
    }

    func toKoboldResponse() -> KoboldResponse {
        let result = results.first 
        return KoboldResponse(
            role: "assistant",
            text: result?.text,
            responseTokens: result?.completionTokens,
            promptTokens: result?.promptTokens,
            responseContent: self
        )
    }

    func toModelResponse() -> ModelResponse {
        return ModelResponse(
            role: "assistant",
            text: results.first?.text,
            responseTokens: results.first?.completionTokens,
            promptTokens: results.first?.promptTokens,
            rawResponse: self
        )
    }
}


