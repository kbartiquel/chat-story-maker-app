# Textery - TODO for Tomorrow

## Completed Today
- [x] AI Story Generation feature (OpenAI/Anthropic integration)
- [x] Aptabase analytics integration (App Key: A-US-7778178477)
- [x] Onboarding screens (4 animated pages)
- [x] Paywall implementation (mock RevenueCat)
- [x] App renamed from ChatStoryMaker to Textery
- [x] Usage limits (3 free video exports, 5 free AI generations)

## Ready for Tomorrow

### 1. Create App Icon (Priority: High)
- Design Textery app icon
- Export for all required sizes (1024x1024 for App Store, plus device sizes)
- Add to Assets.xcassets/AppIcon

### 2. Fix Export Screen (Priority: High)
- Redesign/fix the export screen UI (current layout not right)
- Review and improve export options layout

### 3. ~~Finalize Screenshot Export~~ ✅ DONE
- ~~Complete screenshot/image export functionality~~
- ~~Ensure proper rendering and quality~~
- **Two export modes implemented:**
  - **Long Screenshot**: One tall image containing all messages
  - **Paginated**: Auto-split into multiple screen-sized images
- ~~Add UI toggle/picker for selecting export mode~~

### 4. RevenueCat Integration (Priority: High)
- Replace mock `SubscriptionService.swift` with real RevenueCat SDK
- Create products in App Store Connect:
  - `com.kimbytes.chatstorymaker.lifetime` - $29.99
  - `com.kimbytes.chatstorymaker.weekly` - $4.99/week
  - `com.kimbytes.chatstorymaker.monthly` - $9.99/month
  - `com.kimbytes.chatstorymaker.yearly` - $39.99/year
- Configure RevenueCat dashboard with Textery app

### 4b. Update Paywall UI (Priority: High)
- Redesign paywall to be more visually appealing
- Improve plan selection cards layout
- Add better visual hierarchy for pricing
- Removed free trial toggle (App Store compliance)

### 5. Xcode Project Rename (Priority: High)
- Rename Xcode project folder from `ChatStoryMaker` to `Textery`
- Update scheme names
- Update target names
- Update Info.plist display name

### 6. App Store Submission Prep
- App icon for all sizes
- Screenshots for App Store
- App description and keywords
- Privacy policy URL (currently placeholder in PaywallView)
- Terms of service URL (currently placeholder in PaywallView)

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
- Test full AI generation flow end-to-end
- Test video export with server
- Test paywall flow (when RevenueCat is ready)
- Test onboarding on fresh install

### 9. Video Export Enhancements (Priority: Medium)
- [ ] **Keyboard key sound**: Add individual key tap sounds when typing in video export
- [ ] **Keyboard mistake simulation**: Simulate typing mistakes (typos) and corrections for more realistic typing animation

## Notes
- Backend server runs on port 8000
- Start server: `cd server && uvicorn main:app --host 0.0.0.0 --port 8000 --reload`
- Current analytics events tracked in `AnalyticsService.swift`
