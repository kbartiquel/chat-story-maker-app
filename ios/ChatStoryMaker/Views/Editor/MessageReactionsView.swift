//
//  MessageReactionsView.swift
//  ChatStoryMaker
//
//  iMessage-style reaction pills that overlap message bubble corners
//

import SwiftUI

struct MessageReactionsView: View {
    let reactions: [Reaction]
    let isMe: Bool

    private var groupedReactions: [(emoji: String, count: Int)] {
        var counts: [String: Int] = [:]
        for reaction in reactions {
            counts[reaction.emoji, default: 0] += 1
        }
        return counts.map { (emoji: $0.key, count: $0.value) }
            .sorted { $0.count > $1.count }
    }

    var body: some View {
        HStack(spacing: 2) {
            ForEach(groupedReactions, id: \.emoji) { item in
                HStack(spacing: 1) {
                    Text(item.emoji)
                        .font(.system(size: 14))
                    if item.count > 1 {
                        Text("\(item.count)")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.primary)
                    }
                }
                .padding(.horizontal, 5)
                .padding(.vertical, 2)
                .background(
                    Capsule()
                        .fill(Color(.systemBackground))
                        .shadow(color: .black.opacity(0.15), radius: 2, x: 0, y: 1)
                )
                .overlay(
                    Capsule()
                        .stroke(Color(.systemGray4), lineWidth: 0.5)
                )
            }
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        MessageReactionsView(
            reactions: [
                Reaction(emoji: "❤️", characterID: UUID()),
                Reaction(emoji: "❤️", characterID: UUID()),
                Reaction(emoji: "😂", characterID: UUID())
            ],
            isMe: true
        )

        MessageReactionsView(
            reactions: [
                Reaction(emoji: "👍", characterID: UUID())
            ],
            isMe: false
        )
    }
    .padding()
}
