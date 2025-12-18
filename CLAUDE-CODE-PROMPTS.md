# Claude Code Quick-Start Prompts

Copy and paste these prompts in sequence to Claude Code. Wait for each to complete before moving to the next.

---

## PROMPT 1: Initialize Project

```
Create a new iOS app called "ChatTale" with these specs:

- iOS 17+ deployment target
- SwiftUI lifecycle
- SwiftData for persistence  
- MVVM architecture

Create this folder structure:
```
ChatTale/
├── App/
├── Models/
├── Views/
│   ├── Home/
│   ├── Setup/
│   ├── Editor/
│   ├── Export/
│   ├── AIGenerator/
│   ├── Settings/
│   └── Components/
├── ViewModels/
├── Services/
├── Utilities/
└── Resources/
```

Add a Config.swift file with placeholder API keys for Claude and RevenueCat.
```

---

## PROMPT 2: Data Models

```
In the Models folder, create these SwiftData models:

1. Character.swift:
- id: UUID
- name: String
- colorHex: String  
- isMe: Bool (true = right side sender)
- avatarEmoji: String?
- Computed property `color` that converts hex to SwiftUI Color
- Static defaults: defaultSender ("Me", blue), defaultReceiver ("Alex", green)

2. Message.swift:
- id: UUID
- text: String
- characterID: UUID
- timestamp: Date
- order: Int (for sorting)

3. Conversation.swift:
- id: UUID
- title: String
- createdAt: Date
- updatedAt: Date
- themeRawValue: String
- @Relationship characters: [Character]
- @Relationship messages: [Message]
- Computed sortedMessages property

4. Theme.swift - ChatTheme enum:
- Cases: imessage, whatsapp, messenger, discord
- Properties: displayName, senderBubbleColor, receiverBubbleColor, backgroundColor, senderTextColor, receiverTextColor, isPremium

5. ExportSettings.swift:
- ExportSettings struct with format, typingSpeed, showKeyboard, showTypingIndicator, enableSounds, darkMode
- ExportFormat enum: tiktok (9:16), instagram (1:1), youtube (16:9) with resolution CGSize
- TypingSpeed enum: slow, normal, fast with delay values
```

---

## PROMPT 3: Utilities

```
In Utilities folder, create:

1. Constants.swift with app-wide constants

2. Extensions.swift with:
- Color extension to init from hex string
- Date extension for formatting
- View extension for common modifiers

3. Helpers.swift with utility functions
```

---

## PROMPT 4: Home Screen

```
Create the Home screen in Views/Home/:

1. HomeView.swift:
- NavigationStack with title "Chat Stories"  
- Toolbar with plus button to add new story
- List of saved conversations using ForEach
- Each row shows: icon, title, message count, date
- Tap row navigates to ChatEditorView
- Swipe to delete
- Tab bar at bottom: Stories (selected), AI Generate, Settings

2. ConversationRowView.swift:
- Chat bubble icon in colored circle
- Title as headline
- "X messages" as caption
- Date on trailing side

3. EmptyStateView.swift:
- Large chat icon
- "No Stories Yet" title
- "Create your first chat story" subtitle
- "Create Story" button

Create ViewModels/ConversationViewModel.swift:
- @Published conversations array
- SwiftData modelContext
- CRUD functions: create, update, delete conversation
- Fetch conversations sorted by updatedAt
```

---

## PROMPT 5: Setup Screen

```
Create the New Conversation setup screen in Views/Setup/:

1. NewConversationView.swift:
- Navigation bar with back button and "New Story" title
- Text field for story title
- Characters section showing 2 default characters as cards
- Each character card shows: colored circle, name, "Right/Left side" label
- "Add Character" button (dashed border)
- Theme picker: iMessage, WhatsApp, Messenger, Discord (horizontal buttons)
- "Start Writing" primary button at bottom
- On submit: create conversation and navigate to editor

2. CharacterEditorView.swift (sheet):
- Name text field
- Color picker (preset colors)
- Side picker (Sender/Receiver)
- Save button

3. ThemePickerView.swift:
- Horizontal scroll of theme options
- Selected theme has blue border/background
- Show lock icon on premium themes
```

---

## PROMPT 6: Chat Editor

```
Create the Chat Editor in Views/Editor/:

1. ChatEditorView.swift:
- Navigation bar: back button, conversation title, "Export 🎬" button
- ScrollView with messages
- Messages positioned: isMe on right (blue), others on left (gray)
- Character switcher at bottom (horizontal buttons for each character)
- Text input field with send button
- Long press message for context menu: Edit, Delete, Move Up, Move Down

2. MessageBubbleView.swift:
- Rounded rectangle bubble
- Color based on isMe and theme
- Proper text color contrast
- Tail/pointer toward sender side
- Padding and spacing like iMessage

3. MessageInputView.swift:
- Horizontal stack
- TextField with placeholder "Type message..."
- Circular send button with arrow icon
- Send on button tap or Return key

4. CharacterSwitcherView.swift:
- Horizontal buttons for each character
- Shows character color dot and name
- Selected character is highlighted

Create ViewModels/ChatEditorViewModel.swift:
- @Published messages, activeCharacter
- addMessage(), deleteMessage(), updateMessage(), reorderMessage()
- Save changes to SwiftData
```

---

## PROMPT 7: Export Screen

```
Create the Export screen in Views/Export/:

1. ExportView.swift:
- Navigation bar with back button and "Export Video" title
- Video preview area (dark rounded rect showing chat preview)
- "Preview Animation" button to play typing effect
- Format picker: 3 buttons for TikTok, Instagram, YouTube
- Typing speed slider: Slow - Normal - Fast
- Toggle options in a card:
  - Show keyboard
  - Typing sounds  
  - Show "..." indicator
  - Dark mode
- Export button (full width, blue)
- Show progress bar during export
- Show share sheet when complete

2. VideoPreviewView.swift:
- Animates messages appearing with typing effect
- Shows typing indicator before each message
- Preview at smaller scale

3. ExportProgressView.swift:
- Progress bar with percentage
- Cancel button

Create ViewModels/ExportViewModel.swift:
- @Published settings, isExporting, progress, exportedURL
- startExport() calls VideoExportService
- Handle completion and errors
```

---

## PROMPT 8: Video Export Service

```
Create Services/VideoExportService.swift:

Build a video export service using AVFoundation that creates MP4 videos with typing animation.

Key requirements:
1. Use AVAssetWriter with H.264 codec
2. Support resolutions: 1080x1920 (9:16), 1080x1080 (1:1), 1920x1080 (16:9)
3. 60 FPS output

Animation logic:
1. For each message in order:
   a. Show typing indicator "..." for 0.5 seconds (if enabled)
   b. Type out message one character at a time
   c. Speed based on TypingSpeed setting
   d. Brief pause after message completes
2. Show all previous messages above current typing

Frame rendering with UIGraphicsImageRenderer:
1. Fill background color (theme-based, or black if dark mode)
2. Draw all completed message bubbles from top
3. Draw current typing bubble with cursor "|"
4. Draw typing indicator if active
5. Draw keyboard at bottom if enabled

Implement:
- exportVideo(config:progress:) async throws -> URL
- renderFrame() -> UIImage
- drawBubble() helper
- drawTypingIndicator() helper  
- drawKeyboard() helper
- pixelBuffer(from:) converter

Report progress via callback (0.0 to 1.0).
Return temporary file URL on completion.
```

---

## PROMPT 9: Audio Service

```
Create Services/AudioService.swift:

Simple audio service using iOS SYSTEM SOUNDS (no mp3 files needed).

Use AudioToolbox framework with AudioServicesPlaySystemSound():

1. System Sound IDs to use:
   - Send message: 1004 (SMS sent swoosh)
   - Receive message: 1007 (SMS received) 
   - Keyboard tap: 1104 (keyboard click)

2. Functions:
   - playSendSound() -> AudioServicesPlaySystemSound(1004)
   - playReceiveSound() -> AudioServicesPlaySystemSound(1007)
   - playTypingSound() -> AudioServicesPlaySystemSound(1104)

3. Add a setting to enable/disable sounds
4. Check if user has sounds enabled before playing

Example implementation:
```swift
import AudioToolbox

class AudioService {
    static let shared = AudioService()
    
    var soundsEnabled = true
    
    func playSendSound() {
        guard soundsEnabled else { return }
        AudioServicesPlaySystemSound(1004)
    }
    
    func playReceiveSound() {
        guard soundsEnabled else { return }
        AudioServicesPlaySystemSound(1007)
    }
    
    func playTypingSound() {
        guard soundsEnabled else { return }
        AudioServicesPlaySystemSound(1104)
    }
}
```

No sound files needed - these are built into iOS!
```

---

## PROMPT 10: AI Generator Screen

```
Create the AI Generator in Views/AIGenerator/:

1. AIGeneratorView.swift:
- Navigation bar with back and "AI Story Generator" title
- TextEditor for story prompt with placeholder
- Genre picker dropdown: Drama, Comedy, Romance, Horror, Mystery
- Mood selector (horizontal pills): Funny, Dramatic, Scary, Romantic
- Length options (vertical radio buttons):
  - Short (5-10 messages)
  - Medium (10-20 messages)  
  - Long (20-30 messages)
- "✨ Generate Story" button with gradient background
- Loading overlay during generation
- On success: create conversation and navigate to editor

2. GenrePickerView, MoodPickerView, LengthPickerView as reusable components

Create ViewModels/AIGeneratorViewModel.swift:
- @Published prompt, genre, mood, length, isGenerating
- generateStory() async
- Create conversation from generated messages
```

---

## PROMPT 11: AI Service

```
Create Services/AIService.swift:

Claude API integration for generating chat stories.

1. GenerationRequest struct:
   - prompt: String
   - genre: String
   - mood: String
   - length: MessageLength enum (short=8, medium=15, long=25)

2. generateConversation(request:) async throws -> [GeneratedMessage]

3. API call to Claude:
   - Endpoint: https://api.anthropic.com/v1/messages
   - Model: claude-sonnet-4-20250514
   - System prompt instructs Claude to:
     - Generate realistic text conversation
     - Use "Person A" and "Person B" as senders
     - Match genre and mood
     - Output JSON array only
   
4. Parse response JSON into GeneratedMessage array:
   - sender: String ("A" or "B")
   - text: String

5. Handle errors: network, parsing, empty response
```

---

## PROMPT 12: Settings & Paywall

```
Create Settings and Paywall screens:

1. Views/Settings/SettingsView.swift:
- Premium status banner (if free, show upgrade button)
- Sections:
  - Account: Restore Purchases
  - Export: Default format, Default speed
  - About: Version, Rate App, Privacy Policy, Terms
- Premium badge shows current plan

2. Views/Settings/PaywallView.swift:
- Close button (X) top right
- Premium illustration/icon at top
- "Unlock Premium" title
- Feature comparison:
  - Free: 3 exports/day, watermark, iMessage only, 2 characters
  - Premium: Unlimited, no watermark, all themes, AI generator, unlimited characters
- Subscription options:
  - Monthly $4.99/month (highlight "Most Popular")
  - Yearly $29.99/year (show savings)
- Subscribe button
- Restore purchases link
- Terms and privacy links at bottom

3. Services/PurchaseService.swift:
- RevenueCat integration
- checkPremiumStatus() -> Bool
- purchase(product:) async
- restorePurchases() async
- Entitlement ID: "premium"

4. ViewModels/SettingsViewModel.swift:
- @Published isPremium
- Monitor purchase state
```

---

## PROMPT 13: Premium Gating

```
Add premium feature gating throughout the app:

1. In ConversationViewModel:
- Free users: max 2 characters per conversation
- Track daily export count in UserDefaults
- Free users: max 3 exports per day

2. In ExportViewModel:
- Free exports include watermark (small "Made with ChatTale" text)
- Check export limit before starting

3. In ThemePickerView:
- Show lock icon on WhatsApp, Messenger, Discord
- Tapping locked theme shows paywall

4. In AIGeneratorView:
- Entire feature requires premium
- Show paywall if free user taps Generate

5. In ChatEditorView:
- "Add Character" beyond 2 requires premium

6. Create a PremiumGate view modifier that shows paywall when condition fails
```

---

## PROMPT 14: Polish & Components

```
Create reusable components in Views/Components/:

1. PrimaryButton.swift:
- Full-width rounded button
- Customizable title, color, icon
- Loading state with spinner
- Disabled state

2. CardView.swift:
- White background, rounded corners, shadow
- Generic content wrapper

3. ToggleRow.swift:
- Label on left, toggle on right
- Used in settings/export options

4. SectionHeader.swift:
- Gray uppercase text for section titles

5. Add app-wide styling:
- Consistent spacing/padding
- Color scheme from theme
- Typography scale

6. Add haptic feedback on key actions:
- Send message
- Export complete
- Character switch
```

---

## PROMPT 15: Final Integration

```
Final integration and polish:

1. Update ChatTaleApp.swift:
- Setup SwiftData modelContainer
- Initialize PurchaseService on launch
- Configure app appearance

2. Add proper navigation flow:
- Home -> Setup -> Editor -> Export (full flow)
- Home -> AI Generator -> Editor -> Export (AI flow)
- Settings accessible from tab bar

3. Add error handling:
- Network errors in AI generation
- Export failures
- Storage errors

4. Add loading states throughout

5. Test data migration if models change

6. Add app icon placeholder (1024x1024)

7. Create sample conversation for first launch

8. Add onboarding for first-time users (optional)

Print a summary of all files created and any remaining TODOs.
```

---

## Post-Build Checklist

After running all prompts, verify:

- [ ] App launches without crashes
- [ ] Can create new conversation
- [ ] Can add/edit/delete messages  
- [ ] Can switch between characters
- [ ] Chat bubbles display correctly
- [ ] Export produces valid MP4
- [ ] Typing animation looks realistic
- [ ] AI generation works (need API key)
- [ ] Premium gating works
- [ ] All navigation flows work

## Files You'll Need to Add Manually

1. **App Icon** in Assets.xcassets

2. **API Keys** in Config.swift:
   - Claude API key
   - RevenueCat API key

3. **RevenueCat Setup**:
   - Create products in App Store Connect
   - Configure in RevenueCat dashboard

Note: Sound files NOT needed - we use built-in iOS system sounds!

---

Good luck! 🚀
