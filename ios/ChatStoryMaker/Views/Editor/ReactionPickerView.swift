//
//  ReactionPickerView.swift
//  Textory
//
//  iMessage-style floating reaction picker
//

import SwiftUI

struct ReactionPickerView: View {
    let onSelect: (String) -> Void
    let onDismiss: () -> Void

    private let reactions = Reaction.availableReactions

    var body: some View {
        HStack(spacing: 12) {
            ForEach(reactions, id: \.self) { emoji in
                Button(action: {
                    HapticManager.selection()
                    onSelect(emoji)
                }) {
                    Text(emoji)
                        .font(.system(size: 28))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(
            Capsule()
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
        )
    }
}

struct ReactionPickerOverlay: View {
    @Binding var isPresented: Bool
    let onSelect: (String) -> Void

    var body: some View {
        ZStack {
            if isPresented {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation(.easeOut(duration: 0.2)) {
                            isPresented = false
                        }
                    }

                ReactionPickerView(
                    onSelect: { emoji in
                        onSelect(emoji)
                        withAnimation(.easeOut(duration: 0.2)) {
                            isPresented = false
                        }
                    },
                    onDismiss: {
                        withAnimation(.easeOut(duration: 0.2)) {
                            isPresented = false
                        }
                    }
                )
                .transition(.scale.combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isPresented)
    }
}

#Preview {
    VStack {
        ReactionPickerView(
            onSelect: { print("Selected: \($0)") },
            onDismiss: {}
        )
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color.gray.opacity(0.2))
}
