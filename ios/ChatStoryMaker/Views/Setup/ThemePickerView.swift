//
//  ThemePickerView.swift
//  Textory
//
//  Horizontal theme picker
//

import SwiftUI

struct ThemePickerView: View {
    @Binding var selectedTheme: ChatTheme

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Theme")
                .font(.headline)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(ChatTheme.allCases, id: \.self) { theme in
                        ThemeOptionButton(
                            theme: theme,
                            isSelected: selectedTheme == theme,
                            onTap: { selectedTheme = theme }
                        )
                    }
                }
                .padding(.horizontal, 1)
            }
        }
    }
}

struct ThemeOptionButton: View {
    let theme: ChatTheme
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: {
            onTap()
            HapticManager.selection()
        }) {
            VStack(spacing: 8) {
                // Theme preview
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(theme.backgroundColor)
                        .frame(width: 80, height: 60)

                    VStack(spacing: 4) {
                        // Receiver bubble
                        HStack {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(theme.receiverBubbleColor)
                                .frame(width: 40, height: 12)
                            Spacer()
                        }
                        .padding(.horizontal, 6)

                        // Sender bubble
                        HStack {
                            Spacer()
                            RoundedRectangle(cornerRadius: 8)
                                .fill(theme.senderBubbleColor)
                                .frame(width: 40, height: 12)
                        }
                        .padding(.horizontal, 6)
                    }
                }
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isSelected ? Color.accentColor : Color.gray.opacity(0.3), lineWidth: isSelected ? 2 : 1)
                )

                Text(theme.displayName)
                    .font(.caption)
                    .fontWeight(isSelected ? .semibold : .regular)
                    .foregroundColor(isSelected ? .accentColor : .primary)
            }
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    ThemePickerView(selectedTheme: .constant(.imessage))
        .padding()
}
