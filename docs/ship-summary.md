# ParkTimer — Ship Summary

**Date:** April 9, 2026
**Status:** Code-complete, ready for App Store submission
**Built in:** 30 autonomous development runs + 1 initial build session

## IDs & Configuration

| Item | Value |
|------|-------|
| Bundle ID | com.parktimer.app |
| Widget Bundle ID | com.parktimer.app.widget |
| Team ID | JVZFL2WCHV |
| IAP Product ID | com.parktimer.pro |
| Deployment Target | iOS 17.0 |
| Swift Version | 6.0 |
| Xcode | 26.4 |

## What Was Built

### Core Features (Free)
- **Metered countdown** — 15m/30m/1h/2h presets + custom hours:minutes picker
- **Unmetered tracking** — count-up timer for garages/airports/lots
- **GPS car location** — auto-saved on session start, reverse geocoded to street address
- **Live Activity + Dynamic Island** — countdown on Lock Screen (widget extension)
- **Photo of parking spot** — via PhotosPicker, saved to app documents
- **Note field** — "Level 3, Row B"
- **Find Car** — MapKit view with car pin, walking distance, Directions + Share buttons
- **Find last parked** — shows last session's location even after ending (airport use case)
- **Alert at 10 min before expiry** — local notification via UNUserNotificationCenter
- **Quick Restart** — one-tap card repeats last metered duration at current location
- **Vehicle icon picker** — car, bicycle, truck, motorcycle, scooter (SF Symbols)
- **Audio + haptics** — ambient audio over music, haptic feedback on state changes
- **Session restore** — persists to JSON, resumes on app relaunch (wall-clock based)
- **Auto-suggest end** — "Back at your car?" when user returns within 50m (after being >100m away)

### Pro Features ($4.99 one-time IAP)
- **Smart alerts** — distance-aware, accounts for walking time
- **Custom alert timing** — 5/10/15/20/30 min before expiry
- **Full parking history** — all sessions (free: 3 visible + 3 blurred)
- **Extend time** — add time to a running meter
- **Alert sound picker** — 5 sounds with preview
- **Parking cost tracker** — enter hourly rate, see running cost, total in history
- **Monthly statistics** — sessions, hours parked, total cost at a glance

### Pro Discovery (conversion)
- Welcome sheet on first launch (free features + Pro teaser)
- Pro nudge card on Start screen after 3+ sessions
- Distance-based hint on Active Session when >200m from car
- Blurred monthly stats with "Unlock Stats" button in History
- Blurred history items (3 visible + 3 teaser) with upgrade prompt
- Lock icons on Pro features in Settings
- App Store review request at 3rd, 10th, 25th session

## Project Stats

| Metric | Value |
|--------|-------|
| Swift files | 29 |
| Lines of Swift | ~3,200 |
| Commits | 36 |
| Development runs | 31 (1 build + 30 iterations) |
| Targets | 2 (app + widget extension) |
| Build warnings | 0 |

## Architecture

```
ParkTimer/
├── App/              — ParkTimerApp, ContentView (TabView + state wiring)
├── Models/           — ParkingSession, ParkingLocation, ParkingState, VehicleType
├── Engine/           — ParkingEngine (@Observable state machine), LocationManager, AlertManager
├── Audio/            — AudioManager (AVAudioPlayer, .ambient), HapticManager
├── Views/
│   ├── Start/        — StartParkingView, DurationPicker
│   ├── Active/       — ActiveSessionView, CountdownDisplay
│   ├── FindCar/      — FindCarView (MapKit, last-parked fallback)
│   ├── History/      — HistoryListView (stats + blur), SessionDetailView
│   ├── Settings/     — SettingsView, UpgradeView, AlertSoundPicker
│   └── Components/   — TimeFormatting, WelcomeSheet
├── Store/            — StoreManager (StoreKit 2), SettingsManager
├── Persistence/      — SessionStore, HistoryStore (JSON files)
├── LiveActivity/     — ParkingActivityManager, ParkingActivityAttributes
└── Resources/        — Assets.xcassets (AppIcon), Sounds/ (7 .wav files)

ParkTimerWidgetExtension/  — Live Activity + Dynamic Island rendering
```

## QA Results

| Screen/Flow | Light | Dark | iPhone 17 Pro | iPhone 17e |
|-------------|-------|------|---------------|------------|
| Start screen | PASS | PASS | PASS | PASS |
| Active metered | PASS | PASS | PASS | — |
| Active unmetered | PASS | PASS | PASS | — |
| Find Car (active) | PASS | PASS | PASS | — |
| Find Car (last parked) | PASS | — | PASS | — |
| History (free) | PASS | PASS | PASS | — |
| History (Pro) | PASS | PASS | PASS | — |
| Settings | PASS | PASS | PASS | — |
| Session restore | PASS | — | PASS | — |
| Permission denied | PASS | — | PASS | — |

## Known Limitations

1. **Live Activity** — code written and builds, but not verified on real device (simulator doesn't show Lock Screen Live Activities)
2. **Sound files** — functional synthesized tones; Tal can optionally replace with professionally recorded sounds
3. **StoreKit IAP** — scaffolded with product ID `com.parktimer.pro`; needs App Store Connect product setup to actually process purchases
4. **Notifications** — scheduled correctly in code, but background notification delivery can't be fully tested on simulator

## Files for App Store Submission

| File | Location |
|------|----------|
| App icon (1024x1024, no alpha) | `ParkTimer/Resources/Assets.xcassets/AppIcon.appiconset/icon_1024.png` |
| Screenshots (5 screens) | `docs/screenshots/` |
| Privacy policy | `docs/privacy-policy.md` |
| App Store listing copy | `docs/app-store-listing.md` |

## Commands

```bash
# Build for simulator
xcodebuild -project ParkTimer.xcodeproj -scheme ParkTimer \
  -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build

# Build for Tal's iPhone
xcodebuild -project ParkTimer.xcodeproj -scheme ParkTimer \
  -destination 'platform=iOS,id=238F2C67-7800-582F-B432-6DC906C0F716' \
  -allowProvisioningUpdates build

# Archive + upload
xcodebuild archive -project ParkTimer.xcodeproj -scheme ParkTimer \
  -destination 'generic/platform=iOS' -archivePath /tmp/ParkTimer.xcarchive \
  -allowProvisioningUpdates
xcodebuild -exportArchive -archivePath /tmp/ParkTimer.xcarchive \
  -exportOptionsPlist /tmp/ExportOptions.plist -exportPath /tmp/ParkTimerExport \
  -allowProvisioningUpdates
```

## Next Steps (Tal)

1. Create app listing in App Store Connect
2. Host privacy policy on GitHub Pages → update URL in SettingsView
3. Resize screenshots for 6.7" display (1284x2778)
4. Create iPad screenshots (letterbox iPhone screenshots)
5. Test on real device (especially Live Activity + notifications)
6. Set up IAP product in App Store Connect
7. Archive and upload
8. Submit for review
