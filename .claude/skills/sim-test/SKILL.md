---
name: sim-test
description: Build, launch, and QA test ParkTimer in the iOS simulator — starts a parking session, screenshots key states, verifies UI
disable-model-invocation: true
---

# Simulator QA Test

Run an interactive QA flow on the ParkTimer app in the iOS Simulator.

## Arguments

- `mode` (optional): "metered" or "unmetered". Defaults to "metered".
- `duration` (optional): Duration preset to tap (e.g., "30m", "1h"). Defaults to "15m" (shortest).

## Steps

1. **Build and launch** the app:
   - Run `xcodegen generate` via Bash
   - Call `mcp__XcodeBuildMCP__build_run_sim` to build, install, and launch
   - Wait 2 seconds for launch

2. **Screenshot the start screen** to verify it loaded:
   - Call `mcp__XcodeBuildMCP__screenshot`
   - Verify the duration presets are visible

3. **Start a parking session**:
   - If metered: tap the duration preset button
   - If unmetered: tap "No meter — just save my spot"
   - Tap "Start Parking"
   - Wait 1 second

4. **Screenshot the active session**:
   - Call `mcp__XcodeBuildMCP__screenshot`
   - Verify: countdown (metered) or elapsed time (unmetered) displayed
   - Verify: location info visible, progress bar shown (metered)

5. **Test Find Car tab**:
   - Tap the "Find Car" tab
   - Call `mcp__XcodeBuildMCP__screenshot`
   - Verify: map visible with car pin

6. **Test End Parking**:
   - Return to Park tab
   - Tap "End Parking"
   - Call `mcp__XcodeBuildMCP__screenshot`
   - Verify: returned to start screen

7. **Report results**:
   - Summarize what was verified at each step
   - Flag any visual issues
   - Show all screenshots to the user

## Tips

- Use `mcp__XcodeBuildMCP__snapshot_ui` to get precise element coordinates when tap-by-label doesn't work
- Simulator location defaults to Apple HQ (Cupertino) — this is fine for testing
