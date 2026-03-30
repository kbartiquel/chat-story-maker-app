# Project Memory

This file is maintained as a timeline of important project decisions, fixes, review context, and next steps.

## 2026-03-30

### Context
- Reviewed the app against a prior App Store rejection related to Guideline 1.1.6.
- Goal was to verify whether the app was ready to resubmit and align the codebase with the planned rejection response.

### Decisions
- Treat the app as video-only for export.
- Position Textery clearly as a fictional story creation app for entertainment and short-form video content.
- Keep durable project memory in Markdown files so future AI sessions can reuse it.
- Store durable project notes in the `docs/` folder by default.
- When asked to "save to memory", update a Markdown note in `docs/` instead of relying on chat history.

### Changes Made
- Updated onboarding copy to remove risky wording about "fake" chats that "look completely real".
- Confirmed and kept the first-launch fictional-content disclaimer and export warning.
- Updated the Terms page to say video export only.
- Removed iOS-side screenshot export plumbing:
  - deleted `ios/ChatStoryMaker/Services/ImageExportService.swift`
  - removed screenshot-specific fields from `ios/ChatStoryMaker/Models/ExportSettings.swift`
  - removed image export remnants from `ios/ChatStoryMaker/ViewModels/ExportViewModel.swift`
  - removed screenshot request/response code from `ios/ChatStoryMaker/Services/ServerExportService.swift`
- Removed server-side screenshot endpoint and related models:
  - updated `server/main.py`
  - updated `server/models.py`
  - cleaned a leftover screenshot type reference in `server/renderer.py`

### Verification
- `xcodebuild -project ios/ChatStoryMaker.xcodeproj -scheme ChatStoryMaker -sdk iphonesimulator -configuration Debug build` succeeded.
- `python3 -m py_compile server/main.py server/models.py server/renderer.py` succeeded.
- Searched the app and server for:
  - `fake text conversations`
  - `look completely real`
  - `videos or screenshots`
  - screenshot export identifiers
- Those risky strings and app/server screenshot references were removed from the checked paths.

### App Review Reply Draft
- Suggested reply:

```text
Hello App Review Team,

Thank you for your feedback regarding Guideline 1.1.6.

We have updated the app to more clearly position Textery as a fictional story creation tool for entertainment and short-form video content. The following changes were made in this submission:

1. We removed screenshot export functionality and now support video export only.
2. We added a first-launch disclaimer stating that Textery is for fictional content only and must not be used for impersonation or deception.
3. We added an export reminder reinforcing that exported content is fictional and should be shared responsibly.
4. We added an editor “Story Mode” indicator to better distinguish the app from a real messaging interface.
5. We revised onboarding and in-app wording to emphasize fictional storytelling instead of realistic or deceptive messaging.
6. We updated our Terms page to reflect video-only export and fictional-use positioning.

These changes are intended to make the app’s purpose clear: Textery is for creating fictional chat stories for entertainment and creative storytelling, not for impersonation, deception, or misleading real-world communication.

We respectfully ask that you review this updated version.

Best regards,
Kim
```

### Remaining Submission Check
- Codebase is much closer to safe for resubmission.
- Still verify App Store Connect metadata manually:
  - app subtitle
  - app description
  - screenshots
  - review notes
- Avoid phrases like:
  - "fake chats"
  - "looks real"
  - "screenshots" if the app is now video-only

### Reusable Skill Added
- Added global Codex skill:
  - `/Users/kbartiquel/.codex/skills/memory-update/SKILL.md`
- Purpose:
  - when asked to "save to memory" or "make a portable note", create or update a Markdown memory file in the current project
  - keeps context portable across future AI sessions

### Docs Convention
- Use `docs/PROJECT_MEMORY.md` as the default durable memory file for this repo.
- Use `docs/PROJECT_GUIDE.md` as the durable project overview and architecture reference.
- Future notes can also live in:
  - `docs/APP_REVIEW.md`
  - `docs/DECISIONS.md`
  - `docs/HANDOFF.md`
