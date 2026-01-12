# ChatStoryMaker (ChatTale)

iOS app for creating fake text message conversations and exporting them as videos/screenshots for TikTok, Instagram, and YouTube content creators.

## Tech Stack

### iOS App
- iOS 17+, SwiftUI, SwiftData
- MVVM architecture
- Cloud-based video export (server rendering)

### Python Server
- FastAPI + Uvicorn
- Pillow + pilmoji (emoji support)
- MoviePy for video encoding
- OpenAI GPT / Anthropic Claude for AI generation
- Deployable to Render.com (~$7/month)

## Features Implemented

### Core Chat Features
- **Theme**: iMessage only
- **Character management**: Custom names, colors, avatars (emoji or photo)
- **Message types**: Text and image messages
- **Message reactions**: iMessage-style reactions overlapping bubble corners
- **Timestamps**: Editable custom times per message for storytelling
- **Delivery status**: iMessage-style "Delivered"/"Read" text
- **Drag-to-reorder**: Reorganize message order
- **Group chats**: Support for 2-10 characters with editable group name

### Export
- **Video export**: Server-rendered chat simulation with:
  - Keyboard typing animation with key highlighting
  - Text appearing character-by-character in input field
  - Typing indicator for received messages
  - Sound effects (send.mp3/receive.mp3)
- **Screenshot export**: Static image with quality options
- **Formats**: TikTok (9:16), Instagram (1:1), YouTube (16:9)
- **Dark mode** option for exports
- **Export History**:
  - Dedicated tab to view past exports
  - Tap to play video in sheet player
  - Swipe left for Share/Delete actions

### AI Story Generation
- **Server-side generation**: Uses Python server `/generate` endpoint
- **Dual AI support**: OpenAI GPT or Anthropic Claude (env configurable)
- **Chat types**:
  - 1-on-1 (2 characters)
  - Group chat (3-10 characters with slider)
- **Genres**: Romance, Horror, Comedy, Drama, Mystery, Thriller, Friendship, Family + Custom text input
- **Moods**: Happy, Sad, Tense, Funny, Romantic, Scary, Dramatic, Casual + Custom text input
- **Story lengths**: Short (~10), Medium (~18), Long (~30) messages
- **Group chat names**: AI generates realistic names like "birthday squad", "the boys", "fam"
- **No avatars**: Generated characters use first letter fallback (user can add later)

### Organization
- **Folders**: Create colored folders to organize conversations
- **Search**: Search by title or message content
- **Duplicate**: Deep copy conversations as templates

## Tab Navigation
```
TabView {
  Stories (HomeView)              - Conversation list
  Generate (AIGeneratorView)      - AI story generation
  Exports (ExportHistoryTabView)  - Export history with play/share
  Settings (SettingsView)         - App settings
}
```

## Architecture

### Models (`ios/ChatStoryMaker/Models/`)
| File | Purpose |
|------|---------|
| `Conversation.swift` | Main container with characters, messages, theme, folder, isGroupChat |
| `Character.swift` | Name, color, avatar (emoji/photo), isMe flag |
| `Message.swift` | Text/image, reactions, status, timestamps |
| `MessageType.swift` | Enums: MessageType, DeliveryStatus, ReceiptStyle, Reaction |
| `Folder.swift` | Folder organization |
| `Theme.swift` | iMessage theme colors |
| `ExportSettings.swift` | Video/screenshot export options |
| `ExportHistory.swift` | SwiftData model for tracking past exports |

### Views (`ios/ChatStoryMaker/Views/`)

**Home**
- `HomeView.swift` - Main list with search, folders, swipe actions
- `FolderManagementView.swift` - Create/edit/delete folders
- `ConversationRowView.swift` - List row display
- `EmptyStateView.swift` - No conversations placeholder

**Editor**
- `ChatEditorView.swift` - Main chat editor with reorder mode
- `MessageBubbleView.swift` - Chat bubble with image/reactions/status
- `MessageInputView.swift` - Text input + photo picker
- `CharacterSwitcherView.swift` - Character selection buttons
- `MessageReactionsView.swift` - iMessage-style reaction pills
- `DeliveryStatusView.swift` - "Delivered"/"Read" text
- `TimestampView.swift` - Formatted time display
- `TimestampEditorView.swift` - Date/time picker per message
- `StatusPickerView.swift` - Delivery status selection
- `ReactionPickerView.swift` - Emoji reaction picker

**Export**
- `ExportView.swift` - Export settings (format, dark mode, etc.)
- `ExportHistoryView.swift` - History list with swipe actions, sheet video player

**AI**
- `AIGeneratorView.swift` - Clean UI with genre/mood/length/character count options

**Setup**
- `NewConversationView.swift` - Create new conversation
- `CharacterEditorView.swift` - Edit character with photo picker

### ViewModels (`ios/ChatStoryMaker/ViewModels/`)
| File | Purpose |
|------|---------|
| `ConversationViewModel.swift` | CRUD conversations, folders, search, duplicate |
| `ChatEditorViewModel.swift` | Message operations, reactions, timestamps, status |
| `ExportViewModel.swift` | Video/screenshot export orchestration |
| `AIGeneratorViewModel.swift` | AI generation with custom genre/mood, group name handling |
| `SettingsViewModel.swift` | App settings management |

### Services (`ios/ChatStoryMaker/Services/`)
| File | Purpose |
|------|---------|
| `VideoExportService.swift` | On-device AVAssetWriter rendering (backup) |
| `ServerExportService.swift` | API client for server video rendering |
| `ImageExportService.swift` | UIGraphicsImageRenderer screenshot |
| `AudioService.swift` | iOS system sounds for editing feedback |
| `AIService.swift` | Server API client for AI story generation |
| `PurchaseService.swift` | Premium features (bypassed - all free) |

## Server API

### Endpoints
| Endpoint | Method | Purpose |
|----------|--------|---------|
| `/` | GET | Health check with version |
| `/health` | GET | Simple health check |
| `/render` | POST | Start video render job, returns `job_id` |
| `/status/{job_id}` | GET | Poll render progress (0.0-1.0) |
| `/download/{job_id}` | GET | Download rendered video |
| `/generate` | POST | Generate AI chat story |
| `/ai-status` | GET | Get AI service configuration status |

### Server Files (`server/`)
| File | Purpose |
|------|---------|
| `main.py` | FastAPI server with all endpoints |
| `renderer.py` | Video rendering engine (iMessage styling) |
| `ai_service.py` | AI generation with OpenAI/Claude support |
| `models.py` | Pydantic request/response models |
| `requirements.txt` | Python dependencies |
| `.env.example` | Environment variables template |
| `assets/send.mp3` | Sound for sent messages |
| `assets/receive.mp3` | Sound for received messages |

### Environment Configuration (`.env`)
```bash
# AI Service (choose one)
AI_SERVICE=anthropic  # or "openai"

# OpenAI
OPENAI_API_KEY=sk-...
OPENAI_MODEL=gpt-4o

# Anthropic
ANTHROPIC_API_KEY=sk-ant-...
ANTHROPIC_MODEL=claude-sonnet-4-20250514

# Optional: Cloudinary for cloud video storage
CLOUDINARY_CLOUD_NAME=
CLOUDINARY_API_KEY=
CLOUDINARY_API_SECRET=
```

### Running Server Locally
```bash
cd server
python -m venv venv
source venv/bin/activate
pip install -r requirements.txt

# Create .env file with your API keys
cp .env.example .env
# Edit .env with your keys

# Run server
uvicorn main:app --host 0.0.0.0 --port 8000 --reload
```

Update `ServerExportService.baseURL` in iOS to your Mac's IP:
```swift
static var baseURL: String = "http://YOUR_MAC_IP:8000"
```

### AI Generation Request/Response

**Request:**
```json
{
  "topic": "Planning a surprise birthday party",
  "num_messages": 15,
  "genre": "comedy",
  "mood": "happy",
  "num_characters": 4,
  "character_names": null
}
```

**Response:**
```json
{
  "title": "The Surprise Party Disaster",
  "group_name": "party planning committee",
  "characters": [
    {"id": "1", "name": "Me", "is_me": true, "suggested_color": "#007AFF", "suggested_emoji": null},
    {"id": "2", "name": "Sarah", "is_me": false, "suggested_color": "#34C759", "suggested_emoji": null}
  ],
  "messages": [
    {"id": "m1", "character_id": "1", "text": "guys we need to plan this party asap"},
    {"id": "m2", "character_id": "2", "text": "omg yes!! when should we do it?"}
  ]
}
```

- `group_name` is only populated for group chats (3+ characters), null for 1-on-1
- iOS uses `group_name` as conversation title for groups, `title` for 1-on-1

## Video Rendering Details

### iMessage Styling (renderer.py)

**1:1 Chat (2 characters)**
- Header: Contact avatar (40px), name, FaceTime video icon
- No avatars on message bubbles
- Bubbles have tails (polygon-drawn)
- Header height: 120px

**Group Chat (3+ characters)**
- Header: Centered group name (editable)
- Avatars (28px) LEFT of received message bubbles
- Character names above received messages
- No video icon in header
- Header height: 50px

### Message Positioning
```python
if total_all_messages <= available_height:
    # FEW MESSAGES: Start from TOP
    y_offset = message_area_top
else:
    # MANY MESSAGES: Auto-scroll from bottom
    y_offset = message_area_bottom - total_all_messages
```

### Avatar Priority
1. **Base64 image** - Photo avatars (compressed JPEG)
2. **Emoji** - Rendered via pilmoji
3. **Initial** - Colored circle with first letter

### Sound Effects
- `send.mp3` - Played when "Me" sends a message
- `receive.mp3` - Played when receiving a message
- Mixed via MoviePy's CompositeAudioClip

## Key Implementation Details

### SwiftData Models
- Use `@Model` macro for persistence
- Raw values for enums (`themeRawValue`, `typeRawValue`, etc.)
- Computed properties for enum access
- `@Attribute(.externalStorage)` for image data
- JSON encoding for arrays (`reactionsData`)

### Video Export (Simulator Fix)
Pixel buffer format must use BGRA for Simulator compatibility:
```swift
kCVPixelFormatType_32BGRA
CGBitmapInfo.byteOrder32Little.rawValue | CGImageAlphaInfo.premultipliedFirst.rawValue
```

### Reactions Positioning
iMessage-style reactions overlap bubble corners:
- Sender: `alignment: .topLeading`, offset `x: -8, y: -12`
- Receiver: `alignment: .topTrailing`, offset `x: 8, y: -12`

## Premium Features
All premium features bypassed - app is fully free:
- `PurchaseService.isPremium` always returns `true`
- No paywall/RevenueCat integration

## File Structure
```
ChatStoryMaker/
├── CLAUDE.md                 <- This file (technical reference)
├── server/
│   ├── main.py               <- FastAPI server
│   ├── renderer.py           <- Video rendering engine
│   ├── ai_service.py         <- AI generation (OpenAI/Claude)
│   ├── models.py             <- Pydantic models
│   ├── requirements.txt      <- Python dependencies
│   ├── .env.example          <- Environment template
│   └── assets/
│       ├── send.mp3
│       └── receive.mp3
└── ios/
    ├── ChatStoryMaker.xcodeproj
    └── ChatStoryMaker/
        ├── ChatStoryMakerApp.swift
        ├── ContentView.swift
        ├── Models/
        ├── Views/
        │   ├── Home/
        │   ├── Editor/
        │   ├── Export/
        │   ├── AI/
        │   └── Setup/
        ├── ViewModels/
        ├── Services/
        └── Utilities/
```
