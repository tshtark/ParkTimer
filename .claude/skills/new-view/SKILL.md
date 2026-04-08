---
name: new-view
description: Create a new SwiftUI view file with proper structure, preview macro, and correct placement in the ParkTimer project
disable-model-invocation: true
---

# New SwiftUI View

Scaffold a new SwiftUI view file in the ParkTimer project.

## Arguments

- `name` (required): The view name in PascalCase (e.g., "StartParkingView")
- `group` (optional): Subdirectory under Views/ (e.g., "Start", "Active", "FindCar", "History", "Settings"). Defaults to root Views/.

## Steps

1. **Determine file path**:
   - If group is provided: `ParkTimer/Views/{group}/{name}.swift`
   - Otherwise: `ParkTimer/Views/{name}.swift`

2. **Create the view file** with this template:

```swift
import SwiftUI

struct {name}: View {
    var body: some View {
        Text("{name}")
    }
}

#Preview {
    {name}()
}
```

3. **Xcodegen will auto-regenerate** (the PostToolUse hook on Write handles this).

4. **Verify**: Confirm the file was created and mention the file path to the user.

## Conventions

- SwiftUI views are always structs, never classes
- One major view per file
- File name matches the struct name exactly
- `#Preview` macro at the bottom of every view file
- Extract subviews when body exceeds ~40 lines
- Use `@Environment` and `@State` for state injection, minimize prop drilling
- Navigation via `NavigationStack`, not deprecated `NavigationView`
