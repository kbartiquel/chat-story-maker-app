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

## 2026-04-01

### Context
- Added a hosted admin/dashboard layer for Textery so remote settings are easier to manage and future sessions can inspect product health from one place.
- Goal was to make Textery closer to the Quiz Maker admin direction while keeping the existing live API untouched.
- Also fixed the paywall layout so plans and the purchase button stay anchored at the bottom.
- Later work on the same day migrated Hosting and Cloud Run fully onto the user's own `textery` project and expanded the admin to match the Quiz Maker / SocMedAI dashboard direction more closely.

### Decisions
- Keep the live app API on Cloud Run:
  - `https://textery-api-7uam4panra-uc.a.run.app`
- Use Firebase Hosting only for the admin frontend.
- Use Firebase account `kimoytech@gmail.com` and dedicated Firebase project `textery` rather than any boss/company project.
- Use the live Hosting site:
  - `https://textery-6e482.web.app`
  - admin at `https://textery-6e482.web.app/admin`
- Keep analytics storage lightweight for now using server-side file-backed storage, with Firestore still the likely next upgrade.
- Follow the richer admin style from Quiz Maker / SocMedAI:
  - date filters
  - funnel presets
  - user filters
  - user timeline table
  - RevenueCat webhook-driven revenue visibility
- Do not keep cost settings or cost reporting in the admin UI, even if the reference dashboards included them.

### Changes Made
- Added Firebase Hosting-ready admin files:
  - `firebase.json`
  - `hosting/README.md`
  - `hosting/public/index.html`
  - `hosting/public/admin/index.html`
  - `hosting/public/admin/styles.css`
  - `hosting/public/admin/app.js`
- Hosted admin now includes:
  - login
  - grouped paywall settings
  - environment/API status
  - analytics summary cards
  - date filter pills
  - funnel filters
  - user filters
  - expandable user timelines
  - revenue reporting
  - raw JSON/settings editor
- Added backend admin analytics plumbing:
  - `server/tracking_manager.py`
  - updated `server/main.py`
  - updated `server/models.py`
- Added app-side backend event forwarding:
  - `ios/ChatStoryMaker/Services/TrackingService.swift`
  - updated `ios/ChatStoryMaker/Services/AnalyticsService.swift`
- Analytics now flow to both:
  - Aptabase
  - Textery backend `/track` endpoint for admin visibility
- Added RevenueCat webhook support on the backend:
  - `POST /webhooks/revenuecat`
  - `POST /revenuecat/webhook`
- Fixed settings reset mismatch so defaults match the intended v3 paywall setup:
  - `server/settings_manager.py`
- Updated old server admin auth handling:
  - `server/admin.html`
- Fixed paywall layout so plans and CTA stay pinned at the bottom:
  - `ios/ChatStoryMaker/Views/Paywall/PaywallView.swift`
- Updated app networking so AI generation and video export requests send user/app identity headers for admin reporting:
  - `ios/ChatStoryMaker/Services/AIService.swift`
  - `ios/ChatStoryMaker/Services/ServerExportService.swift`
  - `ios/ChatStoryMaker/Services/TrackingService.swift`
- Removed cost-reporting UI from the hosted admin after deciding it was irrelevant/noisy for Textery.
- Removed server-side admin cost reporting fields and cost-rate admin routes from the codebase so the admin payload stops surfacing render cost.
- Removed obsolete paywall configuration flags from both the admin and server/app settings layer:
  - `customPaywall`
  - `customPaywallVersion`
- Cleaned the hosted admin dashboard further by removing the `AI / Render Requests` summary card.
- Updated RevenueCat initialization so it uses the same stable Textery tracking ID as backend analytics:
  - `ios/ChatStoryMaker/ChatStoryMakerApp.swift`
  - this makes RevenueCat `app_user_id` line up with Textery backend `user_id` going forward
- Increased the app build number to `1.0 (5)` in:
  - `ios/ChatStoryMaker.xcodeproj/project.pbxproj`

### Deployment / Hosting Notes
- Initial Hosting work briefly used a different Firebase project, but the final intended setup is:
  - Firebase project: `textery`
  - Hosting URL: `https://textery-6e482.web.app`
- Google Cloud Run API is also now deployed from the user's own `textery` project, not the earlier boss-linked setup.
- RevenueCat webhook target for Textery:
  - `https://textery-api-7uam4panra-uc.a.run.app/webhooks/revenuecat`
- The live Cloud Run server was redeployed after the paywall-settings cleanup and now serves `/settings` without the removed custom paywall fields.

### Verification
- `python3 -m py_compile server/main.py server/models.py server/settings_manager.py server/tracking_manager.py` succeeded.
- `xcodebuild -project ios/ChatStoryMaker.xcodeproj -scheme ChatStoryMaker -sdk iphonesimulator -configuration Debug build` succeeded after admin/analytics/paywall changes.
- `node --check hosting/public/admin/app.js` succeeded.
- Firebase Hosting deployment succeeded for:
  - `https://textery-6e482.web.app`
- Authenticated admin endpoint checks succeeded for:
  - `/admin/auth`
  - `/admin/stats`
- Cloud Run deployed successfully to later revisions including `textery-api-00003-7cp`.
- Final same-day server cleanup removed cost reporting in code, but if a future session sees cost still appearing live, verify that the latest Cloud Run revision finished deploying and that the browser is not showing a cached admin payload.
- `docs/PROJECT_GUIDE.md` was updated to match the final Hosting URL and dedicated `textery` project so docs no longer point at the older admin hostname.
- Firebase Hosting redeploy succeeded after removing the extra paywall fields and `AI / Render Requests` card.
- Cloud Run later went live on revision `textery-api-00005-pkl`.
- Live `/settings` now returns only the supported paywall fields and no longer includes:
  - `customPaywall`
  - `customPaywallVersion`
- `xcodebuild -project ios/ChatStoryMaker.xcodeproj -scheme ChatStoryMaker -sdk iphonesimulator -configuration Debug build` succeeded after the RevenueCat `appUserID` fix.
- `xcodebuild -project ios/ChatStoryMaker.xcodeproj -scheme ChatStoryMaker -showBuildSettings` confirmed:
  - `CURRENT_PROJECT_VERSION = 5`
  - `MARKETING_VERSION = 1.0`

### Risks / Next Steps
- Analytics storage is currently file-backed on the API server, so it may not be durable enough for multi-instance Cloud Run behavior.
- Best next infrastructure upgrade:
  - move tracking storage to Firestore
- After testing the new paywall layout on device, fine-tune vertical spacing if needed, but keep plans + button pinned.
- If the product truly no longer uses server render, audit and remove the remaining `/render` export path from app/server code instead of only hiding admin reporting.
- RevenueCat ID matching is now fixed for new/current app identity, but older anonymous RevenueCat users from before the change may still exist under previous IDs unless migrated.

## 2026-04-07

### Context
- Apple replied again on Guideline 1.1.6 and explicitly said: apps that allow users to create fake conversations are not an appropriate concept for the App Store.
- This changed the situation from a metadata/screenshot problem into a product-concept problem.

### Decisions
- Stop treating the App Store issue as a small review fix.
- Do not keep resubmitting the same core concept with only wording or disclaimer changes.
- Pivot Textery from a fake-conversation framing into a fictional dialogue story creator for short-form video content.
- Keep the engine:
  - AI generation
  - dialogue editor
  - video export
  - subscriptions
- Change the product framing, sample content, screenshots, and export presentation so the app reads as authored fictional storytelling rather than realistic private-message recreation.
- Do not add a persistent watermark to exported videos.

### Changes Made
- Created a durable pivot plan at:
  - `docs/APP_STORE_PIVOT_PLAN.md`
- Updated screenshot mock data in:
  - `ios/ChatStoryMaker/Services/ScreenshotMockDataService.swift`
  so seeded stories are clearly fictional instead of realistic private drama.
- Updated screenshot marketing copy in the HTML screenshot system to reduce realism/deception framing and lean into story-video creation.
- Exported refreshed screenshot PNGs with safer marketing copy into:
  - `screenshots/iphone-first-2026/TO UPLOAD/iphone`
  - `screenshots/iphone-first-2026/TO UPLOAD/ipad`
- Started the actual product pivot in code across app UI, AI generation, API models, and renderer.
- App/editor UI now reads more like a story tool:
  - `ios/ChatStoryMaker/Views/Home/HomeView.swift`
  - `ios/ChatStoryMaker/Views/Setup/NewConversationView.swift`
  - `ios/ChatStoryMaker/Views/AIGenerator/AIGeneratorView.swift`
  - `ios/ChatStoryMaker/Views/Editor/ChatEditorView.swift`
  - `ios/ChatStoryMaker/Views/Editor/MessageInputView.swift`
  - `ios/ChatStoryMaker/Views/Export/ExportView.swift`
- The message composer was changed from a live chat bar into a story-writing panel in:
  - `ios/ChatStoryMaker/Views/Editor/MessageInputView.swift`
  - new language includes `SCENE COMPOSER`, `Write the next beat in your story`, `Add Visual`, and `Add Story Beat`
- AI generation was hardened to fictional-story-only in:
  - `server/ai_service.py`
  - `server/main.py`
  - `server/models.py`
  - `ios/ChatStoryMaker/Services/AIService.swift`
- Added a scene-break system so AI can generate interstitial titles such as `3 Hours Later` or `After The Mall`, and conversations can store them:
  - `server/models.py`
  - `server/ai_service.py`
  - `ios/ChatStoryMaker/Models/Conversation.swift`
  - `ios/ChatStoryMaker/Services/AIService.swift`
  - `ios/ChatStoryMaker/ViewModels/AIGeneratorViewModel.swift`
- Export/render flow now supports story-perspective video output instead of relying on a first-person keyboard-typing view:
  - `server/renderer.py`
  - `ios/ChatStoryMaker/Models/ExportSettings.swift`
  - `ios/ChatStoryMaker/Services/ServerExportService.swift`
  - `ios/ChatStoryMaker/Services/VideoExportService.swift`
  - `ios/ChatStoryMaker/ViewModels/ExportViewModel.swift`
- Renderer changes now include:
  - AI-generated scene interstitial cards between dialogue beats
  - story-perspective outgoing lines rendered directly in-scene
  - less dependence on the live keyboard/composer look in exported videos

### Review / Submission Notes
- The critical issue is now the concept itself as Apple understands it, not just the store assets.
- Best salvage path:
  - reframe Textery as a fictional story-video creator
  - make the editor more story-first
  - make export output less like a believable real private conversation
- Do not resubmit the same concept without pivot-level changes.

### Next Steps
- Finish the export pivot from `docs/APP_STORE_PIVOT_PLAN.md` with visual QA of:
  - intro card
  - story header
  - interstitial scene cards
  - non-first-person story pacing
- Update App Store metadata to match the pivot direction.
- Refresh screenshots again using only the new fictional mock stories.
- Verify the live Cloud Run deploy after build `57cec5c0-2cf0-419b-998a-8f3bf645d19f` finishes and confirm the new revision is serving scene breaks/story-perspective render behavior.

### Verification
- `python3 -m py_compile server/ai_service.py server/main.py server/models.py server/renderer.py` succeeded after the scene-break/export pivot.
- `xcodebuild -project ios/ChatStoryMaker.xcodeproj -scheme ChatStoryMaker -sdk iphonesimulator -configuration Debug build` succeeded after the editor/composer and scene-break changes.
- Cloud Run deploy was started for the new story-video renderer build, but at last check the remote Cloud Build was still `WORKING`:
  - build id: `57cec5c0-2cf0-419b-998a-8f3bf645d19f`
  - live revision still serving at that moment: `textery-api-00006-7d2`
