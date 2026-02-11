//
//  DisclaimerView.swift
//  Textery
//
//  First launch disclaimer about fictional content
//

import SwiftUI

struct DisclaimerView: View {
    @Binding var isPresented: Bool

    private let coral = Color(red: 224/255, green: 123/255, blue: 94/255)

    var body: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()

            VStack(spacing: 24) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.orange)

                Text("Important Notice")
                    .font(.title.bold())

                Text("Textery creates FICTIONAL text conversations for entertainment and creative storytelling purposes only.")
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("For creative storytelling")
                    }

                    HStack(spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("For entertainment videos")
                    }

                    HStack(spacing: 12) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.red)
                        Text("NOT for impersonation")
                    }

                    HStack(spacing: 12) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.red)
                        Text("NOT for deception")
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)

                Button(action: {
                    isPresented = false
                }) {
                    Text("I Understand")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            LinearGradient(
                                colors: [coral, coral.opacity(0.8)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(12)
                }
                .padding(.horizontal)
            }
            .padding(32)
            .background(Color(.systemBackground))
            .cornerRadius(24)
            .padding(32)
        }
    }
}

#Preview {
    DisclaimerView(isPresented: .constant(true))
}
