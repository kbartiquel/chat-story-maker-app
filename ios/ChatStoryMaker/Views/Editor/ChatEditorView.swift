//
//  ChatEditorView.swift
//  Textory
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

    init(conversation: Conversation) {
        self.conversation = conversation
        self._viewModel = State(initialValue: ChatEditorViewModel(conversation: conversation))
    }

    // Get the main contact (receiver) for 1-on-1 chats
    private var mainContact: Character? {
        viewModel.characters.first { !$0.isMe }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Custom iMessage-style navigation bar
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
        .sheet(isPresented: $viewModel.showingExport) {
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

    // MARK: - iMessage Navigation Bar

    private var iMessageNavBar: some View {
        ZStack {
            // Center: Avatar and Name
            VStack(spacing: 2) {
                if conversation.isGroupChat {
                    // Group chat: stacked avatars
                    groupAvatarStack
                } else {
                    // 1-on-1: single contact avatar
                    contactAvatar
                }

                HStack(spacing: 2) {
                    Text(conversation.isGroupChat ? conversation.title : (mainContact?.name ?? conversation.title))
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.secondary)
                }
            }
            .onTapGesture {
                // Could open contact/group details
            }

            // Left: Back button
            HStack {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.accentColor)
                }
                Spacer()
            }

            // Right: Actions
            HStack {
                Spacer()
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
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
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
                    Image(systemName: "person.fill")
                        .font(.system(size: 22))
                        .foregroundColor(.white.opacity(0.8))
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
                        Image(systemName: "person.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.8))
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
                    // iMessage label at top
                    VStack(spacing: 2) {
                        Text("iMessage")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 8)

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
