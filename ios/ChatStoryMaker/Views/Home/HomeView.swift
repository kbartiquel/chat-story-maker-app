//
//  HomeView.swift
//  ChatStoryMaker
//
//  Main view displaying list of saved conversations
//

import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = ConversationViewModel()
    @State private var movingConversation: Conversation?

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.conversations.isEmpty && viewModel.searchQuery.isEmpty {
                    EmptyStateView(onCreateTapped: {
                        viewModel.showingNewConversation = true
                    })
                } else {
                    conversationList
                }
            }
            .navigationTitle("Chat Stories")
            .searchable(text: $viewModel.searchQuery, prompt: "Search conversations")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        viewModel.showingFolderManagement = true
                    }) {
                        Image(systemName: "folder")
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        viewModel.showingNewConversation = true
                    }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $viewModel.showingNewConversation) {
                NewConversationView(viewModel: viewModel)
            }
            .sheet(isPresented: $viewModel.showingFolderManagement) {
                FolderManagementView(viewModel: viewModel)
            }
            .sheet(item: $movingConversation) { conversation in
                MoveToFolderView(
                    conversation: conversation,
                    folders: viewModel.folders,
                    onMove: { folder in
                        viewModel.moveConversation(conversation, to: folder)
                    }
                )
            }
        }
        .onAppear {
            viewModel.setModelContext(modelContext)
        }
    }

    private var conversationList: some View {
        List {
            // Folder sections
            if viewModel.searchQuery.isEmpty && !viewModel.folders.isEmpty {
                ForEach(viewModel.folders) { folder in
                    Section {
                        let folderConversations = viewModel.conversationsInFolder(folder)
                        if folderConversations.isEmpty {
                            Text("No conversations")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        } else {
                            ForEach(folderConversations) { conversation in
                                conversationRow(conversation)
                            }
                        }
                    } header: {
                        HStack(spacing: 6) {
                            Circle()
                                .fill(folder.color)
                                .frame(width: 10, height: 10)
                            Text(folder.name)
                        }
                    }
                }

                // Unfoldered conversations
                if !viewModel.unfolderedConversations.isEmpty {
                    Section("Other") {
                        ForEach(viewModel.unfolderedConversations) { conversation in
                            conversationRow(conversation)
                        }
                    }
                }
            } else {
                // Search results or no folders - flat list
                ForEach(viewModel.filteredConversations) { conversation in
                    conversationRow(conversation)
                }
                .onDelete(perform: viewModel.deleteConversations)
            }
        }
        .listStyle(.insetGrouped)
    }

    @ViewBuilder
    private func conversationRow(_ conversation: Conversation) -> some View {
        NavigationLink(destination: ChatEditorView(conversation: conversation)) {
            ConversationRowView(conversation: conversation)
        }
        .swipeActions(edge: .trailing) {
            Button(role: .destructive) {
                viewModel.deleteConversation(conversation)
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
        .swipeActions(edge: .leading) {
            Button {
                viewModel.duplicateConversation(conversation)
            } label: {
                Label("Duplicate", systemImage: "doc.on.doc")
            }
            .tint(.blue)

            Button {
                movingConversation = conversation
            } label: {
                Label("Move", systemImage: "folder")
            }
            .tint(.orange)
        }
        .contextMenu {
            Button {
                viewModel.duplicateConversation(conversation)
            } label: {
                Label("Duplicate", systemImage: "doc.on.doc")
            }

            Button {
                movingConversation = conversation
            } label: {
                Label("Move to Folder", systemImage: "folder")
            }

            Button(role: .destructive) {
                viewModel.deleteConversation(conversation)
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }
}

// MARK: - Move to Folder View

struct MoveToFolderView: View {
    @Environment(\.dismiss) private var dismiss
    let conversation: Conversation
    let folders: [Folder]
    let onMove: (Folder?) -> Void

    var body: some View {
        NavigationStack {
            List {
                Button(action: {
                    onMove(nil)
                    dismiss()
                }) {
                    HStack {
                        Image(systemName: "tray")
                            .foregroundColor(.gray)
                        Text("No Folder")
                        Spacer()
                        if conversation.folderID == nil {
                            Image(systemName: "checkmark")
                                .foregroundColor(.blue)
                        }
                    }
                }

                ForEach(folders) { folder in
                    Button(action: {
                        onMove(folder)
                        dismiss()
                    }) {
                        HStack {
                            Circle()
                                .fill(folder.color)
                                .frame(width: 16, height: 16)
                            Text(folder.name)
                            Spacer()
                            if conversation.folderID == folder.id {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Move to Folder")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    HomeView()
        .modelContainer(for: [Conversation.self, Character.self, Message.self, Folder.self], inMemory: true)
}
