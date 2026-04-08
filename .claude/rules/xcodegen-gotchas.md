---
paths:
  - "project.yml"
  - "**/*.plist"
---

# xcodegen & Build System Gotchas

1. **Info.plist keys in project.yml** — Use `INFOPLIST_KEY_` prefix in `settings.base` for plist entries. Bare keys like `NSSupportsLiveActivities: true` become meaningless build settings. Must be `INFOPLIST_KEY_NSSupportsLiveActivities: true`.

2. **Widget extension Info.plist** — `NSExtension.NSExtensionPointIdentifier` must be set via `info.properties` in project.yml (NOT via `INFOPLIST_KEY_*` build settings). Different pattern from the main app.

3. **Shared files between targets** — Files shared between the app and widget extension (e.g., `ParkingState.swift`, `ParkingActivityAttributes.swift`) must be listed in both targets' sources in `project.yml`.

4. **iPad orientations required** — `INFOPLIST_KEY_UISupportedInterfaceOrientations_iPad` must include all 4 orientations for App Store submission, even though the app is iPhone-only.

5. **App icon no alpha** — `ASSETCATALOG_COMPILER_APPICON_NAME: AppIcon` points to `Assets.xcassets/AppIcon.appiconset/`. The PNG must have no alpha channel or App Store rejects the upload.

6. **Location usage description** — Must set `INFOPLIST_KEY_NSLocationWhenInUseUsageDescription` in project.yml with a clear user-facing string explaining why location is needed.

7. **Camera usage description** — Must set `INFOPLIST_KEY_NSCameraUsageDescription` in project.yml for the parking spot photo feature.
