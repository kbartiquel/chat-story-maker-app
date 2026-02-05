# Textery - App Design Documentation

## App Overview

**Textery** is an iOS app for creating fake text message conversations and exporting them as videos/screenshots for TikTok, Instagram, and YouTube content creators.

**Tagline:** Create viral chat stories in minutes

**Target Audience:** Social media content creators, storytellers, TikTokers

---

## Design System

### Colors

| Color | Hex | Usage |
|-------|-----|-------|
| Coral | `#E07B5E` | Branding, accents, selected states |
| iOS Blue | `#007AFF` | Tab bar, links, secondary actions |
| Green | `#1A9E6D` | CTA buttons, success states, "Try Free" |
| White | `#FFFFFF` | Backgrounds |
| Black | `#000000` | Primary text |
| Gray | `#8E8E93` | Secondary text, borders |

### Typography

- **Titles:** SF Pro Display, Bold
- **Body:** SF Pro Text, Regular
- **Captions:** SF Pro Text, Regular, smaller size

### Components

- **Buttons:** Rounded corners (12px), full-width for primary actions
- **Cards:** White background, subtle border or shadow
- **Tab Bar:** 3 tabs with SF Symbols icons

---

## App Flow & Screens

### 1. Onboarding (First Launch Only)

**Purpose:** Introduce app features to new users

**Flow:** 4 swipeable pages → Paywall

**Pages:**
1. **Welcome**
   - App icon (animated wiggle)
   - "Create Viral Chat Stories"
   - Subtitle: "Turn your ideas into engaging text conversations"

2. **Feature: AI Generation**
   - Sparkles icon
   - "AI-Powered Stories"
   - "Describe your idea and let AI create the conversation"

3. **Feature: Export**
   - Video icon
   - "Export as Video"
   - "Share directly to TikTok, Instagram, and YouTube"

4. **Feature: Customization**
   - Paintbrush icon
   - "Fully Customizable"
   - "Edit characters, messages, timestamps, and more"

**UI Elements:**
- Page indicator dots at bottom
- "Continue" button on each page
- Skip button (top right, subtle)

---

### 2. Paywall

**Purpose:** Convert users to premium subscribers

**Layout (top to bottom):**
```
┌─────────────────────────────────────────┐
│                    [X]                  │  ← Close button (after delay)
│                                         │
│              [App Icon]                 │  ← Animated wiggle
│                                         │
│          "Unlock Premium"               │  ← Title, bold
│                                         │
│   ○ Unlimited Video Exports             │
│   ○ Unlimited AI Story Generation       │  ← Feature list with
│   ○ All Export Formats                  │     coral icon circles
│   ○ Priority Support                    │
│                                         │
├─────────────────────────────────────────┤
│  YEARLY (Only $0.58/week)          ○    │  ← Plan option
│  FREE for 3 days                SAVE 85%│
│  then $29.99/year                       │
├─────────────────────────────────────────┤
│  MONTHLY (Only $2.50/week)         ○    │
│  $9.99                          SAVE 38%│
│  Billed monthly                         │
├─────────────────────────────────────────┤
│  WEEKLY                            ○    │
│  $0.99 first week           🔥MOST POP  │
│  then $4.99/week                        │
├─────────────────────────────────────────┤
│                                         │
│      [ Try For FREE ]                   │  ← Green button
│                                         │
│   Restore • Privacy • Terms             │  ← Footer links
└─────────────────────────────────────────┘
```

**Plan Card Structure:**
- Plan name: Small (12pt), gray, uppercase (e.g., "YEARLY (Only $0.58/week)")
- Price info: Large (15pt), bold, black (e.g., "FREE for 3 days" or "$29.99")
- Secondary info: Medium (13pt), gray (e.g., "then $29.99/year")
- Radio button: Right side, inner dot when selected
- Badge: Below radio (e.g., "SAVE 85%", "🔥 MOST POPULAR")

---

### 3. Home Tab (Stories)

**Purpose:** List all user's conversations/stories

**Tab Bar Item:** "Stories" with `bubble.left.and.bubble.right.fill` icon

**Layout:**
```
┌─────────────────────────────────────────┐
│  Stories                    [+] [Folder]│  ← Navigation bar
├─────────────────────────────────────────┤
│  🔍 Search stories...                   │  ← Search bar
├─────────────────────────────────────────┤
│                                         │
│  ┌─────────────────────────────────┐    │
│  │ [Avatar] The Surprise           │    │  ← Conversation row
│  │          "omg you won't believe │    │     - Avatar (color circle
│  │           what just happened"   │    │       with initial)
│  │                      2 min ago  │    │     - Title
│  └─────────────────────────────────┘    │     - Last message preview
│                                         │     - Timestamp
│  ┌─────────────────────────────────┐    │
│  │ [Avatar] Birthday Squad 🎂      │    │  ← Group chat example
│  │          "guys the party is..." │    │     (stacked avatars)
│  │                      Yesterday  │    │
│  └─────────────────────────────────┘    │
│                                         │
│  ┌─────────────────────────────────┐    │
│  │ [Avatar] Mom                    │    │
│  │          "call me when you can" │    │
│  │                      3 days ago │    │
│  └─────────────────────────────────┘    │
│                                         │
└─────────────────────────────────────────┘
│  [Stories]    [Generate]    [Settings]  │  ← Tab bar
└─────────────────────────────────────────┘
```

**Empty State:**
- Illustration or icon
- "No stories yet"
- "Create your first chat story"
- [Create Story] button

**Swipe Actions:**
- Swipe left: Delete (red)
- Swipe right: Duplicate (blue)

---

### 4. Generate Tab (AI Generator)

**Purpose:** Create AI-generated chat stories

**Tab Bar Item:** "Generate" with `sparkles` icon

**Layout:**
```
┌─────────────────────────────────────────┐
│  Generate Story                         │  ← Navigation title
├─────────────────────────────────────────┤
│                                         │
│  Story Idea                             │
│  ┌─────────────────────────────────┐    │
│  │ "My best friend told me she's   │    │  ← Text input (multiline)
│  │  been secretly dating my ex..." │    │
│  └─────────────────────────────────┘    │
│                                         │
│  Genre                    [Auto ▼]      │  ← Optional selector
│  ┌────┐ ┌────┐ ┌────┐ ┌────┐           │     (chips/pills)
│  │Drama│ │Comedy│ │Horror│ │Romance│    │
│  └────┘ └────┘ └────┘ └────┘           │
│                                         │
│  Mood                     [Auto ▼]      │
│  ┌────┐ ┌────┐ ┌────┐ ┌────┐           │
│  │Tense│ │Funny│ │Scary│ │Happy│        │
│  └────┘ └────┘ └────┘ └────┘           │
│                                         │
│  Length                                 │
│  ┌────────┐ ┌────────┐ ┌────────┐      │
│  │ Short  │ │ Medium │ │  Long  │      │  ← Short selected by default
│  │   ●    │ │   ○    │ │   ○    │      │
│  └────────┘ └────────┘ └────────┘      │
│                                         │
│  Characters                             │
│  ┌─────────────────────────────────┐    │
│  │  2  ←─────●─────────────────→ 10│    │  ← Slider
│  │     1-on-1          Group Chat  │    │
│  └─────────────────────────────────┘    │
│                                         │
│       [ ✨ Generate Story ]             │  ← Green button
│                                         │
└─────────────────────────────────────────┘
```

**Loading State:**
- Full screen overlay
- Spinner
- "Creating your story..."
- Fun loading messages that rotate

---

### 5. Chat Editor

**Purpose:** Edit and customize the generated/created conversation

**Navigation:** Push from Home or Generate

**Layout:**
```
┌─────────────────────────────────────────┐
│ [<]            [Avatar]           [↑↓][↗]│  ← Back, Contact info
│                 Sarah                    │     (tap to edit name),
│                   >                      │     Reorder, Export
├─────────────────────────────────────────┤
│                                         │
│              iMessage                   │  ← Label at top
│                                         │
│                    ┌──────────────────┐ │
│                    │ hey, r u free    │ │  ← Sender bubble (blue)
│                    │ tonight?         │ │
│                    └──────────────────┘ │
│                              Delivered  │  ← Delivery status
│                                         │
│  ┌──────────────────┐                   │
│  │ omg yes!! what's │                   │  ← Receiver bubble (gray)
│  │ up?? 👀          │                   │
│  └──────────────────┘                   │
│                                         │
│              2:34 PM                    │  ← Timestamp (tappable)
│                                         │
│                    ┌──────────────────┐ │
│                    │ i have HUGE news │ │
│                    └──────────────────┘ │
│                                Read 2:35│
│                                         │
├─────────────────────────────────────────┤
│  [Me]  [Sarah]  [+]                     │  ← Character switcher
├─────────────────────────────────────────┤
│  ┌─────────────────────────────┐  [📷] │  ← Message input
│  │ Message...                  │  [↑]  │
│  └─────────────────────────────┘       │
└─────────────────────────────────────────┘
```

**Message Bubble Features:**
- Long press for context menu:
  - Add Reaction
  - Edit (text only)
  - Show/Hide Time
  - Delivery Status (sender only)
  - Delete

**Group Chat Header:**
- Stacked avatars (up to 3 shown)
- Group name centered
- Tap to edit group name

**Character Switcher:**
- Horizontal scroll of character pills
- Each shows avatar + name
- Selected has coral border
- [+] button to add character (group chat)
- Tap character to select for next message
- Long press to edit character

---

### 6. Character Editor (Sheet)

**Purpose:** Customize character appearance

**Layout:**
```
┌─────────────────────────────────────────┐
│  Edit Character              [Done]     │
├─────────────────────────────────────────┤
│                                         │
│              ┌───────┐                  │
│              │   S   │                  │  ← Avatar preview
│              │       │                  │     (color + initial/emoji/photo)
│              └───────┘                  │
│           [Choose Photo]                │
│                                         │
│  Name                                   │
│  ┌─────────────────────────────────┐    │
│  │ Sarah                           │    │
│  └─────────────────────────────────┘    │
│                                         │
│  Avatar Emoji (optional)                │
│  ┌─────────────────────────────────┐    │
│  │ 👩                              │    │
│  └─────────────────────────────────┘    │
│                                         │
│  Color                                  │
│  ● 🔴 ● 🟠 ● 🟡 ● 🟢 ● 🔵 ● 🟣        │  ← Color picker
│                                         │
│  [ ] This is me (sender)                │  ← Toggle
│                                         │
└─────────────────────────────────────────┘
```

---

### 7. Export View (Sheet)

**Purpose:** Configure and initiate export

**Layout:**
```
┌─────────────────────────────────────────┐
│  Export                      [X]        │
├─────────────────────────────────────────┤
│                                         │
│  Format                                 │
│  ┌─────────┐ ┌─────────┐ ┌─────────┐   │
│  │ TikTok  │ │Instagram│ │ YouTube │   │
│  │  9:16   │ │   1:1   │ │  16:9   │   │
│  │    ●    │ │    ○    │ │    ○    │   │
│  └─────────┘ └─────────┘ └─────────┘   │
│                                         │
│  Type                                   │
│  ┌─────────────┐ ┌─────────────┐       │
│  │    Video    │ │  Screenshot │       │
│  │      ●      │ │      ○      │       │
│  └─────────────┘ └─────────────┘       │
│                                         │
│  [ ] Dark Mode                          │  ← Toggle
│                                         │
│  ─────────────────────────────────────  │
│                                         │
│  Preview                                │
│  ┌─────────────────────────────────┐   │
│  │                                 │   │  ← Live preview
│  │      [Phone Frame Mockup]       │   │
│  │                                 │   │
│  └─────────────────────────────────┘   │
│                                         │
│       [ Export Video ]                  │  ← Green button
│                                         │
└─────────────────────────────────────────┘
```

**Video Export Loading:**
- Progress bar
- "Rendering video..."
- Percentage complete

**After Export:**
- Share sheet automatically opens
- Options: Save to Photos, Share to TikTok, etc.

---

### 8. Settings Tab

**Purpose:** App settings and account management

**Tab Bar Item:** "Settings" with `gearshape.fill` icon

**Layout:**
```
┌─────────────────────────────────────────┐
│  Settings                               │
├─────────────────────────────────────────┤
│                                         │
│  SUBSCRIPTION                           │
│  ┌─────────────────────────────────┐   │
│  │ Premium Status        [Active] ✓│   │
│  │ Manage Subscription          >  │   │
│  │ Restore Purchases            >  │   │
│  └─────────────────────────────────┘   │
│                                         │
│  SUPPORT                                │
│  ┌─────────────────────────────────┐   │
│  │ Rate App                     >  │   │
│  │ Contact Support              >  │   │
│  │ Privacy Policy               >  │   │
│  │ Terms of Service             >  │   │
│  └─────────────────────────────────┘   │
│                                         │
│  ABOUT                                  │
│  ┌─────────────────────────────────┐   │
│  │ Version                   1.0.0 │   │
│  └─────────────────────────────────┘   │
│                                         │
└─────────────────────────────────────────┘
```

---

## Key User Flows

### Flow 1: First Time User
```
App Launch → Onboarding (4 pages) → Paywall → Home (empty) → Generate Tab → Create Story → Edit → Export
```

### Flow 2: Returning User (Premium)
```
App Launch → Home → Tap Story → Edit → Export
```

### Flow 3: AI Story Generation
```
Generate Tab → Enter idea → (Optional: select genre/mood) → Tap Generate → Loading → Auto-navigate to Editor → Customize → Export
```

### Flow 4: Manual Story Creation
```
Home → [+] New Story → Enter title → Choose 1-on-1 or Group → Editor → Add messages manually → Export
```

---

## iMessage Styling Details

### Message Bubbles
- **Sender (Me):** Blue (`#007AFF`), right-aligned, tail on bottom-right
- **Receiver:** Light gray (`#E5E5EA`), left-aligned, tail on bottom-left
- **Border radius:** 18px
- **Padding:** 10px vertical, 14px horizontal

### Delivery Status (Sender only)
- "Delivered" - gray text, right-aligned below bubble
- "Read [time]" - gray text with timestamp

### Timestamps
- Centered, gray text
- Format: "2:34 PM" or "Yesterday 2:34 PM"
- Tappable to edit

### Reactions
- Small pill overlapping top corner of bubble
- Contains emoji + count (e.g., "❤️ 2")
- Positioned: sender = top-left, receiver = top-right

### Group Chat
- Receiver messages show:
  - Small avatar (32px) to the left of bubble
  - Sender name above bubble in gray

---

## App Store Screenshot Suggestions

1. **Hero Shot:** Phone showing chat editor with dramatic conversation
2. **AI Generation:** Generate screen with prompt and "Creating your story..." loading
3. **Export Options:** Export sheet showing TikTok/Instagram/YouTube formats
4. **Customization:** Character editor with color picker
5. **Before/After:** Side by side of prompt → generated story

---

## App Icon

- Background: Coral gradient (`#E07B5E` to lighter shade)
- Foreground: Two chat bubbles (white) overlapping
- Style: Modern, minimal, recognizable at small sizes

---

*Document Version: 1.0*
*Last Updated: February 2026*
