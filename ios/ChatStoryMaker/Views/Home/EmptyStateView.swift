//
//  EmptyStateView.swift
//  Textory
//
//  Empty state UI when no conversations exist
//

import SwiftUI

struct EmptyStateView: View {
    var onCreateTapped: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "bubble.left.and.bubble.right")
                .font(.system(size: 80))
                .foregroundColor(.gray.opacity(0.5))

            VStack(spacing: 8) {
                Text("No Stories Yet")
                    .font(.title2)
                    .fontWeight(.semibold)

                Text("Create your first chat story and\nexport it as a video")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }

            Button(action: onCreateTapped) {
                Label("Create Story", systemImage: "plus")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor)
                    .cornerRadius(12)
            }
            .padding(.horizontal, 40)

            Spacer()
        }
        .padding()
    }
}

#Preview {
    EmptyStateView(onCreateTapped: {})
}
