//
//  Theme.swift
//  Textery
//
//  iMessage theme definition
//

import SwiftUI

enum ChatTheme: String, CaseIterable {
    case imessage

    var displayName: String {
        return "Classic"
    }

    var senderBubbleColor: Color {
        Color(hex: "#E07B5E")
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
