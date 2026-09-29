import Foundation

/// A Codable representation of arbitrary JSON values, used for JSON Schema
/// tool parameters without sacrificing type safety.
public enum JSONValue: Codable, Equatable, Sendable {
    case object([String: JSONValue])
    case array([JSONValue])
    case string(String)
    case integer(Int)
    case number(Double)
    case bool(Bool)
    case null

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        if container.decodeNil() {
            self = .null
        } else if let value = try? container.decode(Bool.self) {
            self = .bool(value)
        } else if let value = try? container.decode(Int.self) {
            self = .integer(value)
        } else if let value = try? container.decode(Double.self) {
            self = .number(value)
        } else if let value = try? container.decode(String.self) {
            self = .string(value)
        } else if let value = try? container.decode([JSONValue].self) {
            self = .array(value)
        } else if let value = try? container.decode([String: JSONValue].self) {
            self = .object(value)
        } else {
            throw DecodingError.typeMismatch(
                JSONValue.self,
                DecodingError.Context(
                    codingPath: decoder.codingPath,
                    debugDescription: "Expected a JSON value"
                )
            )
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()

        switch self {
        case .object(let value):
            try container.encode(value)
        case .array(let value):
            try container.encode(value)
        case .string(let value):
            try container.encode(value)
        case .integer(let value):
            try container.encode(value)
        case .number(let value):
            try container.encode(value)
        case .bool(let value):
            try container.encode(value)
        case .null:
            try container.encodeNil()
        }
    }
}

public enum ToolType: String, Codable, Sendable {
    case function
}

public struct ToolDefinition: Codable, Equatable, Sendable {
    public var type: ToolType
    public var function: FunctionDefinition

    public init(type: ToolType = .function, function: FunctionDefinition) {
        self.type = type
        self.function = function
    }
}

public struct FunctionDefinition: Codable, Equatable, Sendable {
    public var name: String
    public var description: String?
    public var parameters: JSONValue
    public var strict: Bool?

    public init(
        name: String,
        description: String? = nil,
        parameters: JSONValue = .object([:]),
        strict: Bool? = nil
    ) {
        self.name = name
        self.description = description
        self.parameters = parameters
        self.strict = strict
    }
}

public struct FunctionCall: Codable, Equatable, Sendable {
    public var name: String?
    /// JSON encoded arguments. Providers stream this value in fragments, so it
    /// should only be decoded after the tool call is complete.
    public var arguments: String

    public init(name: String?, arguments: String) {
        self.name = name
        self.arguments = arguments
    }

    public func decodeArguments<T: Decodable>(as type: T.Type = T.self) throws -> T {
        try JSONDecoder().decode(T.self, from: Data(arguments.utf8))
    }
}

public struct ToolCall: Codable, Equatable, Sendable {
    public var id: String?
    public var type: ToolType?
    public var function: FunctionCall

    public init(id: String?, type: ToolType? = .function, function: FunctionCall) {
        self.id = id
        self.type = type
        self.function = function
    }
}

public struct FunctionCallDelta: Codable, Equatable, Sendable {
    public var name: String?
    public var arguments: String?

    public init(name: String? = nil, arguments: String? = nil) {
        self.name = name
        self.arguments = arguments
    }
}

public struct ToolCallDelta: Codable, Equatable, Sendable {
    public var index: Int
    public var id: String?
    public var type: ToolType?
    public var function: FunctionCallDelta?

    public init(
        index: Int,
        id: String? = nil,
        type: ToolType? = nil,
        function: FunctionCallDelta? = nil
    ) {
        self.index = index
        self.id = id
        self.type = type
        self.function = function
    }
}

public enum ToolChoice: Codable, Equatable, Sendable {
    case auto
    case none
    case required
    case function(name: String)

    private enum CodingKeys: String, CodingKey {
        case type
        case function
    }

    private struct NamedFunction: Codable, Equatable, Sendable {
        var name: String
    }

    public init(from decoder: Decoder) throws {
        let singleValue = try decoder.singleValueContainer()
        if let value = try? singleValue.decode(String.self) {
            switch value {
            case "auto": self = .auto
            case "none": self = .none
            case "required": self = .required
            default:
                throw DecodingError.dataCorruptedError(
                    in: singleValue,
                    debugDescription: "Unknown tool choice: \(value)"
                )
            }
            return
        }

        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(ToolType.self, forKey: .type)
        guard type == .function else {
            throw DecodingError.dataCorruptedError(
                forKey: .type,
                in: container,
                debugDescription: "Only function tool choices are supported"
            )
        }
        let function = try container.decode(NamedFunction.self, forKey: .function)
        self = .function(name: function.name)
    }

    public func encode(to encoder: Encoder) throws {
        switch self {
        case .auto:
            var container = encoder.singleValueContainer()
            try container.encode("auto")
        case .none:
            var container = encoder.singleValueContainer()
            try container.encode("none")
        case .required:
            var container = encoder.singleValueContainer()
            try container.encode("required")
        case .function(let name):
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(ToolType.function, forKey: .type)
            try container.encode(NamedFunction(name: name), forKey: .function)
        }
    }
}

struct ToolCallAccumulator {
    var id: String?
    var type: ToolType?
    var name: String?
    var arguments = ""

    mutating func append(_ delta: ToolCallDelta) {
        id = delta.id ?? id
        type = delta.type ?? type
        if let nameFragment = delta.function?.name {
            name = (name ?? "") + nameFragment
        }
        arguments += delta.function?.arguments ?? ""
    }

    var toolCall: ToolCall {
        ToolCall(
            id: id,
            type: type,
            function: FunctionCall(name: name, arguments: arguments)
        )
    }
}
