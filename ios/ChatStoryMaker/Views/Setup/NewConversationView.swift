//
//  NewConversationView.swift
//  ChatStoryMaker
//
//  View for creating a new conversation (1-on-1 or group chat)
//

import SwiftUI

struct NewConversationView: View {
    @Environment(\.dismiss) private var dismiss
    var viewModel: ConversationViewModel

    @State private var title = ""
    @State private var isGroupChat = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Story Title") {
                    TextField("Enter title", text: $title)
                }

                Section("Chat Type") {
                    Toggle(isOn: $isGroupChat) {
                        HStack {
                            Image(systemName: isGroupChat ? "person.3.fill" : "person.fill")
                                .foregroundColor(.blue)
                            Text(isGroupChat ? "Group Chat" : "1-on-1 Chat")
                        }
                    }
                }

                Section {
                    if isGroupChat {
                        Label {
                            Text("Avatars will appear next to messages from other participants")
                        } icon: {
                            Image(systemName: "info.circle")
                                .foregroundColor(.blue)
                        }
                        .font(.caption)
                    } else {
                        Label {
                            Text("Simple two-person conversation with contact info in header")
                        } icon: {
                            Image(systemName: "info.circle")
                                .foregroundColor(.blue)
                        }
                        .font(.caption)
                    }
                }
            }
            .navigationTitle("New Story")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Create") {
                        createConversation()
                    }
                    .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }

    private func createConversation() {
        let trimmedTitle = title.trimmingCharacters(in: .whitespaces)
        guard !trimmedTitle.isEmpty else { return }
        viewModel.createConversation(title: trimmedTitle, isGroupChat: isGroupChat)
        dismiss()
    }
}

#Preview {
    NewConversationView(viewModel: ConversationViewModel())
}
