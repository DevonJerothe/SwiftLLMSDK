import Foundation

/// Universal importer for character cards and lore books.
///
/// Character cards support PNG and JSON imports locally or via URL.
/// Lore books support JSON imports locally or via URL.
public struct CharImporter {
    public var urlSession: URLSession

    public init(urlSession: URLSession = .shared) {
        self.urlSession = urlSession
    }

    public func importCard(from url: URL) async throws -> CharacterCard {
        let url = try await checkSourceURL(url)
        let data = try await loadData(from: url)
        let card = try importCard(from: data)

        if isPNG(data) {
            card.pngData = data
        }

        return card
    }

    public func importCard(from data: Data) throws -> CharacterCard {
        if isPNG(data) {
            return try importPNG(data)
        }

        return try importJSON(data)
    }

    public func importLoreBook(from url: URL) async throws -> LoreBookModel {
        let data = try await loadData(from: url)
        return try importLoreBook(from: data)
    }

    public func importLoreBook(from data: Data) throws -> LoreBookModel {
        guard !isPNG(data) else {
            throw ImporterError.invalidJson
        }

        do {
            return try JSONDecoder().decode(LoreBookModel.self, from: data)
        } catch {
            throw ImporterError.invalidJson
        }
    }
}

extension CharImporter {
    private func loadData(from url: URL) async throws -> Data {
        if url.isFileURL {
            return try Data(contentsOf: url)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"

        let (data, response) = try await urlSession.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw ImporterError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            throw ImporterError.serverError(code: httpResponse.statusCode)
        }

        return data
    }

    private func isPNG(_ data: Data) -> Bool {
        let pngSig = Data([137, 80, 78, 71, 13, 10, 26, 10])

        return data.count >= 8 && data[0..<8] == pngSig
    }

    private func importPNG(_ data: Data) throws -> CharacterCard {
        var textChunks = [String: String]()

        var offset = 8

        while offset + 8 <= data.count {
            let length = data.subdata(in: offset..<offset + 4)
                .withUnsafeBytes {
                    $0.load(as: UInt32.self).bigEndian
                }
            let typeData = data.subdata(in: offset + 4..<offset + 8)
            guard let chunkType = String(data: typeData, encoding: .ascii)
            else {
                break
            }

            let dataStart = offset + 8
            let dataEnd = dataStart + Int(length)
            let chunkEnd = dataEnd + 4

            guard chunkEnd <= data.count else {
                break
            }

            // Check if chunk is tEXt. This is where char info is stored.
            if chunkType == "tEXt" {
                let textData = data.subdata(in: dataStart..<dataEnd)
                if let textString = String(data: textData, encoding: .isoLatin1) {
                    let chunkParts = textString.components(separatedBy: "\0")
                    if chunkParts.count >= 2 {
                        let key = chunkParts[0]
                        let value = chunkParts.dropFirst().joined(
                            separator: "\0")
                        textChunks[key] = value
                    }
                }
            }

            offset = chunkEnd
        }

        // parse ccv3 over chara if present
        if let ccv3 = textChunks.first(where: { $0.key.lowercased() == "ccv3" }) {
            return try decodeCharacterCard(from: ccv3.value)
        }

        if let chara = textChunks.first(where: { $0.key.lowercased() == "chara" }) {
            return try decodeCharacterCard(from: chara.value)
        }

        throw ImporterError.noCharacterData
    }

    private func importJSON(_ data: Data) throws -> CharacterCard {
        if let characterCard = try? JSONDecoder().decode(CharacterCard.self, from: data) {
            return characterCard
        }
        throw ImporterError.invalidJson
    }

    private func decodeCharacterCard(from text: String) throws -> CharacterCard {
        let jsonData = try decodeCharacterMetaData(text)
        let characterCard = try JSONDecoder().decode(CharacterCard.self, from: jsonData)
        return characterCard
    }

    // Check if we are using clean JSON or Base64
    private func decodeCharacterMetaData(_ value: String) throws -> Data {
        if value.first == "{" {
            return Data(value.utf8)
        }

        if let data = Data(base64Encoded: value, options: .ignoreUnknownCharacters) {
            return data
        }

        if let percentDecoded = value.removingPercentEncoding {
            if percentDecoded.first == "{" {
                return Data(percentDecoded.utf8)
            }

            if let data = Data(base64Encoded: percentDecoded, options: .ignoreUnknownCharacters) {
                return data
            }
        }

        throw ImporterError.invalidJson
    }

    private func checkSourceURL(_ sourceURL: URL) async throws -> URL {
        guard !pointsToDirectImportFile(sourceURL) else {
            return sourceURL
        }

        for source in knownCharacterSources where source.matches(sourceURL) {
            return try await source.resolve(sourceURL, self)
        }

        return sourceURL
    }

    private var knownCharacterSources: [KnownCharacterSource] {
        [
            KnownCharacterSource(domains: ["botbooru.com"]) { url, _ in
                guard !url.path.hasPrefix("/download/png/"), let cardId = url.pathComponents.last else {
                    return url
                }

                return URL(string: "https://botbooru.com/download/png/\(cardId)") ?? url
            },
            KnownCharacterSource(domains: ["chub.ai", "characterhub.org"]) { url, importer in
                guard !url.hostMatches("gateway.chub.ai"), let fullPath = url.characterFullPath else {
                    return url
                }

                guard let apiURL = URL(string: "https://gateway.chub.ai/api/characters/\(fullPath)") else {
                    return url
                }

                let data = try await importer.loadData(from: apiURL)
                let chubData = try JSONDecoder().decode(ChubCard.self, from: data)

                return chubData.node?.avatar ?? url
            },
        ]
    }

    private func pointsToDirectImportFile(_ url: URL) -> Bool {
        switch url.pathExtension.lowercased() {
        case "json", "png":
            return true
        default:
            return false
        }
    }
}

private struct KnownCharacterSource {
    let domains: Set<String>
    let resolve: (URL, CharImporter) async throws -> URL

    init(domains: Set<String>, resolve: @escaping (URL, CharImporter) async throws -> URL) {
        self.domains = domains
        self.resolve = resolve
    }

    func matches(_ url: URL) -> Bool {
        domains.contains { url.hostMatches($0) }
    }
}

private extension URL {
    func hostMatches(_ domain: String) -> Bool {
        guard let host = host?.lowercased() else {
            return false
        }

        let domain = domain.lowercased()
        return host == domain || host.hasSuffix(".\(domain)")
    }

    var characterFullPath: String? {
        let pathComponents = pathComponents
        guard let characterIndex = pathComponents.firstIndex(of: "characters") else {
            return nil
        }

        let pathSegments = pathComponents[(characterIndex + 1)...]
        guard !pathSegments.isEmpty else {
            return nil
        }

        return pathSegments.joined(separator: "/")
    }
}

enum ImporterError: Error {
    case invalidResponse
    case serverError(code: Int)
    case noCharacterData
    case invalidJson
}
