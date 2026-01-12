//
//  Character.swift
//  Textory
//
//  Character model for conversation participants
//

import SwiftUI
import SwiftData

@Model
class Character {
    var id: UUID
    var name: String
    var colorHex: String
    var isMe: Bool
    var avatarEmoji: String?
    @Attribute(.externalStorage) var avatarImageData: Data?

    init(name: String, colorHex: String, isMe: Bool, avatarEmoji: String? = nil, avatarImageData: Data? = nil) {
        self.id = UUID()
        self.name = name
        self.colorHex = colorHex
        self.isMe = isMe
        self.avatarEmoji = avatarEmoji
        self.avatarImageData = avatarImageData
    }

    var color: Color {
        Color(hex: colorHex)
    }

    var avatarImage: UIImage? {
        guard let data = avatarImageData else { return nil }
        return UIImage(data: data)
    }

    static let defaultSender = Character(name: "Me", colorHex: "#007AFF", isMe: true)
    static let defaultReceiver = Character(name: "Alex", colorHex: "#34C759", isMe: false)
}
