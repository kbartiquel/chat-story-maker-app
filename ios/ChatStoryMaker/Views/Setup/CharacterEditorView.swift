//
//  CharacterEditorView.swift
//  Textory
//
//  Edit character name, color, and side
//

import SwiftUI
import PhotosUI

struct CharacterEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var character: Character
    var onSave: (() -> Void)?

    @State private var name: String = ""
    @State private var selectedColorHex: String = "#1DB678"
    @State private var isMe: Bool = true
    @State private var selectedEmoji: String = ""
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var avatarImageData: Data?

    private let avatarEmojis: [String] = [
        "😀", "😎", "🥰", "😈", "🤖", "👻", "💀", "🎃",
        "🦊", "🐱", "🐶", "🦁", "🐸", "🐵", "🦄", "🐼",
        "👤", "👩", "👨", "👧", "👦", "🧑", "👴", "👵"
    ]

    private let presetColors: [String] = [
        "#1DB678", // Textory Green
        "#007AFF", // Blue
        "#FF3B30", // Red
        "#FF9500", // Orange
        "#AF52DE", // Purple
        "#5856D6", // Indigo
        "#FF2D55", // Pink
        "#00C7BE", // Teal
        "#FFD60A", // Yellow
        "#8E8E93"  // Gray
    ]

    var body: some View {
        NavigationStack {
            Form {
                Section("Name") {
                    TextField("Character name", text: $name)
                }

                Section("Avatar") {
                    VStack(spacing: 16) {
                        // Current avatar preview
                        HStack {
                            Spacer()
                            currentAvatarPreview
                                .frame(width: 80, height: 80)
                            Spacer()
                        }

                        // Photo picker
                        PhotosPicker(selection: $selectedPhoto, matching: .images) {
                            Label("Choose Photo", systemImage: "photo.on.rectangle")
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(Color.accentColor.opacity(0.1))
                                .foregroundColor(.accentColor)
                                .cornerRadius(8)
                        }
                        .onChange(of: selectedPhoto) { _, newValue in
                            Task {
                                if let data = try? await newValue?.loadTransferable(type: Data.self) {
                                    avatarImageData = data
                                    selectedEmoji = ""
                                    HapticManager.selection()
                                }
                            }
                        }

                        // Clear photo button (if photo is set)
                        if avatarImageData != nil {
                            Button(role: .destructive) {
                                avatarImageData = nil
                                selectedPhoto = nil
                                HapticManager.selection()
                            } label: {
                                Label("Remove Photo", systemImage: "trash")
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                                    .background(Color.red.opacity(0.1))
                                    .cornerRadius(8)
                            }
                        }

                        // Emoji options
                        Text("Or choose an emoji:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 8), spacing: 10) {
                            // No avatar option
                            Circle()
                                .fill(Color(.systemGray5))
                                .frame(width: 40, height: 40)
                                .overlay(
                                    Image(systemName: "person.fill")
                                        .foregroundColor(.gray)
                                )
                                .overlay(
                                    Circle()
                                        .stroke(Color.primary, lineWidth: (selectedEmoji.isEmpty && avatarImageData == nil) ? 3 : 0)
                                )
                                .onTapGesture {
                                    selectedEmoji = ""
                                    avatarImageData = nil
                                    selectedPhoto = nil
                                    HapticManager.selection()
                                }

                            ForEach(avatarEmojis, id: \.self) { emoji in
                                Text(emoji)
                                    .font(.system(size: 28))
                                    .frame(width: 40, height: 40)
                                    .background(
                                        Circle()
                                            .fill(selectedEmoji == emoji ? Color.accentColor.opacity(0.2) : Color.clear)
                                    )
                                    .overlay(
                                        Circle()
                                            .stroke(Color.primary, lineWidth: selectedEmoji == emoji ? 2 : 0)
                                    )
                                    .onTapGesture {
                                        selectedEmoji = emoji
                                        avatarImageData = nil
                                        selectedPhoto = nil
                                        HapticManager.selection()
                                    }
                            }
                        }
                    }
                    .padding(.vertical, 8)
                }

                Section("Color") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 12) {
                        ForEach(presetColors, id: \.self) { colorHex in
                            Circle()
                                .fill(Color(hex: colorHex))
                                .frame(width: 44, height: 44)
                                .overlay(
                                    Circle()
                                        .stroke(Color.primary, lineWidth: selectedColorHex == colorHex ? 3 : 0)
                                )
                                .onTapGesture {
                                    selectedColorHex = colorHex
                                    HapticManager.selection()
                                }
                        }
                    }
                    .padding(.vertical, 8)
                }

                Section("Position") {
                    Picker("Side", selection: $isMe) {
                        Text("Right (Sender)").tag(true)
                        Text("Left (Receiver)").tag(false)
                    }
                    .pickerStyle(.segmented)
                }

                Section("Preview") {
                    HStack(spacing: 12) {
                        currentAvatarPreview
                            .frame(width: 44, height: 44)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(name.isEmpty ? "Character" : name)
                                .font(.headline)
                            Text(isMe ? "Right side (Sender)" : "Left side (Receiver)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        Spacer()
                    }
                }
            }
            .navigationTitle("Edit Character")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveCharacter()
                    }
                    .disabled(name.trimmed.isEmpty)
                }
            }
            .onAppear {
                name = character.name
                selectedColorHex = character.colorHex
                isMe = character.isMe
                selectedEmoji = character.avatarEmoji ?? ""
                avatarImageData = character.avatarImageData
            }
        }
    }

    @ViewBuilder
    private var currentAvatarPreview: some View {
        ZStack {
            Circle()
                .fill(Color(hex: selectedColorHex))

            if let imageData = avatarImageData, let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .clipShape(Circle())
            } else if !selectedEmoji.isEmpty {
                Text(selectedEmoji)
                    .font(.system(size: 32))
            } else {
                Image(systemName: "person.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.white.opacity(0.8))
            }
        }
    }

    private func saveCharacter() {
        character.name = name.trimmed
        character.colorHex = selectedColorHex
        character.isMe = isMe
        character.avatarEmoji = selectedEmoji.isEmpty ? nil : selectedEmoji
        character.avatarImageData = avatarImageData
        onSave?()
        dismiss()
    }
}

#Preview {
    CharacterEditorView(character: Character(name: "Test", colorHex: "#007AFF", isMe: true))
}
