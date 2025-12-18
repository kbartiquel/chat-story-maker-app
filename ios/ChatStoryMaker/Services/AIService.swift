//
//  AIService.swift
//  ChatStoryMaker
//
//  Claude API integration for AI story generation
//

import Foundation

class AIService {
    private let apiKey: String
    private let baseURL = "https://api.anthropic.com/v1/messages"

    init(apiKey: String = Config.claudeAPIKey) {
        self.apiKey = apiKey
    }

    struct GenerationRequest {
        let prompt: String
        let genre: Genre
        let mood: Mood
        let length: MessageLength
    }

    enum Genre: String, CaseIterable {
        case drama = "Drama"
        case comedy = "Comedy"
        case romance = "Romance"
        case horror = "Horror"
        case mystery = "Mystery"
    }

    enum Mood: String, CaseIterable {
        case funny = "Funny"
        case dramatic = "Dramatic"
        case scary = "Scary"
        case romantic = "Romantic"
    }

    enum MessageLength: Int, CaseIterable {
        case short = 8
        case medium = 15
        case long = 25

        var displayName: String {
            switch self {
            case .short: return "Short (5-10)"
            case .medium: return "Medium (10-20)"
            case .long: return "Long (20-30)"
            }
        }
    }

    func generateConversation(request: GenerationRequest) async throws -> [GeneratedMessage] {
        let systemPrompt = """
        You are a creative writer that generates realistic text message conversations.
        Generate a conversation based on the user's prompt.

        Rules:
        - Use exactly 2 characters: "Person A" (sender) and "Person B" (receiver)
        - Generate exactly \(request.length.rawValue) messages
        - Match the requested genre: \(request.genre.rawValue)
        - Match the requested mood: \(request.mood.rawValue)
        - Make it feel realistic with natural texting patterns
        - Include occasional typos, abbreviations, and emojis where appropriate

        Output format (JSON array):
        [
            {"sender": "A", "text": "message text"},
            {"sender": "B", "text": "reply text"},
            ...
        ]

        Only output the JSON array, nothing else.
        """

        let userPrompt = "Generate a \(request.mood.rawValue.lowercased()) \(request.genre.rawValue.lowercased()) text conversation about: \(request.prompt)"

        let requestBody: [String: Any] = [
            "model": "claude-sonnet-4-20250514",
            "max_tokens": 2000,
            "messages": [
                ["role": "user", "content": userPrompt]
            ],
            "system": systemPrompt
        ]

        var urlRequest = URLRequest(url: URL(string: baseURL)!)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        urlRequest.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        urlRequest.httpBody = try JSONSerialization.data(withJSONObject: requestBody)

        let (data, response) = try await URLSession.shared.data(for: urlRequest)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw AIError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            throw AIError.apiError(statusCode: httpResponse.statusCode)
        }

        let claudeResponse = try JSONDecoder().decode(ClaudeResponse.self, from: data)

        guard let content = claudeResponse.content.first?.text else {
            throw AIError.emptyResponse
        }

        // Parse JSON array from response
        guard let jsonData = content.data(using: .utf8),
              let messages = try? JSONDecoder().decode([GeneratedMessage].self, from: jsonData) else {
            throw AIError.parseError
        }

        return messages
    }
}

struct ClaudeResponse: Codable {
    let content: [ContentBlock]
}

struct ContentBlock: Codable {
    let text: String
}

struct GeneratedMessage: Codable {
    let sender: String
    let text: String
}

enum AIError: Error, LocalizedError {
    case emptyResponse
    case parseError
    case invalidResponse
    case apiError(statusCode: Int)

    var errorDescription: String? {
        switch self {
        case .emptyResponse:
            return "AI returned empty response"
        case .parseError:
            return "Failed to parse AI response"
        case .invalidResponse:
            return "Invalid response from server"
        case .apiError(let code):
            return "API error (code: \(code))"
        }
    }
}
