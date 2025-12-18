//
//  ConversationRowView.swift
//  ChatStoryMaker
//
//  List row component for displaying a conversation
//

import SwiftUI

struct ConversationRowView: View {
    let conversation: Conversation

    private var chatIcon: String {
        conversation.isGroupChat ? "person.3.fill" : "person.fill"
    }

    var body: some View {
        HStack(spacing: 12) {
            // Chat type icon
            Circle()
                .fill(conversation.theme.senderBubbleColor)
                .frame(width: 50, height: 50)
                .overlay(
                    Image(systemName: chatIcon)
                        .foregroundColor(.white)
                        .font(.system(size: conversation.isGroupChat ? 18 : 22))
                )

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(conversation.title)
                        .font(.headline)
                        .lineLimit(1)

                    if conversation.isGroupChat {
                        Text("Group")
                            .font(.caption2)
                            .fontWeight(.medium)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color(.systemGray5))
                            .cornerRadius(4)
                    }
                }

                HStack(spacing: 8) {
                    Label("\(conversation.messages.count)", systemImage: "message.fill")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    if conversation.isGroupChat {
                        Label("\(conversation.characters.count)", systemImage: "person.2.fill")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Text("•")
                        .foregroundColor(.secondary)

                    Text(conversation.updatedAt.timeAgo())
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 8)
    }
}

#Preview("1-on-1 Chat") {
    ConversationRowView(conversation: Conversation(title: "Sample Chat"))
        .padding()
}

#Preview("Group Chat") {
    ConversationRowView(conversation: Conversation(title: "Family Chat", isGroupChat: true))
        .padding()
}
