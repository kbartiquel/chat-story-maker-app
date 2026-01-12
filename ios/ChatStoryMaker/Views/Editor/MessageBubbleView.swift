//
//  MessageBubbleView.swift
//  Textory
//
//  Chat bubble component styled like iMessage
//

import SwiftUI

struct MessageBubbleView: View {
    let message: Message
    let character: Character?
    let theme: ChatTheme
    let receiptStyle: ReceiptStyle
    let isGroupChat: Bool
    var onEdit: (() -> Void)?
    var onDelete: (() -> Void)?
    var onReaction: (() -> Void)?
    var onTimestamp: (() -> Void)?
    var onStatus: (() -> Void)?

    init(
        message: Message,
        character: Character?,
        theme: ChatTheme,
        receiptStyle: ReceiptStyle = .imessage,
        isGroupChat: Bool = false,
        onEdit: (() -> Void)? = nil,
        onDelete: (() -> Void)? = nil,
        onReaction: (() -> Void)? = nil,
        onTimestamp: (() -> Void)? = nil,
        onStatus: (() -> Void)? = nil
    ) {
        self.message = message
        self.character = character
        self.theme = theme
        self.receiptStyle = receiptStyle
        self.isGroupChat = isGroupChat
        self.onEdit = onEdit
        self.onDelete = onDelete
        self.onReaction = onReaction
        self.onTimestamp = onTimestamp
        self.onStatus = onStatus
    }

    private var isMe: Bool {
        character?.isMe ?? true
    }

    // Show avatar only in group chats for non-sender messages
    private var showAvatar: Bool {
        isGroupChat && !isMe
    }

    // Show sender name only in group chats for non-sender messages
    private var showSenderName: Bool {
        isGroupChat && !isMe
    }

    var body: some View {
        VStack(spacing: 4) {
            // Timestamp (if enabled)
            if message.showTimestamp {
                TimestampView(date: message.effectiveDisplayTime)
            }

            HStack(alignment: .bottom, spacing: 8) {
                if isMe { Spacer(minLength: 60) }

                // Avatar for receiver (left side) - only in group chats
                if showAvatar {
                    avatarView
                }

                VStack(alignment: isMe ? .trailing : .leading, spacing: 2) {
                    // Sender name - only in group chats
                    if showSenderName, let name = character?.name {
                        Text(name)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 4)
                    }

                    // Message content with overlapping reactions (iMessage style)
                    ZStack(alignment: isMe ? .topLeading : .topTrailing) {
                        bubbleContent

                        // Reactions overlapping top corner
                        if !message.reactions.isEmpty {
                            MessageReactionsView(reactions: message.reactions, isMe: isMe)
                                .offset(
                                    x: isMe ? -8 : 8,
                                    y: -12
                                )
                        }
                    }
                    .contextMenu {
                            Button(action: { onReaction?() }) {
                                Label("Add Reaction", systemImage: "face.smiling")
                            }
                            if message.type == .text {
                                Button(action: { onEdit?() }) {
                                    Label("Edit", systemImage: "pencil")
                                }
                            }
                            Button(action: { onTimestamp?() }) {
                                Label(message.showTimestamp ? "Hide Time" : "Show Time", systemImage: "clock")
                            }
                            if isMe {
                                Button(action: { onStatus?() }) {
                                    Label("Delivery Status", systemImage: "checkmark.circle")
                                }
                            }
                            Button(role: .destructive, action: { onDelete?() }) {
                                Label("Delete", systemImage: "trash")
                            }
                        }

                    // Delivery status (only for sender)
                    if isMe && message.status != .none {
                        DeliveryStatusView(status: message.status, style: receiptStyle)
                    }
                }

                if !isMe { Spacer(minLength: 60) }
            }
        }
    }

    @ViewBuilder
    private var bubbleContent: some View {
        switch message.type {
        case .text:
            Text(message.text)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(bubbleColor)
                .foregroundColor(textColor)
                .clipShape(BubbleShape(isMe: isMe))

        case .image:
            if let imageData = message.imageData, let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: 220, maxHeight: 300)
                    .clipShape(RoundedRectangle(cornerRadius: 18))
            } else {
                // Placeholder for missing image
                RoundedRectangle(cornerRadius: 18)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 150, height: 150)
                    .overlay(
                        Image(systemName: "photo")
                            .font(.largeTitle)
                            .foregroundColor(.gray)
                    )
            }
        }
    }

    @ViewBuilder
    private var avatarView: some View {
        ZStack {
            Circle()
                .fill(character?.color ?? .gray)
                .frame(width: 32, height: 32)

            if let imageData = character?.avatarImageData, let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 32, height: 32)
                    .clipShape(Circle())
            } else if let emoji = character?.avatarEmoji, !emoji.isEmpty {
                Text(emoji)
                    .font(.system(size: 16))
            } else {
                Image(systemName: "person.fill")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.8))
            }
        }
    }

    private var bubbleColor: Color {
        isMe ? theme.senderBubbleColor : theme.receiverBubbleColor
    }

    private var textColor: Color {
        isMe ? theme.senderTextColor : theme.receiverTextColor
    }
}

struct BubbleShape: Shape {
    let isMe: Bool

    func path(in rect: CGRect) -> Path {
        let radius: CGFloat = 18
        let tailSize: CGFloat = 6

        var path = Path()

        if isMe {
            // Sender bubble (right side with tail on right)
            path.move(to: CGPoint(x: rect.minX + radius, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX - radius, y: rect.minY))
            path.addQuadCurve(
                to: CGPoint(x: rect.maxX, y: rect.minY + radius),
                control: CGPoint(x: rect.maxX, y: rect.minY)
            )
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - radius))
            path.addQuadCurve(
                to: CGPoint(x: rect.maxX - tailSize, y: rect.maxY),
                control: CGPoint(x: rect.maxX, y: rect.maxY)
            )
            path.addLine(to: CGPoint(x: rect.minX + radius, y: rect.maxY))
            path.addQuadCurve(
                to: CGPoint(x: rect.minX, y: rect.maxY - radius),
                control: CGPoint(x: rect.minX, y: rect.maxY)
            )
            path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + radius))
            path.addQuadCurve(
                to: CGPoint(x: rect.minX + radius, y: rect.minY),
                control: CGPoint(x: rect.minX, y: rect.minY)
            )
        } else {
            // Receiver bubble (left side with tail on left)
            path.move(to: CGPoint(x: rect.minX + radius, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX - radius, y: rect.minY))
            path.addQuadCurve(
                to: CGPoint(x: rect.maxX, y: rect.minY + radius),
                control: CGPoint(x: rect.maxX, y: rect.minY)
            )
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - radius))
            path.addQuadCurve(
                to: CGPoint(x: rect.maxX - radius, y: rect.maxY),
                control: CGPoint(x: rect.maxX, y: rect.maxY)
            )
            path.addLine(to: CGPoint(x: rect.minX + tailSize, y: rect.maxY))
            path.addQuadCurve(
                to: CGPoint(x: rect.minX, y: rect.maxY - radius),
                control: CGPoint(x: rect.minX, y: rect.maxY)
            )
            path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + radius))
            path.addQuadCurve(
                to: CGPoint(x: rect.minX + radius, y: rect.minY),
                control: CGPoint(x: rect.minX, y: rect.minY)
            )
        }

        path.closeSubpath()
        return path
    }
}

#Preview {
    VStack(spacing: 8) {
        MessageBubbleView(
            message: Message(text: "Hey! How are you?", characterID: UUID(), order: 0),
            character: Character(name: "Alex", colorHex: "#34C759", isMe: false),
            theme: .imessage,
            receiptStyle: .imessage
        )
        MessageBubbleView(
            message: Message(text: "I'm doing great, thanks!", characterID: UUID(), order: 1),
            character: Character(name: "Me", colorHex: "#007AFF", isMe: true),
            theme: .imessage,
            receiptStyle: .imessage
        )
    }
    .padding()
}
