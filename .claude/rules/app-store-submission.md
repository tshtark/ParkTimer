---
paths:
  - "project.yml"
---

# App Store Submission Requirements

Lessons learned from RoundTimer V1.0 submission (April 8, 2026).

## Before archiving
- App icon PNG must have NO alpha channel (flatten with PIL or sips onto opaque background)
- iPad orientations must be declared even for iPhone-only apps: all 4 orientations in `INFOPLIST_KEY_UISupportedInterfaceOrientations_iPad`
- Export compliance: select "None of the algorithms" (app uses zero encryption, zero network)
- Content rights: "Does not contain third-party content"

## Screenshots
- iPhone: 1284x2778 (6.7" display) or 1242x2688 (6.5" display)
- iPad: 2048x2732 (required even for iPhone-only apps — resize iPhone screenshots with black letterboxing)
- Minimum 3 screenshots per device class

## Archive and upload command
```bash
xcodebuild archive -project ParkTimer.xcodeproj -scheme ParkTimer \
  -destination 'generic/platform=iOS' -archivePath /tmp/ParkTimer.xcarchive \
  -allowProvisioningUpdates
xcodebuild -exportArchive -archivePath /tmp/ParkTimer.xcarchive \
  -exportOptionsPlist /tmp/ExportOptions.plist -exportPath /tmp/ParkTimerExport \
  -allowProvisioningUpdates
```

ExportOptions.plist needs: `method: app-store-connect`, `teamID: JVZFL2WCHV`, `destination: upload`.

## App Store Connect
- Privacy: "Data Not Collected" (no network, no analytics)
- Age rating: 4+ (no mature content)
- Privacy policy URL: TBD (create GitHub Pages like RoundTimer)
