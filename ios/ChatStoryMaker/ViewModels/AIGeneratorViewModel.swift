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
    var selectedGenre: AIService.Genre = .drama
    var selectedMood: AIService.Mood = .dramatic
    var selectedLength: AIService.MessageLength = .medium

    var isGenerating = false
    var errorMessage: String?
    var generatedConversation: Conversation?
    var showingEditor = false

    private let aiService = AIService()
    private var modelContext: ModelContext?

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

        let request = AIService.GenerationRequest(
            prompt: prompt,
            genre: selectedGenre,
            mood: selectedMood,
            length: selectedLength
        )

        do {
            let messages = try await aiService.generateConversation(request: request)
            await MainActor.run {
                createConversation(from: messages)
            }
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.isGenerating = false
            }
        }
    }

    private func createConversation(from generatedMessages: [GeneratedMessage]) {
        guard let modelContext else {
            isGenerating = false
            return
        }

        // Create conversation with default title from prompt
        let title = String(prompt.prefix(30)) + (prompt.count > 30 ? "..." : "")
        let conversation = Conversation(title: title)

        // Update character names based on generation
        if conversation.characters.count >= 2 {
            conversation.characters[0].name = "Me"
            conversation.characters[1].name = "Other"
        }

        // Add messages
        for (index, genMessage) in generatedMessages.enumerated() {
            let characterIndex = genMessage.sender == "A" ? 0 : 1
            if characterIndex < conversation.characters.count {
                let message = Message(
                    text: genMessage.text,
                    characterID: conversation.characters[characterIndex].id,
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
        selectedLength = .medium
        generatedConversation = nil
        showingEditor = false
    }
}
