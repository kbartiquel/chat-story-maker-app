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

## In Progress

### 1. App Store Connect Products (Priority: High)
- [ ] Complete product metadata in App Store Connect:
  - `chatstorymaker_annual` - needs localization, price
  - `chatstorymaker_weekly` - needs localization, price
- [ ] Wait for products to be "Ready to Submit" status
- [ ] Test purchases with Sandbox tester account

## Remaining Tasks

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

### 7. Publish Backend on Render & Update App (Priority: High)
- Deploy Python server to Render.com
- Configure environment variables:
  - `AI_SERVICE=anthropic` or `openai`
  - `ANTHROPIC_API_KEY` or `OPENAI_API_KEY`
  - Optional: Cloudinary for video storage
- Update iOS app with production URLs:
  - `AIService.baseURL` - for AI story generation
  - `ServerExportService.baseURL` - for video rendering
- Test all endpoints after deployment

### 8. Testing
- [ ] Test full AI generation flow end-to-end
- [ ] Test video export with server
- [ ] Test paywall/purchase flow with Sandbox tester
- [ ] Test onboarding on fresh install

### 9. Video Export Enhancements (Priority: Low)
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
- Local: `http://192.168.1.5:8000`
- Start: `cd server && uvicorn main:app --host 0.0.0.0 --port 8000 --reload`
