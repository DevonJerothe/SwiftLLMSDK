# SwiftLLMSDK

A unified Swift package for connecting to various Large Language Model (LLM) backend services with a focus on character cards and AI interactions. SwiftLLMSDK provides a clean, type-safe interface for working with different LLM providers while maintaining character card compatibility.

## Features

- **🔗 Unified API Interface**: Single interface for multiple LLM providers
- **🤖 Character Card Support**: Built-in support for character cards with system prompts, personalities, and scenarios
- **📥 ChubAI Import**: Direct import of character cards from Chub.ai and CharacterHub.org
- **⚡ Async/Await**: Modern Swift concurrency with async/await
- **🛡️ Type Safety**: Strong typing with Result types for error handling
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

// Send a message
let requestBuilder = RequestBodyBuilder(
    selectedModel: "openai/gpt-4",
    messages: [
        RequestBodyMessages(role: .user, message: "Hello, how are you?")
    ]
)

let response = await apiManager.sendMessage(promptModel: requestBuilder)
switch response {
case .success(let modelResponse):
    print("Response: \(modelResponse.text ?? "No response")")
case .failure(let error):
    print("Error: \(error)")
}
```

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

// Send a prompt
let requestBuilder = RequestBodyBuilder(
    prompt: "Once upon a time",
    maxLength: 100,
    temperature: 0.8
)

let response = await apiManager.sendMessage(promptModel: requestBuilder)
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
let requestBuilder = RequestBodyBuilder(
    selectedModel: "openai/gpt-4",
    messages: [
        RequestBodyMessages(role: .user, message: "Hello there!")
    ],
    characterDescription: "A friendly AI assistant who loves to help with coding questions.",
    characterPersonality: "Enthusiastic, patient, and knowledgeable about programming.",
    characterScenario: "You are helping a developer learn Swift programming."
)

let response = await apiManager.sendMessage(promptModel: requestBuilder)
```

### Using Character Cards with KoboldCPP

```swift
import SwiftLLMSDK

// For KoboldCPP, character info goes into memory and prompt
let requestBuilder = RequestBodyBuilder(
    prompt: "User: Hello there!\nAssistant:",
    memory: "You are a friendly AI assistant who loves to help with coding questions. You are enthusiastic, patient, and knowledgeable about programming.",
    maxLength: 150,
    temperature: 0.7,
    stopSequence: ["\nUser:", "\nAssistant:"]
)

let response = await apiManager.sendMessage(promptModel: requestBuilder)
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
let requestBuilder = RequestBodyBuilder(
    selectedModel: "anthropic/claude-3-haiku",
    messages: [
        RequestBodyMessages(role: .system, message: "You are a helpful assistant."),
        RequestBodyMessages(role: .user, message: "Explain quantum computing")
    ],
    maxContextLength: 8192,
    maxLength: 500,
    temperature: 0.7,
    topP: 0.9,
    topK: 40,
    stopSequence: ["\n\nHuman:", "\n\nAssistant:"],
    frequencyPen: 0.1,
    presencePen: 0.1
)
```

### Error Handling

```swift
let response = await apiManager.sendMessage(promptModel: requestBuilder)
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
    case .invalidURL:
        print("Invalid URL configuration")
    case .serverError(let code):
        print("Server error with code: \(code)")
    case .timeout:
        print("Request timed out")
    case .decodingError:
        print("Failed to decode response")
    default:
        print("Other error: \(error.localizedDescription)")
    }
}
```

## API Reference

### Core Classes

#### `APIManager<T: LanguageModelService>`
Generic manager for handling API calls to different LLM services.

**Methods:**
- `sendMessage(promptModel: RequestBodyBuilder) async -> Result<ModelResponse, APIError>`
- `connect() async -> Result<String, APIError>` (OpenRouter/Kobold specific)
- `getAvailableModels() async -> Result<[OpenRouterModel], APIError>` (OpenRouter only)

#### `RequestBodyBuilder`
Builder class for constructing requests with support for both OpenRouter and KoboldCPP parameters.

**Key Properties:**
- `selectedModel: String` - Model identifier (OpenRouter)
- `messages: [RequestBodyMessages]` - Chat messages (OpenRouter)
- `prompt: String?` - Direct prompt text (KoboldCPP)
- `memory: String?` - System/character context (KoboldCPP)
- `temperature: Double?` - Sampling temperature
- `maxLength: Int?` - Maximum response length
- Character card properties: `characterDescription`, `characterPersonality`, `characterScenario`

#### `ModelResponse`
Unified response structure containing:
- `text: String?` - Generated text response
- `role: String?` - Response role (usually "assistant")
- `responseTokens: Int?` - Tokens used in response
- `promptTokens: Int?` - Tokens used in prompt
- `rawResponse: Codable` - Original API response


## Contributing

Contributions are welcome! Please feel free to submit a Pull Request. For major changes, please open an issue first to discuss what you would like to change.

## License

This project is licensed under the MIT License - see the LICENSE file for details.