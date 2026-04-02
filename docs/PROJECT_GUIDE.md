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
- Google Cloud Run for the live API

### Admin / Hosting
- Firebase Hosting for the admin frontend
- Current live admin URL:
  - `https://textery-6e482.web.app/admin`
- Current live Hosting root:
  - `https://textery-6e482.web.app`
- Dedicated Firebase project:
  - `textery`
- Hosted admin talks to the live API at:
  - `https://textery-api-7uam4panra-uc.a.run.app`

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
- Current paywall direction is one Textery custom paywall layout with no version switching exposed in admin
- RevenueCat now uses the same stable Textery tracking user ID so webhook `app_user_id` matches backend analytics more reliably going forward

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
- [hosting/README.md](/Users/kbartiquel/Documents/PROJECTS/ChatStoryMaker/hosting/README.md)

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
- Firebase Hosting admin deployed
- Lightweight admin analytics dashboard added
- Hosted admin moved onto the dedicated `textery` Firebase project
- Cloud Run API moved onto the user's own Google Cloud project

### Current Phase
- App Store submission hardening
- documentation cleanup
- final product polish
- admin/dashboard infrastructure upgrade

### Current Priorities
1. Final App Store submission prep
2. Firestore migration for admin analytics durability
3. App icon and screenshots
4. End-to-end testing
5. Xcode/project naming cleanup from `ChatStoryMaker` to `Textery`

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
- The live app API currently points to Cloud Run while the admin frontend is hosted separately on Firebase Hosting.
- Admin analytics are currently stored in a server-side JSON file, not Firestore yet.
- Admin now follows the richer Quiz Maker / SocMedAI direction with date filters, funnels, user filters, timelines, and RevenueCat-backed revenue visibility.
- Cost settings and cost reporting were intentionally removed from the admin/dashboard direction.
- Extra custom paywall/version toggles were removed from server settings and admin because Textery only ships one paywall.

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
