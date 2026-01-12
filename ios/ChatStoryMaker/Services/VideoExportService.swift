//
//  VideoExportService.swift
//  Textory
//
//  AVFoundation video export with sound effects
//

import AVFoundation
import UIKit
import SwiftUI

class VideoExportService {

    // Simple data structs for thread-safe export (no SwiftData)
    struct ExportMessage: Sendable {
        let id: UUID
        let text: String
        let characterID: UUID
    }

    struct ExportCharacter: Sendable {
        let id: UUID
        let name: String
        let isMe: Bool
        let colorHex: String
        let avatarEmoji: String?
        let avatarImageData: Data?
    }

    struct ExportConfig: Sendable {
        let messages: [ExportMessage]
        let characters: [ExportCharacter]
        let theme: ChatTheme
        let settings: ExportSettings
        let conversationTitle: String
        let isGroupChat: Bool

        func getCharacter(for id: UUID) -> ExportCharacter? {
            characters.first { $0.id == id }
        }

        var mainContact: ExportCharacter? {
            characters.first { !$0.isMe }
        }
    }

    // Track when each message appears for audio sync
    struct MessageTiming: Sendable {
        let messageID: UUID
        let timeInSeconds: Double
        let isMe: Bool
    }

    func exportVideo(config: ExportConfig, progress: @escaping (Double) -> Void) async throws -> URL {
        // Report initial progress immediately
        progress(0.02)

        let resolution = config.settings.format.resolution
        let fps: Int32 = 30
        let silentVideoURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("mp4")

        // Track message timings for audio
        var messageTimings: [MessageTiming] = []

        progress(0.03)

        // Setup AVAssetWriter for video
        let writer = try AVAssetWriter(outputURL: silentVideoURL, fileType: .mp4)

        let videoSettings: [String: Any] = [
            AVVideoCodecKey: AVVideoCodecType.h264,
            AVVideoWidthKey: resolution.width,
            AVVideoHeightKey: resolution.height
        ]

        let writerInput = AVAssetWriterInput(mediaType: .video, outputSettings: videoSettings)
        let adaptor = AVAssetWriterInputPixelBufferAdaptor(
            assetWriterInput: writerInput,
            sourcePixelBufferAttributes: [
                kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA,
                kCVPixelBufferWidthKey as String: resolution.width,
                kCVPixelBufferHeightKey as String: resolution.height,
                kCVPixelBufferCGImageCompatibilityKey as String: true,
                kCVPixelBufferCGBitmapContextCompatibilityKey as String: true
            ]
        )

        writer.add(writerInput)
        writer.startWriting()
        writer.startSession(atSourceTime: .zero)

        progress(0.05)

        var frameCount: Int64 = 0
        var visibleMessages: [(ExportMessage, String)] = []

        // Typing speed: frames per character based on settings
        let framesPerChar = config.settings.typingSpeed.framesPerChar

        let totalMessages = config.messages.count

        // Render frames for each message - REALISTIC CHAT SIMULATION
        for (index, message) in config.messages.enumerated() {
            // Yield to allow UI updates (animations) to process
            await Task.yield()

            let character = config.getCharacter(for: message.characterID)
            let isMe = character?.isMe ?? true

            // Calculate base progress for this message (5% to 80% range = 75% for messages)
            let messageBaseProgress = 0.05 + (Double(index) / Double(totalMessages) * 0.75)
            let messageProgressRange = 0.75 / Double(totalMessages)

            if isMe {
                // SENDER MESSAGE: Show typing in keyboard text field, then send
                let totalChars = message.text.count

                // Type out message character by character in the text field
                for charIndex in 1...totalChars {
                    try autoreleasepool {
                        let partialText = String(message.text.prefix(charIndex))
                        let currentChar = String(message.text[message.text.index(message.text.startIndex, offsetBy: charIndex - 1)])
                        let frame = renderFrame(
                            visibleMessages: visibleMessages,
                            typingText: nil,
                            showTypingIndicator: false,
                            typingIsMe: isMe,
                            config: config,
                            resolution: resolution,
                            keyboardTypingText: partialText,
                            highlightedKey: currentChar.lowercased()
                        )
                        // Show each character for a moment
                        for _ in 0..<framesPerChar {
                            try appendFrame(frame, to: adaptor, at: frameCount, fps: fps)
                            frameCount += 1
                        }
                    }

                    // Yield every 3 characters to allow UI updates
                    if charIndex % 3 == 0 {
                        await Task.yield()
                    }

                    // Update progress during typing (first 60% of message progress)
                    let typingProgress = Double(charIndex) / Double(totalChars) * 0.6
                    progress(messageBaseProgress + typingProgress * messageProgressRange)
                }

                // Brief pause before sending (like pressing send button)
                try autoreleasepool {
                    let frame = renderFrame(
                        visibleMessages: visibleMessages,
                        typingText: nil,
                        showTypingIndicator: false,
                        typingIsMe: isMe,
                        config: config,
                        resolution: resolution,
                        keyboardTypingText: message.text
                    )
                    for _ in 0..<10 { // ~0.3 seconds
                        try appendFrame(frame, to: adaptor, at: frameCount, fps: fps)
                        frameCount += 1
                    }
                }

                // Yield after pause frames
                await Task.yield()

                // Record timing when message is sent (for audio sync)
                let messageTime = Double(frameCount) / Double(fps)
                messageTimings.append(MessageTiming(messageID: message.id, timeInSeconds: messageTime, isMe: isMe))

                // Message appears (sent!)
                visibleMessages.append((message, message.text))

                // Update progress after sending (80% of message progress)
                progress(messageBaseProgress + 0.8 * messageProgressRange)

            } else {
                // RECEIVED MESSAGE: Show typing indicator, then message appears

                // Typing indicator for 1.5-2.5 seconds based on message length
                let typingDuration = min(max(Double(message.text.count) / 20.0, 1.5), 2.5)
                let typingFrames = Int(typingDuration * Double(fps))

                try autoreleasepool {
                    let frame = renderFrame(
                        visibleMessages: visibleMessages,
                        typingText: nil,
                        showTypingIndicator: true,
                        typingIsMe: isMe,
                        config: config,
                        resolution: resolution,
                        keyboardTypingText: nil
                    )
                    for _ in 0..<typingFrames {
                        try appendFrame(frame, to: adaptor, at: frameCount, fps: fps)
                        frameCount += 1
                    }
                }

                // Yield after typing indicator frames
                await Task.yield()

                // Record timing when message appears (for audio sync)
                let messageTime = Double(frameCount) / Double(fps)
                messageTimings.append(MessageTiming(messageID: message.id, timeInSeconds: messageTime, isMe: isMe))

                // Message appears
                visibleMessages.append((message, message.text))

                // Update progress after message appears (80% of message progress)
                progress(messageBaseProgress + 0.8 * messageProgressRange)
            }

            // Show message for reading time (1.5-3 seconds based on length)
            let readingTime = min(max(Double(message.text.count) / 25.0, 1.5), 3.0)
            let pauseFrames = Int(readingTime * Double(fps))

            try autoreleasepool {
                let frame = renderFrame(
                    visibleMessages: visibleMessages,
                    typingText: nil,
                    showTypingIndicator: false,
                    typingIsMe: isMe,
                    config: config,
                    resolution: resolution,
                    keyboardTypingText: nil // Clear keyboard after sending
                )
                for _ in 0..<pauseFrames {
                    try appendFrame(frame, to: adaptor, at: frameCount, fps: fps)
                    frameCount += 1
                }
            }

            // Yield after reading time frames
            await Task.yield()

            // Update progress after reading time (100% of message progress)
            progress(messageBaseProgress + messageProgressRange)
        }

        progress(0.82)

        // Final pause (2 seconds at 30fps)
        try autoreleasepool {
            let frame = renderFrame(
                visibleMessages: visibleMessages,
                typingText: nil,
                showTypingIndicator: false,
                typingIsMe: true,
                config: config,
                resolution: resolution,
                keyboardTypingText: nil
            )
            for _ in 0..<60 {
                try appendFrame(frame, to: adaptor, at: frameCount, fps: fps)
                frameCount += 1
            }
        }

        // Yield after final pause
        await Task.yield()

        progress(0.85)

        let totalDuration = Double(frameCount) / Double(fps)

        writerInput.markAsFinished()
        await writer.finishWriting()

        progress(0.88)

        // Add audio if sounds are enabled
        if config.settings.enableSounds {
            progress(0.90)

            let finalURL = FileManager.default.temporaryDirectory
                .appendingPathComponent(UUID().uuidString)
                .appendingPathExtension("mp4")

            try await addAudioToVideo(
                videoURL: silentVideoURL,
                outputURL: finalURL,
                messageTimings: messageTimings,
                totalDuration: totalDuration,
                progress: progress
            )

            // Clean up silent video
            try? FileManager.default.removeItem(at: silentVideoURL)

            progress(1.0)
            return finalURL
        } else {
            progress(1.0)
            return silentVideoURL
        }
    }

    // MARK: - Add Audio to Video

    private func addAudioToVideo(
        videoURL: URL,
        outputURL: URL,
        messageTimings: [MessageTiming],
        totalDuration: Double,
        progress: @escaping (Double) -> Void
    ) async throws {
        let composition = AVMutableComposition()
        let videoAsset = AVURLAsset(url: videoURL)

        progress(0.91)

        // Add video track
        guard let videoTrack = try await videoAsset.loadTracks(withMediaType: .video).first,
              let compositionVideoTrack = composition.addMutableTrack(
                withMediaType: .video,
                preferredTrackID: kCMPersistentTrackID_Invalid
              ) else {
            throw ExportError.writerFailed
        }

        let videoDuration = try await videoAsset.load(.duration)
        try compositionVideoTrack.insertTimeRange(
            CMTimeRange(start: .zero, duration: videoDuration),
            of: videoTrack,
            at: .zero
        )

        progress(0.93)

        // Create audio track with generated sounds
        let audioURL = try createAudioFile(messageTimings: messageTimings, totalDuration: totalDuration)

        progress(0.95)

        let audioAsset = AVURLAsset(url: audioURL)
        if let audioTrack = try await audioAsset.loadTracks(withMediaType: .audio).first,
           let compositionAudioTrack = composition.addMutableTrack(
            withMediaType: .audio,
            preferredTrackID: kCMPersistentTrackID_Invalid
           ) {
            let audioDuration = try await audioAsset.load(.duration)
            try compositionAudioTrack.insertTimeRange(
                CMTimeRange(start: .zero, duration: audioDuration),
                of: audioTrack,
                at: .zero
            )
        }

        progress(0.96)

        // Export combined video
        guard let exportSession = AVAssetExportSession(
            asset: composition,
            presetName: AVAssetExportPresetHighestQuality
        ) else {
            throw ExportError.writerFailed
        }

        exportSession.outputURL = outputURL
        exportSession.outputFileType = .mp4

        progress(0.97)

        await exportSession.export()

        progress(0.99)

        if exportSession.status != .completed {
            throw exportSession.error ?? ExportError.writerFailed
        }

        // Clean up temp audio file
        try? FileManager.default.removeItem(at: audioURL)
    }

    // MARK: - Create Audio File

    private func createAudioFile(messageTimings: [MessageTiming], totalDuration: Double) throws -> URL {
        let sampleRate: Double = 44100
        let totalSamples = Int(sampleRate * totalDuration)

        // Generate audio samples with sounds at message times
        var audioSamples = [Float](repeating: 0, count: totalSamples)

        let sendSound = SoundGenerator.shared.generateSendSound()
        let receiveSound = SoundGenerator.shared.generateReceiveSound()

        for timing in messageTimings {
            let sound = timing.isMe ? sendSound : receiveSound
            let startSample = Int(timing.timeInSeconds * sampleRate)

            for (i, sample) in sound.enumerated() {
                let targetIndex = startSample + i
                if targetIndex < totalSamples {
                    audioSamples[targetIndex] += sample
                }
            }
        }

        // Clamp to prevent clipping
        for i in 0..<totalSamples {
            audioSamples[i] = max(-1.0, min(1.0, audioSamples[i]))
        }

        // Write to WAV file
        let audioURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("wav")

        try writeWAVFile(samples: audioSamples, sampleRate: Int(sampleRate), to: audioURL)

        return audioURL
    }

    // MARK: - Write WAV File

    private func writeWAVFile(samples: [Float], sampleRate: Int, to url: URL) throws {
        let numChannels: Int16 = 1
        let bitsPerSample: Int16 = 16
        let byteRate = Int32(sampleRate * Int(numChannels) * Int(bitsPerSample) / 8)
        let blockAlign = Int16(numChannels * bitsPerSample / 8)
        let dataSize = Int32(samples.count * Int(blockAlign))
        let chunkSize = Int32(36 + dataSize)

        var data = Data()

        // RIFF header
        data.append("RIFF".data(using: .ascii)!)
        data.append(withUnsafeBytes(of: chunkSize.littleEndian) { Data($0) })
        data.append("WAVE".data(using: .ascii)!)

        // fmt subchunk
        data.append("fmt ".data(using: .ascii)!)
        data.append(withUnsafeBytes(of: Int32(16).littleEndian) { Data($0) }) // Subchunk1Size
        data.append(withUnsafeBytes(of: Int16(1).littleEndian) { Data($0) }) // AudioFormat (PCM)
        data.append(withUnsafeBytes(of: numChannels.littleEndian) { Data($0) })
        data.append(withUnsafeBytes(of: Int32(sampleRate).littleEndian) { Data($0) })
        data.append(withUnsafeBytes(of: byteRate.littleEndian) { Data($0) })
        data.append(withUnsafeBytes(of: blockAlign.littleEndian) { Data($0) })
        data.append(withUnsafeBytes(of: bitsPerSample.littleEndian) { Data($0) })

        // data subchunk
        data.append("data".data(using: .ascii)!)
        data.append(withUnsafeBytes(of: dataSize.littleEndian) { Data($0) })

        // Audio samples (16-bit PCM)
        for sample in samples {
            let int16Sample = Int16(max(-32768, min(32767, sample * 32767)))
            data.append(withUnsafeBytes(of: int16Sample.littleEndian) { Data($0) })
        }

        try data.write(to: url)
    }

    private func renderFrame(
        visibleMessages: [(ExportMessage, String)],
        typingText: (ExportMessage, String, Bool)?,
        showTypingIndicator: Bool,
        typingIsMe: Bool,
        config: ExportConfig,
        resolution: CGSize,
        keyboardTypingText: String? = nil,
        highlightedKey: String? = nil
    ) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: resolution)

        return renderer.image { context in
            // Background
            let bgColor = config.settings.darkMode ? UIColor.black : UIColor(config.theme.backgroundColor)
            bgColor.setFill()
            context.fill(CGRect(origin: .zero, size: resolution))

            // Layout constants - scaled for iPhone 12 Pro Max proportions
            let scale = resolution.width / 390.0 // Base scale on iPhone 14 width
            let keyboardHeight: CGFloat = 216 * scale  // Realistic iOS keyboard height
            let inputBarHeight: CGFloat = 52 * scale   // Compact input bar
            let headerHeight: CGFloat = 95 * scale     // Slightly smaller header
            let bubblePadding: CGFloat = 16 * scale
            let maxBubbleWidth = resolution.width * 0.75

            // Draw header bar (compact, iPhone style)
            drawCompactHeader(
                config: config,
                context: context.cgContext,
                canvasWidth: resolution.width,
                headerHeight: headerHeight,
                darkMode: config.settings.darkMode,
                scale: scale
            )

            // Calculate keyboard position
            let keyboardY = resolution.height - keyboardHeight
            let inputBarY = keyboardY - inputBarHeight

            // Draw keyboard and input bar if enabled
            if config.settings.showKeyboard {
                drawKeyboard(
                    at: keyboardY,
                    context: context.cgContext,
                    canvasSize: resolution,
                    darkMode: config.settings.darkMode,
                    typingText: keyboardTypingText,
                    highlightedKey: highlightedKey,
                    scale: scale
                )
            }

            // Calculate message area (between header and input bar)
            let messageAreaTop = headerHeight + 10 * scale
            let messageAreaBottom = config.settings.showKeyboard ? inputBarY - 10 * scale : resolution.height - 20 * scale

            // First pass: calculate heights for all messages
            var messageHeights: [CGFloat] = []

            for (message, text) in visibleMessages {
                let character = config.getCharacter(for: message.characterID)
                let isMe = character?.isMe ?? true
                let height = calculateBubbleHeight(
                    text: text,
                    isMe: isMe,
                    isGroupChat: config.isGroupChat,
                    maxWidth: maxBubbleWidth,
                    scale: scale
                )
                messageHeights.append(height)
            }

            // Available height for messages
            let availableHeight = messageAreaBottom - messageAreaTop
            let typingIndicatorHeight: CGFloat = showTypingIndicator ? 50 * scale : 0

            // Auto-scroll: Find which messages fit from the end (most recent)
            var startIndex = 0
            var totalHeight = typingIndicatorHeight

            // Work backwards from the most recent message
            for i in stride(from: visibleMessages.count - 1, through: 0, by: -1) {
                if totalHeight + messageHeights[i] <= availableHeight {
                    totalHeight += messageHeights[i]
                    startIndex = i
                } else {
                    break
                }
            }

            // Position messages from bottom
            var yOffset: CGFloat
            if totalHeight < availableHeight {
                // Messages don't fill screen - position from bottom
                yOffset = messageAreaBottom - totalHeight
            } else {
                // Messages fill screen - start from top
                yOffset = messageAreaTop
            }

            // Draw only the messages that fit (from startIndex onwards)
            for i in startIndex..<visibleMessages.count {
                let (message, text) = visibleMessages[i]
                let character = config.getCharacter(for: message.characterID)
                let isMe = character?.isMe ?? true

                yOffset = drawBubble(
                    text: text,
                    isMe: isMe,
                    character: character,
                    isGroupChat: config.isGroupChat,
                    at: yOffset,
                    maxWidth: maxBubbleWidth,
                    padding: bubblePadding,
                    theme: config.theme,
                    context: context.cgContext,
                    canvasWidth: resolution.width,
                    darkMode: config.settings.darkMode,
                    scale: scale
                )
            }

            // Draw typing indicator (for received messages)
            if showTypingIndicator {
                drawTypingIndicator(
                    isMe: typingIsMe,
                    at: yOffset,
                    padding: bubblePadding,
                    theme: config.theme,
                    context: context.cgContext,
                    canvasWidth: resolution.width,
                    scale: scale
                )
            }
        }
    }

    // MARK: - Calculate Bubble Height (for layout)

    private func calculateBubbleHeight(
        text: String,
        isMe: Bool,
        isGroupChat: Bool,
        maxWidth: CGFloat,
        scale: CGFloat
    ) -> CGFloat {
        let font = UIFont.systemFont(ofSize: 17 * scale, weight: .regular)
        let attributes: [NSAttributedString.Key: Any] = [.font: font]

        let textSize = (text as NSString).boundingRect(
            with: CGSize(width: maxWidth - 24 * scale, height: .greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: attributes,
            context: nil
        ).size

        var height = textSize.height + 16 * scale // Bubble padding
        height += 8 * scale // Spacing between messages

        // Add name height for group chat non-me messages
        if isGroupChat && !isMe {
            height += 20 * scale
        }

        return height
    }

    // MARK: - Compact Header (iPhone style)

    private func drawCompactHeader(
        config: ExportConfig,
        context: CGContext,
        canvasWidth: CGFloat,
        headerHeight: CGFloat,
        darkMode: Bool,
        scale: CGFloat
    ) {
        let headerBgColor = darkMode ? UIColor(white: 0.1, alpha: 1) : UIColor.white
        let textColor = darkMode ? UIColor.white : UIColor.black
        let blueColor = UIColor.systemBlue

        // Header background
        headerBgColor.setFill()
        context.fill(CGRect(x: 0, y: 0, width: canvasWidth, height: headerHeight))

        // Draw separator line
        UIColor.separator.setFill()
        context.fill(CGRect(x: 0, y: headerHeight - 1, width: canvasWidth, height: 1))

        // Back chevron (left)
        let chevronFont = UIFont.systemFont(ofSize: 20 * scale, weight: .semibold)
        let chevronAttrs: [NSAttributedString.Key: Any] = [.font: chevronFont, .foregroundColor: blueColor]
        let chevronY = headerHeight / 2 - 12 * scale
        "‹".draw(at: CGPoint(x: 10 * scale, y: chevronY), withAttributes: chevronAttrs)

        // Avatar (center)
        let avatarSize: CGFloat = 40 * scale
        let avatarX = (canvasWidth - avatarSize) / 2
        let avatarY: CGFloat = 15 * scale

        if let contact = config.mainContact {
            let avatarRect = CGRect(x: avatarX, y: avatarY, width: avatarSize, height: avatarSize)
            let avatarColor = UIColor(Color(hex: contact.colorHex))
            avatarColor.setFill()
            UIBezierPath(ovalIn: avatarRect).fill()

            if let emoji = contact.avatarEmoji, !emoji.isEmpty {
                let emojiFont = UIFont.systemFont(ofSize: 20 * scale)
                let emojiAttrs: [NSAttributedString.Key: Any] = [.font: emojiFont]
                let emojiSize = emoji.size(withAttributes: emojiAttrs)
                let emojiX = avatarX + (avatarSize - emojiSize.width) / 2
                let emojiY = avatarY + (avatarSize - emojiSize.height) / 2
                emoji.draw(at: CGPoint(x: emojiX, y: emojiY), withAttributes: emojiAttrs)
            }
        }

        // Name (below avatar)
        let nameFont = UIFont.systemFont(ofSize: 13 * scale, weight: .semibold)
        let name = config.isGroupChat ? config.conversationTitle : (config.mainContact?.name ?? config.conversationTitle)
        let nameAttrs: [NSAttributedString.Key: Any] = [.font: nameFont, .foregroundColor: textColor]
        let nameSize = name.size(withAttributes: nameAttrs)
        let nameX = (canvasWidth - nameSize.width) / 2
        let nameY = avatarY + avatarSize + 4 * scale
        name.draw(at: CGPoint(x: nameX, y: nameY), withAttributes: nameAttrs)

        // Video icon (right) - only for 1:1 chats, not group chats
        if !config.isGroupChat {
            drawVideoIcon(at: CGPoint(x: canvasWidth - 35 * scale, y: headerHeight / 2 - 10 * scale), color: blueColor, context: context, scale: scale)
        }
    }

    private func drawHeaderBar(
        config: ExportConfig,
        context: CGContext,
        canvasWidth: CGFloat,
        darkMode: Bool
    ) -> CGFloat {
        let headerHeight: CGFloat = 180
        let headerBgColor = darkMode ? UIColor(white: 0.1, alpha: 1) : UIColor.white
        let textColor = darkMode ? UIColor.white : UIColor.black
        let blueColor = UIColor.systemBlue

        // Header background
        headerBgColor.setFill()
        context.fill(CGRect(x: 0, y: 0, width: canvasWidth, height: headerHeight))

        // Draw separator line
        UIColor.separator.setFill()
        context.fill(CGRect(x: 0, y: headerHeight - 1, width: canvasWidth, height: 1))

        // Back chevron (left)
        let chevronX: CGFloat = 20
        let chevronY: CGFloat = 90
        let chevronFont = UIFont.systemFont(ofSize: 40, weight: .semibold)
        let chevronAttrs: [NSAttributedString.Key: Any] = [.font: chevronFont, .foregroundColor: blueColor]
        "‹".draw(at: CGPoint(x: chevronX, y: chevronY), withAttributes: chevronAttrs)

        // Avatar (center)
        let avatarSize: CGFloat = 80
        let avatarX = (canvasWidth - avatarSize) / 2
        let avatarY: CGFloat = 40

        if let contact = config.mainContact {
            // Draw avatar circle
            let avatarRect = CGRect(x: avatarX, y: avatarY, width: avatarSize, height: avatarSize)
            let avatarColor = UIColor(Color(hex: contact.colorHex))
            avatarColor.setFill()
            UIBezierPath(ovalIn: avatarRect).fill()

            // Draw emoji if available
            if let emoji = contact.avatarEmoji, !emoji.isEmpty {
                let emojiFont = UIFont.systemFont(ofSize: 40)
                let emojiAttrs: [NSAttributedString.Key: Any] = [.font: emojiFont]
                let emojiSize = emoji.size(withAttributes: emojiAttrs)
                let emojiX = avatarX + (avatarSize - emojiSize.width) / 2
                let emojiY = avatarY + (avatarSize - emojiSize.height) / 2
                emoji.draw(at: CGPoint(x: emojiX, y: emojiY), withAttributes: emojiAttrs)
            }
        }

        // Name (below avatar)
        let nameFont = UIFont.systemFont(ofSize: 28, weight: .semibold)
        let name = config.isGroupChat ? config.conversationTitle : (config.mainContact?.name ?? config.conversationTitle)
        let nameAttrs: [NSAttributedString.Key: Any] = [.font: nameFont, .foregroundColor: textColor]
        let nameSize = name.size(withAttributes: nameAttrs)
        let nameX = (canvasWidth - nameSize.width) / 2 - 10
        let nameY = avatarY + avatarSize + 8
        name.draw(at: CGPoint(x: nameX, y: nameY), withAttributes: nameAttrs)

        // Chevron after name
        let smallChevronFont = UIFont.systemFont(ofSize: 22, weight: .semibold)
        let smallChevronAttrs: [NSAttributedString.Key: Any] = [.font: smallChevronFont, .foregroundColor: UIColor.systemGray]
        ">".draw(at: CGPoint(x: nameX + nameSize.width + 4, y: nameY + 4), withAttributes: smallChevronAttrs)

        // Video icon (right) - only for 1:1 chats, not group chats
        if !config.isGroupChat {
            let videoIconX = canvasWidth - 60
            let videoIconY: CGFloat = 85
            drawVideoIcon(at: CGPoint(x: videoIconX, y: videoIconY), color: blueColor, context: context)
        }

        return headerHeight
    }

    private func drawVideoIcon(at point: CGPoint, color: UIColor, context: CGContext, scale: CGFloat = 1.0) {
        color.setFill()
        color.setStroke()

        // Camera body (rounded rectangle)
        let bodyWidth: CGFloat = 20 * scale
        let bodyHeight: CGFloat = 14 * scale
        let bodyRect = CGRect(x: point.x - bodyWidth - 2 * scale, y: point.y, width: bodyWidth, height: bodyHeight)
        let bodyPath = UIBezierPath(roundedRect: bodyRect, cornerRadius: 3 * scale)
        bodyPath.fill()

        // Camera lens (triangle pointing right)
        let trianglePath = UIBezierPath()
        let triStartX = bodyRect.maxX + 2 * scale
        let triWidth: CGFloat = 10 * scale
        let centerY = point.y + bodyHeight / 2
        trianglePath.move(to: CGPoint(x: triStartX, y: centerY - 5 * scale))
        trianglePath.addLine(to: CGPoint(x: triStartX + triWidth, y: centerY))
        trianglePath.addLine(to: CGPoint(x: triStartX, y: centerY + 5 * scale))
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

    private func drawBubble(
        text: String,
        isMe: Bool,
        character: ExportCharacter?,
        isGroupChat: Bool,
        at yOffset: CGFloat,
        maxWidth: CGFloat,
        padding: CGFloat,
        theme: ChatTheme,
        context: CGContext,
        canvasWidth: CGFloat,
        darkMode: Bool,
        scale: CGFloat = 1.0
    ) -> CGFloat {
        let font = UIFont.systemFont(ofSize: 17 * scale, weight: .regular)
        let textColor = isMe ? UIColor(theme.senderTextColor) : UIColor(theme.receiverTextColor)
        let bubbleColor = isMe ? UIColor(theme.senderBubbleColor) : UIColor(theme.receiverBubbleColor)

        // Avatar size for group chats
        let avatarSize: CGFloat = 28 * scale
        let avatarSpacing: CGFloat = 6 * scale
        let showAvatar = isGroupChat && !isMe

        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: textColor
        ]

        let textSize = (text as NSString).boundingRect(
            with: CGSize(width: maxWidth - 24 * scale, height: .greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: attributes,
            context: nil
        ).size

        let bubbleWidth = textSize.width + 24 * scale
        let bubbleHeight = textSize.height + 14 * scale

        // Adjust bubble X position for avatar in group chats
        let bubbleX: CGFloat
        if isMe {
            bubbleX = canvasWidth - bubbleWidth - padding
        } else if showAvatar {
            bubbleX = padding + avatarSize + avatarSpacing
        } else {
            bubbleX = padding
        }

        // Draw sender name above bubble for group chat (non-me messages)
        var actualYOffset = yOffset
        if isGroupChat && !isMe, let char = character {
            let nameFont = UIFont.systemFont(ofSize: 12 * scale, weight: .medium)
            let nameColor = UIColor(Color(hex: char.colorHex))
            let nameAttrs: [NSAttributedString.Key: Any] = [.font: nameFont, .foregroundColor: nameColor]
            char.name.draw(at: CGPoint(x: bubbleX, y: actualYOffset), withAttributes: nameAttrs)
            actualYOffset += 16 * scale // Space for name
        }

        let bubbleRect = CGRect(x: bubbleX, y: actualYOffset, width: bubbleWidth, height: bubbleHeight)

        // Draw avatar for group chat (non-me messages) - positioned after we know the bubble position
        if showAvatar, let char = character {
            let avatarX = padding
            let avatarY = actualYOffset + bubbleHeight - avatarSize // Align to bottom of bubble

            // Draw avatar circle
            let avatarRect = CGRect(x: avatarX, y: avatarY, width: avatarSize, height: avatarSize)
            let avatarColor = UIColor(Color(hex: char.colorHex))
            avatarColor.setFill()
            UIBezierPath(ovalIn: avatarRect).fill()

            // Draw emoji if available
            if let emoji = char.avatarEmoji, !emoji.isEmpty {
                let emojiFont = UIFont.systemFont(ofSize: 14 * scale)
                let emojiAttrs: [NSAttributedString.Key: Any] = [.font: emojiFont]
                let emojiSize = emoji.size(withAttributes: emojiAttrs)
                let emojiX = avatarX + (avatarSize - emojiSize.width) / 2
                let emojiY = avatarY + (avatarSize - emojiSize.height) / 2
                emoji.draw(at: CGPoint(x: emojiX, y: emojiY), withAttributes: emojiAttrs)
            } else {
                // Draw first letter of name
                let initial = String(char.name.prefix(1)).uppercased()
                let initialFont = UIFont.systemFont(ofSize: 12 * scale, weight: .semibold)
                let initialAttrs: [NSAttributedString.Key: Any] = [.font: initialFont, .foregroundColor: UIColor.white]
                let initialSize = initial.size(withAttributes: initialAttrs)
                let initialX = avatarX + (avatarSize - initialSize.width) / 2
                let initialY = avatarY + (avatarSize - initialSize.height) / 2
                initial.draw(at: CGPoint(x: initialX, y: initialY), withAttributes: initialAttrs)
            }
        }

        // Draw bubble
        let bubblePath = UIBezierPath(roundedRect: bubbleRect, cornerRadius: 18 * scale)
        bubbleColor.setFill()
        bubblePath.fill()

        // Draw text
        let textRect = CGRect(
            x: bubbleX + 12 * scale,
            y: actualYOffset + 7 * scale,
            width: textSize.width,
            height: textSize.height
        )
        (text as NSString).draw(in: textRect, withAttributes: attributes)

        return actualYOffset + bubbleHeight + 6 * scale
    }

    private func drawTypingIndicator(
        isMe: Bool,
        at yOffset: CGFloat,
        padding: CGFloat,
        theme: ChatTheme,
        context: CGContext,
        canvasWidth: CGFloat,
        scale: CGFloat = 1.0
    ) {
        let bubbleColor = isMe ? UIColor(theme.senderBubbleColor) : UIColor(theme.receiverBubbleColor)
        let bubbleWidth: CGFloat = 60 * scale
        let bubbleHeight: CGFloat = 36 * scale
        let bubbleX = isMe ? canvasWidth - bubbleWidth - padding : padding

        let bubbleRect = CGRect(x: bubbleX, y: yOffset, width: bubbleWidth, height: bubbleHeight)
        let bubblePath = UIBezierPath(roundedRect: bubbleRect, cornerRadius: 18 * scale)
        bubbleColor.setFill()
        bubblePath.fill()

        // Draw dots
        let dotColor = isMe ? UIColor.white.withAlphaComponent(0.8) : UIColor.gray
        dotColor.setFill()

        let dotSize: CGFloat = 8 * scale
        for i in 0..<3 {
            let dotX = bubbleX + 15 * scale + CGFloat(i) * 12 * scale
            let dotY = yOffset + bubbleHeight / 2
            let dotPath = UIBezierPath(ovalIn: CGRect(x: dotX - dotSize/2, y: dotY - dotSize/2, width: dotSize, height: dotSize))
            dotPath.fill()
        }
    }

    private func drawKeyboard(at yOffset: CGFloat, context: CGContext, canvasSize: CGSize, darkMode: Bool, typingText: String? = nil, highlightedKey: String? = nil, scale: CGFloat = 1.0) {
        // iOS Keyboard Layout
        let row1 = ["q", "w", "e", "r", "t", "y", "u", "i", "o", "p"]
        let row2 = ["a", "s", "d", "f", "g", "h", "j", "k", "l"]
        let row3 = ["z", "x", "c", "v", "b", "n", "m"]

        // Keyboard dimensions - compact like real iOS keyboard
        let keyboardHeight: CGFloat = 216 * scale  // Match the layout allocation
        let keyHeight: CGFloat = 38 * scale        // Slightly smaller keys
        let keySpacing: CGFloat = 5 * scale        // Tighter spacing
        let rowSpacing: CGFloat = 8 * scale        // Less row spacing
        let sideMargin: CGFloat = 3 * scale

        // Colors
        let keyboardBgColor = darkMode ? UIColor(white: 0.12, alpha: 1) : UIColor(red: 0.82, green: 0.84, blue: 0.86, alpha: 1)
        let keyColor = darkMode ? UIColor(white: 0.35, alpha: 1) : UIColor.white
        let specialKeyColor = darkMode ? UIColor(white: 0.25, alpha: 1) : UIColor(white: 0.68, alpha: 1)
        let highlightColor = UIColor(white: 0.5, alpha: 1)
        let textColor = darkMode ? UIColor.white : UIColor.black
        let keyShadowColor = darkMode ? UIColor(white: 0.1, alpha: 1) : UIColor(white: 0.6, alpha: 1)

        // Text input field (scaled) - compact like real iOS
        let inputFieldHeight: CGFloat = 32 * scale
        let inputBgColor = darkMode ? UIColor(white: 0.2, alpha: 1) : UIColor.white
        let inputBorderColor = darkMode ? UIColor(white: 0.4, alpha: 1) : UIColor(white: 0.8, alpha: 1)

        // Draw input field area - positioned just above keyboard
        let inputMargin: CGFloat = 8 * scale
        let inputRect = CGRect(x: inputMargin, y: yOffset - inputFieldHeight - 10 * scale, width: canvasSize.width - 54 * scale, height: inputFieldHeight)
        inputBgColor.setFill()
        let inputPath = UIBezierPath(roundedRect: inputRect, cornerRadius: 18 * scale)
        inputPath.fill()
        inputBorderColor.setStroke()
        inputPath.lineWidth = 1
        inputPath.stroke()

        // Draw typed text in input field
        let inputFontSize: CGFloat = 15 * scale
        if let text = typingText, !text.isEmpty {
            let inputTextColor = darkMode ? UIColor.white : UIColor.black
            let font = UIFont.systemFont(ofSize: inputFontSize)
            let attrs: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: inputTextColor]
            let textY = inputRect.origin.y + (inputFieldHeight - font.lineHeight) / 2
            let displayText = text + "|"
            displayText.draw(at: CGPoint(x: inputRect.origin.x + 12 * scale, y: textY), withAttributes: attrs)
        } else {
            let placeholderColor = UIColor.gray
            let font = UIFont.systemFont(ofSize: inputFontSize)
            let attrs: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: placeholderColor]
            let textY = inputRect.origin.y + (inputFieldHeight - font.lineHeight) / 2
            "iMessage".draw(at: CGPoint(x: inputRect.origin.x + 12 * scale, y: textY), withAttributes: attrs)
        }

        // Send button
        let sendButtonSize: CGFloat = 28 * scale
        let sendButtonX = canvasSize.width - sendButtonSize - 12 * scale
        let sendButtonY = yOffset - inputFieldHeight - 10 * scale + (inputFieldHeight - sendButtonSize) / 2
        let sendButtonRect = CGRect(x: sendButtonX, y: sendButtonY, width: sendButtonSize, height: sendButtonSize)
        UIColor.systemBlue.setFill()
        UIBezierPath(ovalIn: sendButtonRect).fill()

        let arrowFont = UIFont.systemFont(ofSize: 16 * scale, weight: .bold)
        let arrowAttrs: [NSAttributedString.Key: Any] = [.font: arrowFont, .foregroundColor: UIColor.white]
        let arrow = "↑"
        let arrowSize = arrow.size(withAttributes: arrowAttrs)
        let arrowX = sendButtonX + (sendButtonSize - arrowSize.width) / 2
        let arrowY = sendButtonY + (sendButtonSize - arrowSize.height) / 2
        arrow.draw(at: CGPoint(x: arrowX, y: arrowY), withAttributes: arrowAttrs)

        // Keyboard background - fill to bottom of screen
        keyboardBgColor.setFill()
        context.fill(CGRect(x: 0, y: yOffset, width: canvasSize.width, height: canvasSize.height - yOffset))

        // Calculate key width for each row
        let keyboardWidth = canvasSize.width - (sideMargin * 2)
        let row1KeyWidth = (keyboardWidth - CGFloat(row1.count - 1) * keySpacing) / CGFloat(row1.count)
        let row2Indent: CGFloat = 16 * scale
        let row2KeyWidth = (keyboardWidth - CGFloat(row2.count - 1) * keySpacing - row2Indent) / CGFloat(row2.count)
        let specialKeyWidth: CGFloat = 38 * scale
        let row3KeyWidth = (keyboardWidth - CGFloat(row3.count - 1) * keySpacing - specialKeyWidth * 2 - keySpacing * 2) / CGFloat(row3.count)

        var currentY = yOffset + 8 * scale

        // Helper function to draw a key
        func drawKey(char: String, rect: CGRect, isHighlighted: Bool, isSpecial: Bool = false) {
            // Key shadow
            keyShadowColor.setFill()
            let shadowRect = CGRect(x: rect.minX, y: rect.minY + 1, width: rect.width, height: rect.height)
            UIBezierPath(roundedRect: shadowRect, cornerRadius: 5 * scale).fill()

            // Key background
            let bgColor = isHighlighted ? highlightColor : (isSpecial ? specialKeyColor : keyColor)
            bgColor.setFill()
            UIBezierPath(roundedRect: rect, cornerRadius: 5 * scale).fill()

            // Key text
            let fontSize: CGFloat = isSpecial ? 11 * scale : 16 * scale
            let font = UIFont.systemFont(ofSize: fontSize, weight: .regular)
            let attrs: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: textColor]
            let textSize = char.size(withAttributes: attrs)
            let textX = rect.minX + (rect.width - textSize.width) / 2
            let textY = rect.minY + (rect.height - textSize.height) / 2
            char.draw(at: CGPoint(x: textX, y: textY), withAttributes: attrs)
        }

        // Draw Row 1 (QWERTYUIOP)
        var xPos = sideMargin
        for char in row1 {
            let keyRect = CGRect(x: xPos, y: currentY, width: row1KeyWidth, height: keyHeight)
            let isHighlighted = highlightedKey?.lowercased() == char
            drawKey(char: char, rect: keyRect, isHighlighted: isHighlighted)
            xPos += row1KeyWidth + keySpacing
        }
        currentY += keyHeight + rowSpacing

        // Draw Row 2 (ASDFGHJKL) - slightly indented
        xPos = sideMargin + row2Indent / 2
        for char in row2 {
            let keyRect = CGRect(x: xPos, y: currentY, width: row2KeyWidth, height: keyHeight)
            let isHighlighted = highlightedKey?.lowercased() == char
            drawKey(char: char, rect: keyRect, isHighlighted: isHighlighted)
            xPos += row2KeyWidth + keySpacing
        }
        currentY += keyHeight + rowSpacing

        // Draw Row 3 (shift, ZXCVBNM, delete)
        // Shift key
        xPos = sideMargin
        let shiftRect = CGRect(x: xPos, y: currentY, width: specialKeyWidth, height: keyHeight)
        drawKey(char: "⇧", rect: shiftRect, isHighlighted: false, isSpecial: true)
        xPos += specialKeyWidth + keySpacing

        // Letter keys
        for char in row3 {
            let keyRect = CGRect(x: xPos, y: currentY, width: row3KeyWidth, height: keyHeight)
            let isHighlighted = highlightedKey?.lowercased() == char
            drawKey(char: char, rect: keyRect, isHighlighted: isHighlighted)
            xPos += row3KeyWidth + keySpacing
        }

        // Delete key
        let deleteRect = CGRect(x: canvasSize.width - sideMargin - specialKeyWidth, y: currentY, width: specialKeyWidth, height: keyHeight)
        drawKey(char: "⌫", rect: deleteRect, isHighlighted: false, isSpecial: true)
        currentY += keyHeight + rowSpacing

        // Draw Row 4 (123, emoji, space, return)
        let bottomKeyHeight: CGFloat = 38 * scale
        let numKeyWidth: CGFloat = 38 * scale
        let emojiKeyWidth: CGFloat = 36 * scale
        let spaceKeyWidth = canvasSize.width - numKeyWidth - emojiKeyWidth - 60 * scale - keySpacing * 4 - sideMargin * 2

        xPos = sideMargin

        // 123 key
        let numRect = CGRect(x: xPos, y: currentY, width: numKeyWidth, height: bottomKeyHeight)
        drawKey(char: "123", rect: numRect, isHighlighted: false, isSpecial: true)
        xPos += numKeyWidth + keySpacing

        // Emoji key
        let emojiRect = CGRect(x: xPos, y: currentY, width: emojiKeyWidth, height: bottomKeyHeight)
        drawKey(char: "😊", rect: emojiRect, isHighlighted: false, isSpecial: true)
        xPos += emojiKeyWidth + keySpacing

        // Space bar - check if space is highlighted
        let spaceRect = CGRect(x: xPos, y: currentY, width: spaceKeyWidth, height: bottomKeyHeight)
        let spaceHighlighted = highlightedKey == " "
        drawKey(char: "space", rect: spaceRect, isHighlighted: spaceHighlighted, isSpecial: false)
        xPos += spaceKeyWidth + keySpacing

        // Return key
        let returnRect = CGRect(x: xPos, y: currentY, width: canvasSize.width - xPos - sideMargin, height: bottomKeyHeight)
        drawKey(char: "return", rect: returnRect, isHighlighted: false, isSpecial: true)
    }

    private func appendFrame(_ image: UIImage, to adaptor: AVAssetWriterInputPixelBufferAdaptor, at frameCount: Int64, fps: Int32) throws {
        guard let pixelBuffer = pixelBuffer(from: image, adaptor: adaptor) else {
            throw ExportError.pixelBufferCreationFailed
        }

        let presentationTime = CMTime(value: frameCount, timescale: fps)

        while !adaptor.assetWriterInput.isReadyForMoreMediaData {
            Thread.sleep(forTimeInterval: 0.01)
        }

        adaptor.append(pixelBuffer, withPresentationTime: presentationTime)
    }

    private func pixelBuffer(from image: UIImage, adaptor: AVAssetWriterInputPixelBufferAdaptor) -> CVPixelBuffer? {
        guard let cgImage = image.cgImage,
              let pool = adaptor.pixelBufferPool else { return nil }

        var pixelBuffer: CVPixelBuffer?
        CVPixelBufferPoolCreatePixelBuffer(nil, pool, &pixelBuffer)

        guard let buffer = pixelBuffer else { return nil }

        CVPixelBufferLockBaseAddress(buffer, [])

        let width = CVPixelBufferGetWidth(buffer)
        let height = CVPixelBufferGetHeight(buffer)
        let bytesPerRow = CVPixelBufferGetBytesPerRow(buffer)

        let context = CGContext(
            data: CVPixelBufferGetBaseAddress(buffer),
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: bytesPerRow,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGBitmapInfo.byteOrder32Little.rawValue | CGImageAlphaInfo.premultipliedFirst.rawValue
        )

        context?.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        CVPixelBufferUnlockBaseAddress(buffer, [])

        return buffer
    }
}

enum ExportError: Error, LocalizedError {
    case pixelBufferCreationFailed
    case writerFailed

    var errorDescription: String? {
        switch self {
        case .pixelBufferCreationFailed:
            return "Failed to create pixel buffer"
        case .writerFailed:
            return "Video writer failed"
        }
    }
}
