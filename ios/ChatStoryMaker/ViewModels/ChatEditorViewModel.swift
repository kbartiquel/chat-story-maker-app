//
//  ChatEditorViewModel.swift
//  ChatStoryMaker
//
//  ViewModel for chat editor logic
//

import SwiftUI
import SwiftData

@Observable
class ChatEditorViewModel {
    var conversation: Conversation
    var messageText = ""
    var selectedCharacter: Character?
    var editingMessage: Message?
    var showingExport = false

    private var modelContext: ModelContext?

    init(conversation: Conversation) {
        self.conversation = conversation
        self.selectedCharacter = conversation.characters.first
    }

    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
    }

    var sortedMessages: [Message] {
        conversation.messages.sorted { $0.order < $1.order }
    }

    var characters: [Character] {
        conversation.characters
    }

    func getCharacter(for message: Message) -> Character? {
        conversation.characters.first { $0.id == message.characterID }
    }

    func sendMessage() {
        guard !messageText.trimmingCharacters(in: .whitespaces).isEmpty,
              let character = selectedCharacter else { return }

        let newOrder = (conversation.messages.map { $0.order }.max() ?? -1) + 1
        let message = Message(
            text: messageText.trimmingCharacters(in: .whitespaces),
            characterID: character.id,
            order: newOrder
        )

        conversation.messages.append(message)
        conversation.updatedAt = Date()
        messageText = ""
        saveContext()

        // Haptic feedback and sound
        HapticManager.impact(.light)
        if character.isMe {
            AudioService.shared.playSendSound()
        } else {
            AudioService.shared.playReceiveSound()
        }
    }

    func deleteMessage(_ message: Message) {
        conversation.messages.removeAll { $0.id == message.id }
        reorderMessages()
        conversation.updatedAt = Date()
        saveContext()
    }

    func deleteMessages(at offsets: IndexSet) {
        let sorted = sortedMessages
        for index in offsets {
            if let messageIndex = conversation.messages.firstIndex(where: { $0.id == sorted[index].id }) {
                conversation.messages.remove(at: messageIndex)
            }
        }
        reorderMessages()
        conversation.updatedAt = Date()
        saveContext()
    }

    func moveMessage(from source: IndexSet, to destination: Int) {
        var sorted = sortedMessages
        sorted.move(fromOffsets: source, toOffset: destination)
        for (index, message) in sorted.enumerated() {
            message.order = index
        }
        conversation.updatedAt = Date()
        saveContext()
    }

    func updateMessage(_ message: Message, newText: String) {
        message.text = newText
        conversation.updatedAt = Date()
        saveContext()
    }

    // MARK: - Image Messages

    func sendImageMessage(imageData: Data) {
        guard let character = selectedCharacter else { return }

        let newOrder = (conversation.messages.map { $0.order }.max() ?? -1) + 1
        let message = Message(imageData: imageData, characterID: character.id, order: newOrder)

        conversation.messages.append(message)
        conversation.updatedAt = Date()
        saveContext()

        HapticManager.impact(.light)
        if character.isMe {
            AudioService.shared.playSendSound()
        } else {
            AudioService.shared.playReceiveSound()
        }
    }

    // MARK: - Reactions

    func addReaction(to message: Message, emoji: String) {
        guard let character = selectedCharacter else { return }
        message.addReaction(emoji, from: character.id)
        conversation.updatedAt = Date()
        saveContext()
        HapticManager.impact(.light)
    }

    func removeReaction(from message: Message) {
        guard let character = selectedCharacter else { return }
        message.removeReaction(from: character.id)
        conversation.updatedAt = Date()
        saveContext()
    }

    // MARK: - Timestamps

    func toggleTimestamp(for message: Message) {
        message.showTimestamp.toggle()
        conversation.updatedAt = Date()
        saveContext()
        HapticManager.selection()
    }

    func setDisplayTime(for message: Message, time: Date?) {
        message.displayTime = time
        conversation.updatedAt = Date()
        saveContext()
    }

    // MARK: - Delivery Status

    func setDeliveryStatus(for message: Message, status: DeliveryStatus) {
        message.status = status
        conversation.updatedAt = Date()
        saveContext()
        HapticManager.selection()
    }

    // MARK: - Receipt Style

    func setReceiptStyle(_ style: ReceiptStyle) {
        conversation.receiptStyle = style
        conversation.updatedAt = Date()
        saveContext()
    }

    // MARK: - Character Management

    private let participantColors = ["#FF3B30", "#34C759", "#FF9500", "#5856D6", "#FF2D55", "#AF52DE", "#00C7BE", "#FF6482"]

    func addCharacter() {
        let participantNumber = conversation.characters.filter { !$0.isMe }.count + 1
        let colorIndex = (participantNumber - 1) % participantColors.count
        let newCharacter = Character(
            name: "Person \(participantNumber)",
            colorHex: participantColors[colorIndex],
            isMe: false
        )
        conversation.characters.append(newCharacter)
        conversation.updatedAt = Date()
        saveContext()
        HapticManager.impact(.light)
    }

    func removeCharacter(_ character: Character) {
        // Don't allow removing the sender
        guard !character.isMe else { return }
        // Don't allow removing if there would be no receivers
        guard conversation.characters.filter({ !$0.isMe }).count > 1 else { return }

        conversation.characters.removeAll { $0.id == character.id }
        // Remove messages from this character
        conversation.messages.removeAll { $0.characterID == character.id }
        reorderMessages()
        conversation.updatedAt = Date()
        saveContext()
    }

    private func reorderMessages() {
        for (index, message) in sortedMessages.enumerated() {
            message.order = index
        }
    }

    private func saveContext() {
        guard let modelContext else { return }
        do {
            try modelContext.save()
        } catch {
            print("Failed to save: \(error)")
        }
    }
}
