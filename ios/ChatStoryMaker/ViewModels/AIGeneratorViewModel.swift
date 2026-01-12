//
//  AIGeneratorViewModel.swift
//  ChatStoryMaker
//
//  ViewModel for AI story generation
//

import SwiftUI
import SwiftData

@Observable
class AIGeneratorViewModel {
    var prompt = ""
    var selectedGenre: AIService.Genre? = .drama
    var selectedMood: AIService.Mood? = .dramatic
    var customGenre = ""
    var customMood = ""
    var selectedLength: AIService.MessageLength = .medium
    var numCharacters: Int = 2

    var isGenerating = false
    var errorMessage: String?
    var generatedConversation: Conversation?
    var showingEditor = false

    private let aiService = AIService()
    private var modelContext: ModelContext?

    var isGroupChat: Bool {
        numCharacters > 2
    }

    // Get effective genre string (preset or custom)
    var effectiveGenre: String {
        if let genre = selectedGenre {
            return genre.rawValue
        }
        return customGenre.isEmpty ? "drama" : customGenre
    }

    // Get effective mood string (preset or custom)
    var effectiveMood: String {
        if let mood = selectedMood {
            return mood.rawValue
        }
        return customMood.isEmpty ? "dramatic" : customMood
    }

    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
    }

    var canGenerate: Bool {
        !prompt.trimmingCharacters(in: .whitespaces).isEmpty && !isGenerating
    }

    func generateStory() async {
        guard canGenerate else { return }

        isGenerating = true
        errorMessage = nil

        AnalyticsService.shared.trackAIGenerationStarted(
            genre: effectiveGenre,
            mood: effectiveMood,
            length: String(selectedLength.rawValue),
            characterCount: numCharacters
        )

        let request = AIService.GenerationRequest(
            prompt: prompt,
            genre: effectiveGenre,
            mood: effectiveMood,
            length: selectedLength,
            numCharacters: numCharacters
        )

        do {
            let story = try await aiService.generateConversation(request: request)
            await MainActor.run {
                createConversation(from: story)
                AnalyticsService.shared.trackAIGenerationCompleted(messageCount: story.messages.count)
            }
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.isGenerating = false
                AnalyticsService.shared.trackAIGenerationFailed(error: error.localizedDescription)
            }
        }
    }

    private func createConversation(from story: AIService.GeneratedStory) {
        guard let modelContext else {
            isGenerating = false
            return
        }

        // For group chats, use the group_name as conversation title (realistic chat names)
        // For 1-on-1 chats, use the story title
        let conversationTitle = isGroupChat ? (story.groupName ?? story.title) : story.title
        let conversation = Conversation(title: conversationTitle, isGroupChat: isGroupChat)

        // Clear default characters and create from AI response
        conversation.characters.removeAll()

        // Create characters from AI response (no avatar - use first letter of name)
        for genChar in story.characters {
            let character = Character(
                name: genChar.name,
                colorHex: genChar.colorHex,
                isMe: genChar.isMe,
                avatarEmoji: nil
            )
            conversation.characters.append(character)
        }

        // Create a mapping from AI character IDs to app character IDs
        var characterIdMap: [String: UUID] = [:]
        for (index, genChar) in story.characters.enumerated() {
            if index < conversation.characters.count {
                characterIdMap[genChar.id] = conversation.characters[index].id
            }
        }

        // Add messages with correct character IDs
        for (index, genMessage) in story.messages.enumerated() {
            if let characterId = characterIdMap[genMessage.characterId] {
                let message = Message(
                    text: genMessage.text,
                    characterID: characterId,
                    order: index
                )
                conversation.messages.append(message)
            }
        }

        modelContext.insert(conversation)
        try? modelContext.save()

        generatedConversation = conversation
        isGenerating = false
        showingEditor = true
    }

    func reset() {
        prompt = ""
        selectedGenre = .drama
        selectedMood = .dramatic
        customGenre = ""
        customMood = ""
        selectedLength = .medium
        numCharacters = 2
        generatedConversation = nil
        showingEditor = false
    }
}
