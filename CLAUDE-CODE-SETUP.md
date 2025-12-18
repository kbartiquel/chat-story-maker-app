# Chat Story Maker - Complete Project Documentation

## Project Overview

**App Name:** ChatTale (or TextTale - check availability)
**Platform:** iOS 17+
**Language:** Swift 5.9+
**UI Framework:** SwiftUI
**Architecture:** MVVM

### What This App Does
A mobile app that lets users create fake text message conversations and export them as videos with realistic "live typing" animations. Perfect for content creators making TikTok/Instagram/YouTube content.

### Key Differentiator
AI-powered story generation - users enter a prompt and get a full conversation generated automatically.

---

## Core Features

### 1. Conversation Management
- Create/edit/delete conversations
- Add 2+ characters per conversation
- Customize character names and colors
- Save conversations locally

### 2. Chat Editor
- Add messages by switching between characters
- Edit/delete/reorder messages
- Support for emoji
- Real-time preview of chat bubbles

### 3. Video Export (⭐ Key Feature)
- Live typing animation (characters appear one by one)
- Typing indicator ("...") before messages
- Send/receive sound effects
- Multiple export formats: 9:16 (TikTok), 1:1 (Instagram), 16:9 (YouTube)
- Adjustable typing speed
- Optional keyboard overlay
- Dark/Light mode

### 4. AI Story Generator (⭐ Premium)
- Text prompt input
- Genre selection (Drama, Comedy, Romance, Horror, Mystery)
- Mood selection (Funny, Dramatic, Scary, Romantic)
- Length options (Short: 5-10, Medium: 10-20, Long: 20-30 messages)
- Generates full conversation from prompt

### 5. Themes
- iMessage (default)
- WhatsApp (premium)
- Messenger (premium)
- Discord (premium)

### 6. Monetization
- Free: 3 exports/day with watermark, 2 characters, iMessage only
- Premium: Unlimited exports, no watermark, all themes, AI generator

---

## Technical Architecture

### Project Structure

```
ChatTale/
├── App/
│   ├── ChatTaleApp.swift              # App entry point
│   └── AppDelegate.swift              # App lifecycle (if needed)
│
├── Models/
│   ├── Character.swift                # Character model
│   ├── Message.swift                  # Message model
│   ├── Conversation.swift             # Conversation model
│   ├── ExportSettings.swift           # Video export settings
│   └── Theme.swift                    # Chat theme definitions
│
├── Views/
│   ├── Home/
│   │   ├── HomeView.swift             # Main story list
│   │   ├── ConversationRowView.swift  # List row component
│   │   └── EmptyStateView.swift       # Empty state UI
│   │
│   ├── Setup/
│   │   ├── NewConversationView.swift  # Create new story
│   │   ├── CharacterEditorView.swift  # Edit character
│   │   └── ThemePickerView.swift      # Select theme
│   │
│   ├── Editor/
│   │   ├── ChatEditorView.swift       # Main chat editor
│   │   ├── MessageBubbleView.swift    # Chat bubble component
│   │   ├── MessageInputView.swift     # Input bar
│   │   └── CharacterSwitcherView.swift # Switch active character
│   │
│   ├── Export/
│   │   ├── ExportView.swift           # Export settings screen
│   │   ├── VideoPreviewView.swift     # Animated preview
│   │   ├── FormatPickerView.swift     # 9:16, 1:1, 16:9
│   │   └── ExportProgressView.swift   # Progress indicator
│   │
│   ├── AIGenerator/
│   │   ├── AIGeneratorView.swift      # AI prompt screen
│   │   ├── GenrePickerView.swift      # Genre selection
│   │   ├── MoodPickerView.swift       # Mood selection
│   │   └── LengthPickerView.swift     # Length selection
│   │
│   ├── Settings/
│   │   ├── SettingsView.swift         # App settings
│   │   └── PaywallView.swift          # Premium upgrade
│   │
│   └── Components/
│       ├── PrimaryButton.swift        # Reusable button
│       ├── CardView.swift             # Reusable card
│       └── ToggleRow.swift            # Settings toggle row
│
├── ViewModels/
│   ├── ConversationViewModel.swift    # Manage conversations
│   ├── ChatEditorViewModel.swift      # Editor logic
│   ├── ExportViewModel.swift          # Export logic
│   ├── AIGeneratorViewModel.swift     # AI generation logic
│   └── SettingsViewModel.swift        # Settings & premium state
│
├── Services/
│   ├── StorageService.swift           # SwiftData persistence
│   ├── VideoExportService.swift       # AVFoundation video creation
│   ├── AudioService.swift             # System sounds (no files needed)
│   ├── AIService.swift                # Claude API integration
│   └── PurchaseService.swift          # RevenueCat integration
│
├── Utilities/
│   ├── Constants.swift                # App constants
│   ├── Extensions.swift               # Swift extensions
│   └── Helpers.swift                  # Utility functions
│
└── Resources/
    ├── Assets.xcassets/               # Images, colors, app icon
    └── Localizable.strings            # Localization
```

---

## Data Models

### Character.swift
```swift
import SwiftUI
import SwiftData

@Model
class Character {
    var id: UUID
    var name: String
    var colorHex: String
    var isMe: Bool // true = right side (sender), false = left side
    var avatarEmoji: String?
    
    init(name: String, colorHex: String, isMe: Bool, avatarEmoji: String? = nil) {
        self.id = UUID()
        self.name = name
        self.colorHex = colorHex
        self.isMe = isMe
        self.avatarEmoji = avatarEmoji
    }
    
    var color: Color {
        Color(hex: colorHex)
    }
    
    static let defaultSender = Character(name: "Me", colorHex: "#007AFF", isMe: true)
    static let defaultReceiver = Character(name: "Alex", colorHex: "#34C759", isMe: false)
}
```

### Message.swift
```swift
import SwiftData
import Foundation

@Model
class Message {
    var id: UUID
    var text: String
    var characterID: UUID
    var timestamp: Date
    var order: Int
    
    init(text: String, characterID: UUID, order: Int) {
        self.id = UUID()
        self.text = text
        self.characterID = characterID
        self.timestamp = Date()
        self.order = order
    }
}
```

### Conversation.swift
```swift
import SwiftData
import Foundation

@Model
class Conversation {
    var id: UUID
    var title: String
    var createdAt: Date
    var updatedAt: Date
    var themeRawValue: String
    
    @Relationship(deleteRule: .cascade)
    var characters: [Character]
    
    @Relationship(deleteRule: .cascade)
    var messages: [Message]
    
    init(title: String, theme: ChatTheme = .imessage) {
        self.id = UUID()
        self.title = title
        self.createdAt = Date()
        self.updatedAt = Date()
        self.themeRawValue = theme.rawValue
        self.characters = [Character.defaultSender, Character.defaultReceiver]
        self.messages = []
    }
    
    var theme: ChatTheme {
        ChatTheme(rawValue: themeRawValue) ?? .imessage
    }
    
    var sortedMessages: [Message] {
        messages.sorted { $0.order < $1.order }
    }
}
```

### Theme.swift
```swift
import SwiftUI

enum ChatTheme: String, CaseIterable {
    case imessage
    case whatsapp
    case messenger
    case discord
    
    var displayName: String {
        switch self {
        case .imessage: return "iMessage"
        case .whatsapp: return "WhatsApp"
        case .messenger: return "Messenger"
        case .discord: return "Discord"
        }
    }
    
    var senderBubbleColor: Color {
        switch self {
        case .imessage: return Color(hex: "#007AFF")
        case .whatsapp: return Color(hex: "#DCF8C6")
        case .messenger: return Color(hex: "#0084FF")
        case .discord: return Color(hex: "#5865F2")
        }
    }
    
    var receiverBubbleColor: Color {
        switch self {
        case .imessage: return Color(hex: "#E5E5EA")
        case .whatsapp: return Color.white
        case .messenger: return Color(hex: "#E4E6EB")
        case .discord: return Color(hex: "#2F3136")
        }
    }
    
    var backgroundColor: Color {
        switch self {
        case .imessage: return Color(hex: "#FFFFFF")
        case .whatsapp: return Color(hex: "#ECE5DD")
        case .messenger: return Color(hex: "#FFFFFF")
        case .discord: return Color(hex: "#36393F")
        }
    }
    
    var senderTextColor: Color {
        switch self {
        case .imessage: return .white
        case .whatsapp: return .black
        case .messenger: return .white
        case .discord: return .white
        }
    }
    
    var receiverTextColor: Color {
        switch self {
        case .imessage: return .black
        case .whatsapp: return .black
        case .messenger: return .black
        case .discord: return .white
        }
    }
    
    var isPremium: Bool {
        self != .imessage
    }
}
```

### ExportSettings.swift
```swift
import Foundation

struct ExportSettings {
    var format: ExportFormat = .tiktok
    var typingSpeed: TypingSpeed = .normal
    var showKeyboard: Bool = true
    var showTypingIndicator: Bool = true
    var enableSounds: Bool = true
    var darkMode: Bool = false
}

enum ExportFormat: String, CaseIterable {
    case tiktok   // 9:16 (1080x1920)
    case instagram // 1:1 (1080x1080)
    case youtube  // 16:9 (1920x1080)
    
    var displayName: String {
        switch self {
        case .tiktok: return "TikTok"
        case .instagram: return "Instagram"
        case .youtube: return "YouTube"
        }
    }
    
    var aspectRatio: String {
        switch self {
        case .tiktok: return "9:16"
        case .instagram: return "1:1"
        case .youtube: return "16:9"
        }
    }
    
    var resolution: CGSize {
        switch self {
        case .tiktok: return CGSize(width: 1080, height: 1920)
        case .instagram: return CGSize(width: 1080, height: 1080)
        case .youtube: return CGSize(width: 1920, height: 1080)
        }
    }
}

enum TypingSpeed: Double, CaseIterable {
    case slow = 0.08
    case normal = 0.05
    case fast = 0.02
    
    var displayName: String {
        switch self {
        case .slow: return "Slow"
        case .normal: return "Normal"
        case .fast: return "Fast"
        }
    }
    
    var charDelay: Double { rawValue }
    var messageDelay: Double { rawValue * 10 }
}
```

---

## Video Export Service (Core Logic)

### VideoExportService.swift
```swift
import AVFoundation
import UIKit
import SwiftUI

class VideoExportService {
    
    struct ExportConfig {
        let messages: [Message]
        let characters: [Character]
        let theme: ChatTheme
        let settings: ExportSettings
        let getCharacter: (UUID) -> Character?
    }
    
    func exportVideo(config: ExportConfig, progress: @escaping (Double) -> Void) async throws -> URL {
        let resolution = config.settings.format.resolution
        let fps: Int32 = 60
        let outputURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("mp4")
        
        // Setup AVAssetWriter
        let writer = try AVAssetWriter(outputURL: outputURL, fileType: .mp4)
        
        let videoSettings: [String: Any] = [
            AVVideoCodecKey: AVVideoCodecType.h264,
            AVVideoWidthKey: resolution.width,
            AVVideoHeightKey: resolution.height
        ]
        
        let writerInput = AVAssetWriterInput(mediaType: .video, outputSettings: videoSettings)
        let adaptor = AVAssetWriterInputPixelBufferAdaptor(
            assetWriterInput: writerInput,
            sourcePixelBufferAttributes: [
                kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32ARGB,
                kCVPixelBufferWidthKey as String: resolution.width,
                kCVPixelBufferHeightKey as String: resolution.height
            ]
        )
        
        writer.add(writerInput)
        writer.startWriting()
        writer.startSession(atSourceTime: .zero)
        
        var frameCount: Int64 = 0
        var visibleMessages: [(Message, String)] = [] // (message, visibleText)
        var showTypingIndicator = false
        
        // Render frames for each message
        for (index, message) in config.messages.enumerated() {
            let character = config.getCharacter(message.characterID)
            let isMe = character?.isMe ?? true
            
            // Show typing indicator frames
            if config.settings.showTypingIndicator {
                showTypingIndicator = true
                for _ in 0..<30 { // 0.5 seconds of typing indicator
                    let frame = renderFrame(
                        visibleMessages: visibleMessages,
                        typingText: nil,
                        showTypingIndicator: showTypingIndicator,
                        typingIsMe: isMe,
                        config: config,
                        resolution: resolution
                    )
                    try appendFrame(frame, to: adaptor, at: frameCount, fps: fps)
                    frameCount += 1
                }
                showTypingIndicator = false
            }
            
            // Type out message character by character
            for charIndex in 1...message.text.count {
                let visibleText = String(message.text.prefix(charIndex))
                
                let frame = renderFrame(
                    visibleMessages: visibleMessages,
                    typingText: (message, visibleText, isMe),
                    showTypingIndicator: false,
                    typingIsMe: isMe,
                    config: config,
                    resolution: resolution
                )
                
                // Add frames based on typing speed (3 frames per character at 60fps)
                let framesPerChar = Int(config.settings.typingSpeed.charDelay * Double(fps))
                for _ in 0..<max(framesPerChar, 1) {
                    try appendFrame(frame, to: adaptor, at: frameCount, fps: fps)
                    frameCount += 1
                }
            }
            
            // Add completed message to visible messages
            visibleMessages.append((message, message.text))
            
            // Pause between messages
            let pauseFrames = Int(config.settings.typingSpeed.messageDelay * Double(fps))
            for _ in 0..<pauseFrames {
                let frame = renderFrame(
                    visibleMessages: visibleMessages,
                    typingText: nil,
                    showTypingIndicator: false,
                    typingIsMe: isMe,
                    config: config,
                    resolution: resolution
                )
                try appendFrame(frame, to: adaptor, at: frameCount, fps: fps)
                frameCount += 1
            }
            
            progress(Double(index + 1) / Double(config.messages.count))
        }
        
        // Final pause
        for _ in 0..<60 {
            let frame = renderFrame(
                visibleMessages: visibleMessages,
                typingText: nil,
                showTypingIndicator: false,
                typingIsMe: true,
                config: config,
                resolution: resolution
            )
            try appendFrame(frame, to: adaptor, at: frameCount, fps: fps)
            frameCount += 1
        }
        
        writerInput.markAsFinished()
        await writer.finishWriting()
        
        return outputURL
    }
    
    private func renderFrame(
        visibleMessages: [(Message, String)],
        typingText: (Message, String, Bool)?,
        showTypingIndicator: Bool,
        typingIsMe: Bool,
        config: ExportConfig,
        resolution: CGSize
    ) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: resolution)
        
        return renderer.image { context in
            // Background
            let bgColor = config.settings.darkMode ? UIColor.black : UIColor(config.theme.backgroundColor)
            bgColor.setFill()
            context.fill(CGRect(origin: .zero, size: resolution))
            
            // Calculate message positions
            var yOffset: CGFloat = 100
            let bubblePadding: CGFloat = 16
            let maxBubbleWidth = resolution.width * 0.7
            
            // Draw visible messages
            for (message, text) in visibleMessages {
                let character = config.getCharacter(message.characterID)
                let isMe = character?.isMe ?? true
                
                yOffset = drawBubble(
                    text: text,
                    isMe: isMe,
                    at: yOffset,
                    maxWidth: maxBubbleWidth,
                    padding: bubblePadding,
                    theme: config.theme,
                    context: context.cgContext,
                    canvasWidth: resolution.width
                )
            }
            
            // Draw typing text (current message being typed)
            if let (message, text, isMe) = typingText {
                yOffset = drawBubble(
                    text: text + "|", // Cursor
                    isMe: isMe,
                    at: yOffset,
                    maxWidth: maxBubbleWidth,
                    padding: bubblePadding,
                    theme: config.theme,
                    context: context.cgContext,
                    canvasWidth: resolution.width
                )
            }
            
            // Draw typing indicator
            if showTypingIndicator {
                drawTypingIndicator(
                    isMe: typingIsMe,
                    at: yOffset,
                    padding: bubblePadding,
                    theme: config.theme,
                    context: context.cgContext,
                    canvasWidth: resolution.width
                )
            }
            
            // Draw keyboard (optional)
            if config.settings.showKeyboard {
                drawKeyboard(
                    at: resolution.height - 300,
                    context: context.cgContext,
                    canvasSize: resolution
                )
            }
        }
    }
    
    private func drawBubble(
        text: String,
        isMe: Bool,
        at yOffset: CGFloat,
        maxWidth: CGFloat,
        padding: CGFloat,
        theme: ChatTheme,
        context: CGContext,
        canvasWidth: CGFloat
    ) -> CGFloat {
        let font = UIFont.systemFont(ofSize: 32, weight: .regular)
        let textColor = isMe ? UIColor(theme.senderTextColor) : UIColor(theme.receiverTextColor)
        let bubbleColor = isMe ? UIColor(theme.senderBubbleColor) : UIColor(theme.receiverBubbleColor)
        
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: textColor
        ]
        
        let textSize = (text as NSString).boundingRect(
            with: CGSize(width: maxWidth - 32, height: .greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: attributes,
            context: nil
        ).size
        
        let bubbleWidth = textSize.width + 32
        let bubbleHeight = textSize.height + 20
        
        let bubbleX = isMe ? canvasWidth - bubbleWidth - padding : padding
        let bubbleRect = CGRect(x: bubbleX, y: yOffset, width: bubbleWidth, height: bubbleHeight)
        
        // Draw bubble
        let bubblePath = UIBezierPath(roundedRect: bubbleRect, cornerRadius: 20)
        bubbleColor.setFill()
        bubblePath.fill()
        
        // Draw text
        let textRect = CGRect(
            x: bubbleX + 16,
            y: yOffset + 10,
            width: textSize.width,
            height: textSize.height
        )
        (text as NSString).draw(in: textRect, withAttributes: attributes)
        
        return yOffset + bubbleHeight + 8
    }
    
    private func drawTypingIndicator(
        isMe: Bool,
        at yOffset: CGFloat,
        padding: CGFloat,
        theme: ChatTheme,
        context: CGContext,
        canvasWidth: CGFloat
    ) {
        let bubbleColor = isMe ? UIColor(theme.senderBubbleColor) : UIColor(theme.receiverBubbleColor)
        let bubbleWidth: CGFloat = 80
        let bubbleHeight: CGFloat = 44
        let bubbleX = isMe ? canvasWidth - bubbleWidth - padding : padding
        
        let bubbleRect = CGRect(x: bubbleX, y: yOffset, width: bubbleWidth, height: bubbleHeight)
        let bubblePath = UIBezierPath(roundedRect: bubbleRect, cornerRadius: 20)
        bubbleColor.setFill()
        bubblePath.fill()
        
        // Draw dots
        let dotColor = isMe ? UIColor.white.withAlphaComponent(0.8) : UIColor.gray
        dotColor.setFill()
        
        for i in 0..<3 {
            let dotX = bubbleX + 22 + CGFloat(i) * 16
            let dotY = yOffset + bubbleHeight/2
            let dotPath = UIBezierPath(ovalIn: CGRect(x: dotX - 5, y: dotY - 5, width: 10, height: 10))
            dotPath.fill()
        }
    }
    
    private func drawKeyboard(at yOffset: CGFloat, context: CGContext, canvasSize: CGSize) {
        // Simplified keyboard drawing
        UIColor(white: 0.85, alpha: 1).setFill()
        context.fill(CGRect(x: 0, y: yOffset, width: canvasSize.width, height: 300))
        
        // Draw key rows (simplified)
        let keyRows = ["QWERTYUIOP", "ASDFGHJKL", "ZXCVBNM"]
        let keySize: CGFloat = 70
        let keySpacing: CGFloat = 8
        
        for (rowIndex, row) in keyRows.enumerated() {
            let rowWidth = CGFloat(row.count) * (keySize + keySpacing) - keySpacing
            var xOffset = (canvasSize.width - rowWidth) / 2
            let yPos = yOffset + 20 + CGFloat(rowIndex) * (keySize + keySpacing)
            
            for char in row {
                let keyRect = CGRect(x: xOffset, y: yPos, width: keySize, height: keySize)
                UIColor.white.setFill()
                UIBezierPath(roundedRect: keyRect, cornerRadius: 8).fill()
                
                let font = UIFont.systemFont(ofSize: 28, weight: .medium)
                let attrs: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: UIColor.black]
                let textSize = String(char).size(withAttributes: attrs)
                let textX = xOffset + (keySize - textSize.width) / 2
                let textY = yPos + (keySize - textSize.height) / 2
                String(char).draw(at: CGPoint(x: textX, y: textY), withAttributes: attrs)
                
                xOffset += keySize + keySpacing
            }
        }
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
        let context = CGContext(
            data: CVPixelBufferGetBaseAddress(buffer),
            width: cgImage.width,
            height: cgImage.height,
            bitsPerComponent: 8,
            bytesPerRow: CVPixelBufferGetBytesPerRow(buffer),
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue
        )
        
        context?.draw(cgImage, in: CGRect(x: 0, y: 0, width: cgImage.width, height: cgImage.height))
        CVPixelBufferUnlockBaseAddress(buffer, [])
        
        return buffer
    }
}

enum ExportError: Error {
    case pixelBufferCreationFailed
    case writerFailed
}
```

---

## AI Service (Claude API)

### AIService.swift
```swift
import Foundation

class AIService {
    private let apiKey: String
    private let baseURL = "https://api.anthropic.com/v1/messages"
    
    init(apiKey: String) {
        self.apiKey = apiKey
    }
    
    struct GenerationRequest {
        let prompt: String
        let genre: String
        let mood: String
        let length: MessageLength
    }
    
    enum MessageLength: Int {
        case short = 8
        case medium = 15
        case long = 25
    }
    
    func generateConversation(request: GenerationRequest) async throws -> [GeneratedMessage] {
        let systemPrompt = """
        You are a creative writer that generates realistic text message conversations.
        Generate a conversation based on the user's prompt.
        
        Rules:
        - Use exactly 2 characters: "Person A" (sender) and "Person B" (receiver)
        - Generate exactly \(request.length.rawValue) messages
        - Match the requested genre: \(request.genre)
        - Match the requested mood: \(request.mood)
        - Make it feel realistic with natural texting patterns
        - Include occasional typos, abbreviations, and emojis where appropriate
        
        Output format (JSON array):
        [
            {"sender": "A", "text": "message text"},
            {"sender": "B", "text": "reply text"},
            ...
        ]
        
        Only output the JSON array, nothing else.
        """
        
        let userPrompt = "Generate a \(request.mood) \(request.genre) text conversation about: \(request.prompt)"
        
        let requestBody: [String: Any] = [
            "model": "claude-sonnet-4-20250514",
            "max_tokens": 2000,
            "messages": [
                ["role": "user", "content": userPrompt]
            ],
            "system": systemPrompt
        ]
        
        var urlRequest = URLRequest(url: URL(string: baseURL)!)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        urlRequest.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        urlRequest.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        let (data, _) = try await URLSession.shared.data(for: urlRequest)
        let response = try JSONDecoder().decode(ClaudeResponse.self, from: data)
        
        guard let content = response.content.first?.text else {
            throw AIError.emptyResponse
        }
        
        // Parse JSON array from response
        guard let jsonData = content.data(using: .utf8),
              let messages = try? JSONDecoder().decode([GeneratedMessage].self, from: jsonData) else {
            throw AIError.parseError
        }
        
        return messages
    }
}

struct ClaudeResponse: Codable {
    let content: [ContentBlock]
}

struct ContentBlock: Codable {
    let text: String
}

struct GeneratedMessage: Codable {
    let sender: String
    let text: String
}

enum AIError: Error {
    case emptyResponse
    case parseError
}
```

---

## Audio Service (System Sounds)

### AudioService.swift
```swift
import AudioToolbox

class AudioService {
    static let shared = AudioService()
    
    var soundsEnabled = true
    
    // System Sound IDs (built into iOS - no files needed!)
    private let sendSoundID: SystemSoundID = 1004      // SMS sent swoosh
    private let receiveSoundID: SystemSoundID = 1007   // SMS received ding  
    private let typingSoundID: SystemSoundID = 1104    // Keyboard click
    
    private init() {}
    
    func playSendSound() {
        guard soundsEnabled else { return }
        AudioServicesPlaySystemSound(sendSoundID)
    }
    
    func playReceiveSound() {
        guard soundsEnabled else { return }
        AudioServicesPlaySystemSound(receiveSoundID)
    }
    
    func playTypingSound() {
        guard soundsEnabled else { return }
        AudioServicesPlaySystemSound(typingSoundID)
    }
    
    // Play sound with vibration
    func playSendWithHaptic() {
        guard soundsEnabled else { return }
        AudioServicesPlayAlertSound(sendSoundID)
    }
}

// Useful iOS System Sound IDs:
// 1004 - Sent message (SMS swoosh) ✓
// 1007 - SMS received tone ✓
// 1104 - Keyboard click ✓
// 1000 - New mail
// 1001 - Mail sent
// 1105 - Lock sound
// 1106 - Unlock sound
```

**Benefits of System Sounds:**
- Zero sound files to manage
- Built into every iOS device
- Users recognize the sounds
- No licensing issues
- Upgrade to custom sounds later if needed

---

## Implementation Steps

### Phase 1: Project Setup (Day 1-2)
```
1. Create new Xcode project (iOS App, SwiftUI, SwiftData)
2. Setup folder structure as defined above
3. Add SwiftData models (Character, Message, Conversation)
4. Configure app icon and launch screen
5. Setup RevenueCat SDK
```

### Phase 2: Core UI (Day 3-5)
```
1. Build HomeView with conversation list
2. Build NewConversationView (setup screen)
3. Build ChatEditorView with message bubbles
4. Implement character switching
5. Add message CRUD operations
```

### Phase 3: Video Export (Day 6-10)
```
1. Implement VideoExportService with AVFoundation
2. Build frame-by-frame rendering
3. Add typing animation logic
4. Implement typing indicator
5. Add keyboard overlay
6. Test all export formats (9:16, 1:1, 16:9)
7. Add sound effects
```

### Phase 4: AI Integration (Day 11-13)
```
1. Setup FastAPI backend (or direct API calls)
2. Implement AIService with Claude API
3. Build AIGeneratorView UI
4. Connect generation to editor
5. Add loading states and error handling
```

### Phase 5: Monetization (Day 14-16)
```
1. Configure RevenueCat products
2. Build PaywallView
3. Implement premium feature gating
4. Add watermark for free users
5. Test subscription flow
```

### Phase 6: Polish & Submit (Day 17-21)
```
1. Add app icon and screenshots
2. Implement analytics
3. Test on multiple devices
4. Fix bugs and edge cases
5. App Store submission
```

---

## Claude Code Prompts

Use these prompts in sequence with Claude Code:

### Prompt 1: Project Setup
```
Create a new iOS SwiftUI project called "ChatTale" with SwiftData.
Setup the folder structure for MVVM architecture with these folders:
- App, Models, Views, ViewModels, Services, Utilities, Resources

Create the data models:
- Character (id, name, colorHex, isMe, avatarEmoji)
- Message (id, text, characterID, timestamp, order)
- Conversation (id, title, createdAt, updatedAt, theme, characters, messages)

Use SwiftData @Model macro for all models.
```

### Prompt 2: Theme System
```
Create a ChatTheme enum with cases: imessage, whatsapp, messenger, discord

Each theme needs:
- displayName
- senderBubbleColor
- receiverBubbleColor  
- backgroundColor
- senderTextColor
- receiverTextColor
- isPremium (only imessage is free)

Also create ExportSettings struct and ExportFormat enum for video export options.
```

### Prompt 3: Home Screen
```
Create HomeView that displays a list of saved conversations.
Include:
- Navigation title "Chat Stories"
- Plus button to create new conversation
- List rows showing title, message count, date
- Empty state when no conversations
- Tab bar with Stories, AI Generate, Settings

Use ConversationViewModel to manage the data.
```

### Prompt 4: Chat Editor
```
Create ChatEditorView for editing a conversation.
Include:
- Navigation bar with back, title, and Export button
- ScrollView with message bubbles (right for "me", left for others)
- Character switcher buttons at bottom
- Text input field with send button
- Support for adding, editing, deleting messages

Create MessageBubbleView component styled like iMessage.
Create ChatEditorViewModel to handle the logic.
```

### Prompt 5: Video Export Service
```
Create VideoExportService using AVFoundation.

Implement exportVideo() that:
1. Creates AVAssetWriter for MP4 output
2. Renders frames showing messages appearing with typing animation
3. Each character types out one letter at a time
4. Shows "..." typing indicator before each message
5. Supports different speeds (slow, normal, fast)
6. Supports formats: 9:16 (1080x1920), 1:1 (1080x1080), 16:9 (1920x1080)
7. Optional keyboard overlay at bottom
8. Reports progress via callback

Use UIGraphicsImageRenderer to draw each frame.
```

### Prompt 6: Export UI
```
Create ExportView screen with:
- Video preview area showing animation
- Format picker (TikTok 9:16, Instagram 1:1, YouTube 16:9)
- Typing speed slider
- Toggle options: show keyboard, typing sounds, typing indicator, dark mode
- Export button with progress indicator
- Share sheet after export completes

Create ExportViewModel to manage state and call VideoExportService.
```

### Prompt 7: AI Generator
```
Create AIGeneratorView screen with:
- Text area for story prompt
- Genre picker (Drama, Comedy, Romance, Horror, Mystery)
- Mood selector (Funny, Dramatic, Scary, Romantic)
- Length options (Short 5-10, Medium 10-20, Long 20-30)
- Generate button with loading state
- Navigate to editor with generated conversation

Create AIService that calls Claude API to generate conversations.
Create AIGeneratorViewModel to manage the flow.
```

### Prompt 8: Paywall & Premium
```
Setup RevenueCat integration for subscriptions.

Create PaywallView showing:
- Free tier features (3 exports/day, watermark, iMessage only, 2 characters)
- Premium features (unlimited, no watermark, all themes, AI generator)
- Monthly $4.99 and Yearly $29.99 options
- Restore purchases button

Create PurchaseService to handle RevenueCat.
Gate premium features throughout the app.
```

---

## API Keys & Configuration

Create `Config.swift`:
```swift
enum Config {
    static let claudeAPIKey = "YOUR_CLAUDE_API_KEY"
    static let revenueCatAPIKey = "YOUR_REVENUECAT_API_KEY"
    
    enum Entitlements {
        static let premium = "premium"
    }
    
    enum Products {
        static let monthly = "chattale_monthly"
        static let yearly = "chattale_yearly"
    }
}
```

---

## App Store Assets Needed

1. **App Icon**: 1024x1024 (chat bubble with play button)
2. **Screenshots**: 6.7", 6.5", 5.5" sizes
3. **Preview Video**: 30 seconds showing the typing animation export
4. **Description**: Focus on AI generation and TikTok/Instagram export
5. **Keywords**: chat story maker, text story, fake text, texting video, AI story

---

## Success Checklist

- [ ] All 5 screens functional
- [ ] Messages save persistently
- [ ] Video export works on all 3 formats
- [ ] Typing animation looks realistic
- [ ] Sound effects play correctly
- [ ] AI generates valid conversations
- [ ] RevenueCat subscription works
- [ ] Free tier has watermark
- [ ] Premium unlocks all features
- [ ] No crashes on iPhone 12-15
- [ ] App Store screenshots ready
- [ ] Privacy policy URL ready

---

Ready to build! 🚀
