# ParkTimer

Parking meter countdown + car finder iPhone app. Freemium ($4.99 IAP), no ads, no accounts, no backend.

## Status: Pre-Development

Design spec complete. Implementation plan pending.

## Documentation

| Doc | Purpose |
|-----|---------|
| `docs/prd.md` | Product vision, features, phases, user stories, market research |
| `docs/specs/2026-04-08-parktimer-design.md` | Technical design spec — architecture, data model, screens |

**Read `docs/prd.md` first** — it has all product decisions and rationale.

## Tech Stack

- **Language:** Swift 6.0, SwiftUI, iOS 17.0+
- **Frameworks:** ActivityKit (Live Activities), AVFoundation (audio), CoreLocation, MapKit
- **Persistence:** JSON files in app documents (not SwiftData)
- **IAP:** StoreKit 2 (non-consumable, no server needed)
- **Project generation:** xcodegen (`project.yml` → `.xcodeproj`)
- **Xcode:** 26.4, simulators: iPhone 17 Pro (iOS 26.4)

## Prerequisites

- **`xcode-select` must point to Xcode.app**, not CommandLineTools: `sudo xcode-select -s /Applications/Xcode.app/Contents/Developer`. Without this, `xcrun simctl` and XcodeBuildMCP fail.

## Commands

```bash
# Regenerate project (REQUIRED after adding/moving/deleting Swift files)
xcodegen generate

# Build for simulator
xcodebuild -project ParkTimer.xcodeproj -scheme ParkTimer \
  -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build

# Build for Tal's iPhone (connected via USB, Developer Mode enabled)
xcodebuild -project ParkTimer.xcodeproj -scheme ParkTimer \
  -destination 'platform=iOS,id=238F2C67-7800-582F-B432-6DC906C0F716' \
  -allowProvisioningUpdates build

# Archive + upload to App Store Connect
xcodebuild -project ParkTimer.xcodeproj -scheme ParkTimer \
  -destination 'generic/platform=iOS' -archivePath /tmp/ParkTimer.xcarchive \
  -allowProvisioningUpdates archive
xcodebuild -exportArchive -archivePath /tmp/ParkTimer.xcarchive \
  -exportOptionsPlist /tmp/ExportOptions.plist -exportPath /tmp/ParkTimerExport \
  -allowProvisioningUpdates
```

## Architecture

```
ParkTimer/
├── App/              — ParkTimerApp, ContentView (TabView)
├── Models/           — ParkingSession, ParkingLocation, ParkingState
├── Engine/           — ParkingEngine (@Observable state machine), LocationManager, AlertManager
├── Audio/            — AudioManager, HapticManager
├── Views/
│   ├── Start/        — StartParkingView, DurationPicker
│   ├── Active/       — ActiveSessionView, CountdownDisplay
│   ├── FindCar/      — FindCarView (MapKit)
│   ├── History/      — HistoryListView, SessionDetailView
│   └── Settings/     — SettingsView, UpgradeView
├── Store/            — StoreManager (StoreKit 2 IAP)
├── Persistence/      — SessionStore, HistoryStore
├── LiveActivity/     — ParkingActivityManager
└── Resources/Sounds/ — warning.wav, expired.wav, tick.wav

ParkTimerWidgetExtension/  — Live Activity + Dynamic Island rendering
```

**ParkingEngine** is `@MainActor @Observable`. 1-second tick, wall-clock based. Two modes: metered (countdown) and unmetered (count-up).

## Key Rules

1. **Audio plays over music** — `.ambient` + `.mixWithOthers` via `AVAudioPlayer` with bundled `.wav` files. NEVER use `AudioServicesPlaySystemSound` (bypasses audio session).
2. **Wall-clock countdown** — `Timer.scheduledTimer` for tick, but remaining time calculated from `meterEndDate - Date()`. Ticks drift; wall clock doesn't.
3. **Background alerts MUST use local notifications** — `UNUserNotificationCenter` with scheduled notifications. The app is backgrounded 99% of the time. In-app timers don't fire when backgrounded.
4. **Swift 6 concurrency** — `@MainActor` on all engine/manager classes. `MainActor.assumeIsolated {}` in Timer closures. Don't call `@MainActor` methods from `App.init()`.
5. **xcodegen regenerate** — after ANY Swift file add/move/delete.
6. **Location: "When In Use" only** — never request "Always" permission. We use scheduled notifications, not geofences.
7. **Photos: camera capture only** — use `UIImagePickerController` or `PhotosUI.PhotosPicker`. No Photos library permission needed for camera-only.
8. **IAP: StoreKit 2 only** — single non-consumable `com.parktimer.pro`. No server validation needed.

## Working Conventions

- Tal is a senior TS/Node developer, zero Swift — Claude writes ALL Swift code
- Tal handles: product decisions, real device testing, App Store listing
- Ship iteratively — validate with real sales before adding complexity
- When uncertain about Swift APIs, check context7 docs first
