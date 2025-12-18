//
//  Conversation.swift
//  ChatStoryMaker
//
//  Conversation model containing characters and messages
//

import SwiftData
import Foundation

@Model
class Conversation {
    var id: UUID
    var title: String
    var createdAt: Date
    var updatedAt: Date
    var themeRawValue: String

    // Folder organization
    var folderID: UUID?

    // Group chat support
    var isGroupChat: Bool = false

    // Receipt style preference
    var receiptStyleRawValue: String

    var receiptStyle: ReceiptStyle {
        get { ReceiptStyle(rawValue: receiptStyleRawValue) ?? .imessage }
        set { receiptStyleRawValue = newValue.rawValue }
    }

    @Relationship(deleteRule: .cascade)
    var characters: [Character]

    @Relationship(deleteRule: .cascade)
    var messages: [Message]

    init(title: String, theme: ChatTheme = .imessage, isGroupChat: Bool = false) {
        self.id = UUID()
        self.title = title
        self.createdAt = Date()
        self.updatedAt = Date()
        self.themeRawValue = theme.rawValue
        self.folderID = nil
        self.isGroupChat = isGroupChat
        self.receiptStyleRawValue = ReceiptStyle.imessage.rawValue
        self.characters = isGroupChat
            ? [Character.defaultSender]
            : [Character.defaultSender, Character.defaultReceiver]
        self.messages = []
    }

    var theme: ChatTheme {
        ChatTheme(rawValue: themeRawValue) ?? .imessage
    }

    var sortedMessages: [Message] {
        messages.sorted { $0.order < $1.order }
    }
}
