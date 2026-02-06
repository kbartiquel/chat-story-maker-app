//
//  TexteryApp.swift
//  Textery
//
//  Created with Claude Code
//  Copyright © 2024 KimBytes. All rights reserved.
//

import SwiftUI
import SwiftData
import Aptabase
import RevenueCat

@main
struct TexteryApp: App {
    let container: ModelContainer

    init() {
        // Initialize analytics
        AnalyticsService.shared.initialize()
        AnalyticsService.shared.trackAppLaunch()

        // Initialize RevenueCat
        Purchases.logLevel = .debug
        Purchases.configure(withAPIKey: Config.revenueCatAPIKey)

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
        let descriptor = FetchDescriptor<Conversation>()

        do {
            let existing = try context.fetch(descriptor)
            if existing.count >= 6 { return }
            // Delete old demos to recreate with full set
            for conv in existing { context.delete(conv) }
        } catch {
            print("Failed to check for demo chat: \(error)")
        }

        // MARK: - 1. Ex Texts at 2AM
        let exChat = Conversation(title: "Ex Texts at 2AM Wanting to Get Back Together")

        if let sender = exChat.characters.first(where: { $0.isMe }) {
            sender.name = "Me"
        }
        if let receiver = exChat.characters.first(where: { !$0.isMe }) {
            receiver.name = "Jordan"
            receiver.colorHex = "#FF3B30"
        }

        let exMessages: [(String, Bool, DeliveryStatus)] = [
            ("hey", false, .none),
            ("are you up?", false, .none),
            ("i miss you so much", false, .none),
            ("jordan its 2am", true, .delivered),
            ("i know but i cant stop thinking about us", false, .none),
            ("we broke up for a reason", true, .read),
            ("i know but what if we gave it another shot", false, .none),
            ("no. goodnight jordan.", true, .read),
        ]

        for (index, (text, isMe, status)) in exMessages.enumerated() {
            let charID = isMe
                ? exChat.characters.first(where: { $0.isMe })!.id
                : exChat.characters.first(where: { !$0.isMe })!.id
            let msg = Message(text: text, characterID: charID, order: index)
            msg.status = status
            exChat.messages.append(msg)
        }
        context.insert(exChat)

        // MARK: - 2. My Ex Texted Me After 3 Years
        let exChat2 = Conversation(title: "My Ex Texted Me After 3 Years")

        if let sender = exChat2.characters.first(where: { $0.isMe }) {
            sender.name = "Me"
        }
        if let receiver = exChat2.characters.first(where: { !$0.isMe }) {
            receiver.name = "Alex"
            receiver.colorHex = "#AF52DE"
        }

        let exMessages2: [(String, Bool, DeliveryStatus)] = [
            ("hey stranger", false, .none),
            ("who is this", true, .delivered),
            ("its alex... from college", false, .none),
            ("oh wow. its been like 3 years", true, .read),
            ("yeah i know. i saw your post and it made me think of you", false, .none),
            ("alex... you literally ghosted me", true, .read),
            ("i know and i feel terrible about it", false, .none),
            ("can we get coffee and talk?", false, .none),
            ("i dont think thats a good idea", true, .read),
            ("please just hear me out", false, .none),
        ]

        for (index, (text, isMe, status)) in exMessages2.enumerated() {
            let charID = isMe
                ? exChat2.characters.first(where: { $0.isMe })!.id
                : exChat2.characters.first(where: { !$0.isMe })!.id
            let msg = Message(text: text, characterID: charID, order: index)
            msg.status = status
            exChat2.messages.append(msg)
        }
        context.insert(exChat2)

        // MARK: - 3. Family Group
        let familyChat = Conversation(title: "Family Group", isGroupChat: true)

        if let sender = familyChat.characters.first(where: { $0.isMe }) {
            sender.name = "Me"
        }

        let mom = Character(name: "Mom", colorHex: "#FF3B30", isMe: false)
        let dad = Character(name: "Dad", colorHex: "#007AFF", isMe: false)
        let sister = Character(name: "Sarah", colorHex: "#AF52DE", isMe: false)

        familyChat.characters.append(mom)
        familyChat.characters.append(dad)
        familyChat.characters.append(sister)

        let familySender = familyChat.characters.first(where: { $0.isMe })!

        let familyMessages: [(String, Character, DeliveryStatus)] = [
            ("whos coming to thanksgiving this year?", mom, .none),
            ("me and sarah for sure", familySender, .delivered),
            ("ill be there! bringing pie", dad, .none),
            ("omg dads making pie again", sister, .none),
            ("whats wrong with my pie??", dad, .none),
            ("nothing dad we love your pie", familySender, .read),
            ("should i make two this year?", dad, .none),
            ("YES", sister, .none),
        ]

        for (index, (text, character, status)) in familyMessages.enumerated() {
            let msg = Message(text: text, characterID: character.id, order: index)
            msg.status = character.isMe ? status : .none
            familyChat.messages.append(msg)
        }
        context.insert(familyChat)

        // MARK: - 4. The Trio (Friend Group)
        let trioChat = Conversation(title: "the trio", isGroupChat: true)

        if let sender = trioChat.characters.first(where: { $0.isMe }) {
            sender.name = "Me"
        }

        let friend1 = Character(name: "Mia", colorHex: "#FF9500", isMe: false)
        let friend2 = Character(name: "Chloe", colorHex: "#34C759", isMe: false)

        trioChat.characters.append(friend1)
        trioChat.characters.append(friend2)

        let trioSender = trioChat.characters.first(where: { $0.isMe })!

        let trioMessages: [(String, Character, DeliveryStatus)] = [
            ("GIRLS", friend1, .none),
            ("you will NOT believe what just happened", friend1, .none),
            ("WHAT", friend2, .none),
            ("tell us everything", trioSender, .delivered),
            ("i ran into my ex at the grocery store", friend1, .none),
            ("NO WAY", friend2, .none),
            ("and he was with his new girlfriend", friend1, .none),
            ("omg what did you do", trioSender, .read),
            ("i pretended i didnt see them and hid behind the cereal aisle", friend1, .none),
            ("LMAOOO", friend2, .none),
        ]

        for (index, (text, character, status)) in trioMessages.enumerated() {
            let msg = Message(text: text, characterID: character.id, order: index)
            msg.status = character.isMe ? status : .none
            trioChat.messages.append(msg)
        }
        context.insert(trioChat)

        // MARK: - 5. Wrong Number Horror
        let horrorChat = Conversation(title: "Wrong Number Turned Creepy")

        if let sender = horrorChat.characters.first(where: { $0.isMe }) {
            sender.name = "Me"
        }
        if let receiver = horrorChat.characters.first(where: { !$0.isMe }) {
            receiver.name = "Unknown"
            receiver.colorHex = "#8E8E93"
        }

        let horrorMessages: [(String, Bool, DeliveryStatus)] = [
            ("hey is this mike?", false, .none),
            ("no sorry wrong number", true, .delivered),
            ("thats weird because i got your number from your front door", false, .none),
            ("what?? i dont have my number on my door", true, .read),
            ("i know. i followed you home to get it.", false, .none),
            ("this isnt funny. who is this?", true, .read),
            ("look outside your window", false, .none),
            ("im calling the police", true, .read),
        ]

        for (index, (text, isMe, status)) in horrorMessages.enumerated() {
            let charID = isMe
                ? horrorChat.characters.first(where: { $0.isMe })!.id
                : horrorChat.characters.first(where: { !$0.isMe })!.id
            let msg = Message(text: text, characterID: charID, order: index)
            msg.status = status
            horrorChat.messages.append(msg)
        }
        context.insert(horrorChat)

        // MARK: - 6. Best Friend Confession
        let confessionChat = Conversation(title: "Best Friend Has a Secret")

        if let sender = confessionChat.characters.first(where: { $0.isMe }) {
            sender.name = "Me"
        }
        if let receiver = confessionChat.characters.first(where: { !$0.isMe }) {
            receiver.name = "Emma"
            receiver.colorHex = "#FF2D55"
        }

        let confessionMessages: [(String, Bool, DeliveryStatus)] = [
            ("hey can we talk about something", false, .none),
            ("of course whats up", true, .delivered),
            ("ive been keeping something from you", false, .none),
            ("youre scaring me emma", true, .read),
            ("its nothing bad i promise", false, .none),
            ("then what is it", true, .read),
            ("i think im in love with your brother", false, .none),
            ("WHAT", true, .read),
            ("please dont be mad", false, .none),
            ("emma... how long??", true, .read),
            ("like 2 years", false, .none),
            ("TWO YEARS?!", true, .read),
        ]

        for (index, (text, isMe, status)) in confessionMessages.enumerated() {
            let charID = isMe
                ? confessionChat.characters.first(where: { $0.isMe })!.id
                : confessionChat.characters.first(where: { !$0.isMe })!.id
            let msg = Message(text: text, characterID: charID, order: index)
            msg.status = status
            confessionChat.messages.append(msg)
        }
        context.insert(confessionChat)

        do {
            try context.save()
            print("Demo chats created successfully")
        } catch {
            print("Failed to save demo chats: \(error)")
        }
    }
}
