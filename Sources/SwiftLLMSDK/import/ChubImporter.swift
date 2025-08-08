//
//  ChubImporter.swift
//  SwiftLLMSDK
//
//  Created by devon jerothe on 3/18/25.
//

import Foundation

public protocol CharacterImporterService {
    var urlSession: URLSession { get }
    var siteURL: URL { get }

    func getCardViaURL(_ url: URL) async throws -> Result<CharacterCard, APIError>
}

public struct ChubImporter: CharacterImporterService {
    public var urlSession: URLSession
    public var siteURL: URL = URL(string: "https://chub.dev")!

    public init(urlSession: URLSession) {
        self.urlSession = urlSession
    }

    public func getCardViaURL(_ url: URL) async throws -> Result<CharacterCard, APIError>
    {
        // Example URL: "https://chub.ai/characters/Anonymous/aweseomeCard"
        // Extract the path after "characters/"
        // Check if URL matches expected patterns
        let validDomains = ["chub.ai", "characterhub.org"]
        let urlComponents = url.pathComponents
        guard let host = url.host, validDomains.contains(host), url.pathComponents.contains("characters") else {
            return .failure(.unsupportedURLImport)
        }

        let charactersIndex = urlComponents.firstIndex(of: "characters")

        // Combine the components after "characters/" to form the fullPath
        let fullPath = charactersIndex.flatMap { index in
            let pathSegments = Array(urlComponents[(index + 1)...])
            return pathSegments.isEmpty
                ? nil : pathSegments.joined(separator: "/")
        }
        guard let fullPath else {
            throw PNGMetadataError.invalidURL
        }

        let downloadURL = URL(string: "https://gateway.chub.ai/api/characters/\(fullPath)")!
        let data = try await getData(url: downloadURL)

        // Pull the Chub AI Info and then parse the png data prior to saving as PNG.
        // PNG is saved in CgBI format on Apple devices. This breaks standard chunk data extract.
        // Can prob be fixed, but I spent to much time trying to do it. This works fine.
        do {

            let chubCard = try JSONDecoder().decode(ChubCard.self, from: data)
            // Download the PNG data from the chub info
            guard let pngURL = chubCard.node?.avatar else {
                throw APIError.invalidResponse
            }

            let pngData = try await getData(url: pngURL)
            let characterCard = try getCharData(data: pngData)
            // inject card info into the returned character card. This info is not in the png data.
            characterCard.data?.avatar = pngURL.absoluteString
            characterCard.cardDescription = chubCard.node?.tagline
            characterCard.totalTokens = chubCard.node?.nTokens

            // Also add downloaded PNG data to model so we can skip using async image via URL
            characterCard.pngData = pngData
            return .success(characterCard)
        } catch (let error) {
            throw error
        }
    }
}

extension ChubImporter {

    private func getData(url: URL) async throws -> Data {
        var request = URLRequest(url: url)
        request.httpMethod = "GET"

        let (data, response) = try await urlSession.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        if !(200...299).contains(httpResponse.statusCode) {
            throw APIError.serverError(code: httpResponse.statusCode)
        }

        return data
    }

    /**
     * Reads Character metadata from a PNG image buffer.
     * Supports both V2 (chara) and V3 (ccv3). V3 (ccv3) takes precedence.
     * @param data PNG image data
     * @returns Character data as a CharacterCard object
     */
    private func getCharData(data: Data) throws -> CharacterCard {
        var textChunks = [String: String]()
        let pngSig = Data([137, 80, 78, 71, 13, 10, 26, 10])

        // Validate file is PNG format
        guard data.count >= 8, data[0..<8] == pngSig else {
            throw PNGMetadataError.invalidImage
        }

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
                if let textString = String(data: textData, encoding: .isoLatin1)
                {
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

        var charText: String?

        // Parse the data for `chara` or 'ccv3' char types
        if let charChunks = textChunks.first(where: {
            $0.key.lowercased() == "chara" || $0.key.lowercased() == "ccv3"
        }) {
            guard let decodedData = Data(base64Encoded: charChunks.value),
                let text = String(data: decodedData, encoding: .utf8)
            else {
                throw PNGMetadataError.invalidEncoding
            }
            charText = text
        }

        // Load parsed char info in CharacterCard..
        if let charText = charText {
            let jsonData = charText.data(using: .utf8)!
            let characterCard = try JSONDecoder().decode(CharacterCard.self, from: jsonData)
            return characterCard
        }

        throw PNGMetadataError.noCharacterData
    }

    enum PNGMetadataError: Error {
        case invalidImage
        case noMetadata
        case noTextChunks
        case invalidEncoding
        case noCharacterData
        case unsupportedFormat
        case invalidURL
    }
}
