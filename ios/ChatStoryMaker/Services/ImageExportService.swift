//
//  ImageExportService.swift
//  Textory
//
//  Export conversation as screenshot image
//

import UIKit
import SwiftUI

class ImageExportService {

    struct ExportConfig {
        let messages: [Message]
        let characters: [Character]
        let theme: ChatTheme
        let settings: ExportSettings
        let conversationTitle: String
        let isGroupChat: Bool
        let getCharacter: (UUID) -> Character?

        var mainContact: Character? {
            characters.first { !$0.isMe }
        }
    }

    func exportImage(config: ExportConfig) -> UIImage {
        let scale = config.settings.imageQuality.scale
        let width: CGFloat = 1080 / scale
        let padding: CGFloat = 16
        let maxBubbleWidth = width * 0.75

        // Calculate total height needed
        let headerHeight: CGFloat = 120 // Header bar
        var totalHeight: CGFloat = headerHeight + 40 // Header + iMessage label

        for message in config.messages {
            let character = config.getCharacter(message.characterID)
            let isMe = character?.isMe ?? true

            // Timestamp height
            if config.settings.showTimestamps && message.showTimestamp {
                totalHeight += 30
            }

            // Reactions height
            if config.settings.showReactions && !message.reactions.isEmpty {
                totalHeight += 26
            }

            // Character name height (for non-sender)
            if !isMe {
                totalHeight += 20
            }

            // Bubble height
            if message.type == .image {
                totalHeight += 220
            } else {
                let bubbleHeight = calculateBubbleHeight(text: message.text, maxWidth: maxBubbleWidth - 32)
                totalHeight += bubbleHeight
            }

            totalHeight += 12 // Message spacing
        }

        totalHeight += 60 // Bottom padding

        let size = CGSize(width: width, height: totalHeight)
        let renderer = UIGraphicsImageRenderer(size: size)

        let image = renderer.image { context in
            // Background
            let bgColor = config.settings.darkMode ? UIColor.black : UIColor(config.theme.backgroundColor)
            bgColor.setFill()
            context.fill(CGRect(origin: .zero, size: size))

            // Draw header bar
            let headerHeight = drawHeaderBar(
                config: config,
                context: context.cgContext,
                canvasWidth: width,
                darkMode: config.settings.darkMode
            )

            // Draw "iMessage" label
            var yOffset = headerHeight + 16
            drawCenteredText(
                "iMessage",
                at: yOffset,
                fontSize: 12,
                color: UIColor.systemGray,
                canvasWidth: width
            )
            yOffset += 24

            for message in config.messages {
                let character = config.getCharacter(message.characterID)
                let isMe = character?.isMe ?? true

                // Draw timestamp
                if config.settings.showTimestamps && message.showTimestamp {
                    yOffset = drawTimestamp(
                        date: message.effectiveDisplayTime,
                        at: yOffset,
                        canvasWidth: width,
                        context: context.cgContext
                    )
                }

                // Draw character name (for receivers)
                if !isMe, let name = character?.name {
                    yOffset = drawCharacterName(
                        name: name,
                        at: yOffset,
                        padding: padding + 44, // Account for avatar
                        context: context.cgContext
                    )
                }

                // Draw reactions
                if config.settings.showReactions && !message.reactions.isEmpty {
                    yOffset = drawReactions(
                        reactions: message.reactions,
                        isMe: isMe,
                        at: yOffset,
                        padding: padding,
                        canvasWidth: width,
                        context: context.cgContext
                    )
                }

                // Draw avatar + bubble
                if message.type == .image {
                    yOffset = drawImageBubble(
                        imageData: message.imageData,
                        isMe: isMe,
                        character: character,
                        at: yOffset,
                        padding: padding,
                        config: config,
                        canvasWidth: width,
                        context: context.cgContext
                    )
                } else {
                    yOffset = drawBubbleWithAvatar(
                        text: message.text,
                        isMe: isMe,
                        character: character,
                        at: yOffset,
                        maxWidth: maxBubbleWidth,
                        padding: padding,
                        config: config,
                        canvasWidth: width,
                        context: context.cgContext
                    )
                }

                yOffset += 12
            }
        }

        return image
    }

    private func calculateBubbleHeight(text: String, maxWidth: CGFloat) -> CGFloat {
        let font = UIFont.systemFont(ofSize: 17, weight: .regular)
        let textSize = (text as NSString).boundingRect(
            with: CGSize(width: maxWidth, height: .greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: [.font: font],
            context: nil
        ).size

        return textSize.height + 24 // Padding
    }

    private func drawTimestamp(
        date: Date,
        at yOffset: CGFloat,
        canvasWidth: CGFloat,
        context: CGContext
    ) -> CGFloat {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        let timeString = formatter.string(from: date)

        let font = UIFont.systemFont(ofSize: 12, weight: .medium)
        let color = UIColor.secondaryLabel
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: color
        ]

        let textSize = (timeString as NSString).size(withAttributes: attributes)
        let x = (canvasWidth - textSize.width) / 2
        (timeString as NSString).draw(at: CGPoint(x: x, y: yOffset), withAttributes: attributes)

        return yOffset + textSize.height + 8
    }

    private func drawCharacterName(
        name: String,
        at yOffset: CGFloat,
        padding: CGFloat,
        context: CGContext
    ) -> CGFloat {
        let font = UIFont.systemFont(ofSize: 12, weight: .medium)
        let color = UIColor.secondaryLabel
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: color
        ]

        (name as NSString).draw(at: CGPoint(x: padding, y: yOffset), withAttributes: attributes)

        return yOffset + 16
    }

    private func drawReactions(
        reactions: [Reaction],
        isMe: Bool,
        at yOffset: CGFloat,
        padding: CGFloat,
        canvasWidth: CGFloat,
        context: CGContext
    ) -> CGFloat {
        var counts: [String: Int] = [:]
        for reaction in reactions {
            counts[reaction.emoji, default: 0] += 1
        }

        let font = UIFont.systemFont(ofSize: 14)
        var xOffset: CGFloat = isMe ? canvasWidth - padding : padding + 44

        for (emoji, count) in counts.sorted(by: { $0.value > $1.value }) {
            let text = count > 1 ? "\(emoji)\(count)" : emoji
            let attrs: [NSAttributedString.Key: Any] = [.font: font]
            let size = (text as NSString).size(withAttributes: attrs)

            // Draw pill background
            let pillRect = CGRect(
                x: isMe ? xOffset - size.width - 12 : xOffset,
                y: yOffset,
                width: size.width + 12,
                height: size.height + 6
            )

            UIColor.systemBackground.setFill()
            UIBezierPath(roundedRect: pillRect, cornerRadius: 10).fill()

            // Draw text
            let textX = pillRect.origin.x + 6
            let textY = pillRect.origin.y + 3
            (text as NSString).draw(at: CGPoint(x: textX, y: textY), withAttributes: attrs)

            if isMe {
                xOffset -= size.width + 20
            } else {
                xOffset += size.width + 20
            }
        }

        return yOffset + 22
    }

    private func drawBubbleWithAvatar(
        text: String,
        isMe: Bool,
        character: Character?,
        at yOffset: CGFloat,
        maxWidth: CGFloat,
        padding: CGFloat,
        config: ExportConfig,
        canvasWidth: CGFloat,
        context: CGContext
    ) -> CGFloat {
        let avatarSize: CGFloat = 32
        let avatarPadding: CGFloat = 8

        // Draw avatar if enabled
        if config.settings.showAvatars {
            let avatarX = isMe ? canvasWidth - padding - avatarSize : padding
            let avatarY = yOffset

            // Avatar circle
            let avatarRect = CGRect(x: avatarX, y: avatarY, width: avatarSize, height: avatarSize)
            let avatarColor = UIColor(character?.color ?? .gray)
            avatarColor.setFill()
            UIBezierPath(ovalIn: avatarRect).fill()

            // Avatar content
            if let imageData = character?.avatarImageData, let image = UIImage(data: imageData) {
                UIGraphicsGetCurrentContext()?.saveGState()
                UIBezierPath(ovalIn: avatarRect).addClip()
                image.draw(in: avatarRect)
                UIGraphicsGetCurrentContext()?.restoreGState()
            } else if let emoji = character?.avatarEmoji, !emoji.isEmpty {
                let emojiFont = UIFont.systemFont(ofSize: 16)
                let emojiAttrs: [NSAttributedString.Key: Any] = [.font: emojiFont]
                let emojiSize = (emoji as NSString).size(withAttributes: emojiAttrs)
                let emojiX = avatarX + (avatarSize - emojiSize.width) / 2
                let emojiY = avatarY + (avatarSize - emojiSize.height) / 2
                (emoji as NSString).draw(at: CGPoint(x: emojiX, y: emojiY), withAttributes: emojiAttrs)
            } else {
                // Default person icon (simplified)
                let iconColor = UIColor.white.withAlphaComponent(0.8)
                iconColor.setFill()
                let iconRect = CGRect(
                    x: avatarX + avatarSize * 0.3,
                    y: avatarY + avatarSize * 0.25,
                    width: avatarSize * 0.4,
                    height: avatarSize * 0.4
                )
                UIBezierPath(ovalIn: iconRect).fill()
            }
        }

        // Calculate bubble position
        let bubbleMargin = config.settings.showAvatars ? avatarSize + avatarPadding : 0
        let adjustedMaxWidth = maxWidth - bubbleMargin

        let font = UIFont.systemFont(ofSize: 17, weight: .regular)
        let textColor = isMe ? UIColor(config.theme.senderTextColor) : UIColor(config.theme.receiverTextColor)
        let bubbleColor = isMe ? UIColor(config.theme.senderBubbleColor) : UIColor(config.theme.receiverBubbleColor)

        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: textColor
        ]

        let textSize = (text as NSString).boundingRect(
            with: CGSize(width: adjustedMaxWidth - 28, height: .greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: attributes,
            context: nil
        ).size

        let bubbleWidth = min(textSize.width + 28, adjustedMaxWidth)
        let bubbleHeight = textSize.height + 20

        let bubbleX: CGFloat
        if isMe {
            bubbleX = canvasWidth - padding - bubbleMargin - bubbleWidth
        } else {
            bubbleX = padding + bubbleMargin
        }

        let bubbleRect = CGRect(x: bubbleX, y: yOffset, width: bubbleWidth, height: bubbleHeight)

        // Draw bubble
        bubbleColor.setFill()
        UIBezierPath(roundedRect: bubbleRect, cornerRadius: 18).fill()

        // Draw text
        let textRect = CGRect(
            x: bubbleX + 14,
            y: yOffset + 10,
            width: textSize.width,
            height: textSize.height
        )
        (text as NSString).draw(in: textRect, withAttributes: attributes)

        return yOffset + bubbleHeight
    }

    private func drawImageBubble(
        imageData: Data?,
        isMe: Bool,
        character: Character?,
        at yOffset: CGFloat,
        padding: CGFloat,
        config: ExportConfig,
        canvasWidth: CGFloat,
        context: CGContext
    ) -> CGFloat {
        let avatarSize: CGFloat = 32
        let avatarPadding: CGFloat = 8
        let imageWidth: CGFloat = 200
        let imageHeight: CGFloat = 200

        // Draw avatar if enabled
        if config.settings.showAvatars {
            let avatarX = isMe ? canvasWidth - padding - avatarSize : padding
            let avatarY = yOffset

            let avatarRect = CGRect(x: avatarX, y: avatarY, width: avatarSize, height: avatarSize)
            let avatarColor = UIColor(character?.color ?? .gray)
            avatarColor.setFill()
            UIBezierPath(ovalIn: avatarRect).fill()

            if let emoji = character?.avatarEmoji, !emoji.isEmpty {
                let emojiFont = UIFont.systemFont(ofSize: 16)
                let emojiAttrs: [NSAttributedString.Key: Any] = [.font: emojiFont]
                let emojiSize = (emoji as NSString).size(withAttributes: emojiAttrs)
                let emojiX = avatarX + (avatarSize - emojiSize.width) / 2
                let emojiY = avatarY + (avatarSize - emojiSize.height) / 2
                (emoji as NSString).draw(at: CGPoint(x: emojiX, y: emojiY), withAttributes: emojiAttrs)
            }
        }

        // Calculate image position
        let bubbleMargin = config.settings.showAvatars ? avatarSize + avatarPadding : 0
        let imageX: CGFloat
        if isMe {
            imageX = canvasWidth - padding - bubbleMargin - imageWidth
        } else {
            imageX = padding + bubbleMargin
        }

        let imageRect = CGRect(x: imageX, y: yOffset, width: imageWidth, height: imageHeight)

        // Draw image or placeholder
        if let data = imageData, let uiImage = UIImage(data: data) {
            UIGraphicsGetCurrentContext()?.saveGState()
            UIBezierPath(roundedRect: imageRect, cornerRadius: 18).addClip()
            uiImage.draw(in: imageRect)
            UIGraphicsGetCurrentContext()?.restoreGState()
        } else {
            UIColor.systemGray4.setFill()
            UIBezierPath(roundedRect: imageRect, cornerRadius: 18).fill()
        }

        return yOffset + imageHeight
    }

    private func drawHeaderBar(
        config: ExportConfig,
        context: CGContext,
        canvasWidth: CGFloat,
        darkMode: Bool
    ) -> CGFloat {
        let headerHeight: CGFloat = 100
        let headerBgColor = darkMode ? UIColor(white: 0.1, alpha: 1) : UIColor.white
        let textColor = darkMode ? UIColor.white : UIColor.black
        let blueColor = UIColor.systemBlue

        // Header background
        headerBgColor.setFill()
        context.fill(CGRect(x: 0, y: 0, width: canvasWidth, height: headerHeight))

        // Draw separator line
        UIColor.separator.setFill()
        context.fill(CGRect(x: 0, y: headerHeight - 0.5, width: canvasWidth, height: 0.5))

        // Back chevron (left)
        let chevronX: CGFloat = 12
        let chevronY: CGFloat = 48
        let chevronFont = UIFont.systemFont(ofSize: 22, weight: .semibold)
        let chevronAttrs: [NSAttributedString.Key: Any] = [.font: chevronFont, .foregroundColor: blueColor]
        "‹".draw(at: CGPoint(x: chevronX, y: chevronY), withAttributes: chevronAttrs)

        // Avatar (center)
        let avatarSize: CGFloat = 44
        let avatarX = (canvasWidth - avatarSize) / 2
        let avatarY: CGFloat = 20

        if let contact = config.mainContact {
            // Draw avatar circle
            let avatarRect = CGRect(x: avatarX, y: avatarY, width: avatarSize, height: avatarSize)
            let avatarColor = UIColor(Color(hex: contact.colorHex))
            avatarColor.setFill()
            UIBezierPath(ovalIn: avatarRect).fill()

            // Draw emoji if available
            if let emoji = contact.avatarEmoji, !emoji.isEmpty {
                let emojiFont = UIFont.systemFont(ofSize: 22)
                let emojiAttrs: [NSAttributedString.Key: Any] = [.font: emojiFont]
                let emojiSize = emoji.size(withAttributes: emojiAttrs)
                let emojiX = avatarX + (avatarSize - emojiSize.width) / 2
                let emojiY = avatarY + (avatarSize - emojiSize.height) / 2
                emoji.draw(at: CGPoint(x: emojiX, y: emojiY), withAttributes: emojiAttrs)
            }
        }

        // Name (below avatar)
        let nameFont = UIFont.systemFont(ofSize: 14, weight: .semibold)
        let name = config.isGroupChat ? config.conversationTitle : (config.mainContact?.name ?? config.conversationTitle)
        let nameAttrs: [NSAttributedString.Key: Any] = [.font: nameFont, .foregroundColor: textColor]
        let nameSize = name.size(withAttributes: nameAttrs)
        let nameX = (canvasWidth - nameSize.width) / 2 - 6
        let nameY = avatarY + avatarSize + 4
        name.draw(at: CGPoint(x: nameX, y: nameY), withAttributes: nameAttrs)

        // Chevron after name
        let smallChevronFont = UIFont.systemFont(ofSize: 12, weight: .semibold)
        let smallChevronAttrs: [NSAttributedString.Key: Any] = [.font: smallChevronFont, .foregroundColor: UIColor.systemGray]
        ">".draw(at: CGPoint(x: nameX + nameSize.width + 2, y: nameY + 1), withAttributes: smallChevronAttrs)

        // Video icon (right)
        drawVideoIcon(at: CGPoint(x: canvasWidth - 35, y: 45), size: 18, color: blueColor, context: context)

        return headerHeight
    }

    private func drawVideoIcon(at point: CGPoint, size: CGFloat, color: UIColor, context: CGContext) {
        color.setFill()
        color.setStroke()

        // Camera body (rounded rectangle)
        let bodyWidth = size * 1.4
        let bodyHeight = size
        let bodyRect = CGRect(x: point.x - bodyWidth - 4, y: point.y - bodyHeight/2, width: bodyWidth, height: bodyHeight)
        let bodyPath = UIBezierPath(roundedRect: bodyRect, cornerRadius: size * 0.2)
        bodyPath.fill()

        // Camera lens (triangle pointing right)
        let trianglePath = UIBezierPath()
        let triStartX = bodyRect.maxX + 2
        let triWidth = size * 0.6
        trianglePath.move(to: CGPoint(x: triStartX, y: point.y - bodyHeight * 0.3))
        trianglePath.addLine(to: CGPoint(x: triStartX + triWidth, y: point.y))
        trianglePath.addLine(to: CGPoint(x: triStartX, y: point.y + bodyHeight * 0.3))
        trianglePath.close()
        trianglePath.fill()
    }

    private func drawCenteredText(_ text: String, at y: CGFloat, fontSize: CGFloat, color: UIColor, canvasWidth: CGFloat) {
        let font = UIFont.systemFont(ofSize: fontSize)
        let attrs: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: color]
        let textSize = text.size(withAttributes: attrs)
        let x = (canvasWidth - textSize.width) / 2
        text.draw(at: CGPoint(x: x, y: y), withAttributes: attrs)
    }
}
