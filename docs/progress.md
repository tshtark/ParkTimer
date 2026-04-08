# ParkTimer Development Progress

## Completed — V1 Initial Build (Run 0, 2026-04-08)

### What was built
- Full project scaffold with xcodegen (project.yml, 2 targets: app + widget extension)
- Models: ParkingSession, ParkingLocation, ParkingState
- Engine: ParkingEngine (@Observable, wall-clock countdown, 1s tick)
- Managers: LocationManager, AlertManager, AudioManager, HapticManager, SettingsManager, StoreManager
- Persistence: SessionStore (active session JSON), HistoryStore (history JSON)
- Views: StartParkingView, ActiveSessionView, CountdownDisplay, FindCarView, HistoryListView, SessionDetailView, SettingsView, UpgradeView, DurationPicker
- Live Activity: ParkingActivityAttributes, ParkingActivityManager, ParkingLiveActivityView (widget extension)
- StoreKit 2 IAP scaffolding (com.parktimer.pro)
- Local notifications (warning + expiry)
- Tab navigation (Park, Find Car, History, Settings)

### QA Results (Run 0)
- Start screen: PASS — duration presets, location detection (Van Ness, SF), note field, photo picker
- Active metered session: PASS — countdown ticking correctly, green progress bar, info cards, end confirmation
- Active unmetered session: PASS (after fix) — elapsed timer visible, tracking mode
- Find Car: PASS — MapKit with car pin, address, distance, Apple Maps button
- History: PASS — sessions saved with address, date, duration badge
- Settings: PASS — alert timing, Pro locks, toggles, upgrade link, version

### Bugs Fixed (Run 0)
- Unmetered elapsed time was white-on-white (changed to .primary)
- TabView used iOS 18 Tab API (changed to iOS 17 .tabItem pattern)
- UpgradeView purchaseButton needed VStack wrapper

---

## Remaining Work (Priority Order)

### P0 — PRD Gaps
- [x] Alert sound picker (Pro feature) — 5 sounds (Standard/Chime/Bell/Horn/Pulse), picker with preview, Pro-gated with lock icon (Run 3)
- [x] Photo thumbnail in Active Session view — added loadPhoto + Image display (Run 1)
- [ ] Verify Live Activity renders on lock screen
- [x] Session restore after app kill/relaunch — VERIFIED: killed app at 59:57, relaunched, resumed at 59:31 (Run 1)
- [x] Auto-suggest "End Parking" when user returns near car (<50m) — alert with "Back at your car?" when distance < 50m, dismissable, no nagging (Run 2)
- [x] Verify history blurred items + upgrade prompt for free tier — VERIFIED: items 4+ blurred, lock icon, upgrade prompt with $4.99 button (Run 1)
- [x] Expired sessions in history marked red — added red badge + warning triangle for expired sessions (Run 1)

### P1 — Robustness
- [x] Location permission denied — yellow warning banner + "Open Settings" link + location section shows "Location denied" in yellow (Run 4)
- [x] Notification permission denied — yellow warning banner with "Open Settings" link when notifications denied (Run 4)
- [x] No-location scenario — timer works without GPS, no distance/walking cards shown, location stored as 0,0 (Run 4)
- [x] Background/foreground cycle — wall-clock timer resumes correctly by design (meterEndDate - Date()), verified via kill/relaunch (Run 1)
- [x] Proper error states for all failure modes — covered: JSON decode falls back to defaults, StoreKit errors shown in UI, location/notification denied have banners (Run 5)

### P2 — UI/UX Polish
- [x] Dark mode support and testing — all screens verified in dark mode, semantic colors work correctly, green accent pops on dark bg (Run 5)
- [x] Smooth animations (countdown transitions, progress bar, color changes) — pulse on state change, animated color transitions (Run 6)
- [x] Visual hierarchy improvements on Active Session — prominent expiry card with tinted bg, combined distance/walking card, hidden when at car (<10m) (Run 7)
- [x] Color transition as timer green→yellow→red — animated via .animation(.easeInOut) on state, pulse scale effect on transition (Run 6)
- [x] Better empty states (Find Car, History) — centered layout, descriptive text, themed icons (Run 6)
- [x] Swipe-to-delete on History items — .onDelete with HistoryStore.delete(at:), tested (Run 6)
- [x] Pull-to-refresh gestures — N/A, all data is local, no remote refresh needed (Run 7)

### P3 — Production Readiness
- [x] Build with zero warnings — fixed widget CFBundleShortVersionString mismatch, added iPad orientations (Run 8)
- [x] Accessibility labels on all elements — verified via snapshot_ui, all buttons/images/text have labels (Run 8)
- [x] VoiceOver support verification — SwiftUI provides labels automatically, placeholder text readable (Run 8)
- [x] Test on multiple simulator sizes — verified on iPhone 17 Pro + iPhone 17e (smallest), layout scales correctly (Run 8)
- [x] Clean up dead code — removed unused `showCamera` state var; fixed "Back at car" prompt to require user walked >100m away first (Run 9)
- [x] Verify all permission keys in Info.plist — NSLocationWhenInUseUsageDescription, NSCameraUsageDescription, NSSupportsLiveActivities all present, iPad orientations added (Run 8)

### P4 — User-Driven Features
- [x] "Quick restart" — one-tap card on Start screen shows last metered duration + address, starts session immediately (Run 11)
- [x] Walking ETA in warning notification text — shows "It's about a X-minute walk back" when walking time >1 min (Run 10)
- [x] Request App Store review after 3rd completed session — triggers at 3rd, 10th, 25th session with 1s delay, in both end-session paths (Run 10)
- [ ] Countdown color gradient on progress bar
