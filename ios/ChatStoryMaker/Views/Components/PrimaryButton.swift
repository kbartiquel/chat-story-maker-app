//
//  PrimaryButton.swift
//  ChatStoryMaker
//
//  Full-width rounded button with loading state
//

import SwiftUI

struct PrimaryButton: View {
    let title: String
    var icon: String? = nil
    var color: Color = .blue
    var isLoading: Bool = false
    var isDisabled: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: {
            HapticManager.impact(.light)
            action()
        }) {
            HStack(spacing: 8) {
                if isLoading {
                    ProgressView()
                        .tint(.white)
                } else {
                    if let icon = icon {
                        Image(systemName: icon)
                    }
                    Text(title)
                }
            }
            .font(.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(isDisabled ? Color.gray : color)
            .cornerRadius(12)
        }
        .disabled(isDisabled || isLoading)
    }
}

#Preview {
    VStack(spacing: 16) {
        PrimaryButton(title: "Continue", icon: "arrow.right", action: {})
        PrimaryButton(title: "Loading...", isLoading: true, action: {})
        PrimaryButton(title: "Disabled", isDisabled: true, action: {})
        PrimaryButton(title: "Export", icon: "square.and.arrow.up", color: .purple, action: {})
    }
    .padding()
}
