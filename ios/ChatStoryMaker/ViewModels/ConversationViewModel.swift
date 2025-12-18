//
//  ConversationViewModel.swift
//  ChatStoryMaker
//
//  ViewModel for managing conversations
//

import SwiftUI
import SwiftData

@Observable
class ConversationViewModel {
    var conversations: [Conversation] = []
    var folders: [Folder] = []
    var selectedConversation: Conversation?
    var showingNewConversation = false
    var showingFolderManagement = false
    var searchQuery = ""
    var selectedFolderID: UUID?

    private var modelContext: ModelContext?

    var filteredConversations: [Conversation] {
        var result = conversations

        // Filter by folder
        if let folderID = selectedFolderID {
            result = result.filter { $0.folderID == folderID }
        }

        // Filter by search query
        if !searchQuery.isEmpty {
            result = result.filter { conversation in
                conversation.title.localizedCaseInsensitiveContains(searchQuery) ||
                conversation.messages.contains { $0.text.localizedCaseInsensitiveContains(searchQuery) }
            }
        }

        return result
    }

    var unfolderedConversations: [Conversation] {
        conversations.filter { $0.folderID == nil }
    }

    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
        fetchConversations()
        fetchFolders()
        createSampleConversationIfNeeded()
    }

    private func createSampleConversationIfNeeded() {
        guard let modelContext else { return }

        // Check if this is first launch
        let hasLaunched = UserDefaults.standard.bool(forKey: "hasLaunchedBefore")
        guard !hasLaunched, conversations.isEmpty else { return }

        // Create sample conversation
        let sample = Conversation(title: "Sample Chat", theme: .imessage)

        // Add sample messages
        let sampleMessages = [
            ("Hey! Welcome to ChatTale!", false),
            ("Thanks! This app looks cool", true),
            ("You can create fake chat conversations and export them as videos!", false),
            ("Perfect for my TikTok content", true),
            ("Try adding more messages and then tap Export!", false)
        ]

        for (index, (text, isMe)) in sampleMessages.enumerated() {
            let characterIndex = isMe ? 0 : 1
            if characterIndex < sample.characters.count {
                let message = Message(
                    text: text,
                    characterID: sample.characters[characterIndex].id,
                    order: index
                )
                sample.messages.append(message)
            }
        }

        modelContext.insert(sample)
        saveContext()
        fetchConversations()

        UserDefaults.standard.set(true, forKey: "hasLaunchedBefore")
    }

    func fetchConversations() {
        guard let modelContext else { return }
        let descriptor = FetchDescriptor<Conversation>(
            sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]
        )
        do {
            conversations = try modelContext.fetch(descriptor)
        } catch {
            print("Failed to fetch conversations: \(error)")
        }
    }

    func createConversation(title: String, theme: ChatTheme = .imessage, isGroupChat: Bool = false) {
        guard let modelContext else { return }
        let conversation = Conversation(title: title, theme: theme, isGroupChat: isGroupChat)
        modelContext.insert(conversation)
        saveContext()
        fetchConversations()
    }

    func deleteConversation(_ conversation: Conversation) {
        guard let modelContext else { return }
        modelContext.delete(conversation)
        saveContext()
        fetchConversations()
    }

    func deleteConversations(at offsets: IndexSet) {
        let conversationsToDelete = offsets.map { filteredConversations[$0] }
        for conversation in conversationsToDelete {
            deleteConversation(conversation)
        }
    }

    // MARK: - Duplicate

    func duplicateConversation(_ conversation: Conversation) {
        guard let modelContext else { return }

        // Create new conversation with copied properties
        let duplicate = Conversation(title: "\(conversation.title) (Copy)", theme: conversation.theme)
        duplicate.folderID = conversation.folderID
        duplicate.receiptStyle = conversation.receiptStyle

        // Copy characters (need new IDs)
        duplicate.characters = []
        var characterIDMapping: [UUID: UUID] = [:]

        for character in conversation.characters {
            let newCharacter = Character(
                name: character.name,
                colorHex: character.colorHex,
                isMe: character.isMe,
                avatarEmoji: character.avatarEmoji,
                avatarImageData: character.avatarImageData
            )
            characterIDMapping[character.id] = newCharacter.id
            duplicate.characters.append(newCharacter)
        }

        // Copy messages with updated character IDs
        duplicate.messages = []
        for message in conversation.sortedMessages {
            let newCharacterID = characterIDMapping[message.characterID] ?? message.characterID
            let newMessage = Message(
                text: message.text,
                characterID: newCharacterID,
                order: message.order,
                type: message.type,
                imageData: message.imageData
            )
            newMessage.reactionsData = message.reactionsData
            newMessage.statusRawValue = message.statusRawValue
            newMessage.showTimestamp = message.showTimestamp
            newMessage.displayTime = message.displayTime
            duplicate.messages.append(newMessage)
        }

        modelContext.insert(duplicate)
        saveContext()
        fetchConversations()
        HapticManager.impact(.medium)
    }

    // MARK: - Folders

    func fetchFolders() {
        guard let modelContext else { return }
        let descriptor = FetchDescriptor<Folder>(
            sortBy: [SortDescriptor(\.order)]
        )
        do {
            folders = try modelContext.fetch(descriptor)
        } catch {
            print("Failed to fetch folders: \(error)")
        }
    }

    func createFolder(name: String, colorHex: String = "#007AFF") {
        guard let modelContext else { return }
        let order = (folders.map { $0.order }.max() ?? -1) + 1
        let folder = Folder(name: name, colorHex: colorHex, order: order)
        modelContext.insert(folder)
        saveContext()
        fetchFolders()
        HapticManager.impact(.light)
    }

    func updateFolder(_ folder: Folder, name: String, colorHex: String) {
        folder.name = name
        folder.colorHex = colorHex
        saveContext()
        fetchFolders()
    }

    func deleteFolder(_ folder: Folder) {
        guard let modelContext else { return }
        // Move conversations out of folder before deleting
        for conversation in conversations where conversation.folderID == folder.id {
            conversation.folderID = nil
        }
        modelContext.delete(folder)
        saveContext()
        fetchFolders()
        fetchConversations()
    }

    func moveConversation(_ conversation: Conversation, to folder: Folder?) {
        conversation.folderID = folder?.id
        conversation.updatedAt = Date()
        saveContext()
        fetchConversations()
        HapticManager.selection()
    }

    func conversationsInFolder(_ folder: Folder) -> [Conversation] {
        conversations.filter { $0.folderID == folder.id }
    }

    private func saveContext() {
        guard let modelContext else { return }
        do {
            try modelContext.save()
        } catch {
            print("Failed to save context: \(error)")
        }
    }
}
