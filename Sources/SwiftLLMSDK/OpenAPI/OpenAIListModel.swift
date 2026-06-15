import Foundation 

protocol APIModel {
    var id: String { get }
}

public class OpenAIModelList: Codable {
    public let data: [OpenAIModel]

    public init (data: [OpenAIModel]) {
        self.data = data
    }
}

public class OpenAIModel: APIModel, Codable {
    public let id: String
    public let object: String? 
    public let ownedBy: String?

    enum CodingKeys: String, CodingKey {
        case id
        case object
        case ownedBy = "owned_by"
    }
}