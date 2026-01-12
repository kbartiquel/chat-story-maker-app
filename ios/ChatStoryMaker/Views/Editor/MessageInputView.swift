//
//  MessageInputView.swift
//  Textory
//
//  iMessage-style input field with + button, text field, and send/mic button
//

import SwiftUI
import PhotosUI

struct MessageInputView: View {
    @Binding var text: String
    var selectedCharacter: Character?
    var onSend: () -> Void
    var onImageSelected: ((Data) -> Void)?

    @State private var selectedPhoto: PhotosPickerItem?

    var body: some View {
        HStack(spacing: 8) {
            // Plus button (opens photo picker)
            PhotosPicker(selection: $selectedPhoto, matching: .images) {
                ZStack {
                    Circle()
                        .fill(Color(.systemGray5))
                        .frame(width: 32, height: 32)
                    Image(systemName: "plus")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.gray)
                }
            }
            .disabled(selectedCharacter == nil)
            .onChange(of: selectedPhoto) { _, newValue in
                Task {
                    if let data = try? await newValue?.loadTransferable(type: Data.self) {
                        onImageSelected?(data)
                        selectedPhoto = nil
                    }
                }
            }

            // Text field with iMessage styling
            HStack(spacing: 8) {
                TextField("iMessage", text: $text, axis: .vertical)
                    .textFieldStyle(.plain)
                    .lineLimit(1...5)

                // Microphone or Send button
                if hasText {
                    Button(action: onSend) {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 28))
                            .foregroundColor(canSend ? .accentColor : .gray)
                    }
                    .disabled(!canSend)
                } else {
                    Image(systemName: "mic.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.gray)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(.systemGray6))
            .cornerRadius(20)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
    }

    private var hasText: Bool {
        !text.trimmingCharacters(in: .whitespaces).isEmpty
    }

    private var canSend: Bool {
        hasText && selectedCharacter != nil
    }
}

#Preview("Empty") {
    MessageInputView(
        text: .constant(""),
        selectedCharacter: Character(name: "Me", colorHex: "#007AFF", isMe: true),
        onSend: {},
        onImageSelected: { _ in }
    )
}

#Preview("With Text") {
    MessageInputView(
        text: .constant("Hello there!"),
        selectedCharacter: Character(name: "Me", colorHex: "#007AFF", isMe: true),
        onSend: {},
        onImageSelected: { _ in }
    )
}
