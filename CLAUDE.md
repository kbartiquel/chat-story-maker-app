# ChatStoryMaker (ChatTale)

iOS app for creating fake text message conversations and exporting them as videos/screenshots for TikTok, Instagram, and YouTube content creators.

## Tech Stack
- iOS 17+, SwiftUI, SwiftData
- MVVM architecture
- AVFoundation for video export

## Features Implemented

### Core Chat Features
- **Multiple themes**: iMessage, WhatsApp, Messenger, Discord
- **Character management**: Custom names, colors, avatars (emoji or photo)
- **Message types**: Text and image messages
- **Message reactions**: iMessage-style reactions overlapping bubble corners
- **Timestamps**: Editable custom times for storytelling
- **Delivery status**: WhatsApp checkmarks OR iMessage text (user choice per conversation)
- **Drag-to-reorder**: Reorganize message order

### Export
- **Video export**: Realistic chat simulation with:
  - Keyboard typing animation with key highlighting
  - Text appearing character-by-character in input field
  - Typing indicator for received messages
  - Programmatically generated send/receive sound effects
  - Audio mixed into video
- **Screenshot export**: Static image with quality options
- **Formats**: TikTok (9:16), Instagram (1:1), YouTube (16:9)
- **Dark mode** option for exports

### Organization
- **Folders**: Create colored folders to organize conversations
- **Search**: Search by title or message content
- **Duplicate**: Deep copy conversations as templates

## Architecture

### Models (`/Models`)
| File | Purpose |
|------|---------|
| `Conversation.swift` | Main container with characters, messages, theme, folder |
| `Character.swift` | Name, color, avatar (emoji/photo), isMe flag |
| `Message.swift` | Text/image, reactions, status, timestamps |
| `MessageType.swift` | Enums: MessageType, DeliveryStatus, ReceiptStyle, Reaction |
| `Folder.swift` | Folder organization |
| `Theme.swift` | ChatTheme enum with colors |
| `ExportSettings.swift` | Video/screenshot export options |

### Views (`/Views`)

**Home**
- `HomeView.swift` - Main list with search, folders, swipe actions
- `FolderManagementView.swift` - Create/edit/delete folders
- `ConversationRowView.swift` - List row display
- `EmptyStateView.swift` - No conversations placeholder

**Editor**
- `ChatEditorView.swift` - Main chat editor with reorder mode
- `MessageBubbleView.swift` - Chat bubble with image/reactions/status support
- `MessageInputView.swift` - Text input + photo picker
- `CharacterSwitcherView.swift` - Character selection buttons
- `MessageReactionsView.swift` - iMessage-style reaction pills
- `DeliveryStatusView.swift` - Checkmarks or text status
- `TimestampView.swift` - Formatted time display
- `TimestampEditorView.swift` - Date/time picker
- `StatusPickerView.swift` - Delivery status selection
- `ReactionPickerView.swift` - Emoji reaction picker

**Export**
- `ExportView.swift` - Export settings with type/format pickers
- `VideoPreviewView.swift` - Preview component (inline in ExportView)

**Setup**
- `NewConversationView.swift` - Create new conversation
- `CharacterEditorView.swift` - Edit character with photo picker

### ViewModels (`/ViewModels`)
| File | Purpose |
|------|---------|
| `ConversationViewModel.swift` | CRUD conversations, folders, search, duplicate |
| `ChatEditorViewModel.swift` | Message operations, reactions, timestamps, status |
| `ExportViewModel.swift` | Video/screenshot export orchestration |

### Services (`/Services`)
| File | Purpose |
|------|---------|
| `VideoExportService.swift` | AVAssetWriter video rendering with realistic typing simulation |
| `ImageExportService.swift` | UIGraphicsImageRenderer screenshot |
| `SoundGenerator.swift` | Programmatic send/receive sound generation (WAV) |
| `AudioService.swift` | Send/receive sound effects for editing |
| `HapticManager.swift` | Haptic feedback |
| `PurchaseService.swift` | Premium features (bypassed - all free) |

## Key Implementation Details

### SwiftData Models
- Use `@Model` macro for persistence
- Raw values for enums (`themeRawValue`, `typeRawValue`, etc.)
- Computed properties for enum access
- `@Attribute(.externalStorage)` for image data
- JSON encoding for arrays (`reactionsData`)

### Video Export with Audio
Video export combines rendered frames with programmatically generated audio:
```swift
// SoundGenerator creates PCM audio samples
let sendSound = SoundGenerator.shared.generateSendSound()    // Ascending swoosh
let receiveSound = SoundGenerator.shared.generateReceiveSound() // Two-tone ding

// Audio written as WAV, combined with video via AVMutableComposition
```

### Keyboard Rendering
Realistic iOS keyboard with key highlighting:
```swift
// Full QWERTY layout with special keys
let row1 = ["q", "w", "e", "r", "t", "y", "u", "i", "o", "p"]
let row2 = ["a", "s", "d", "f", "g", "h", "j", "k", "l"]
let row3 = ["z", "x", "c", "v", "b", "n", "m"]
// + shift, delete, 123, emoji, space, return

// Currently typed key is highlighted
let isHighlighted = highlightedKey?.lowercased() == char
```

### Video Export Fix (Simulator)
Pixel buffer format must use BGRA for Simulator compatibility:
```swift
kCVPixelFormatType_32BGRA
CGBitmapInfo.byteOrder32Little.rawValue | CGImageAlphaInfo.premultipliedFirst.rawValue
```

### Reactions Positioning
iMessage-style reactions overlap bubble corners using ZStack:
- Sender: `alignment: .topLeading`, offset `x: -8, y: -12`
- Receiver: `alignment: .topTrailing`, offset `x: 8, y: -12`

### Receipt Styles
Per-conversation setting in `Conversation.receiptStyle`:
- `.whatsapp` - Single/double/blue checkmarks
- `.imessage` - "Delivered"/"Read" text labels

## Tab Navigation
```
TabView {
  Stories (HomeView)        - Conversation list
  AI Generate (AIGeneratorView) - AI features
  Settings (SettingsView)   - App settings
}
```

## Premium Features
All premium features bypassed - app is fully free:
- `PurchaseService.isPremium` always returns `true`
- All themes unlocked
- No paywall/RevenueCat integration

## File Structure
```
ChatStoryMaker/
├── README.md                 <- App features documentation
├── CLAUDE.md                 <- Technical reference (this file)
├── CLAUDE-CODE-SETUP.md      <- Original setup instructions
├── CLAUDE-CODE-PROMPTS.md    <- Development prompts
└── ios/
    ├── ChatStoryMaker.xcodeproj
    └── ChatStoryMaker/
        ├── ChatStoryMakerApp.swift
        ├── Models/
        │   ├── Conversation.swift
        │   ├── Character.swift
        │   ├── Message.swift
        │   ├── MessageType.swift
        │   ├── Folder.swift
        │   ├── Theme.swift
        │   └── ExportSettings.swift
        ├── Views/
        │   ├── ContentView.swift
        │   ├── Home/
        │   ├── Editor/
        │   ├── Export/
        │   │   └── ExportView.swift
        │   └── Setup/
        ├── ViewModels/
        │   ├── ConversationViewModel.swift
        │   ├── ChatEditorViewModel.swift
        │   └── ExportViewModel.swift
        ├── Services/
        │   ├── VideoExportService.swift
        │   ├── ImageExportService.swift
        │   ├── SoundGenerator.swift
        │   ├── AudioService.swift
        │   ├── HapticManager.swift
        │   └── PurchaseService.swift
        └── Utilities/
```
