//
//  CardView.swift
//  ChatStoryMaker
//
//  White background card with rounded corners and shadow
//

import SwiftUI

struct CardView<Content: View>: View {
    var padding: CGFloat = 16
    var cornerRadius: CGFloat = 12
    var shadowRadius: CGFloat = 4
    @ViewBuilder let content: () -> Content

    var body: some View {
        content()
            .padding(padding)
            .background(Color(.systemBackground))
            .cornerRadius(cornerRadius)
            .shadow(color: Color.black.opacity(0.1), radius: shadowRadius, x: 0, y: 2)
    }
}

#Preview {
    VStack(spacing: 16) {
        CardView {
            VStack(alignment: .leading, spacing: 8) {
                Text("Card Title")
                    .font(.headline)
                Text("This is some content inside the card.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }

        CardView(padding: 20, cornerRadius: 16) {
            HStack {
                Image(systemName: "star.fill")
                    .foregroundColor(.yellow)
                Text("Premium Feature")
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
            }
        }
    }
    .padding()
    .background(Color(.systemGray6))
}
