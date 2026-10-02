//
//  MessageInputView.swift
//  Textery
//
//  Story writing panel — Wattpad/screenplay style input
//

import SwiftUI
import PhotosUI

struct MessageInputView: View {
    @Binding var text: String
    var selectedCharacter: Character?
    var onSend: () -> Void
    var onImageSelected: ((Data) -> Void)?

    @State private var selectedPhoto: PhotosPickerItem?
    private let coral = Color(red: 224/255, green: 123/255, blue: 94/255)

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {

            // "Writing as" header strip
            HStack(spacing: 8) {
                if let character = selectedCharacter {
                    Circle()
                        .fill(character.color)
                        .frame(width: 9, height: 9)
                    Text("Writing as \(character.name)")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.secondary)
                } else {
                    Text("Select a character below")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }

                Spacer()

                // Photo picker — subtle icon only
                PhotosPicker(selection: $selectedPhoto, matching: .images) {
                    Image(systemName: "photo")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                }
                .onChange(of: selectedPhoto) { _, newValue in
                    Task {
                        if let data = try? await newValue?.loadTransferable(type: Data.self) {
                            onImageSelected?(data)
                            selectedPhoto = nil
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 8)

            // Writing area — paper feel
            TextField("Write the next line…", text: $text, axis: .vertical)
                .textFieldStyle(.plain)
                .lineLimit(2...6)
                .font(.system(size: 15))
                .padding(.horizontal, 16)
                .padding(.bottom, 14)

            Divider()
                .padding(.horizontal, 0)

            // Bottom action row
            HStack(spacing: 0) {
                Spacer()

                Button(action: onSend) {
                    Text("Add Line")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(canSend ? .white : Color(UIColor.tertiaryLabel))
                        .padding(.horizontal, 22)
                        .padding(.vertical, 9)
                        .background(
                            Capsule()
                                .fill(canSend ? coral : Color(UIColor.systemGray5))
                        )
                }
                .disabled(!canSend)
                .padding(.trailing, 14)
                .padding(.vertical, 10)
            }
        }
        .background(Color(UIColor.systemBackground))
        .overlay(alignment: .top) { Divider() }
    }

    private var hasText: Bool {
        !text.trimmingCharacters(in: .whitespaces).isEmpty
    }

    private var canSend: Bool {
        hasText && selectedCharacter != nil
    }
}
