//
//  ChatEditorView.swift
//  Textery
//
//  Main chat editor for editing a conversation
//

import SwiftUI
import SwiftData

struct ChatEditorView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    let conversation: Conversation
    @State private var viewModel: ChatEditorViewModel
    @State private var editingMessage: Message?
    @State private var editText = ""
    @State private var editingCharacter: Character?
    @State private var isReorderMode = false
    @State private var reactionMessage: Message?
    @State private var timestampMessage: Message?
    @State private var statusMessage: Message?
    @State private var showTitleEditor = false
    @State private var editedTitle = ""

    init(conversation: Conversation) {
        self.conversation = conversation
        self._viewModel = State(initialValue: ChatEditorViewModel(conversation: conversation))
    }

    // Get the main contact (receiver) for 1-on-1 chats
    private var mainContact: Character? {
        viewModel.characters.first { !$0.isMe }
    }

    private let coral = Color(red: 224/255, green: 123/255, blue: 94/255)

    var body: some View {
        VStack(spacing: 0) {
            // Story Mode indicator
            storyModeBar

            // Custom navigation bar
            iMessageNavBar

            Divider()

            if isReorderMode {
                reorderList
            } else {
                messageList
            }

            Divider()

            // Character switcher
            CharacterSwitcherView(
                characters: viewModel.characters,
                selectedCharacter: $viewModel.selectedCharacter,
                isGroupChat: conversation.isGroupChat,
                onEditCharacter: { character in
                    editingCharacter = character
                },
                onAddCharacter: {
                    viewModel.addCharacter()
                }
            )

            Divider()

            // Message input
            MessageInputView(
                text: $viewModel.messageText,
                selectedCharacter: viewModel.selectedCharacter,
                onSend: viewModel.sendMessage,
                onImageSelected: { imageData in
                    viewModel.sendImageMessage(imageData: imageData)
                }
            )
        }
        .navigationBarHidden(true)
        .fullScreenCover(isPresented: $viewModel.showingExport) {
            ExportView(conversation: conversation)
        }
        .sheet(item: $editingCharacter) { character in
            CharacterEditorView(character: character)
        }
        .sheet(item: $timestampMessage) { message in
            TimestampEditorView(
                showTimestamp: Binding(
                    get: { message.showTimestamp },
                    set: { message.showTimestamp = $0; viewModel.setDisplayTime(for: message, time: message.displayTime) }
                ),
                displayTime: Binding(
                    get: { message.displayTime },
                    set: { viewModel.setDisplayTime(for: message, time: $0) }
                ),
                actualTime: message.timestamp
            )
        }
        .sheet(item: $statusMessage) { message in
            StatusPickerView(
                status: Binding(
                    get: { message.status },
                    set: { viewModel.setDeliveryStatus(for: message, status: $0) }
                ),
                receiptStyle: conversation.receiptStyle
            )
        }
        .alert("Edit Message", isPresented: Binding(
            get: { editingMessage != nil },
            set: { if !$0 { editingMessage = nil } }
        )) {
            TextField("Message", text: $editText)
            Button("Cancel", role: .cancel) {
                editingMessage = nil
            }
            Button("Save") {
                if let message = editingMessage {
                    viewModel.updateMessage(message, newText: editText)
                }
                editingMessage = nil
            }
        }
        .alert("Edit Name", isPresented: $showTitleEditor) {
            TextField("Name", text: $editedTitle)
            Button("Cancel", role: .cancel) {}
            Button("Save") {
                if !editedTitle.trimmingCharacters(in: .whitespaces).isEmpty {
                    conversation.title = editedTitle.trimmingCharacters(in: .whitespaces)
                }
            }
        }
        .overlay {
            ReactionPickerOverlay(isPresented: Binding(
                get: { reactionMessage != nil },
                set: { if !$0 { reactionMessage = nil } }
            )) { emoji in
                if let message = reactionMessage {
                    viewModel.addReaction(to: message, emoji: emoji)
                }
            }
        }
        .onAppear {
            viewModel.setModelContext(modelContext)
        }
    }

    // MARK: - Story Mode Bar

    private var storyModeBar: some View {
        HStack {
            HStack(spacing: 6) {
                Image(systemName: "book.fill")
                    .font(.system(size: 14))
                    .foregroundColor(coral)
                Text("Story Mode")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(coral)
            }

            Spacer()

            Text("Editing")
                .font(.system(size: 12))
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 4)
        .background(Color(.systemBackground))
        .overlay(alignment: .bottom) {
            Divider()
                .background(coral.opacity(0.3))
        }
    }

    // MARK: - Navigation Bar

    private var iMessageNavBar: some View {
        HStack {
            // Left: Back button
            Button(action: { dismiss() }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.accentColor)
            }

            Spacer()

            // Right: Actions
            HStack(spacing: 16) {
                Button(action: { isReorderMode.toggle() }) {
                    Image(systemName: isReorderMode ? "checkmark" : "arrow.up.arrow.down")
                        .font(.system(size: 18))
                        .foregroundColor(.accentColor)
                }
                Button(action: { viewModel.showingExport = true }) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 20))
                        .foregroundColor(.accentColor)
                }
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
    }

    // MARK: - Message List Header (Avatar + Name)

    private var messageListHeader: some View {
        Button {
            editedTitle = conversation.title
            showTitleEditor = true
        } label: {
            VStack(spacing: 4) {
                if conversation.isGroupChat {
                    groupAvatarStack
                } else {
                    contactAvatar
                }

                HStack(spacing: 2) {
                    Text(conversation.isGroupChat ? conversation.title : (mainContact?.name ?? conversation.title))
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.secondary)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
        }
    }

    @ViewBuilder
    private var contactAvatar: some View {
        if let contact = mainContact {
            ZStack {
                Circle()
                    .fill(contact.color)
                    .frame(width: 50, height: 50)

                if let imageData = contact.avatarImageData, let uiImage = UIImage(data: imageData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 50, height: 50)
                        .clipShape(Circle())
                } else if let emoji = contact.avatarEmoji, !emoji.isEmpty {
                    Text(emoji)
                        .font(.system(size: 24))
                } else {
                    Text(String(contact.name.prefix(1)).uppercased())
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundColor(.white)
                }
            }
        }
    }

    @ViewBuilder
    private var groupAvatarStack: some View {
        let participants = viewModel.characters.filter { !$0.isMe }
        HStack(spacing: -10) {
            ForEach(participants.prefix(3)) { participant in
                ZStack {
                    Circle()
                        .fill(participant.color)
                        .frame(width: 36, height: 36)

                    if let imageData = participant.avatarImageData, let uiImage = UIImage(data: imageData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 36, height: 36)
                            .clipShape(Circle())
                    } else if let emoji = participant.avatarEmoji, !emoji.isEmpty {
                        Text(emoji)
                            .font(.system(size: 16))
                    } else {
                        Text(String(participant.name.prefix(1)).uppercased())
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                    }
                }
                .overlay(Circle().stroke(Color(.systemBackground), lineWidth: 2))
            }
        }
    }

    // MARK: - Message List (Normal Mode)

    private var messageList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 8) {
                    // Avatar + Name header
                    messageListHeader

                    ForEach(viewModel.sortedMessages) { message in
                        MessageBubbleView(
                            message: message,
                            character: viewModel.getCharacter(for: message),
                            theme: conversation.theme,
                            receiptStyle: conversation.receiptStyle,
                            isGroupChat: conversation.isGroupChat,
                            onEdit: {
                                editingMessage = message
                                editText = message.text
                            },
                            onDelete: {
                                viewModel.deleteMessage(message)
                            },
                            onReaction: {
                                reactionMessage = message
                            },
                            onTimestamp: {
                                timestampMessage = message
                            },
                            onStatus: {
                                statusMessage = message
                            }
                        )
                        .id(message.id)
                    }
                }
                .padding()
            }
            .onChange(of: viewModel.sortedMessages.count) { _, _ in
                if let lastMessage = viewModel.sortedMessages.last {
                    withAnimation {
                        proxy.scrollTo(lastMessage.id, anchor: .bottom)
                    }
                }
            }
        }
        .background(conversation.theme.backgroundColor)
    }

    // MARK: - Reorder List (Edit Mode)

    private var reorderList: some View {
        List {
            ForEach(viewModel.sortedMessages) { message in
                HStack {
                    if let character = viewModel.getCharacter(for: message) {
                        Circle()
                            .fill(character.color)
                            .frame(width: 24, height: 24)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        if message.type == .image {
                            Label("Image", systemImage: "photo")
                                .font(.subheadline)
                        } else {
                            Text(message.text)
                                .font(.subheadline)
                                .lineLimit(2)
                        }

                        if let name = viewModel.getCharacter(for: message)?.name {
                            Text(name)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .onMove(perform: viewModel.moveMessage)
            .onDelete(perform: viewModel.deleteMessages)
        }
        .listStyle(.plain)
        .environment(\.editMode, .constant(.active))
    }
}

#Preview {
    NavigationStack {
        ChatEditorView(conversation: Conversation(title: "Test Chat"))
    }
    .modelContainer(for: [Conversation.self, Character.self, Message.self], inMemory: true)
}
