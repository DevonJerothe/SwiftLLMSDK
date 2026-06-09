import Foundation

public typealias LoreBookModel = LoreBook

public class LoreBook: Codable {
    public var name: String?
    public var description: String?
    public var isCreation: Bool?
    public var scanDepth: Int?
    public var tokenBudget: Int?
    public var recursiveScanning: Bool?
    public var entries: [String: LoreBookEntry]?

    public enum CodingKeys: String, CodingKey {
        case name
        case description
        case isCreation = "is_creation"
        case scanDepth = "scan_depth"
        case tokenBudget = "token_budget"
        case recursiveScanning = "recursive_scanning"
        case entries
    }

    public init() {}

    /// Lorebook entries on character_book calls are returned as `[LoreBookEntries]` instead of the standard dictionary type. 
    /// We need to set some custom decoder rules so that we can re-use our `LoreBookModel` between Character Card imports and standalone Lore Books. 
    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        name = try container.decodeIfPresent(String.self, forKey: .name)
        description = try container.decodeIfPresent(String.self, forKey: .description)
        isCreation = try container.decodeIfPresent(Bool.self, forKey: .isCreation)
        scanDepth = try container.decodeIfPresent(Int.self, forKey: .scanDepth)
        tokenBudget = Self.decodeFlexableInt(from: container, forKey: .tokenBudget)
        recursiveScanning = try container.decodeIfPresent(Bool.self, forKey: .recursiveScanning)

        if let dictionaryEntries = try? container.decodeIfPresent([String: LoreBookEntry].self, forKey: .entries) {
            entries = dictionaryEntries
        } else if let arrayEntries = try? container.decodeIfPresent([LoreBookEntry].self, forKey: .entries) {
            entries = Self.dictionary(from: arrayEntries)
        } else {
            entries = nil 
        }
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encodeIfPresent(name, forKey: .name)
        try container.encodeIfPresent(description, forKey: .description)
        try container.encodeIfPresent(isCreation, forKey: .isCreation)
        try container.encodeIfPresent(scanDepth, forKey: .scanDepth)
        try container.encodeIfPresent(tokenBudget, forKey: .tokenBudget)
        try container.encodeIfPresent(recursiveScanning, forKey: .recursiveScanning)
        try container.encodeIfPresent(entries, forKey: .entries)
    }

    private static func dictionary(from array: [LoreBookEntry]) -> [String: LoreBookEntry] {
        Dictionary(
            uniqueKeysWithValues: array.enumerated().map { index, entry in 
                (String(index), entry)
            }
        )
    }

    private static func decodeFlexableInt(
        from container: KeyedDecodingContainer<CodingKeys>,
        forKey key: CodingKeys
    ) -> Int? {
        if let intValue = try? container.decodeIfPresent(Int.self, forKey: key) {
            return intValue
        } else if let stringValue = try? container.decodeIfPresent(String.self, forKey: key), let intValue = Int(stringValue) {
            return intValue
        } else {
            return nil
        }
    }
}

public class LoreBookEntry: Codable, Identifiable {
    public var uid: Int?
    public var key: [String]?
    public var keysecondary: [String]?
    public var comment: String?
    public var content: String?
    public var constant: Bool?
    public var selective: Bool?
    public var selectiveLogic: Int?
    public var order: Int?
    public var position: EntryPosition?
    public var disable: Bool?
    public var addMemo: Bool?
    public var excludeRecursion: Bool?
    public var probability: Int?
    public var displayIndex: Int?
    public var useProbability: Bool?
    public var secondaryKeys: [String]?
    public var keys: [String]?
    public var id: Int?
    public var priority: Int?
    public var insertionOrder: Int?
    public var enabled: Bool?
    public var name: String?
    public var extensions: LoreBookEntryExtensions?
    public var caseSensitive: Bool?
    public var depth: Int?

    public enum CodingKeys: String, CodingKey {
        case uid
        case key
        case keysecondary
        case comment
        case content
        case constant
        case selective
        case selectiveLogic
        case order
        case position
        case disable
        case addMemo
        case excludeRecursion
        case probability
        case displayIndex
        case useProbability
        case secondaryKeys = "secondary_keys"
        case keys
        case id
        case priority
        case insertionOrder = "insertion_order"
        case enabled
        case name
        case extensions
        case caseSensitive = "case_sensitive"
        case depth
    }
}

public class LoreBookEntryExtensions: Codable {
    public var depth: Int?
    public var weight: Int?
    public var addMemo: Bool?
    public var probability: Int?
    public var displayIndex: Int?
    public var selectiveLogic: Int?
    public var useProbability: Bool?
    public var excludeRecursion: Bool?
}

// Character Books on CharacterCard Models can have different string based values. 
// for now we will only support before / after character injection. 
public enum EntryPosition: Codable, Equatable {
    case index(Int)

    public var intValue: Int {
        switch self {
            case .index(let value): 
                return value
        }
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        if let intValue = try? container.decode(Int.self) {
            self = .index(intValue)
            return 
        }

        if let stringValue = try? container.decode(String.self) {
            switch stringValue {
                case "before_char": 
                    self = .index(0)
                case "after_char": 
                    self = .index(1)
                default: 
                    self = .index(2) // use depth
            }

            return 
        }

        throw DecodingError.typeMismatch(EntryPosition.self, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Expecting Int or String for position value"))
    }


    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()

        switch self {
            case .index(let intValue):
                try container.encode(intValue)
        }
    }
}

