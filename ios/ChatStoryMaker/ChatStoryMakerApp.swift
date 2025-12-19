//
//  ChatStoryMakerApp.swift
//  ChatStoryMaker
//
//  Created with Claude Code
//  Copyright © 2024 KimBytes. All rights reserved.
//

import SwiftUI
import SwiftData

@main
struct ChatStoryMakerApp: App {
    let container: ModelContainer

    init() {
        do {
            let schema = Schema([Conversation.self, Character.self, Message.self, Folder.self, ExportHistory.self])
            let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
            container = try ModelContainer(for: schema, configurations: [config])
            createDemoChatIfNeeded(container: container)
        } catch {
            // If migration fails, try to delete and recreate
            print("ModelContainer error: \(error). Attempting to reset database...")
            do {
                // Delete existing store and create fresh
                let schema = Schema([Conversation.self, Character.self, Message.self, Folder.self, ExportHistory.self])
                let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

                // Try to delete old data
                let url = config.url
                try? FileManager.default.removeItem(at: url)
                // Also remove related files
                let walURL = url.deletingPathExtension().appendingPathExtension("sqlite-wal")
                let shmURL = url.deletingPathExtension().appendingPathExtension("sqlite-shm")
                try? FileManager.default.removeItem(at: walURL)
                try? FileManager.default.removeItem(at: shmURL)

                container = try ModelContainer(for: schema, configurations: [config])
                createDemoChatIfNeeded(container: container)
            } catch {
                fatalError("Failed to create ModelContainer after reset: \(error)")
            }
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(container)
    }

    private func createDemoChatIfNeeded(container: ModelContainer) {
        let context = container.mainContext

        // Check if demo chats already exist
        let descriptor = FetchDescriptor<Conversation>(
            predicate: #Predicate { $0.title == "Demo Chat" || $0.title == "Family Group 👨‍👩‍👧‍👦" }
        )

        do {
            let existing = try context.fetch(descriptor)
            if existing.count >= 2 { return }
        } catch {
            print("Failed to check for demo chat: \(error)")
        }

        // MARK: - Create 1-on-1 Demo Chat
        let demoChat = Conversation(title: "Demo Chat")

        // Update character names
        if let sender = demoChat.characters.first(where: { $0.isMe }) {
            sender.name = "Me"
            sender.avatarEmoji = "😊"
        }
        if let receiver = demoChat.characters.first(where: { !$0.isMe }) {
            receiver.name = "Jane"
            receiver.colorHex = "#34C759"
            receiver.avatarEmoji = "👩"
        }

        // Add demo messages
        let messages: [(String, Bool, DeliveryStatus)] = [
            ("Hey! How's it going? 👋", false, .none),
            ("I'm doing great, thanks for asking!", true, .delivered),
            ("Are you free this weekend?", false, .none),
            ("Let me check my schedule...", true, .read),
            ("Yes! I'm free on Saturday 🎉", true, .read),
            ("Perfect! Let's grab coffee ☕", false, .none),
        ]

        for (index, (text, isMe, status)) in messages.enumerated() {
            let characterID = isMe
                ? demoChat.characters.first(where: { $0.isMe })!.id
                : demoChat.characters.first(where: { !$0.isMe })!.id

            let message = Message(text: text, characterID: characterID, order: index)
            message.status = status

            // Add timestamp to first message
            if index == 0 {
                message.showTimestamp = true
            }

            demoChat.messages.append(message)
        }

        // Add a reaction to one message
        if let lastReceiverMessage = demoChat.messages.last(where: {
            demoChat.characters.first(where: { !$0.isMe })?.id == $0.characterID
        }) {
            let senderID = demoChat.characters.first(where: { $0.isMe })!.id
            lastReceiverMessage.addReaction("❤️", from: senderID)
        }

        context.insert(demoChat)

        // MARK: - Create Group Chat Demo
        let groupChat = Conversation(title: "Family Group 👨‍👩‍👧‍👦", isGroupChat: true)

        // Setup sender
        if let sender = groupChat.characters.first(where: { $0.isMe }) {
            sender.name = "Me"
            sender.avatarEmoji = "😊"
        }

        // Add family members
        let mom = Character(name: "Mom", colorHex: "#FF3B30", isMe: false, avatarEmoji: "👩")
        let dad = Character(name: "Dad", colorHex: "#007AFF", isMe: false, avatarEmoji: "👨")
        let sister = Character(name: "Sarah", colorHex: "#AF52DE", isMe: false, avatarEmoji: "👧")

        groupChat.characters.append(mom)
        groupChat.characters.append(dad)
        groupChat.characters.append(sister)

        // Group chat messages with character references
        let senderID = groupChat.characters.first(where: { $0.isMe })!.id

        let groupMessages: [(String, Character, DeliveryStatus)] = [
            ("Hey everyone! 👋", mom, .none),
            ("Don't forget dinner at 7pm tonight!", mom, .none),
            ("I'll be there! 🍕", groupChat.characters.first(where: { $0.isMe })!, .delivered),
            ("Can we do 7:30 instead? Running late from work", dad, .none),
            ("Sure, 7:30 works!", mom, .none),
            ("I'm bringing dessert! 🎂", sister, .none),
            ("Awesome! Can't wait 😋", groupChat.characters.first(where: { $0.isMe })!, .read),
            ("See you all soon! ❤️", mom, .none),
        ]

        for (index, (text, character, status)) in groupMessages.enumerated() {
            let message = Message(text: text, characterID: character.id, order: index)
            message.status = character.isMe ? status : .none

            // Add timestamp to first message
            if index == 0 {
                message.showTimestamp = true
            }

            groupChat.messages.append(message)
        }

        // Add reactions to group chat
        if let dessertMessage = groupChat.messages.first(where: { $0.text.contains("dessert") }) {
            dessertMessage.addReaction("😍", from: senderID)
            dessertMessage.addReaction("❤️", from: mom.id)
        }

        context.insert(groupChat)

        do {
            try context.save()
            print("Demo chats created successfully")
        } catch {
            print("Failed to save demo chats: \(error)")
        }
    }
}
