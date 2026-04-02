# Textery

iOS app for creating fake text message conversations and exporting them as videos/screenshots for TikTok, Instagram, and YouTube content creators.

## Tech Stack

### iOS App
- iOS 17+, SwiftUI, SwiftData
- MVVM architecture
- Cloud-based video export (server rendering)
- RevenueCat for subscriptions

### Python Server
- FastAPI + Uvicorn
- Pillow + pilmoji (emoji support)
- ffmpeg for video encoding (streams frames, memory efficient)
- OpenAI GPT / Anthropic Claude for AI generation
- Deployed on Render.com (Standard tier - $25/month, 2GB RAM)
- Max 2 concurrent renders (queue limiter)

## Design System

### Colors
| Color | Hex | Usage |
|-------|-----|-------|
| Coral | `#E07B5E` | Branding, accents, selected states in paywall |
| iOS Blue | `#007AFF` | Tab bar, links, iMessage sender bubbles |
| Green | `#1A9E6D` | CTA buttons (Subscribe, Generate), success states |
| White | `#FFFFFF` | Backgrounds |
| Black | `#000000` | Primary text |
| Gray | `#8E8E93` | Secondary text, borders |

### Typography
- SF Pro Display for titles
- SF Pro Text for body

## Features Implemented

### Core Chat Features
- **Theme**: iMessage only
- **Character management**: Custom names, colors, avatars (emoji or photo)
- **Message types**: Text and image messages
- **Message reactions**: iMessage-style reactions overlapping bubble corners
- **Timestamps**: Editable custom times per message (tap timestamp to edit)
- **Delivery status**: iMessage-style "Delivered"/"Read" text
- **Drag-to-reorder**: Reorganize message order
- **Group chats**: Support for 2-10 characters with editable group name
- **Editable title**: Tap header to edit conversation/contact name
- **Avatar initials**: Characters show first letter initial (not person icon)

### Export
- **Video export**: Server-rendered chat simulation with:
  - Keyboard typing animation with key highlighting
  - Text appearing character-by-character in input field
  - Typing indicator for received messages
  - Sound effects (send.mp3/receive.mp3)
- **Screenshot export**: Static image with quality options
  - **Long Screenshot mode**: One tall image containing all messages
  - **Range Selection mode**: User selects start/end messages to export
- **Formats**: TikTok (9:16), Instagram (1:1), YouTube (16:9)
- **Dark mode** option for exports

### AI Story Generation
- **Server-side generation**: Uses Python server `/generate` endpoint
- **Dual AI support**: OpenAI GPT or Anthropic Claude (env configurable)
- **Chat types**:
  - 1-on-1 (2 characters)
  - Group chat (3-10 characters with slider)
- **Genres**: Romance, Horror, Comedy, Drama, Mystery, Thriller, Friendship, Family + Custom + Auto
- **Moods**: Happy, Sad, Tense, Funny, Romantic, Scary, Dramatic, Casual + Custom + Auto
- **Default settings**: Short length, Auto genre, Auto mood (AI decides based on story)
- **Story lengths**: Short (8 messages), Medium (12), Long (20)
- **Group chat names**: AI generates realistic names like "birthday squad", "the boys", "fam"
- **Realistic timestamps**: Generated messages have staggered timestamps (15 sec to 3 min apart)
- **Avatar initials**: Generated characters use first letter fallback (user can add photo later)

### Organization
- **Folders**: Create colored folders to organize conversations
- **Search**: Search by title or message content
- **Duplicate**: Deep copy conversations as templates

## Tab Navigation (3 tabs)
```
TabView {
  Stories (HomeView)              - Conversation list
  Generate (AIGeneratorView)      - AI story generation
  Settings (SettingsView)         - App settings
}
```
Note: Exports tab was removed - exports accessed from chat editor

## Paywall Implementation

### Dynamic Paywall Features
- **Per-week price calculation**: Yearly ÷52, Monthly ÷4
- **Dynamic savings badge**: SAVE X% calculated vs weekly price
- **Intro offer support**:
  - Free trial → "FREE for X days", button "Try For FREE", badge "TRY FREE"
  - Paid intro → "$X first week", badge "🔥 MOST POPULAR"
  - No intro → Regular price with "Billed [period]"
- **Smart default selection**: Weekly with paid intro > Yearly > Monthly
- **Plan display order**: Yearly → Monthly → Weekly (top to bottom)

### Plan Card Layout (Quiz Maker AI style)
```
YEARLY (Only $0.58/week)     ← 12pt gray (small header)
$29.99                       ← 15pt BOLD (the big price)    ○
Billed yearly                ← 13pt gray                 SAVE 85%
```

### Debug Test Flags (PaywallView.swift)
```swift
// Set all to false for production
private let testYearlyFreeTrial = false
private let testMonthlyFreeTrial = false
private let testWeeklyPaidIntro = false
private let testWeeklyFreeTrial = false
```

### Subscription Text (for App Store)
```
SUBSCRIPTION
Unlock full access with 1-year, 1-month, or 1-week plans (3-day free trial included)
Payment is charged to iTunes at purchase confirmation
Cancel anytime before trial ends to avoid charges
Subscriptions auto-renew unless turned off before current period ends

Privacy Policy: https://textery-api-7uam4panra-uc.a.run.app/privacy
Terms of Service: https://textery-api-7uam4panra-uc.a.run.app/terms
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
- `ChatEditorView.swift` - Main chat editor with reorder mode, tappable header for title edit
- `MessageBubbleView.swift` - Chat bubble with image/reactions/status, tappable timestamps
- `MessageInputView.swift` - Text input + photo picker
- `CharacterSwitcherView.swift` - Character selection buttons with initials
- `MessageReactionsView.swift` - iMessage-style reaction pills
- `DeliveryStatusView.swift` - "Delivered"/"Read" text
- `TimestampView.swift` - Formatted time display
- `TimestampEditorView.swift` - Date/time picker per message
- `StatusPickerView.swift` - Delivery status selection
- `ReactionPickerView.swift` - Emoji reaction picker

**Export**
- `ExportView.swift` - Export settings (format, dark mode, etc.)

**Paywall**
- `PaywallView.swift` - Dynamic paywall with intro offer support, test flags

**AI**
- `AIGeneratorView.swift` - Clean UI with genre/mood/length/character count options

**Setup**
- `NewConversationView.swift` - Create new conversation
- `CharacterEditorView.swift` - Edit character with photo picker

**Onboarding**
- `OnboardingView.swift` - 4-page onboarding for new users

### ViewModels (`ios/ChatStoryMaker/ViewModels/`)
| File | Purpose |
|------|---------|
| `ConversationViewModel.swift` | CRUD conversations, folders, search, duplicate |
| `ChatEditorViewModel.swift` | Message operations, reactions, timestamps, status |
| `ExportViewModel.swift` | Video/screenshot export orchestration |
| `AIGeneratorViewModel.swift` | AI generation with auto genre/mood, realistic timestamps |
| `SettingsViewModel.swift` | App settings management |

### Services (`ios/ChatStoryMaker/Services/`)
| File | Purpose |
|------|---------|
| `VideoExportService.swift` | On-device AVAssetWriter rendering (backup) |
| `ServerExportService.swift` | API client for server video rendering |
| `ImageExportService.swift` | UIGraphicsImageRenderer screenshot |
| `AudioService.swift` | iOS system sounds for editing feedback |
| `AIService.swift` | Server API client for AI story generation |
| `SubscriptionService.swift` | RevenueCat subscription management |
| `PaywallSettingsService.swift` | Remote paywall configuration |
| `AnalyticsService.swift` | Aptabase analytics |

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
| `/privacy` | GET | Privacy policy HTML page |
| `/terms` | GET | Terms of service HTML page |

### Server Files (`server/`)
| File | Purpose |
|------|---------|
| `main.py` | FastAPI server with all endpoints |
| `renderer.py` | Video rendering engine (iMessage styling) |
| `ai_service.py` | AI generation with OpenAI/Claude, supports "auto" genre/mood |
| `models.py` | Pydantic request/response models |
| `requirements.txt` | Python dependencies |
| `.env.example` | Environment variables template |
| `privacy.html` | Privacy policy page |
| `terms.html` | Terms of service page |
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

Production URL: `https://textery-api-7uam4panra-uc.a.run.app`

### AI Generation Request/Response

**Request:**
```json
{
  "topic": "Planning a surprise birthday party",
  "num_messages": 8,
  "genre": "auto",
  "mood": "auto",
  "num_characters": 4,
  "character_names": null
}
```
- `genre` and `mood` can be "auto" - AI decides based on story topic

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

### Avatar Priority
1. **Base64 image** - Photo avatars (compressed JPEG)
2. **Emoji** - Rendered via pilmoji
3. **Initial** - Colored circle with first letter (NOT person icon)

### Sound Effects
- `send.mp3` - Played when "Me" sends a message
- `receive.mp3` - Played when receiving a message

## Key Implementation Details

### SwiftData Models
- Use `@Model` macro for persistence
- Raw values for enums (`themeRawValue`, `typeRawValue`, etc.)
- Computed properties for enum access
- `@Attribute(.externalStorage)` for image data
- JSON encoding for arrays (`reactionsData`)

### Reactions Positioning
iMessage-style reactions overlap bubble corners:
- Sender: `alignment: .topLeading`, offset `x: -8, y: -12`
- Receiver: `alignment: .topTrailing`, offset `x: 8, y: -12`

## Premium Features & Subscriptions

RevenueCat SDK integrated for subscription management:
- API Key: `appl_xxogGQbwdYHFSXVQcHXhZOukkKb`
- Entitlement: `premium`
- Products: `chatstorymaker_annual`, `chatstorymaker_monthly`, `chatstorymaker_weekly`
- Bundle ID: `com.kimbytes.chatstorymaker`

Free tier limits:
- 3 video exports
- 5 AI generations

Premium unlocks unlimited access.

## Documentation

- `CLAUDE.md` - This file (technical reference)
- `APP_DESIGN_DOCUMENTATION.md` - UI/UX documentation for App Store screenshots
- `TODO.md` - Task tracking

## File Structure
```
ChatStoryMaker/
├── CLAUDE.md                      <- This file
├── APP_DESIGN_DOCUMENTATION.md    <- UI/UX documentation
├── TODO.md                        <- Task tracking
├── server/
│   ├── main.py                    <- FastAPI server
│   ├── renderer.py                <- Video rendering engine
│   ├── ai_service.py              <- AI generation (OpenAI/Claude)
│   ├── models.py                  <- Pydantic models
│   ├── requirements.txt           <- Python dependencies
│   ├── .env.example               <- Environment template
│   ├── privacy.html               <- Privacy policy
│   ├── terms.html                 <- Terms of service
│   └── assets/
│       ├── send.mp3
│       └── receive.mp3
└── ios/
    └── ChatStoryMaker/
        ├── ChatStoryMakerApp.swift
        ├── ContentView.swift
        ├── Models/
        ├── Views/
        │   ├── Home/
        │   ├── Editor/
        │   ├── Export/
        │   ├── Paywall/
        │   ├── AI/
        │   ├── Onboarding/
        │   └── Setup/
        ├── ViewModels/
        ├── Services/
        └── Utilities/
```

## Current TODO

### Completed
- [x] AI Story Generation feature (OpenAI/Anthropic integration)
- [x] Aptabase analytics integration
- [x] Onboarding screens (4 animated pages)
- [x] App renamed from ChatStoryMaker to Textery
- [x] Usage limits (3 free video exports, 5 free AI generations)
- [x] Screenshot export with Long Screenshot + Paginated modes
- [x] RevenueCat SDK integrated
- [x] Server deployed to Render.com
- [x] iOS app updated with production URL
- [x] Memory-efficient video renderer
- [x] Dynamic paywall with intro offer support (Quiz Maker AI style)
- [x] Paywall test flags for debugging
- [x] Removed Exports tab (3-tab navigation)
- [x] Default AI generation: short length, auto genre/mood
- [x] Avatar initials (not person icon)
- [x] Tappable timestamps to edit
- [x] Editable conversation title (tap header)
- [x] Story lengths reduced: Short (8), Medium (12), Long (20)
- [x] Server handles "auto" genre/mood
- [x] Privacy/Terms pages on server
- [x] APP_DESIGN_DOCUMENTATION.md for App Store screenshots

### Remaining Tasks
1. **Create App Icon** - Design and export for all sizes (1024x1024 for App Store)
2. **Xcode Project Rename** - Rename folder/schemes/targets from ChatStoryMaker to Textery
3. **App Store Submission Prep** - Screenshots, description, privacy policy
4. **Testing** - End-to-end testing of AI, video export, paywall, onboarding
