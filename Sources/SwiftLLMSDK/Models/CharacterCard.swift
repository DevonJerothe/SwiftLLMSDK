//
//  CharacterCard.swift
//  SwiftLLMSDK
//
//  Created by devon jerothe on 3/18/25.
//
import Foundation

public class ChubSearchResponse: Codable {
    public var data: ChubCardList? 

    public enum CodingKeys: String, CodingKey {
        case data = "data"
    }
}

public class ChubCardList: Codable {
    public var count: Int? 
    public var page: Int? 
    public var nodes: [ChubCardNode]? 

    public enum CodingKeys: String, CodingKey {
        case count = "count"
        case page = "page"
        case nodes = "nodes"
    }
}

public class ChubCard: Codable {
    public var node: ChubCardNode? 
}

public class ChubCardNode: Codable, Identifiable {
    public var id: Int? 
    public var name: String?
    public var createdAt: String?
    public var nTokens: Int? 
    public var tagline: String? 
    public var avatar: URL?
    public var thumbnail: URL? 

    public var fullPath: String? 
    public var description: String? 
    public var starCount: Int? 
    public var topics: [String]? // tags
    public var rating: Int? 
    public var ratingCount: Int? 
    public var creatorId: Int?
    public var nsfwImage: Bool? 
    public var isUnlisted: Bool? 

    public enum CodingKeys: String, CodingKey {
        case name = "name"
        case id = "id"
        case createdAt = "createdAt"
        case nTokens = "nTokens"
        case tagline = "tagline"
        case avatar = "max_res_url"
        case thumbnail = "avatar_url"
        case fullPath = "fullPath"
        case description = "description"
        case starCount = "starCount"
        case topics = "topics"
        case rating = "rating"
        case ratingCount = "ratingCount"
        case creatorId = "creatorId"
        case nsfwImage = "nsfw_image"
        case isUnlisted = "is_unlisted"
    }
}

public class CharacterCard: Codable {
    public var spec: String?
    public var spec_version: String?
    public var data: CharacterCardData?
    
    /// We want to pass the downloaded image data so that we can present the img on the view
    public var pngData: Data?
    public var cardDescription: String? 
    public var totalTokens: Int? 
}

public class CharacterCardData: Codable {
    public var name: String?
    public var description: String?
    public var personality: String?
    public var firstMessage: String? // first_mes
    public var avatar: String?
    public var messageExamples: String? // mes_example
    public var scenario: String?
    public var creatorNotes: String?
    public var systemPrompt: String?
    public var postHistoryInstructions: String?
    public var creator: String?
    public var characterVersion: String?
    public var alternateGreetings: [String]?
    public var tags: [String]?
    public var characterBook: LoreBook?

    public enum CodingKeys: String, CodingKey {
        case messageExamples = "mes_example"
        case firstMessage = "first_mes"
        case name = "name"
        case description = "description"
        case personality = "personality"
        case avatar = "avatar"
        case scenario = "scenario"
        case creatorNotes = "creator_notes"
        case systemPrompt = "system_prompt"
        case postHistoryInstructions = "post_history_instructions"
        case creator = "creator"
        case characterVersion = "character_version"
        case alternateGreetings = "alternate_greetings"
        case tags = "tags"
        case characterBook = "character_book"
    }
}
