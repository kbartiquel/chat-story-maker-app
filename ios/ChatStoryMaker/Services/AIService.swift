//
//  AIService.swift
//  Textory
//
//  Server API integration for AI story generation
//

import Foundation

class AIService {
    // Use same base URL as ServerExportService
    private var baseURL: String {
        ServerExportService.baseURL
    }

    struct GenerationRequest {
        let prompt: String
        let genre: String      // Can be preset or custom
        let mood: String       // Can be preset or custom
        let length: MessageLength
        let numCharacters: Int // 2 for 1-on-1, 3-10 for group
    }

    enum Genre: String, CaseIterable {
        case drama = "drama"
        case comedy = "comedy"
        case romance = "romance"
        case horror = "horror"
        case mystery = "mystery"
        case thriller = "thriller"
        case friendship = "friendship"
        case family = "family"

        var displayName: String {
            rawValue.capitalized
        }

        var icon: String {
            switch self {
            case .drama: return "theatermasks.fill"
            case .comedy: return "face.smiling.fill"
            case .romance: return "heart.fill"
            case .horror: return "bolt.fill"
            case .mystery: return "magnifyingglass"
            case .thriller: return "flame.fill"
            case .friendship: return "person.2.fill"
            case .family: return "house.fill"
            }
        }
    }

    enum Mood: String, CaseIterable {
        case funny = "funny"
        case dramatic = "dramatic"
        case scary = "scary"
        case romantic = "romantic"
        case happy = "happy"
        case sad = "sad"
        case tense = "tense"
        case casual = "casual"

        var displayName: String {
            rawValue.capitalized
        }

        var icon: String {
            switch self {
            case .funny: return "face.smiling"
            case .dramatic: return "exclamationmark.triangle"
            case .scary: return "eye.fill"
            case .romantic: return "heart.circle"
            case .happy: return "sun.max.fill"
            case .sad: return "cloud.rain.fill"
            case .tense: return "bolt.heart.fill"
            case .casual: return "cup.and.saucer.fill"
            }
        }
    }

    enum MessageLength: Int, CaseIterable {
        case short = 10
        case medium = 18
        case long = 30

        var displayName: String {
            switch self {
            case .short: return "Short (~10)"
            case .medium: return "Medium (~18)"
            case .long: return "Long (~30)"
            }
        }
    }

    // MARK: - Server Request/Response Models

    private struct ServerGenerateRequest: Codable {
        let topic: String
        let num_messages: Int
        let genre: String
        let mood: String
        let num_characters: Int
        let character_names: [String]?
    }

    private struct ServerGenerateResponse: Codable {
        let title: String
        let group_name: String?  // Realistic group chat name for groups (3+ characters)
        let characters: [ServerCharacter]
        let messages: [ServerMessage]
    }

    private struct ServerCharacter: Codable {
        let id: String
        let name: String
        let is_me: Bool
        let suggested_color: String
        let suggested_emoji: String?
    }

    private struct ServerMessage: Codable {
        let id: String
        let character_id: String
        let text: String
    }

    // MARK: - Public Response Models

    struct GeneratedCharacter {
        let id: String
        let name: String
        let isMe: Bool
        let colorHex: String
        let avatarEmoji: String?
    }

    struct GeneratedMessage {
        let id: String
        let characterId: String
        let text: String
    }

    struct GeneratedStory {
        let title: String
        let groupName: String?  // Realistic group chat name for groups (3+ characters)
        let characters: [GeneratedCharacter]
        let messages: [GeneratedMessage]
    }

    // MARK: - Generate Method

    func generateConversation(request: GenerationRequest) async throws -> GeneratedStory {
        guard let url = URL(string: "\(baseURL)/generate") else {
            throw AIError.invalidURL
        }

        let serverRequest = ServerGenerateRequest(
            topic: request.prompt,
            num_messages: request.length.rawValue,
            genre: request.genre,
            mood: request.mood,
            num_characters: request.numCharacters,
            character_names: nil
        )

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.timeoutInterval = 60 // AI generation can take time

        let encoder = JSONEncoder()
        urlRequest.httpBody = try encoder.encode(serverRequest)

        let (data, response) = try await URLSession.shared.data(for: urlRequest)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw AIError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            // Try to parse error message from server
            if let errorJson = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let detail = errorJson["detail"] as? String {
                throw AIError.serverError(detail)
            }
            throw AIError.apiError(statusCode: httpResponse.statusCode)
        }

        let decoder = JSONDecoder()
        let serverResponse = try decoder.decode(ServerGenerateResponse.self, from: data)

        // Convert server response to app models
        let characters = serverResponse.characters.map { char in
            GeneratedCharacter(
                id: char.id,
                name: char.name,
                isMe: char.is_me,
                colorHex: char.suggested_color,
                avatarEmoji: char.suggested_emoji
            )
        }

        let messages = serverResponse.messages.map { msg in
            GeneratedMessage(
                id: msg.id,
                characterId: msg.character_id,
                text: msg.text
            )
        }

        return GeneratedStory(
            title: serverResponse.title,
            groupName: serverResponse.group_name,
            characters: characters,
            messages: messages
        )
    }
}

enum AIError: Error, LocalizedError {
    case emptyResponse
    case parseError
    case invalidResponse
    case invalidURL
    case apiError(statusCode: Int)
    case serverError(String)

    var errorDescription: String? {
        switch self {
        case .emptyResponse:
            return "AI returned empty response"
        case .parseError:
            return "Failed to parse AI response"
        case .invalidResponse:
            return "Invalid response from server"
        case .invalidURL:
            return "Invalid server URL"
        case .apiError(let code):
            return "Server error (code: \(code))"
        case .serverError(let message):
            return message
        }
    }
}
