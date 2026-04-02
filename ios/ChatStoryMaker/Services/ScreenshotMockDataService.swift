//
//  ScreenshotMockDataService.swift
//  Textery
//
//  Seeds polished mock conversations for App Store screenshot prep.
//

import Foundation
import SwiftData

@MainActor
final class ScreenshotMockDataService {
    static let shared = ScreenshotMockDataService()

    private init() {}

    private struct FolderSeed {
        let name: String
        let colorHex: String
        let order: Int
    }

    private struct MessageSeed {
        let senderIndex: Int
        let text: String
        let minutesOffset: Int
    }

    private struct ConversationSeed {
        let title: String
        let folderName: String?
        let updatedHoursAgo: Int
        let isGroupChat: Bool
        let characters: [(name: String, colorHex: String, isMe: Bool)]
        let messages: [MessageSeed]
    }

    private let folderSeeds: [FolderSeed] = [
        FolderSeed(name: "Trending", colorHex: "#E07B5E", order: 0),
        FolderSeed(name: "Plot Twists", colorHex: "#FF9500", order: 1),
        FolderSeed(name: "Group Chats", colorHex: "#34C759", order: 2)
    ]

    private let conversationSeeds: [ConversationSeed] = [
        ConversationSeed(
            title: "Ex Texted at 2AM",
            folderName: "Trending",
            updatedHoursAgo: 1,
            isGroupChat: false,
            characters: [
                ("Me", "#E07B5E", true),
                ("Luca", "#34C759", false)
            ],
            messages: [
                MessageSeed(senderIndex: 1, text: "you awake", minutesOffset: 0),
                MessageSeed(senderIndex: 0, text: "barely. what happened", minutesOffset: 2),
                MessageSeed(senderIndex: 1, text: "i made a mistake", minutesOffset: 5),
                MessageSeed(senderIndex: 0, text: "that sounds like a morning problem", minutesOffset: 7),
                MessageSeed(senderIndex: 1, text: "i saw your post tonight", minutesOffset: 10),
                MessageSeed(senderIndex: 1, text: "with the flowers", minutesOffset: 11),
                MessageSeed(senderIndex: 0, text: "luca...", minutesOffset: 13),
                MessageSeed(senderIndex: 1, text: "is it serious with him", minutesOffset: 15),
                MessageSeed(senderIndex: 0, text: "why does that matter now", minutesOffset: 18),
                MessageSeed(senderIndex: 1, text: "because i should've said something before", minutesOffset: 21),
                MessageSeed(senderIndex: 0, text: "you had six months", minutesOffset: 24),
                MessageSeed(senderIndex: 1, text: "i know", minutesOffset: 26),
                MessageSeed(senderIndex: 1, text: "i kept thinking i could fix my own life first", minutesOffset: 28),
                MessageSeed(senderIndex: 0, text: "and now", minutesOffset: 31),
                MessageSeed(senderIndex: 1, text: "now i'm outside your building like an idiot", minutesOffset: 34),
                MessageSeed(senderIndex: 0, text: "wait what", minutesOffset: 35),
                MessageSeed(senderIndex: 1, text: "i'm in the blue car across the street", minutesOffset: 37),
                MessageSeed(senderIndex: 0, text: "you are unbelievable", minutesOffset: 40),
                MessageSeed(senderIndex: 1, text: "just tell me to leave and i will", minutesOffset: 42),
                MessageSeed(senderIndex: 0, text: "give me five minutes", minutesOffset: 45)
            ]
        ),
        ConversationSeed(
            title: "The Party Went Wrong",
            folderName: "Plot Twists",
            updatedHoursAgo: 3,
            isGroupChat: false,
            characters: [
                ("Me", "#E07B5E", true),
                ("Nina", "#AF52DE", false)
            ],
            messages: [
                MessageSeed(senderIndex: 1, text: "wait... who invited him", minutesOffset: 0),
                MessageSeed(senderIndex: 0, text: "nobody. he's standing by the cake", minutesOffset: 1),
                MessageSeed(senderIndex: 1, text: "i am literally hiding in the bathroom", minutesOffset: 4)
            ]
        ),
        ConversationSeed(
            title: "Birthday Surprise Plan",
            folderName: "Trending",
            updatedHoursAgo: 6,
            isGroupChat: true,
            characters: [
                ("Me", "#E07B5E", true),
                ("Sarah", "#FF9500", false),
                ("Mika", "#AF52DE", false),
                ("Jay", "#00C7BE", false)
            ],
            messages: [
                MessageSeed(senderIndex: 1, text: "do NOT text her in this group", minutesOffset: 0),
                MessageSeed(senderIndex: 2, text: "too late i already reacted to her story", minutesOffset: 1),
                MessageSeed(senderIndex: 3, text: "we are so bad at secrets", minutesOffset: 3),
                MessageSeed(senderIndex: 0, text: "focus. balloons at 7, cake at 7:30", minutesOffset: 5)
            ]
        ),
        ConversationSeed(
            title: "Mystery Number",
            folderName: "Plot Twists",
            updatedHoursAgo: 11,
            isGroupChat: false,
            characters: [
                ("Me", "#E07B5E", true),
                ("Unknown", "#8E8E93", false)
            ],
            messages: [
                MessageSeed(senderIndex: 1, text: "I know what you did", minutesOffset: 0),
                MessageSeed(senderIndex: 0, text: "wrong number", minutesOffset: 2),
                MessageSeed(senderIndex: 1, text: "then why are you shaking", minutesOffset: 4),
                MessageSeed(senderIndex: 0, text: "okay that's weird", minutesOffset: 6),
                MessageSeed(senderIndex: 1, text: "you checked the window before replying", minutesOffset: 8),
                MessageSeed(senderIndex: 0, text: "who is this", minutesOffset: 10),
                MessageSeed(senderIndex: 1, text: "someone who was there that night", minutesOffset: 13),
                MessageSeed(senderIndex: 0, text: "i think you have the wrong person", minutesOffset: 16),
                MessageSeed(senderIndex: 1, text: "red jacket. rooftop. 11:43 pm.", minutesOffset: 19),
                MessageSeed(senderIndex: 0, text: "stop", minutesOffset: 21),
                MessageSeed(senderIndex: 1, text: "you dropped something when you ran", minutesOffset: 24),
                MessageSeed(senderIndex: 0, text: "what do you want", minutesOffset: 27),
                MessageSeed(senderIndex: 1, text: "to return it", minutesOffset: 30),
                MessageSeed(senderIndex: 0, text: "i'm calling the police", minutesOffset: 31),
                MessageSeed(senderIndex: 1, text: "they won't get here before i do", minutesOffset: 34),
                MessageSeed(senderIndex: 0, text: "where are you", minutesOffset: 37),
                MessageSeed(senderIndex: 1, text: "look at your front door camera", minutesOffset: 39)
            ]
        ),
        ConversationSeed(
            title: "Wedding Group Chat",
            folderName: "Group Chats",
            updatedHoursAgo: 18,
            isGroupChat: true,
            characters: [
                ("Me", "#E07B5E", true),
                ("Ate Jen", "#FF2D55", false),
                ("Marco", "#5856D6", false),
                ("Tita May", "#34C759", false)
            ],
            messages: [
                MessageSeed(senderIndex: 1, text: "table 6 is chaos again", minutesOffset: 0),
                MessageSeed(senderIndex: 2, text: "who gave uncle romy the mic", minutesOffset: 1),
                MessageSeed(senderIndex: 3, text: "he has started a second speech", minutesOffset: 3)
            ]
        ),
        ConversationSeed(
            title: "Mom Found the Secret",
            folderName: nil,
            updatedHoursAgo: 24,
            isGroupChat: false,
            characters: [
                ("Me", "#E07B5E", true),
                ("Mom", "#FF3B30", false)
            ],
            messages: [
                MessageSeed(senderIndex: 1, text: "call me right now", minutesOffset: 0),
                MessageSeed(senderIndex: 0, text: "why do moms type like final bosses", minutesOffset: 2),
                MessageSeed(senderIndex: 1, text: "i heard that", minutesOffset: 4)
            ]
        ),
        ConversationSeed(
            title: "Group Trip Disaster",
            folderName: "Group Chats",
            updatedHoursAgo: 30,
            isGroupChat: true,
            characters: [
                ("Me", "#E07B5E", true),
                ("Ari", "#34C759", false),
                ("Bea", "#FF9500", false),
                ("Kevin", "#007AFF", false)
            ],
            messages: [
                MessageSeed(senderIndex: 1, text: "we left kevin at the gas station", minutesOffset: 0),
                MessageSeed(senderIndex: 2, text: "HE TOLD US TO DRIVE", minutesOffset: 1),
                MessageSeed(senderIndex: 3, text: "i meant emotionally", minutesOffset: 4),
                MessageSeed(senderIndex: 0, text: "please tell me this is a joke", minutesOffset: 6),
                MessageSeed(senderIndex: 1, text: "check the backseat then apologize", minutesOffset: 7),
                MessageSeed(senderIndex: 2, text: "we did. only snacks and betrayal", minutesOffset: 10),
                MessageSeed(senderIndex: 3, text: "i have half a sandwich and full faith you'll return", minutesOffset: 13),
                MessageSeed(senderIndex: 0, text: "what exit are you at", minutesOffset: 15),
                MessageSeed(senderIndex: 3, text: "the one with the giant chicken statue", minutesOffset: 18),
                MessageSeed(senderIndex: 2, text: "that does not narrow it down at all", minutesOffset: 20),
                MessageSeed(senderIndex: 1, text: "also his charger is still here", minutesOffset: 23),
                MessageSeed(senderIndex: 3, text: "great. tell my phone i loved her", minutesOffset: 25),
                MessageSeed(senderIndex: 0, text: "turning around now", minutesOffset: 28),
                MessageSeed(senderIndex: 2, text: "hurry because a tour bus just arrived and kevin is making friends", minutesOffset: 31),
                MessageSeed(senderIndex: 3, text: "update: i may be joining a church retreat", minutesOffset: 34),
                MessageSeed(senderIndex: 1, text: "if they feed you, wait there", minutesOffset: 36),
                MessageSeed(senderIndex: 0, text: "i can see the chicken statue", minutesOffset: 40),
                MessageSeed(senderIndex: 3, text: "pick me up beside the gift shop. i have changed", minutesOffset: 42)
            ]
        ),
        ConversationSeed(
            title: "He Was Never Alone",
            folderName: "Plot Twists",
            updatedHoursAgo: 40,
            isGroupChat: false,
            characters: [
                ("Me", "#E07B5E", true),
                ("Mira", "#AF52DE", false)
            ],
            messages: [
                MessageSeed(senderIndex: 1, text: "then who was standing behind you", minutesOffset: 0),
                MessageSeed(senderIndex: 0, text: "stop texting me stuff like that at midnight", minutesOffset: 2),
                MessageSeed(senderIndex: 1, text: "im serious. check the mirror", minutesOffset: 5)
            ]
        ),
        ConversationSeed(
            title: "Roommate Rules",
            folderName: nil,
            updatedHoursAgo: 52,
            isGroupChat: false,
            characters: [
                ("Me", "#E07B5E", true),
                ("Kai", "#00C7BE", false)
            ],
            messages: [
                MessageSeed(senderIndex: 1, text: "new rule: no blender after midnight", minutesOffset: 0),
                MessageSeed(senderIndex: 0, text: "counter rule: no karaoke before coffee", minutesOffset: 2),
                MessageSeed(senderIndex: 1, text: "absolutely fair", minutesOffset: 6)
            ]
        ),
        ConversationSeed(
            title: "Sister Saw Everything",
            folderName: "Trending",
            updatedHoursAgo: 70,
            isGroupChat: false,
            characters: [
                ("Me", "#E07B5E", true),
                ("Ava", "#FF2D55", false)
            ],
            messages: [
                MessageSeed(senderIndex: 1, text: "i saw you leave with the flowers", minutesOffset: 0),
                MessageSeed(senderIndex: 0, text: "snitches do not get wedding invites", minutesOffset: 2),
                MessageSeed(senderIndex: 1, text: "im literally the maid of honor", minutesOffset: 4)
            ]
        )
    ]

    func seedAppStoreMockData(in modelContext: ModelContext) throws {
        try removeExistingSeedData(in: modelContext)

        let folderMap = try createFolders(in: modelContext)
        try createConversations(in: modelContext, folders: folderMap)

        try modelContext.save()
    }

    private func removeExistingSeedData(in modelContext: ModelContext) throws {
        let folderNames = Set(folderSeeds.map(\.name))
        let conversationTitles = Set(conversationSeeds.map(\.title))

        let existingFolders = try modelContext.fetch(FetchDescriptor<Folder>())
        for folder in existingFolders where folderNames.contains(folder.name) {
            modelContext.delete(folder)
        }

        let existingConversations = try modelContext.fetch(FetchDescriptor<Conversation>())
        for conversation in existingConversations where conversationTitles.contains(conversation.title) {
            modelContext.delete(conversation)
        }
    }

    private func createFolders(in modelContext: ModelContext) throws -> [String: Folder] {
        var folderMap: [String: Folder] = [:]

        for seed in folderSeeds {
            let folder = Folder(name: seed.name, colorHex: seed.colorHex, order: seed.order)
            folder.createdAt = Calendar.current.date(byAdding: .day, value: -seed.order, to: Date()) ?? Date()
            modelContext.insert(folder)
            folderMap[seed.name] = folder
        }

        return folderMap
    }

    private func createConversations(in modelContext: ModelContext, folders: [String: Folder]) throws {
        let now = Date()

        for seed in conversationSeeds {
            let conversation = Conversation(title: seed.title, theme: .imessage, isGroupChat: seed.isGroupChat)
            conversation.characters = seed.characters.map {
                Character(name: $0.name, colorHex: $0.colorHex, isMe: $0.isMe)
            }

            if let folderName = seed.folderName {
                conversation.folderID = folders[folderName]?.id
            }

            let updatedAt = Calendar.current.date(byAdding: .hour, value: -seed.updatedHoursAgo, to: now) ?? now
            conversation.createdAt = Calendar.current.date(byAdding: .hour, value: -(seed.updatedHoursAgo + 6), to: now) ?? updatedAt
            conversation.updatedAt = updatedAt

            conversation.messages = seed.messages.enumerated().map { index, messageSeed in
                let characterID = conversation.characters[messageSeed.senderIndex].id
                let message = Message(text: messageSeed.text, characterID: characterID, order: index)
                let timestamp = Calendar.current.date(byAdding: .minute, value: messageSeed.minutesOffset, to: conversation.createdAt) ?? conversation.createdAt
                message.timestamp = timestamp
                message.displayTime = timestamp
                return message
            }

            modelContext.insert(conversation)
        }
    }
}
