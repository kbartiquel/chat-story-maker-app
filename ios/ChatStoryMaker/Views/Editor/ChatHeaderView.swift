//
//  ChatHeaderView.swift
//  Textory
//
//  iMessage-style chat header with contact/group info
//

import SwiftUI

struct ChatHeaderView: View {
    let conversation: Conversation
    let characters: [Character]

    // Get the main contact (receiver) for 1-on-1 chats
    private var mainContact: Character? {
        characters.first { !$0.isMe }
    }

    // Get all participants except the sender for group chats
    private var participants: [Character] {
        characters.filter { !$0.isMe }
    }

    var body: some View {
        VStack(spacing: 4) {
            if conversation.isGroupChat {
                groupHeader
            } else {
                contactHeader
            }
        }
        .padding(.vertical, 8)
    }

    // MARK: - 1-on-1 Contact Header

    private var contactHeader: some View {
        VStack(spacing: 6) {
            // Contact avatar
            if let contact = mainContact {
                contactAvatar(contact, size: 60)
            }

            // Contact name
            Text(mainContact?.name ?? conversation.title)
                .font(.headline)
                .fontWeight(.semibold)
        }
    }

    // MARK: - Group Chat Header

    private var groupHeader: some View {
        VStack(spacing: 4) {
            // Stacked avatars for group
            HStack(spacing: -12) {
                ForEach(participants.prefix(4)) { participant in
                    contactAvatar(participant, size: 36)
                        .overlay(
                            Circle()
                                .stroke(Color(.systemBackground), lineWidth: 2)
                        )
                }
            }

            // Group name (if set and not default)
            let hasGroupName = !conversation.title.isEmpty &&
                conversation.title != "Chat" &&
                conversation.title != "Group Chat"

            if hasGroupName {
                // Group name (bold)
                HStack(spacing: 2) {
                    Text(conversation.title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.secondary)
                }

                // Member count (gray, smaller)
                Text("\(characters.count) People")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else {
                // No group name - just show people count as main text
                HStack(spacing: 2) {
                    Text("\(characters.count) People")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.secondary)
                }
            }
        }
    }

    // MARK: - Avatar View

    @ViewBuilder
    private func contactAvatar(_ character: Character, size: CGFloat) -> some View {
        ZStack {
            Circle()
                .fill(character.color)
                .frame(width: size, height: size)

            if let imageData = character.avatarImageData, let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: size, height: size)
                    .clipShape(Circle())
            } else if let emoji = character.avatarEmoji, !emoji.isEmpty {
                Text(emoji)
                    .font(.system(size: size * 0.5))
            } else {
                Image(systemName: "person.fill")
                    .font(.system(size: size * 0.4))
                    .foregroundColor(.white.opacity(0.8))
            }
        }
    }
}

#Preview {
    VStack(spacing: 40) {
        // 1-on-1 chat header
        ChatHeaderView(
            conversation: Conversation(title: "Alex"),
            characters: [
                Character(name: "Me", colorHex: "#007AFF", isMe: true),
                Character(name: "Alex", colorHex: "#34C759", isMe: false)
            ]
        )

        Divider()

        // Group chat header
        ChatHeaderView(
            conversation: Conversation(title: "Family Group", isGroupChat: true),
            characters: [
                Character(name: "Me", colorHex: "#007AFF", isMe: true),
                Character(name: "Mom", colorHex: "#FF3B30", isMe: false),
                Character(name: "Dad", colorHex: "#34C759", isMe: false),
                Character(name: "Sister", colorHex: "#FF9500", isMe: false)
            ]
        )
    }
    .padding()
}
