//
//  MessageType.swift
//  ChatStoryMaker
//
//  Enums for message types, delivery status, reactions, and receipt styles
//

import Foundation

enum MessageType: String, Codable, CaseIterable {
    case text
    case image
}

enum DeliveryStatus: String, Codable, CaseIterable {
    case none
    case sending
    case sent
    case delivered
    case read
}

enum ReceiptStyle: String, Codable, CaseIterable {
    case whatsapp
    case imessage

    var displayName: String {
        switch self {
        case .whatsapp: return "WhatsApp"
        case .imessage: return "iMessage"
        }
    }
}

struct Reaction: Codable, Equatable, Identifiable {
    var id: UUID
    let emoji: String
    let characterID: UUID

    init(emoji: String, characterID: UUID) {
        self.id = UUID()
        self.emoji = emoji
        self.characterID = characterID
    }

    static let availableReactions = ["❤️", "👍", "👎", "😂", "‼️", "❓"]
}
