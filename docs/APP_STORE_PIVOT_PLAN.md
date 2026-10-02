# Textery App Store Pivot Plan

## Goal

Reposition Textery from a concept Apple reads as "create fake conversations" into a fictional dialogue story creator for short-form video content.

The core engine stays:
- AI story generation
- dialogue editing
- video export
- subscriptions
- creator workflow

The product framing changes:
- from a realistic private-message simulator
- to a fictional story-video creation tool

## Why This Is Needed

Apple's latest review response indicates the problem is no longer only screenshots, disclaimers, or metadata. The current concept is being understood as an app that lets users create fake conversations, which Apple said is not appropriate for the App Store.

That means the recovery path is a product pivot, not another small review reply.

## New Product Positioning

### Core Message

Textery helps creators write fictional dialogue stories and turn them into short-form videos for TikTok, Reels, and Shorts.

### Approved Direction

Use language like:
- fictional dialogue stories
- scripted story scenes
- creator-ready story videos
- entertainment and storytelling
- episode-style dialogue creation

Avoid language like:
- fake chats
- fake conversations
- looks real
- prank texts
- realistic messages
- private message simulator

## App Plan

### Product Identity

Keep:
- the Textery brand for now if needed
- the story/video creator positioning

Potential later rename directions if needed:
- Storyline
- ChatTale
- SceneText
- PlotChat
- Dialogue Studio

### UX Direction

The app should feel more like a story tool and less like a believable private messaging recreation.

#### Keep
- character-based dialogue editing
- group stories
- AI generation
- story library
- creator export flow

#### Change
- reduce direct resemblance to a real phone messaging app
- strengthen story framing throughout the editor
- make sample content obviously fictional

### Editor Changes

Recommended changes:
1. Add stronger story framing in the editor header.
   - options:
     - `Story Scene`
     - `Episode`
     - `Scene`
     - `Genre`
2. Keep `Story Mode`, but do not rely on it alone.
3. Add more visible fictional context such as:
   - story title
   - episode title
   - genre tag
   - mood tag
4. Make the header styling slightly less identical to iMessage.
5. Prefer story-like sample content over believable private drama.

### Sample Content Plan

All visible sample/mock/default content should be clearly fictional.

Good directions:
- sci-fi
- fantasy
- absurd comedy
- mystery adventure
- school fantasy
- time travel
- portals
- moon base
- dragons
- skyships

Avoid:
- ex drama
- cheating suspicion
- jealousy fights
- realistic family conflict
- anything that reads like leaked real texts

### Screenshot Plan

#### Safer 5-Screen Order

1. `Create Story Videos Fast`
2. `Shape Every Scene Your Way`
3. `Export For TikTok Reels Shorts`
4. `Keep Story Worlds Organized`
5. `Build Bigger Casts And Twists`

#### Screenshot Rules

- use clearly fictional sample content
- lead with creator/story benefits
- avoid believable private-message conflict
- do not overuse the word `fictional`
- make the whole set feel like storytelling software, not deception software

## Export Plan

### Goal

Keep video export, but make the exported result feel clearly like fictional authored story content rather than a believable real private conversation.

### What To Keep

- video export
- short-form social formats
- typing animation
- keyboard animation if still useful
- sound effects if still useful

### What To Change

1. Add a branded intro card before the conversation begins.
   - include:
     - story title
     - optional episode or scene name
     - `Fictional Story`
     - `Created with Textery`
2. Strengthen the story framing in the video header.
   - stronger than the current small `Story Mode` treatment
3. Make the export UI slightly less identical to a real iMessage capture.
4. Optionally add story metadata:
   - episode
   - genre
   - mood
5. Add a short outro card:
   - `Created with Textery`
   - optional title repeat

### Explicit Constraint

Do not add a persistent watermark over the whole video.

### Minimum Viable Export Pivot

If time is limited, implement:
1. intro card
2. stronger branded story header
3. subtle export styling changes

### Better Export Pivot

Implement:
1. intro card
2. story header
3. episode or genre chip
4. outro card
5. less realistic top-bar styling

### Likely Files

- `server/renderer.py`
- `server/main.py`
- `ios/ChatStoryMaker/Models/ExportSettings.swift`
- `ios/ChatStoryMaker/Views/Export/ExportView.swift`

## Server Plan

### Rendering

Update the video renderer to support story-first export framing.

Needed work:
1. intro card support
2. optional episode/genre metadata rendering
3. stronger story header styling
4. outro card support
5. less realistic message-video presentation

### API / Models

If needed, extend render payloads to include:
- story title
- episode title
- genre
- mood
- intro/outro toggles

Possible changes:
- `server/models.py`
- `server/main.py`
- iOS request payload builders in `ServerExportService.swift`

### Admin / Analytics

No major App Review-driven admin changes are required for the pivot.

Optional later additions:
- track which export style is used
- track story-mode / intro-card usage
- track creator workflow events

### Infrastructure

Current infrastructure can stay:
- Firebase Hosting for admin/legal pages
- Cloud Run API for rendering and AI

No immediate infra redesign is required for the pivot.

## App Store Metadata Plan

### Subtitle Direction

Examples:
- `Fictional Story Video Creator`
- `Create Scripted Chat Stories`
- `Write Story Videos Fast`

### Description Direction

The first sentence should clearly say the app is for fictional dialogue stories and short-form video creation.

Suggested opening direction:

`Textery helps you create fictional dialogue stories and turn them into short-form videos for TikTok, Reels, and Shorts.`

### Review Notes Direction

Review notes should say:
- the app is a fictional storytelling and short-form video creation tool
- sample content and metadata were revised to emphasize fictional stories
- the editor and exports are positioned as scripted entertainment content
- screenshot export is removed and the app is video-only

## Resubmission Plan

### Do Not Do

- do not keep resubmitting the current concept with only minor wording tweaks
- do not use realistic private-drama screenshots
- do not rely on disclaimers alone

### Best Order Of Work

1. Update mock/sample content
2. Update screenshot set
3. Update App Store metadata
4. Update export presentation
5. Resubmit with the new story-video positioning

## Salvage Decision

### Keep Building If

- the real value is AI dialogue creation
- the real value is creator-ready story videos
- you are willing to pivot the framing and export presentation

### Stop If

- the core value proposition is specifically believable fake private conversations

That exact direction is what Apple is rejecting.

## Recommended Next Implementation Steps

1. Update the renderer to add intro card and stronger story header.
2. Refresh screenshot captures using only clearly fictional mock stories.
3. Rewrite App Store subtitle and description around fictional dialogue stories.
4. Review the editor header and make it more obviously story-first.
