# SwiftLLMSDK

A unified Swift package for connecting to various Large Language Model (LLM) backend services with a focus on character cards and AI interactions. SwiftLLMSDK provides a clean, type-safe interface for working with different LLM providers while maintaining character card compatibility.

## Features

- **🔗 Unified API Interface**: Single interface for multiple LLM providers
- **🤖 Character Card Support**: Built-in support for character cards with system prompts, personalities, and scenarios
- **📥 Character Import**: Import character cards and lore books from URLs, local data, PNG metadata, and JSON
- **⚡ Async/Await**: Modern Swift concurrency with async/await
- **🛡️ Type Safety**: Strong typing with Result types and normalized provider error details
- **🔧 Flexible Configuration**: Extensive customization options for model parameters

## Supported Providers

### OpenRouter

- **Purpose**: Access to multiple LLM models through a single API
- **Features**: Model listing, low-cost chat-completion connection checks, chat completions
- **Authentication**: API key required

### KoboldCPP

- **Purpose**: Local LLM inference server
- **Features**: Direct HTTP connection to local instances, fast model metadata connection checks
- **Authentication**: No API key required (local connection)

### OpenAI-Compatible APIs

- **Purpose**: Connect to OpenAI-compatible chat completion endpoints
- **Features**: Chat completions, streaming, model listing, low-cost chat-completion connection checks
- **Authentication**: API key optional depending on endpoint

## Requirements

- iOS 16.0+ / macOS 13.0+
- Swift 6.0+

## Installation

### Swift Package Manager

Add SwiftLLMSDK to your project using Xcode:

1. Go to **File** → **Add Package Dependencies**
2. Enter the repository URL: `https://github.com/yourusername/SwiftLLMSDK`
3. Click **Add Package**

Or add it to your `Package.swift` file:

```swift
dependencies: [
    .package(url: "https://github.com/yourusername/SwiftLLMSDK", from: "1.0.0")
]
```

## Quick Start

### Basic OpenRouter Usage

```swift
import SwiftLLMSDK

// Initialize OpenRouter API
let openRouterAPI = OpenRouterAPI(
    selectedModel: "openai/gpt-4",
    apiKey: "your-api-key-here"
)

// Create API manager
let apiManager = APIManager(forService: openRouterAPI)

// Test connection
let connectionResult = await apiManager.connect()
switch connectionResult {
case .success(let model):
    print("Connected successfully using model: \(model)")
case .failure(let error):
    print("Connection failed: \(error)")
}

// Send a message (builder-based API)
let requestBuilder = OpenRouterRequestBuilder(
    model: "openai/gpt-4",
    messages: [
        RequestBodyMessages(role: .user, message: "Hello, how are you?")
    ]
)

let response = await apiManager.sendMessage(builder: requestBuilder)
switch response {
case .success(let modelResponse):
    print("Response: \(modelResponse.text ?? "No response")")
case .failure(let error):
    print("Error: \(error)")
}
```

### Connection Checks

`connect()` remains available as a convenience method and returns a provider-specific string, usually the selected or active model. New code that needs more detail should use `checkConnection()`.

For OpenRouter and OpenAI-compatible APIs, connection checks send a minimal non-streaming chat-completion probe to `/chat/completions`. The probe uses one user message (`"ping"`), `maxTokens: 1`, no character/system context, and no sampling options. This validates the same endpoint used by normal chat requests while keeping latency and token usage as low as practical.

KoboldCPP uses `GET /api/v1/model` for the default check because local generation probes can be slow. The returned `ConnectionCheckResult` identifies this as `.serviceMetadata`, not `.chatCompletion`.

```swift
let checkResult = await apiManager.checkConnection()
switch checkResult {
case .success(let check):
    print("Provider: \(check.provider)")
    print("Check type: \(check.verification)")
    print("Endpoint: \(check.endpoint)")
    print("Model: \(check.model ?? "Unknown")")
    print("Chat ready: \(check.isChatReady)")
case .failure(let error):
    print("Connection check failed: \(error)")
}
```

### Streaming with OpenRouter

```swift
import SwiftLLMSDK
import SwiftUI

let openRouterAPI = OpenRouterAPI(
    selectedModel: "openai/gpt-4o-mini",
    apiKey: "your-api-key-here"
)
let apiManager = APIManager(forService: openRouterAPI)

let builder = OpenRouterRequestBuilder(
    model: "openai/gpt-4o-mini",
    messages: [
        RequestBodyMessages(role: .user, message: "Stream this response?")
    ],
    stream: true
)

// SwiftUI example
struct ChatView: View {
    @State private var assistantText = ""

    var body: some View {
        ScrollView {
            Text(assistantText)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
        }
        .task {
            for await result in apiManager.streamMessage(builder: builder) {
                switch result {
                case .success(let model):
                    await MainActor.run {
                        assistantText = model.text ?? ""

                        if let error = model.error {
                            print("stream ended with provider error: \(error.message)")
                        }
                    }
                case .failure(let error):
                    print("stream error: \(error)")
                }
            }
        }
    }
}
```

NOTE: Streaming with koboldCPP uses the same manager method, simply pass the correct request builder.

### Basic KoboldCPP Usage

```swift
import SwiftLLMSDK

// Initialize KoboldCPP API (local server)
let koboldAPI = KoboldAPI(
    host: "localhost",
    port: 5001
)

// Create API manager
let apiManager = APIManager(forService: koboldAPI)

// Test connection
let connectionResult = await apiManager.connect()
switch connectionResult {
case .success(let modelName):
    print("Connected to model: \(modelName)")
case .failure(let error):
    print("Connection failed: \(error)")
}

// Send a prompt (builder-based API)
let requestBuilder = KoboldRequestBuilder(
    prompt: "Once upon a time",
    maxLength: 100,
    temperature: 0.8
)

let response = await apiManager.sendMessage(builder: requestBuilder)
switch response {
case .success(let modelResponse):
    print("Generated text: \(modelResponse.text ?? "No response")")
case .failure(let error):
    print("Error: \(error)")
}
```

### Getting the services specific raw API response is possible

```swift
import SwiftLLMSDK

// Access raw openrouter response
if let openRouterResponse: OpenRouterAPIResponse = modelResponse.getRawResponse() {
    print("Model used: \(openRouterResponse.model ?? "Unknown")")
}

// Access raw kobold API response
if let koboldAPIResponse: KoboldAPIResponse = modelResponse.getRawResponse() {
    print("Kobold response: \(koboldAPIResponse.results.first?.text ?? "Unknown")")
}

```

## Character Card Integration

### Using Character Cards with OpenRouter

```swift
import SwiftLLMSDK

// Set up character information
let requestBuilder = OpenRouterRequestBuilder(
    model: "openai/gpt-4",
    messages: [
        RequestBodyMessages(role: .user, message: "Hello there!")
    ],
    systemPromptTemplate: nil,
    characterDescription: "A friendly AI assistant who loves to help with coding questions.",
    characterPersonality: "Enthusiastic, patient, and knowledgeable about programming.",
    characterScenario: "You are helping a developer learn Swift programming."
)

let response = await apiManager.sendMessage(builder: requestBuilder)
```

### Using Character Cards with KoboldCPP

```swift
import SwiftLLMSDK

// For KoboldCPP, character info goes into memory and prompt
let requestBuilder = KoboldRequestBuilder(
    prompt: "User: Hello there!\nAssistant:",
    memory: "You are a friendly AI assistant who loves to help with coding questions. You are enthusiastic, patient, and knowledgeable about programming.",
    maxLength: 150,
    temperature: 0.7,
    stopSequence: ["\nUser:", "\nAssistant:"]
)

let response = await apiManager.sendMessage(builder: requestBuilder)
```

## Character Card and Lore Book Import

Use `CharImporter` for character cards and lore books. Character cards support PNG metadata and JSON imports from local data or URLs. Lore books only support JSON imports.

```swift
import SwiftLLMSDK

// Initialize the importer
let importer = CharImporter(urlSession: URLSession.shared)

// Import a character card from a page URL, direct PNG URL, direct JSON URL, or file URL
let characterURL = URL(string: "https://example.com/characterCard.json")!

do {
    let characterCard = try await importer.importCard(from: characterURL)
    print("Character imported: \(characterCard.data?.name ?? "Unknown")")
    print("Description: \(characterCard.data?.description ?? "No description")")

    // Use the character card with your LLM
    let requestBuilder = OpenRouterRequestBuilder(
        model: "openai/gpt-4",
        messages: [
            RequestBodyMessages(role: .user, message: "Hello!")
        ],
        characterDescription: characterCard.data?.description,
        characterPersonality: characterCard.data?.personality,
        characterScenario: characterCard.data?.scenario
    )
} catch {
    print("Import error: \(error)")
}

// Import a lore book from JSON data or a JSON URL
do {
    let loreBookURL = URL(string: "https://example.com/lorebook.json")!
    let loreBook = try await importer.importLoreBook(from: loreBookURL)
    print("Lore book entries: \(loreBook.entries?.count ?? 0)")
} catch {
    print("Lore book import error: \(error)")
}
```

`ChubImporter` is deprecated and remains available only for compatibility. New code should use `CharImporter`.

## Advanced Usage

### Getting Available Models (OpenRouter)

```swift
let modelsResult = await apiManager.getAvailableModels()
switch modelsResult {
case .success(let models):
    for model in models {
        print("Model: \(model.name) - ID: \(model.id)")
        print("Context Length: \(model.contextLength ?? 0)")
        print("Description: \(model.description)")
    }
case .failure(let error):
    print("Failed to fetch models: \(error)")
}
```

### Advanced Parameter Configuration

```swift
let requestBuilder = OpenRouterRequestBuilder(
    model: "anthropic/claude-3-haiku",
    messages: [
        RequestBodyMessages(role: .system, message: "You are a helpful assistant."),
        RequestBodyMessages(role: .user, message: "Explain quantum computing")
    ],
    maxTokens: 500,
    temperature: 0.7,
    topP: 0.9,
    topK: 40,
    stop: ["\n\nHuman:", "\n\nAssistant:"],
    frequencyPenalty: 0.1,
    presencePenalty: 0.1
)
```

### Error Handling

Provider errors are normalized into `LLMError`, so client apps do not need separate parsing logic for KoboldAPI, OpenRouter, or OpenAI-compatible endpoints. The normalized error includes:

- `message` - User-facing provider message when available
- `provider` - `.kobold`, `.openRouter`, `.openAICompatible`, or `.unknown`
- `source` - `.http`, `.streamEvent`, `.transport`, `.decoding`, `.cancellation`, or `.sdk`
- `category` - `.authentication`, `.authorization`, `.rateLimit`, `.quotaExceeded`, `.contextLength`, `.invalidRequest`, `.serverError`, `.networkError`, `.decodingError`, `.cancelled`, `.unavailable`, `.timeout`, or `.unknown`
- `httpStatusCode`, `providerCode`, and `providerType` when available
- `rawBody` or `rawEvent` for bounded debugging payloads

Non-streaming provider failures are returned as `.failure(.llmError(error))`:

```swift
let response = await apiManager.sendMessage(builder: requestBuilder)
switch response {
case .success(let modelResponse):
    print("Success!")
    print("Response: \(modelResponse.text ?? "")")
    print("Tokens used: \(modelResponse.responseTokens ?? 0)")
    
    // Access raw response if needed
    if let openRouterResponse: OpenRouterAPIResponse = modelResponse.getRawResponse() {
        print("Model used: \(openRouterResponse.model ?? "Unknown")")
    }
    
case .failure(let error):
    switch error {
    case .llmError(let llmError):
        print("Provider: \(llmError.provider)")
        print("Category: \(llmError.category)")
        print("Message: \(llmError.message)")

        if let statusCode = llmError.httpStatusCode {
            print("HTTP status: \(statusCode)")
        }
    case .invalidURL:
        print("Invalid URL configuration")
    case .serverError(let code):
        print("Legacy server error with code: \(code)")
    case .timeout:
        print("Legacy timeout")
    case .decodingError:
        print("Legacy decoding failure")
    default:
        print("Other error: \(error.localizedDescription)")
    }
}
```

Streaming provider errors can arrive after partial content has already been emitted. In that case, the stream yields one final successful `ModelResponse` with `error != nil`, `streaming == false`, and `disconnect == true`, then finishes. The final response preserves accumulated `text` and `reasoning` so the app can decide how to display partial output.

```swift
for await result in apiManager.streamMessage(builder: requestBuilder) {
    switch result {
    case .success(let modelResponse):
        if let error = modelResponse.error {
            print("Partial text: \(modelResponse.text ?? "")")
            print("Stream failed: \(error.message)")
            return
        }

        print("Partial text: \(modelResponse.text ?? "")")

    case .failure(let error):
        print("Stream setup or transport error: \(error.localizedDescription)")
    }
}
```

## API Reference

### Core Classes

#### `APIManager<T: LanguageModelService>`

Generic manager for handling API calls to different LLM services.

**Methods:**

- `sendMessage(builder: OpenRouterRequestBuilder) async -> Result<ModelResponse, APIError>`
- `sendMessage(builder: ChatCompletionRequestBuilder) async -> Result<ModelResponse, APIError>`
- `sendMessage(builder: KoboldRequestBuilder) async -> Result<ModelResponse, APIError>`
- `streamMessage(builder: OpenRouterRequestBuilder) -> AsyncStream<Result<ModelResponse, APIError>>`
- `streamMessage(builder: ChatCompletionRequestBuilder) -> AsyncStream<Result<ModelResponse, APIError>>`
- `streamMessage(builder: KoboldRequestBuilder) -> AsyncStream<Result<ModelResponse, APIError>>`
- `checkConnection() async -> Result<ConnectionCheckResult, APIError>`
- `connect() async -> Result<String, APIError>` (convenience wrapper over `checkConnection()`)
- `getAvailableModels() async -> Result<[OpenRouterModel], APIError>` (OpenRouter)
- `getAvailableModels() async -> Result<[OpenAIModel], APIError>` (OpenAI-compatible)

#### `ConnectionCheckResult`

Connection check details returned by `checkConnection()`.

- `provider: LLMProvider` - Provider that was checked.
- `verification: ConnectionVerification` - `.chatCompletion` for OpenRouter/OpenAI-compatible probes, or `.serviceMetadata` for KoboldCPP's fast model metadata check.
- `endpoint: String` - Endpoint used for the check.
- `model: String?` - Model returned by the provider or selected for the probe.
- `message: String` - Short success message.
- `isChatReady: Bool` - `true` only when the check verified the chat-completion endpoint.

#### Request Builders

- `OpenRouterRequestBuilder`: Build chat-completion requests for OpenRouter.
  - Fields include `model`, `messages`, `stop`, `temperature`, `topP`, `minP`, `topA`, `topK`, `maxTokens`, `repetitionPenalty`, `frequencyPenalty`, `presencePenalty`, `stream`, and optional system/character fields.
- `ChatCompletionRequestBuilder`: Build generic OpenAI-compatible chat-completion requests.
  - Fields include `model`, `messages`, `stop`, `temperature`, `topP`, `maxTokens`, `frequencyPenalty`, `presencePenalty`, `stream`, optional `reasoningEffort`, and optional system/character fields.
- `KoboldRequestBuilder`: Build text-generation requests for KoboldCPP.
  - Fields include `prompt`, `memory`, `maxContextLength`, `maxLength`, `temperature`, `tfs`, `topA`, `topK`, `topP`, `minP`, `typical`, `repetitionPenalty`, `repetitionRange`, `repetitionSlope`, `stopSequence`, `trimStop`, `samplerOrder`, `promptTemplate`.

Compatibility: The legacy `RequestBodyBuilder` remains available but new code should prefer provider-specific builders.

#### `ModelResponse`

Unified response structure containing:

- `text: String?` - Generated text response
- `deltaText: String?` - Latest streamed text chunk, when streaming
- `reasoning: String?` - Accumulated reasoning text, when the provider returns reasoning content
- `deltaReasoning: String?` - Latest streamed reasoning chunk, when streaming
- `role: String?` - Response role (usually "assistant")
- `responseTokens: Int?` - Tokens used in response
- `promptTokens: Int?` - Tokens used in prompt
- `error: LLMError?` - Normalized provider or stream error, when a response carries an error
- `streaming`: Bool? - If the response is currently streaming data
- `isThinking: Bool` - Indicates the stream is currently emitting reasoning before response text begins
- `disconnect: Bool` - Indicates a stream should be treated as closed
- `rawResponse: Codable?` - Original API response when available

Note: Streaming uses `AsyncStream<Result<ModelResponse, APIError>>`. Each success emission contains accumulated `text` and `reasoning` so far, with `deltaText` or `deltaReasoning` set when the current event adds new content. If a provider sends a mid-stream error event, the final emission is a `ModelResponse` with accumulated output plus `error`.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request. For major changes, please open an issue first to discuss what you would like to change.

## License

This project is licensed under the MIT License - see the LICENSE file for details.
