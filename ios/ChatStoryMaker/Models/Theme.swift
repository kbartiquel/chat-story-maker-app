//
//  Theme.swift
//  ChatStoryMaker
//
//  iMessage theme definition
//

import SwiftUI

enum ChatTheme: String, CaseIterable {
    case imessage

    var displayName: String {
        return "iMessage"
    }

    var senderBubbleColor: Color {
        Color(hex: "#007AFF")
    }

    var receiverBubbleColor: Color {
        Color(hex: "#E5E5EA")
    }

    var backgroundColor: Color {
        Color.white
    }

    var senderTextColor: Color {
        .white
    }

    var receiverTextColor: Color {
        .black
    }
}
