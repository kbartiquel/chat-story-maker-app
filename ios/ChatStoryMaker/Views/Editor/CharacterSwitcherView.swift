//
//  CharacterSwitcherView.swift
//  Textory
//
//  Character switcher buttons with add participant support for group chats
//

import SwiftUI

struct CharacterSwitcherView: View {
    let characters: [Character]
    @Binding var selectedCharacter: Character?
    var isGroupChat: Bool = false
    var onEditCharacter: ((Character) -> Void)? = nil
    var onAddCharacter: (() -> Void)? = nil

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(characters) { character in
                    CharacterButton(
                        character: character,
                        isSelected: selectedCharacter?.id == character.id,
                        onTap: { selectedCharacter = character },
                        onLongPress: onEditCharacter != nil ? { onEditCharacter?(character) } : nil
                    )
                }

                // Add participant button for group chats
                if isGroupChat, let onAdd = onAddCharacter {
                    AddCharacterButton(onTap: onAdd)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
        .background(Color(.systemBackground))
    }
}

struct AddCharacterButton: View {
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 6) {
                ZStack {
                    Circle()
                        .fill(Color(.systemGray5))
                        .frame(width: 28, height: 28)

                    Image(systemName: "plus")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.gray)
                }

                Text("Add")
                    .font(.subheadline)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(.systemGray6))
            .foregroundColor(.secondary)
            .cornerRadius(20)
        }
    }
}

struct CharacterButton: View {
    let character: Character
    let isSelected: Bool
    let onTap: () -> Void
    var onLongPress: (() -> Void)? = nil

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 6) {
                ZStack {
                    Circle()
                        .fill(character.color)
                        .frame(width: 28, height: 28)

                    if let imageData = character.avatarImageData, let uiImage = UIImage(data: imageData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 28, height: 28)
                            .clipShape(Circle())
                    } else if let emoji = character.avatarEmoji, !emoji.isEmpty {
                        Text(emoji)
                            .font(.system(size: 14))
                    } else {
                        Image(systemName: "person.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.8))
                    }
                }

                Text(character.name)
                    .font(.subheadline)
                    .fontWeight(isSelected ? .semibold : .regular)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isSelected ? character.color.opacity(0.2) : Color(.systemGray6))
            .foregroundColor(isSelected ? character.color : .primary)
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(isSelected ? character.color : Color.clear, lineWidth: 2)
            )
        }
        .contextMenu {
            if let onLongPress = onLongPress {
                Button(action: onLongPress) {
                    Label("Edit Character", systemImage: "pencil")
                }
            }
        }
    }
}

#Preview("1-on-1 Chat") {
    CharacterSwitcherView(
        characters: [
            Character(name: "Me", colorHex: "#007AFF", isMe: true),
            Character(name: "Alex", colorHex: "#34C759", isMe: false)
        ],
        selectedCharacter: .constant(nil),
        isGroupChat: false
    )
}

#Preview("Group Chat") {
    CharacterSwitcherView(
        characters: [
            Character(name: "Me", colorHex: "#007AFF", isMe: true),
            Character(name: "Mom", colorHex: "#FF3B30", isMe: false),
            Character(name: "Dad", colorHex: "#34C759", isMe: false)
        ],
        selectedCharacter: .constant(nil),
        isGroupChat: true,
        onAddCharacter: {}
    )
}
