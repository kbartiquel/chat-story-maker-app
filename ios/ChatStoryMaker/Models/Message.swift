//
//  Message.swift
//  ChatStoryMaker
//
//  Message model for chat messages
//

import SwiftData
import Foundation

@Model
class Message {
    var id: UUID
    var text: String
    var characterID: UUID
    var timestamp: Date
    var order: Int

    // Message type (text or image)
    var typeRawValue: String

    var type: MessageType {
        get { MessageType(rawValue: typeRawValue) ?? .text }
        set { typeRawValue = newValue.rawValue }
    }

    // Image data for image messages
    @Attribute(.externalStorage) var imageData: Data?

    // Reactions stored as JSON
    var reactionsData: Data?

    var reactions: [Reaction] {
        get {
            guard let data = reactionsData else { return [] }
            return (try? JSONDecoder().decode([Reaction].self, from: data)) ?? []
        }
        set {
            reactionsData = try? JSONEncoder().encode(newValue)
        }
    }

    // Delivery status
    var statusRawValue: String

    var status: DeliveryStatus {
        get { DeliveryStatus(rawValue: statusRawValue) ?? .none }
        set { statusRawValue = newValue.rawValue }
    }

    // Timestamp display
    var showTimestamp: Bool
    var displayTime: Date?

    var effectiveDisplayTime: Date {
        displayTime ?? timestamp
    }

    init(text: String, characterID: UUID, order: Int, type: MessageType = .text, imageData: Data? = nil) {
        self.id = UUID()
        self.text = text
        self.characterID = characterID
        self.timestamp = Date()
        self.order = order
        self.typeRawValue = type.rawValue
        self.imageData = imageData
        self.reactionsData = nil
        self.statusRawValue = DeliveryStatus.none.rawValue
        self.showTimestamp = false
        self.displayTime = nil
    }

    // Convenience initializer for image messages
    convenience init(imageData: Data, characterID: UUID, order: Int) {
        self.init(text: "", characterID: characterID, order: order, type: .image, imageData: imageData)
    }

    func addReaction(_ emoji: String, from characterID: UUID) {
        var current = reactions
        // Remove existing reaction from same character
        current.removeAll { $0.characterID == characterID }
        current.append(Reaction(emoji: emoji, characterID: characterID))
        reactions = current
    }

    func removeReaction(from characterID: UUID) {
        var current = reactions
        current.removeAll { $0.characterID == characterID }
        reactions = current
    }

    func hasReaction(from characterID: UUID) -> Bool {
        reactions.contains { $0.characterID == characterID }
    }
}
