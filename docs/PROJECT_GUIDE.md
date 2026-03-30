# Textery Project Guide

## Overview

Textery is an iOS app for creating fictional chat story conversations and exporting them as videos for TikTok, Instagram, and YouTube style content.

The app is positioned as a fictional storytelling tool, not a real messaging simulator. Recent App Store review work tightened that positioning in the product copy, disclaimers, export flow, and policy pages.

## Product Direction

### Core Promise
- Create fictional chat-based stories quickly
- Generate stories manually or with AI
- Export polished video content for short-form social media

### Current Positioning
- Fictional story creation
- Entertainment and creative storytelling
- Video export only

### Things to Avoid in Product or App Store Copy
- "fake chats"
- "looks completely real"
- wording that suggests impersonation or deception
- "screenshots" as a shipped export feature unless reintroduced intentionally

## Tech Stack

### iOS App
- iOS 17+
- SwiftUI
- SwiftData
- MVVM
- RevenueCat for subscriptions
- Aptabase for analytics

### Python Server
- FastAPI + Uvicorn
- Pillow + pilmoji
- ffmpeg
- OpenAI or Anthropic for AI story generation

## Architecture

### Main iOS Areas
- `ios/ChatStoryMaker/Models/`
- `ios/ChatStoryMaker/Views/`
- `ios/ChatStoryMaker/ViewModels/`
- `ios/ChatStoryMaker/Services/`

### Important User Flows
- Stories tab: browse, search, duplicate, organize conversations
- Generate tab: create AI-generated fictional chat stories
- Editor: edit messages, timestamps, characters, reactions, and title
- Export: export video in TikTok, Instagram, or YouTube aspect ratios
- Settings: onboarding replay, premium access, app preferences

### Current Tabs
- Stories
- Generate
- Settings

## Features

### Story Creation
- 1-on-1 and group chat stories
- Custom characters, colors, emoji/photo avatars
- Text and image messages
- Reactions
- Editable timestamps
- Editable group and contact titles
- Reorder messages

### AI Generation
- Topic-based story generation
- Short, medium, long message counts
- Genre and mood support with auto options
- Group name generation
- Staggered timestamps

### Export
- Video export only
- Cloud/server rendering is the main path
- Formats:
  - TikTok 9:16
  - Instagram 1:1
  - YouTube 16:9
- Optional dark mode
- Typing animation, keyboard animation, and sound support

### Monetization
- Free tier limits:
  - 3 video exports
  - 5 AI generations
- Premium unlocks unlimited usage

## Design System

### Core Colors
| Color | Hex | Usage |
|---|---|---|
| Coral | `#E07B5E` | Branding, editor story-mode accents, paywall selected state |
| iOS Blue | `#007AFF` | Tab bar and links |
| Green | `#1A9E6D` | Primary CTAs |
| Gray | `#8E8E93` | Secondary text and borders |

### Typography
- SF Pro Display for titles
- SF Pro Text for body

## Important Project Files

### Repo Guidance
- [AGENTS.md](/Users/kbartiquel/Documents/PROJECTS/ChatStoryMaker/AGENTS.md)
- [TODO.md](/Users/kbartiquel/Documents/PROJECTS/ChatStoryMaker/TODO.md)

### Durable Project Notes
- [PROJECT_MEMORY.md](/Users/kbartiquel/Documents/PROJECTS/ChatStoryMaker/docs/PROJECT_MEMORY.md)

### App Review / Planning
- [appstore-rejection-reply.md](/Users/kbartiquel/Documents/PROJECTS/ChatStoryMaker/appstore-rejection-reply.md)
- [textery-appstore-fix-implementation-plan.md](/Users/kbartiquel/Documents/PROJECTS/ChatStoryMaker/textery-appstore-fix-implementation-plan.md)

## Milestones And Timeline

### Completed Milestones
- AI story generation shipped
- RevenueCat integrated
- Aptabase integrated
- Textery rename completed at the product level
- Onboarding added
- Usage limits added
- Video export working with server rendering
- App Store compliance work started and tightened
- Screenshot export removed from current app/server flow

### Current Phase
- App Store submission hardening
- documentation cleanup
- final product polish

### Current Priorities
1. Final App Store submission prep
2. App icon and screenshots
3. End-to-end testing
4. Xcode/project naming cleanup from `ChatStoryMaker` to `Textery`

## App Store Review Context

### Relevant Review Topic
- Guideline 1.1.6 objectionable or misleading content risk

### Changes Already Made
- fictional-content disclaimer on first launch
- export reminder before video export
- Story Mode bar in the editor
- onboarding copy revised to avoid “looks real” positioning
- Terms page updated to reflect video-only export
- screenshot export plumbing removed from current app and server flow

### Still Manual / Outside Repo
- App Store Connect subtitle
- App Store Connect description
- screenshots submitted in App Store Connect
- review notes text

## Current State Notes

### Important Reality Check
- Some older project docs still describe screenshot export and older positioning.
- Use the current codebase and `docs/PROJECT_MEMORY.md` as the source of truth for current submission posture.
- If older docs conflict with current app behavior, update the docs before using them for store copy or planning.

## Suggested Docs Convention

Store durable project docs in `docs/`:

- `docs/PROJECT_GUIDE.md`
- `docs/PROJECT_MEMORY.md`
- `docs/APP_REVIEW.md`
- `docs/DECISIONS.md`
- `docs/HANDOFF.md`

## Next Recommended Steps

1. Create `docs/APP_REVIEW.md` for App Store notes, reviewer replies, and submission checklists.
2. Reconcile older docs like `AGENTS.md` and `TODO.md` with the current video-only product state.
3. Finish final App Store Connect metadata review before resubmitting.
