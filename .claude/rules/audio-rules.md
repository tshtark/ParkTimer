---
paths:
  - "ParkTimer/Audio/AudioManager*"
  - "ParkTimer/Resources/Sounds/**"
---

# Audio Rules (CRITICAL — must play over user's music)

Parking alerts MUST play over Spotify/Apple Music. This is a proven pattern from RoundTimer.

1. **AVAudioSession** — `.ambient` category with `.mixWithOthers` option. Set in `configure()`, called from `ContentView.onAppear`.

2. **AVAudioPlayer only** — NEVER use `AudioServicesPlaySystemSound`. It bypasses the audio session entirely and will interrupt user's music.

3. **Bundled .wav files** — Sound files live in `Resources/Sounds/`. System sound paths (`/System/Library/Audio/UISounds/`) do NOT exist on real iOS devices. Always use `Bundle.main.url(forResource:withExtension:)`.

4. **Preload sounds** — Call `preloadSounds()` during `configure()` to avoid first-play latency. Each sound gets its own `AVAudioPlayer` instance stored in the `players` dictionary.

5. **Volume levels** — Warning at 0.6, expired at 0.9. Loud enough to hear in a pocket/bag when walking.

6. **Background note** — AudioManager only plays sounds when the app is in the foreground. When backgrounded, alerts come through `UNUserNotificationCenter` local notifications with system notification sounds.
