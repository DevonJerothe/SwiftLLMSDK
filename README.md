# SwiftLLMSDK

A unified Swift package for connecting to various Large Language Model (LLM) backend services with a focus on character cards and AI interactions. SwiftLLMSDK provides a clean, type-safe interface for working with different LLM providers while maintaining character card compatibility.

## Features

- **🔗 Unified API Interface**: Single interface for multiple LLM providers
- **🤖 Character Card Support**: Built-in support for character cards with system prompts, personalities, and scenarios
- **📥 ChubAI Import**: Direct import of character cards from Chub.ai and CharacterHub.org
- **⚡ Async/Await**: Modern Swift concurrency with async/await
- **🛡️ Type Safety**: Strong typing with Result types and normalized provider error details
- **🔧 Flexible Configuration**: Extensive customization options for model parameters

## Supported Providers

### OpenRouter

- **Purpose**: Access to multiple LLM models through a single API
- **Features**: Model listing, API key validation, chat completions
- **Authentication**: API key required

### KoboldCPP

- **Purpose**: Local LLM inference server
- **Features**: Direct HTTP connection to local instances
- **Authentication**: No API key required (local connection)

### OpenAI-Compatible APIs

- **Purpose**: Connect to OpenAI-compatible chat completion endpoints
- **Features**: Chat completions, streaming, model listing
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
case .success(let keyLabel):
    print("Connected successfully: \(keyLabel)")
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

## ChubAI Character Import

Import character cards directly from Chub.ai or CharacterHub.org:

```swift
import SwiftLLMSDK

// Initialize the importer
let chubImporter = ChubImporter(urlSession: URLSession.shared)

// Import a character card from URL
let characterURL = URL(string: "https://chub.ai/characters/author/character-name")!

do {
    let result = try await chubImporter.getCardViaURL(characterURL)
    switch result {
    case .success(let characterCard):
        print("Character imported: \(characterCard.data?.name ?? "Unknown")")
        print("Description: \(characterCard.data?.description ?? "No description")")
        
        // Use the character card with your LLM
        let requestBuilder = RequestBodyBuilder(
            selectedModel: "openai/gpt-4",
            messages: [
                RequestBodyMessages(role: .user, message: "Hello!")
            ],
            characterDescription: characterCard.data?.description,
            characterPersonality: characterCard.data?.personality,
            characterScenario: characterCard.data?.scenario
        )
        
    case .failure(let error):
        print("Import failed: \(error)")
    }
} catch {
    print("Import error: \(error)")
}
```

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
- `connect() async -> Result<String, APIError>` (provider-specific)
- `getAvailableModels() async -> Result<[OpenRouterModel], APIError>` (OpenRouter)
- `getAvailableModels() async -> Result<[OpenAIModel], APIError>` (OpenAI-compatible)

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
- `role: String?` - Response role (usually "assistant")
- `responseTokens: Int?` - Tokens used in response
- `promptTokens: Int?` - Tokens used in prompt
- `error: LLMError?` - Normalized provider or stream error, when a response carries an error
- `streaming`: Bool? - If the response is currently streaming data
- `disconnect: Bool` - Indicates a stream should be treated as closed
- `rawResponse: Codable?` - Original API response when available

Note: Streaming uses `AsyncStream<Result<ModelResponse, APIError>>`. Each success emission contains the accumulated `text` so far. If a provider sends a mid-stream error event, the final emission is a `ModelResponse` with the accumulated text plus `error`.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request. For major changes, please open an issue first to discuss what you would like to change.

## License

This project is licensed under the MIT License - see the LICENSE file for details.
