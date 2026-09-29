import Foundation
import Testing
@testable import SwiftLLMSDK

@Test func chatCompletionBuilderEncodesToolConfiguration() throws {
    let tool = ToolDefinition(function: FunctionDefinition(
        name: "update_character",
        description: "Update fields on the character draft.",
        parameters: .object([
            "type": .string("object"),
            "properties": .object([
                "name": .object(["type": .string("string")]),
                "age": .object(["type": .string("number")])
            ]),
            "required": .array([.string("name")])
        ]),
        strict: true
    ))
    let builder = ChatCompletionRequestBuilder(
        model: "gpt-4o-mini",
        messages: [RequestBodyMessages(role: .user, message: "Create a character")],
        tools: [tool],
        toolChoice: .function(name: "update_character"),
        parallelToolCalls: false
    )

    let data = try #require(builder.build().toJSON().data(using: .utf8))
    let json = try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])
    let tools = try #require(json["tools"] as? [[String: Any]])
    let function = try #require(tools.first?["function"] as? [String: Any])
    let parameters = try #require(function["parameters"] as? [String: Any])
    let choice = try #require(json["tool_choice"] as? [String: Any])
    let chosenFunction = try #require(choice["function"] as? [String: Any])

    #expect(tools.first?["type"] as? String == "function")
    #expect(function["name"] as? String == "update_character")
    #expect(function["strict"] as? Bool == true)
    #expect(parameters["type"] as? String == "object")
    #expect(chosenFunction["name"] as? String == "update_character")
    #expect(json["parallel_tool_calls"] as? Bool == false)
    #expect(builder.build().requiresToolProtocol)
}

@Test func builderPreservesAssistantToolCallsAndToolResults() throws {
    let call = ToolCall(
        id: "call_1",
        function: FunctionCall(name: "update_character", arguments: #"{"name":"Mara"}"#)
    )
    let builder = ChatCompletionRequestBuilder(
        model: "gpt-4o-mini",
        messages: [
            RequestBodyMessages(role: .assistant, content: nil, toolCalls: [call]),
            RequestBodyMessages(
                role: .tool,
                content: .string(#"{"updated":true}"#),
                toolCallID: "call_1",
                name: "update_character"
            )
        ]
    )

    let data = try #require(builder.build().toJSON().data(using: .utf8))
    let json = try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])
    let messages = try #require(json["messages"] as? [[String: Any]])
    let assistantCalls = try #require(messages[0]["tool_calls"] as? [[String: Any]])

    #expect(messages[0]["role"] as? String == "assistant")
    #expect(messages[0]["content"] == nil)
    #expect(assistantCalls.first?["id"] as? String == "call_1")
    #expect(messages[1]["role"] as? String == "tool")
    #expect(messages[1]["tool_call_id"] as? String == "call_1")
    #expect(messages[1]["name"] as? String == "update_character")
    #expect(builder.build().requiresToolProtocol)
}

@Test func nonStreamingResponseExposesToolCallsAndFinishReason() throws {
    let data = Data("""
    {
      "choices": [{
        "index": 0,
        "message": {
          "role": "assistant",
          "content": null,
          "tool_calls": [{
            "id": "call_1",
            "type": "function",
            "function": {
              "name": "update_character",
              "arguments": "{\\"name\\":\\"Mara\\"}"
            }
          }]
        },
        "finish_reason": "tool_calls"
      }]
    }
    """.utf8)

    let response = try JSONDecoder().decode(ChatCompletionResponse.self, from: data)
    let modelResponse = response.toModelResponse()
    let call = try #require(modelResponse.toolCalls?.first)

    #expect(modelResponse.text == nil)
    #expect(modelResponse.finishReason == "tool_calls")
    #expect(call.id == "call_1")
    #expect(call.function.name == "update_character")

    struct Arguments: Decodable {
        let name: String
    }
    let arguments = try call.function.decodeArguments(as: Arguments.self)
    #expect(arguments.name == "Mara")
}
