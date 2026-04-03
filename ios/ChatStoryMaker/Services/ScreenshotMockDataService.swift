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
        FolderSeed(name: "Fictional Worlds", colorHex: "#E07B5E", order: 0),
        FolderSeed(name: "Plot Twists", colorHex: "#FF9500", order: 1),
        FolderSeed(name: "Ensemble Casts", colorHex: "#34C759", order: 2)
    ]

    private let conversationSeeds: [ConversationSeed] = [
        ConversationSeed(
            title: "Moon Base Lockdown",
            folderName: "Fictional Worlds",
            updatedHoursAgo: 1,
            isGroupChat: false,
            characters: [
                ("Me", "#E07B5E", true),
                ("Nova", "#34C759", false)
            ],
            messages: [
                MessageSeed(senderIndex: 1, text: "captain are you awake", minutesOffset: 0),
                MessageSeed(senderIndex: 0, text: "if this is about freeze-dried coffee im resigning", minutesOffset: 2),
                MessageSeed(senderIndex: 1, text: "worse. deck b sealed itself again", minutesOffset: 5),
                MessageSeed(senderIndex: 0, text: "did the station AI get dramatic", minutesOffset: 7),
                MessageSeed(senderIndex: 1, text: "it keeps announcing lunar sunrise in five different voices", minutesOffset: 10),
                MessageSeed(senderIndex: 0, text: "thats unsettlingly creative", minutesOffset: 12),
                MessageSeed(senderIndex: 1, text: "also the greenhouse lights are blinking SOS", minutesOffset: 15),
                MessageSeed(senderIndex: 0, text: "please tell me the tomatoes are not sentient", minutesOffset: 18),
                MessageSeed(senderIndex: 1, text: "no promises", minutesOffset: 20),
                MessageSeed(senderIndex: 0, text: "im heading to command now", minutesOffset: 23),
                MessageSeed(senderIndex: 1, text: "bring the override key", minutesOffset: 25),
                MessageSeed(senderIndex: 0, text: "the gold one or the illegal one", minutesOffset: 28),
                MessageSeed(senderIndex: 1, text: "the illegal one obviously", minutesOffset: 31),
                MessageSeed(senderIndex: 0, text: "you are a terrible influence for a moon engineer", minutesOffset: 34),
                MessageSeed(senderIndex: 1, text: "captain the moon is literally glowing outside", minutesOffset: 37),
                MessageSeed(senderIndex: 0, text: "okay now im running", minutesOffset: 40),
                MessageSeed(senderIndex: 1, text: "good because the AI just called me witness number one", minutesOffset: 44)
            ]
        ),
        ConversationSeed(
            title: "Dragon Detention",
            folderName: "Plot Twists",
            updatedHoursAgo: 3,
            isGroupChat: false,
            characters: [
                ("Me", "#E07B5E", true),
                ("Lyra", "#AF52DE", false)
            ],
            messages: [
                MessageSeed(senderIndex: 1, text: "the baby dragon followed us into detention", minutesOffset: 0),
                MessageSeed(senderIndex: 0, text: "be honest did you feed it cursed glitter again", minutesOffset: 1),
                MessageSeed(senderIndex: 1, text: "only a little", minutesOffset: 4)
            ]
        ),
        ConversationSeed(
            title: "Portal Bus Stop",
            folderName: "Fictional Worlds",
            updatedHoursAgo: 6,
            isGroupChat: true,
            characters: [
                ("Me", "#E07B5E", true),
                ("Iris", "#FF9500", false),
                ("Noel", "#AF52DE", false),
                ("Pax", "#00C7BE", false)
            ],
            messages: [
                MessageSeed(senderIndex: 1, text: "the bus stop opened a portal again", minutesOffset: 0),
                MessageSeed(senderIndex: 2, text: "to where this time", minutesOffset: 1),
                MessageSeed(senderIndex: 3, text: "somewhere windy with three suns", minutesOffset: 3),
                MessageSeed(senderIndex: 0, text: "nobody get on the wrong bus until i arrive", minutesOffset: 5)
            ]
        ),
        ConversationSeed(
            title: "The Missing Map",
            folderName: "Plot Twists",
            updatedHoursAgo: 11,
            isGroupChat: false,
            characters: [
                ("Me", "#E07B5E", true),
                ("Rook", "#8E8E93", false)
            ],
            messages: [
                MessageSeed(senderIndex: 1, text: "i found the map", minutesOffset: 0),
                MessageSeed(senderIndex: 0, text: "the one that leads to the storm vault", minutesOffset: 2),
                MessageSeed(senderIndex: 1, text: "yes and unfortunately it was in your backpack", minutesOffset: 4),
                MessageSeed(senderIndex: 0, text: "that means the thief wanted us blamed", minutesOffset: 6),
                MessageSeed(senderIndex: 1, text: "or recruited", minutesOffset: 9),
                MessageSeed(senderIndex: 0, text: "you always pick the more dangerous option", minutesOffset: 12),
                MessageSeed(senderIndex: 1, text: "because its usually more fun", minutesOffset: 15),
                MessageSeed(senderIndex: 0, text: "meet me at the lighthouse in twenty", minutesOffset: 18)
            ]
        ),
        ConversationSeed(
            title: "Skyship Crew",
            folderName: "Ensemble Casts",
            updatedHoursAgo: 18,
            isGroupChat: true,
            characters: [
                ("Me", "#E07B5E", true),
                ("Captain Sol", "#FF2D55", false),
                ("Miri", "#5856D6", false),
                ("Tess", "#34C759", false)
            ],
            messages: [
                MessageSeed(senderIndex: 1, text: "who untied the cloud whales", minutesOffset: 0),
                MessageSeed(senderIndex: 2, text: "define untied", minutesOffset: 1),
                MessageSeed(senderIndex: 3, text: "they are drifting toward the royal parade", minutesOffset: 3)
            ]
        ),
        ConversationSeed(
            title: "Goblin Cafe Shift",
            folderName: nil,
            updatedHoursAgo: 24,
            isGroupChat: false,
            characters: [
                ("Me", "#E07B5E", true),
                ("Marnie", "#FF3B30", false)
            ],
            messages: [
                MessageSeed(senderIndex: 1, text: "the goblins tipped in shiny buttons again", minutesOffset: 0),
                MessageSeed(senderIndex: 0, text: "are any of them legal currency this time", minutesOffset: 2),
                MessageSeed(senderIndex: 1, text: "one of them sings when you shake it", minutesOffset: 4)
            ]
        ),
        ConversationSeed(
            title: "Time Travel Field Trip",
            folderName: "Ensemble Casts",
            updatedHoursAgo: 30,
            isGroupChat: true,
            characters: [
                ("Me", "#E07B5E", true),
                ("Ari", "#34C759", false),
                ("Bea", "#FF9500", false),
                ("Kevin", "#007AFF", false)
            ],
            messages: [
                MessageSeed(senderIndex: 1, text: "we accidentally lost kevin in 1986", minutesOffset: 0),
                MessageSeed(senderIndex: 2, text: "you said the timeline was stable", minutesOffset: 1),
                MessageSeed(senderIndex: 3, text: "i said i was emotionally stable", minutesOffset: 4),
                MessageSeed(senderIndex: 0, text: "please tell me he has the return watch", minutesOffset: 6),
                MessageSeed(senderIndex: 1, text: "he traded it for a denim jacket", minutesOffset: 8),
                MessageSeed(senderIndex: 2, text: "that is the most kevin sentence ever", minutesOffset: 10),
                MessageSeed(senderIndex: 3, text: "for the record i look incredible in this decade", minutesOffset: 13),
                MessageSeed(senderIndex: 0, text: "focus. where did the portal drop you", minutesOffset: 16),
                MessageSeed(senderIndex: 1, text: "outside a video rental store", minutesOffset: 19),
                MessageSeed(senderIndex: 2, text: "of course", minutesOffset: 20),
                MessageSeed(senderIndex: 3, text: "update i joined a breakdance circle for cover", minutesOffset: 23),
                MessageSeed(senderIndex: 0, text: "do not alter history through dance", minutesOffset: 26),
                MessageSeed(senderIndex: 1, text: "too late hes winning", minutesOffset: 29),
                MessageSeed(senderIndex: 2, text: "bring him back before he becomes a local legend", minutesOffset: 32),
                MessageSeed(senderIndex: 3, text: "if i disappear from the present tell my future self im iconic", minutesOffset: 35),
                MessageSeed(senderIndex: 0, text: "opening a return portal now", minutesOffset: 38),
                MessageSeed(senderIndex: 1, text: "hurry the mayor wants a photo", minutesOffset: 41)
            ]
        ),
        ConversationSeed(
            title: "Alien Roommate Rules",
            folderName: "Plot Twists",
            updatedHoursAgo: 40,
            isGroupChat: false,
            characters: [
                ("Me", "#E07B5E", true),
                ("Mira", "#AF52DE", false)
            ],
            messages: [
                MessageSeed(senderIndex: 1, text: "new rule your alien roommate cannot hatch eggs in the sink", minutesOffset: 0),
                MessageSeed(senderIndex: 0, text: "that feels weirdly targeted", minutesOffset: 2),
                MessageSeed(senderIndex: 1, text: "because it is", minutesOffset: 5)
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
            title: "Wizard Exam Night",
            folderName: "Fictional Worlds",
            updatedHoursAgo: 70,
            isGroupChat: false,
            characters: [
                ("Me", "#E07B5E", true),
                ("Ava", "#FF2D55", false)
            ],
            messages: [
                MessageSeed(senderIndex: 1, text: "did you turn your exam scroll invisible again", minutesOffset: 0),
                MessageSeed(senderIndex: 0, text: "no comment from the broom closet", minutesOffset: 2),
                MessageSeed(senderIndex: 1, text: "thats a yes", minutesOffset: 4)
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
