# Textery - TODO

## Completed
- [x] AI Story Generation feature (OpenAI/Anthropic integration)
- [x] Aptabase analytics integration (App Key: A-US-7778178477)
- [x] Onboarding screens (4 animated pages)
- [x] App renamed from ChatStoryMaker to Textery
- [x] Usage limits (3 free video exports, 5 free AI generations)
- [x] Screenshot export with Long Screenshot + Paginated modes
- [x] RevenueCat SDK integrated (replaced mock SubscriptionService)
- [x] Free trial toggle removed (App Store compliance)
- [x] Yearly subscription plan added to paywall
- [x] StoreKit configuration file for simulator testing
- [x] Server deployed to Render.com (Standard tier - 2GB RAM)
- [x] iOS app updated with production URL
- [x] Memory-efficient video renderer (streams to ffmpeg)
- [x] Render queue limiter (max 2 concurrent renders)
- [x] Input field text wrapping for long messages
- [x] Color scheme updated (Option 3: Coral branding, iOS Blue UI, Green action buttons)

## Remaining Tasks

### 1. App Store Connect Products (Priority: High) - DONE
- [x] Complete product metadata in App Store Connect
- [x] Products ready to submit

### 2. Create App Icon (Priority: High)
- Design Textery app icon
- Export for all required sizes (1024x1024 for App Store, plus device sizes)
- Add to Assets.xcassets/AppIcon

### 3. Fix Export Screen (Priority: High)
- Redesign/fix the export screen UI (current layout not right)
- Review and improve export options layout

### 4. Update Paywall UI (Priority: Medium)
- Redesign paywall to be more visually appealing
- Improve plan selection cards layout
- Add better visual hierarchy for pricing

### 5. Xcode Project Rename (Priority: Low)
- Rename Xcode project folder from `ChatStoryMaker` to `Textery`
- Update scheme names
- Update target names
- Update Info.plist display name

### 6. App Store Submission Prep
- App icon for all sizes
- Screenshots for App Store
- App description and keywords
- Privacy policy URL (https://kimbytes.com/textery/privacy.html)
- Terms of service URL (https://kimbytes.com/textery/terms.html)

### 7. Testing
- [ ] Test full AI generation flow end-to-end
- [x] Test video export with server
- [ ] Test paywall/purchase flow with Sandbox tester
- [ ] Test onboarding on fresh install

### 8. Video Export Enhancements (Priority: Low)
- [ ] Keyboard key sound: Add individual key tap sounds when typing
- [ ] Keyboard mistake simulation: Simulate typos and corrections

## Configuration

### RevenueCat
- API Key: `appl_xxogGQbwdYHFSXVQcHXhZOukkKb`
- Entitlement: `premium`
- Products: `chatstorymaker_annual`, `chatstorymaker_weekly`

### Bundle ID
- `com.kimbytes.chatstorymaker`

### Server
- Production: `https://chat-story-maker.onrender.com`
- Tier: Standard ($25/month, 2GB RAM)
- Queue: Max 2 concurrent renders
- Local: `cd server && uvicorn main:app --host 0.0.0.0 --port 8000 --reload`

### Render Settings
- Python: 3.11 (set via PYTHON_VERSION env var)
- Start Command: `server/ $ uvicorn main:app --host 0.0.0.0 --port $PORT`
- Root Directory: `server/`
