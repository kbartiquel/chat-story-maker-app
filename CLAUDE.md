# ChatStoryMaker (ChatTale)

iOS app for creating fake text message conversations and exporting them as videos/screenshots for TikTok, Instagram, and YouTube content creators.

## Tech Stack

### iOS App
- iOS 17+, SwiftUI, SwiftData
- MVVM architecture
- AVFoundation for on-device video export

### Python Server (Cloud Rendering)
- FastAPI + Uvicorn
- Pillow + pilmoji (emoji support)
- MoviePy for video encoding
- Deployable to Render.com (~$7/month)

## Features Implemented

### Core Chat Features
- **Theme**: iMessage only
- **Character management**: Custom names, colors, avatars (emoji or photo)
- **Message types**: Text and image messages
- **Message reactions**: iMessage-style reactions overlapping bubble corners
- **Timestamps**: Editable custom times for storytelling
- **Delivery status**: iMessage-style "Delivered"/"Read" text
- **Drag-to-reorder**: Reorganize message order

### Export
- **Video export**: Realistic chat simulation with:
  - Keyboard typing animation with key highlighting
  - Text appearing character-by-character in input field
  - Typing indicator for received messages
  - Sound effects (server rendering only - MP3 files)
- **Render modes**:
  - **Device**: On-device rendering using AVFoundation (works offline, no audio)
  - **Cloud/Server**: Server-side rendering via Python API (faster, supports emojis + audio)
- **Screenshot export**: Static image with quality options
- **Formats**: TikTok (9:16), Instagram (1:1), YouTube (16:9)
- **Dark mode** option for exports
- **Export History**: Dedicated tab to view/play/share past exports

### AI Generation
- **Claude API integration**: Generate conversations using AI
- **Genres**: Romance, Horror, Comedy, Drama, etc.
- **Moods**: Happy, Sad, Tense, etc.
- **Story lengths**: Short, Medium, Long

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
| `Theme.swift` | iMessage theme colors |
| `ExportSettings.swift` | Video/screenshot export options, RenderMode enum |
| `ExportHistory.swift` | SwiftData model for tracking past exports |

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
- `DeliveryStatusView.swift` - iMessage "Delivered"/"Read" text
- `TimestampView.swift` - Formatted time display
- `TimestampEditorView.swift` - Date/time picker
- `StatusPickerView.swift` - Delivery status selection
- `ReactionPickerView.swift` - Emoji reaction picker

**Export**
- `ExportView.swift` - Export settings with type/format/render mode pickers
- `ExportHistoryView.swift` - Export history list with play/share (sheet + tab versions)

**AI**
- `AIGeneratorView.swift` - AI conversation generator with genre/mood/length options

**Setup**
- `NewConversationView.swift` - Create new conversation
- `CharacterEditorView.swift` - Edit character with photo picker

### ViewModels (`/ViewModels`)
| File | Purpose |
|------|---------|
| `ConversationViewModel.swift` | CRUD conversations, folders, search, duplicate |
| `ChatEditorViewModel.swift` | Message operations, reactions, timestamps, status |
| `ExportViewModel.swift` | Video/screenshot export orchestration |
| `AIGeneratorViewModel.swift` | AI conversation generation with Claude API |
| `SettingsViewModel.swift` | App settings management |

### Services (`/Services`)
| File | Purpose |
|------|---------|
| `VideoExportService.swift` | AVAssetWriter video rendering with typing simulation |
| `ServerExportService.swift` | API client for cloud/server video rendering |
| `ImageExportService.swift` | UIGraphicsImageRenderer screenshot |
| `AudioService.swift` | iOS system sounds for editing feedback |
| `AIService.swift` | Claude API integration for AI story generation |
| `PurchaseService.swift` | Premium features (bypassed - all free) |

## Key Implementation Details

### SwiftData Models
- Use `@Model` macro for persistence
- Raw values for enums (`themeRawValue`, `typeRawValue`, etc.)
- Computed properties for enum access
- `@Attribute(.externalStorage)` for image data
- JSON encoding for arrays (`reactionsData`)

### Video Export
- On-device: AVAssetWriter renders frames with typing animation
- Server: MoviePy renders video with MP3 sound effects (send.mp3/receive.mp3)

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
iMessage-style delivery status:
- "Delivered" - Message received by recipient
- "Read" - Message read by recipient

## Tab Navigation
```
TabView {
  Stories (HomeView)              - Conversation list
  AI Generate (AIGeneratorView)   - AI features
  Exports (ExportHistoryTabView)  - Export history with play/share
  Settings (SettingsView)         - App settings
}
```

## Server/Cloud Rendering

### Overview
The Python server provides an alternative to on-device rendering with better emoji support via `pilmoji`.

### API Endpoints
- `POST /render` - Start render job, returns `job_id`
- `GET /status/{job_id}` - Poll for progress (0.0-1.0)
- `GET /download/{job_id}` - Download rendered video
- `GET /health` - Health check

### Running Locally
```bash
cd server
python -m venv venv
source venv/bin/activate
pip install -r requirements.txt
python main.py  # Runs on http://localhost:8000
```

Update `ServerExportService.baseURL` to your Mac's IP for phone testing:
```swift
static var baseURL: String = "http://YOUR_MAC_IP:8000"
```

### iMessage Styling (renderer.py)
Two rendering modes based on character count:

**1:1 Chat (2 characters)**
- Header: Contact avatar (40px), name, FaceTime video icon
- No avatars or names on message bubbles
- Bubbles have tails (polygon-drawn)
- Header height: 120px

**Group Chat (3+ characters)**
- Header: Simple centered timestamp only
- Avatars (28px) displayed LEFT of received message bubbles
- Character names shown above received messages
- Header height: 50px

### Message Positioning
Messages start from TOP when few messages fit the screen:
```python
if total_all_messages <= available_height:
    # FEW MESSAGES: Start from TOP
    y_offset = message_area_top
else:
    # MANY MESSAGES: Auto-scroll from bottom
    y_offset = message_area_bottom - total_all_messages
```

### Sound Effects
Uses actual MP3 files for authentic sounds:
- `server/assets/send.mp3` - Played when "Me" sends a message
- `server/assets/receive.mp3` - Played when receiving a message

Audio mixing via MoviePy's CompositeAudioClip:
```python
def create_audio(self, total_duration: float):
    from moviepy.editor import AudioFileClip, CompositeAudioClip
    clips = []
    for timing in self.message_timings:
        sound_path = send_path if timing["is_me"] else receive_path
        clip = AudioFileClip(sound_path).set_start(timing["time"])
        clips.append(clip)
    return CompositeAudioClip(clips).set_duration(total_duration)
```

### Avatar Support
Server supports three avatar types (in priority order):
1. **Base64 image** - Photo avatars sent as compressed JPEG base64
2. **Emoji** - Rendered using pilmoji library
3. **Initial** - Fallback colored circle with first letter

### Deployment (Render.com)
1. Push server folder to GitHub
2. Create new Web Service on Render.com
3. Use `render.yaml` for configuration
4. ~$7/month for basic instance

## Premium Features
All premium features bypassed - app is fully free:
- `PurchaseService.isPremium` always returns `true`
- No paywall/RevenueCat integration

## File Structure
```
ChatStoryMaker/
├── README.md                 <- App features documentation
├── CLAUDE.md                 <- Technical reference (this file)
├── CLAUDE-CODE-SETUP.md      <- Original setup instructions
├── CLAUDE-CODE-PROMPTS.md    <- Development prompts
├── server/                   <- Python server for cloud rendering
│   ├── main.py               <- FastAPI server with /render, /status, /download
│   ├── renderer.py           <- Video rendering engine (iMessage styling)
│   ├── models.py             <- Pydantic models for API
│   ├── requirements.txt      <- Python dependencies
│   ├── render.yaml           <- Render.com deployment config
│   ├── README.md             <- Server documentation
│   └── assets/               <- Sound effect files
│       ├── send.mp3          <- Sound for sent messages
│       └── receive.mp3       <- Sound for received messages
└── ios/
    ├── ChatStoryMaker.xcodeproj
    └── ChatStoryMaker/
        ├── ChatStoryMakerApp.swift
        ├── ContentView.swift
        ├── Models/
        │   ├── Conversation.swift
        │   ├── Character.swift
        │   ├── Message.swift
        │   ├── MessageType.swift
        │   ├── Folder.swift
        │   ├── Theme.swift
        │   ├── ExportSettings.swift
        │   └── ExportHistory.swift
        ├── Views/
        │   ├── Home/
        │   ├── Editor/
        │   ├── Export/
        │   ├── AI/
        │   │   └── AIGeneratorView.swift
        │   └── Setup/
        ├── ViewModels/
        │   ├── ConversationViewModel.swift
        │   ├── ChatEditorViewModel.swift
        │   ├── ExportViewModel.swift
        │   ├── AIGeneratorViewModel.swift
        │   └── SettingsViewModel.swift
        ├── Services/
        │   ├── VideoExportService.swift
        │   ├── ServerExportService.swift
        │   ├── ImageExportService.swift
        │   ├── AudioService.swift
        │   ├── AIService.swift
        │   └── PurchaseService.swift
        └── Utilities/
```
