import Testing
import Foundation
@testable import SwiftLLMSDK

@Test func genericChatCompletionBuilderOmitsOpenRouterSpecificFields() throws {
    let builder = ChatCompletionRequestBuilder(
        model: "gpt-4o-mini",
        messages: [RequestBodyMessages(role: .user, message: "Hello")],
        temperature: 0.7,
        topP: 0.9,
        maxTokens: 128
    )

    let data = try #require(builder.build().toJSON().data(using: .utf8))
    let json = try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])

    #expect(json["model"] as? String == "gpt-4o-mini")
    #expect(json["max_tokens"] as? Int == 128)
    #expect(json["top_a"] == nil)
    #expect(json["top_k"] == nil)
    #expect(json["min_p"] == nil)
    #expect(json["repetition_penalty"] == nil)
    #expect(json["reasoning"] == nil)
}

@Test func openRouterBuilderKeepsOpenRouterSpecificFields() throws {
    let builder = OpenRouterRequestBuilder(
        model: "openai/gpt-4o-mini",
        messages: [RequestBodyMessages(role: .user, message: "Hello")],
        minP: 0.02,
        topA: 0.1,
        topK: 40,
        repetitionPenalty: 1.1
    )

    let data = try #require(builder.build().toJSON().data(using: .utf8))
    let json = try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])

    #expect(json["model"] as? String == "openai/gpt-4o-mini")
    #expect(json["top_a"] as? Double == 0.1)
    #expect(json["top_k"] as? Double == 40)
    #expect(json["min_p"] as? Double == 0.02)
    #expect(json["repetition_penalty"] as? Double == 1.1)
    #expect(json["reasoning"] != nil)
}
