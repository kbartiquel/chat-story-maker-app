//
//  Folder.swift
//  Textory
//
//  Folder model for organizing conversations
//

import SwiftUI
import SwiftData

@Model
class Folder {
    var id: UUID
    var name: String
    var colorHex: String
    var order: Int
    var createdAt: Date

    init(name: String, colorHex: String = "#007AFF", order: Int = 0) {
        self.id = UUID()
        self.name = name
        self.colorHex = colorHex
        self.order = order
        self.createdAt = Date()
    }

    var color: Color {
        Color(hex: colorHex)
    }

    static let presetColors: [String] = [
        "#007AFF", // Blue
        "#34C759", // Green
        "#FF3B30", // Red
        "#FF9500", // Orange
        "#AF52DE", // Purple
        "#5856D6", // Indigo
        "#FF2D55", // Pink
        "#00C7BE"  // Teal
    ]
}
