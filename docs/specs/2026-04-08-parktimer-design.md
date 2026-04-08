# ParkTimer — Design Spec

**Date:** 2026-04-08
**Status:** Draft
**Author:** Tal + Claude

## Overview

ParkTimer is a paid iPhone app ($4.99 one-time IAP, freemium) that solves two problems:
1. **Metered parking** — countdown timer with smart alerts before your meter expires
2. **Unmetered parking** — track where you parked and how long you've been there

No backend, no accounts, no ads. Local-only data. Leverages Live Activities, Dynamic Island, CoreLocation, and MapKit.

## Product Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Pricing | Freemium — free core + $4.99 IAP | Parking is universal; free tier drives downloads and App Store ranking |
| Relationship to RoundTimer | Separate app | Different audience, different keywords, different value prop |
| Architecture approach | Clean-sheet, inspired by RoundTimer | Simpler engine (single countdown vs. multi-phase intervals), no dead code |
| Live Activity | Free tier | Best viral marketing — people see it on friends' phones |
| Location permissions | "When In Use" only | No geofencing needed; keeps permission dialog simple |

## Target Audience

Anyone who parks a car. Primary segments:
- **Urban drivers** who feed street meters daily and risk tickets
- **Airport/mall/garage parkers** who forget where they parked
- **Occasional drivers** in unfamiliar cities

## Competitive Landscape

| App | Price | Live Activity | Smart Alerts | Find Car | Notes |
|-----|-------|--------------|--------------|----------|-------|
| ParqTime | One-time ~$5 | No | Distance-based | Yes | Closest competitor, no Dynamic Island |
| Parking Time | Free | No | Fixed 10 min | GPS only | Mixed reviews, functionality issues |
| SpotPin | Free | No | Fixed options | Yes + photo | v2.0 recent, basic feature set |
| PayByPhone | Free | No | Yes | No | Payment platform, not a timer |
| **ParkTimer** | **Freemium ($4.99)** | **Yes** | **Distance-aware** | **Yes + photo** | **Modern iOS features as differentiator** |

Key differentiator: **Live Activity + Dynamic Island countdown** — no competitor has this. Glanceable parking status without opening the app.

## Two Modes

### Metered Mode (countdown)
User selects a duration (15m, 30m, 1h, 2h, or custom). App counts down to zero. Alerts before expiry. Live Activity shows remaining time with color states (green → yellow → red).

### Unmetered Mode (count-up)
User taps "No meter — just save my spot." App counts up from start time. No alerts, no color states. Live Activity shows elapsed time in neutral color. Primary value: GPS pin + photo to find your car.

## Data Model

```swift
struct ParkingSession: Codable, Identifiable {
    let id: UUID
    let startDate: Date
    let meterEndDate: Date?          // nil = unmetered (count-up mode)
    let duration: TimeInterval?       // how long was purchased (metered only)
    let location: ParkingLocation
    let note: String?                 // "Level 3, Row B"
    var alertMinutesBefore: Int       // default 10, configurable (paid)
    var isSmartAlertEnabled: Bool     // distance-aware (paid)
}

struct ParkingLocation: Codable {
    let latitude: Double
    let longitude: Double
    let address: String?              // reverse geocoded
    let photoFilename: String?        // JPEG in app documents
}

enum ParkingState {
    case idle                         // no active session
    case active                       // metered, >10 min remaining
    case warning                      // metered, <10 min remaining
    case expired                      // metered, past end date
    case tracking                     // unmetered, counting up
}
```

## Engine & Managers

### ParkingEngine
`@Observable @MainActor` class. Core state machine.

- **1-second tick** (not 0.1s — parking doesn't need sub-second precision)
- **Wall-clock based:** `timeRemaining = meterEndDate - Date()` — immune to tick drift
- **State transitions:** `.idle` → `.active` → `.warning` (at 10 min) → `.expired` (at 0)
- **Callbacks:** `onWarning`, `onExpired`
- **Key methods:**
  - `startMetered(duration:location:)` — begin countdown
  - `startUnmetered(location:)` — begin count-up
  - `extendTime(by minutes:)` — re-fed the meter (paid feature)
  - `stop() -> ParkingSession` — end session, return for history

### LocationManager
Wraps `CLLocationManager`. Responsibilities:
- Save current location as car pin on session start
- Reverse geocode to street address (`CLGeocoder`)
- Track distance to car when app is in foreground (`CLLocation.distance(from:)`)
- Calculate walking time: `distance / 80 meters per minute`

### AlertManager
Wraps `UNUserNotificationCenter`. Critical because the app is backgrounded 99% of the time.
- `scheduleFixedAlert(at: Date)` — fires at `meterEndDate - alertMinutesBefore` (free tier)
- `scheduleSmartAlert(session:currentDistance:)` — factors in walking time (paid tier)
- `cancelAll()` — on session end or time extension
- Notifications fire even when app is killed — this is the primary alert mechanism

### AudioManager
Same pattern as RoundTimer. `.ambient` + `.mixWithOthers` via `AVAudioPlayer`.
- Plays over Spotify/podcasts
- 3 sound events: `.warning`, `.expired`, `.countdownTick`
- Bundled `.wav` files in `Resources/Sounds/`
- Only plays when app is in foreground; local notifications handle background alerts

### HapticManager
Same pattern as RoundTimer. `UIImpactFeedbackGenerator`.
- `.warning` → medium impact
- `.expired` → heavy impact + notification feedback
- Settings toggle to disable

### StoreManager
`StoreKit 2` (modern async API, no server needed).
- Single non-consumable product: `com.parktimer.pro`
- `UserDefaults` flag for unlock state + receipt validation
- Restore purchases in Settings

## Screens & Navigation

TabView with 4 tabs:

### Tab 1: Park (Start / Active)
**Start state (idle):**
- Duration presets: 15m, 30m, 1h, 2h, Custom
- "No meter — just save my spot" link
- Auto-detected location with reverse-geocoded address
- Optional note field
- Optional camera button for photo of parking spot
- "Start Parking" button

**Active state (session running):**
- Large countdown display (metered) or elapsed time (unmetered)
- Progress bar with color states (metered only)
- Info cards: expiry time, alert time, distance to car
- Location with "Directions →" link
- Photo thumbnail (if taken)
- "+ Add Time" button (paid) and "End Parking" button

### Tab 2: Find Car
- MapKit view with car pin and user's current location
- Walking distance and estimated time
- Photo of parking spot (if taken)
- "Open in Apple Maps" button for turn-by-turn walking directions
- Disabled/empty state when no active session

### Tab 3: History (paid feature)
- Scrollable list of past sessions
- Each row: address, date/time range, duration, type (metered/unmetered)
- Expired sessions marked with red warning
- Tap for detail view with map and photo
- Free tier: shows 3 most recent blurred with upgrade prompt

### Tab 4: Settings
- Alert timing (default 10 min, configurable with paid)
- Smart alerts toggle (paid, shows lock icon if free)
- Sounds on/off
- Haptics on/off
- Alert sound picker (paid)
- Upgrade to Pro / Restore Purchases
- About / Privacy Policy

## Live Activity & Dynamic Island

### Dynamic Island — Compact
- Leading: 🅿️ icon
- Trailing: countdown timer with color (green/yellow/red)
- Unmetered: elapsed time in white

### Dynamic Island — Expanded (long press)
- Expiry time ("3:47 PM")
- Countdown timer with color
- Progress bar
- Location name
- Distance to car

### Lock Screen Live Activity
- App icon + "ParkTimer" label
- Location name
- Countdown timer with color
- Progress bar
- Expiry time and alert time
- Expired state: red bar, "METER EXPIRED — Move your car!"

### Color States
- **Green (#4ade80):** >10 minutes remaining
- **Yellow (#fbbf24):** <10 minutes remaining
- **Red (#ff4a4a):** expired

### Unmetered Mode
Neutral white text, elapsed time counting up, no progress bar, no color transitions.

### Technical Implementation
- `Text(timerInterval:countsDown:)` for OS-native countdown rendering
- `ActivityKit.Activity` lifecycle: start on session begin, update at warning threshold, end on session stop
- `TimerActivityAttributes`: session type, location name
- `ContentState`: `endDate`, `colorHex`, `isPaused`, `isExpired`

## Free vs. Paid Feature Split

### Free Tier
- Metered countdown (all presets + custom)
- Unmetered count-up
- GPS car pin (auto-saved)
- Photo of parking spot
- Walking directions (Apple Maps)
- Note field
- Live Activity + Dynamic Island
- Fixed alert at 10 min before expiry
- Sounds and haptics

### Paid Unlock ($4.99 one-time IAP: `com.parktimer.pro`)
- Distance-aware smart alerts
- Custom alert timing (5/10/15/20/30 min)
- Full parking history
- Extend time on running meter
- Multiple alert sound choices

### Upgrade Surfacing
- History tab: 3 most recent sessions blurred with upgrade prompt
- Settings: lock icon on smart alerts and custom timing
- No nag screens, no popups, no countdown walls

## Data Storage

All local, no cloud:
- `activeSession.json` — current session or nil
- `history.json` — array of past `ParkingSession` objects
- `photos/` — JPEG images, referenced by `ParkingLocation.photoFilename`
- `UserDefaults` — settings (alert timing, sounds, haptics) + IAP unlock state
- All stored in app documents directory

## Project Structure

```
ParkTimer/
├── App/              — ParkTimerApp, ContentView (TabView)
├── Models/           — ParkingSession, ParkingLocation, ParkingState
├── Engine/           — ParkingEngine, LocationManager, AlertManager
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

## Technical Notes

1. **Background behavior:** App is backgrounded 99% of the time. All alerts via `UNUserNotificationCenter` scheduled local notifications. Live Activity countdown via `Text(timerInterval:)` — OS-rendered, no background refresh.
2. **Location:** "When In Use" permission only. No geofencing. Distance calculated on foreground return.
3. **Audio:** `.ambient` + `.mixWithOthers` — plays over music. Same proven pattern as RoundTimer.
4. **Swift 6 concurrency:** `@MainActor` on all engine/manager classes. Same conventions as RoundTimer.
5. **xcodegen:** `project.yml` generates `.xcodeproj`. Regenerate after file changes.
6. **iOS 17.0+** deployment target (ActivityKit requirement).
7. **Extend time:** Reschedules the notification and updates the Live Activity `endDate`.
8. **Photo storage:** `UIImagePickerController` or `PhotosUI.PhotosPicker`. Saved as JPEG to app documents, filename stored in model. No Photos library permission needed if using camera only.

## App Store Positioning

- **Name:** ParkTimer — Parking Meter Alert
- **Price:** Free (with $4.99 Pro unlock)
- **Keywords:** parking timer, meter, reminder, find my car, parking alert
- **Pitch:** "Never get a parking ticket again. ParkTimer counts down your meter on your Lock Screen and Dynamic Island, and alerts you before time runs out — even when your phone is in your pocket."
- **Anti-subscription angle:** "Pay once, own forever. No subscriptions, no ads, no accounts."
