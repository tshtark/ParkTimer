---
name: build-verify
description: Build the ParkTimer app, install on simulator, and take a screenshot to verify it works
---

# Build & Verify

Run the full build-install-screenshot cycle for the ParkTimer app.

## Steps

1. Regenerate the Xcode project from project.yml:
   ```
   xcodegen generate
   ```

2. Use XcodeBuildMCP to build and run on the simulator:
   - Call `mcp__XcodeBuildMCP__build_run_sim` to build, install, and launch

3. Wait 2 seconds for the app to launch, then take a screenshot:
   - Call `mcp__XcodeBuildMCP__screenshot`

4. If the build fails, show the errors clearly and suggest fixes.

5. If the build succeeds and the screenshot looks correct, report success.
