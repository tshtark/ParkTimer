# ParkTimer — Product Requirements Document

## Vision

ParkTimer is a simple, paid iPhone app that ensures you never get a parking ticket and never forget where you parked. It combines a smart parking meter countdown with GPS car location tracking, displayed on your Lock Screen and Dynamic Island.

**One-liner:** "Never get a parking ticket again."

## Why This App

### The Problem
1. **Parking tickets from expired meters** — urban drivers feed meters, walk away, lose track of time, and return to a $50-$150 ticket. Setting a basic iPhone timer works but doesn't account for walking time back to the car.
2. **Forgetting where you parked** — in garages, lots, airports, and unfamiliar neighborhoods. "Was it Level 3 or Level 4?"

### Why Existing Apps Fall Short
- **ParqTime** (~$5, one-time) — decent but pre-Dynamic Island, no Live Activities. The killer feature of glanceable countdown on your Lock Screen is missing.
- **Parking Time** (free) — mixed reviews, reliability issues, no modern iOS features.
- **SpotPin** (free) — basic feature set, no smart alerts.
- **PayByPhone/ParkMobile** — payment platforms, not timers. Focused on paying for parking, not managing your time.
- **Built-in iPhone timer** — no location saving, no distance-aware alerts, no "find my car."

### The Opportunity
- **Live Activity + Dynamic Island** — no competitor uses this for parking. It's the single strongest differentiator.
- **Subscription fatigue** — parking apps that charge monthly for what should be a utility are resented. One-time $4.99 IAP is the right model.
- **Universal audience** — everyone who drives parks. Much broader than fitness/workout timers.
- **Anti-subscription positioning** — "Pay once, own forever. No subscriptions, no ads, no accounts." This messaging itself is a selling point.

### Market Validation
- Only 5.2% of App Store apps are paid upfront — the paid-utility space is far less crowded than free/freemium
- Reddit threads consistently complain about subscription-based utilities
- Parking tickets cost $50-$150+ — a $4.99 app that prevents even one ticket pays for itself 10x
- Apps like Procreate and Things 3 prove the one-time purchase model still works

## Target Audience

### Primary Segments
1. **Urban daily drivers** — feed street meters regularly, highest ticket risk, highest willingness to pay
2. **Airport/mall/garage parkers** — "where did I park?" is their primary pain point
3. **Occasional drivers in unfamiliar cities** — tourists, business travelers, visitors

### User Persona
*Alex, 32, lives in San Francisco.* Parks on the street 3-4 times per week. Has gotten 4 parking tickets in the past year ($85 each = $340). Currently sets an iPhone timer but sometimes walks 10 minutes and the timer goes off when they're too far from the car. Would happily pay $5 to not get another ticket.

## User Stories

### Core (Free Tier)
- As a driver, I want to set a countdown for my parking meter so I know when it expires
- As a driver, I want to see my remaining time on my Lock Screen without opening any app
- As a driver, I want to be notified before my meter expires so I can get back in time
- As a driver, I want my car's location saved automatically when I start parking
- As a driver, I want to take a photo of my parking spot so I can find my car in a garage
- As a driver, I want walking directions back to my car with one tap
- As a driver, I want to track how long I've been parked in an unmetered spot

### Premium (Paid $4.99 IAP)
- As a driver, I want alerts that account for my walking distance so I have enough time to get back
- As a driver, I want to choose when to be alerted (5/10/15/20/30 min before expiry)
- As a driver, I want to see my parking history to track expenses or dispute tickets
- As a driver, I want to add time to a running meter when I re-feed it
- As a driver, I want to choose from different alert sounds

## Feature Specification

### Two Modes

**Metered Mode (countdown)**
- User selects duration: 15m, 30m, 1h, 2h, or custom
- App counts down to zero with Live Activity on Lock Screen and Dynamic Island
- Color states: green (>10 min) → yellow (<10 min) → red (expired)
- Alert fires before expiry (fixed 10 min free, configurable/smart with paid)

**Unmetered Mode (count-up)**
- User taps "No meter — just save my spot"
- App counts up from start time
- Live Activity shows elapsed time in neutral white
- No alerts, no color transitions
- Primary value: GPS pin + photo

### Start Screen
- Quick duration presets: 15m, 30m, 1h, 2h, Custom
- "No meter — just save my spot" link
- Auto-detected location with reverse-geocoded address
- Optional note field ("Level 3, Row B")
- Optional camera button for photo of spot
- "Start Parking" button

### Active Session Screen
- Large countdown (metered) or elapsed time (unmetered)
- Progress bar with color states (metered only)
- Info cards: expiry time, alert time, distance to car
- Location with "Directions →" link
- Photo thumbnail (if taken)
- "+ Add Time" button (paid) and "End Parking" button

### Find My Car Screen
- MapKit view with car pin and user's current location
- Walking distance and estimated time
- Photo of parking spot (if taken)
- "Open in Apple Maps" button for walking directions
- Disabled when no active session

### History Screen (paid)
- Scrollable list of past sessions
- Each row: address, date/time range, duration, type
- Expired sessions marked red
- Tap for detail view with map and photo
- Free tier: 3 most recent blurred with upgrade prompt

### Settings Screen
- Alert timing (default 10 min, configurable with paid)
- Smart alerts toggle (paid, lock icon if free)
- Sounds on/off, haptics on/off
- Alert sound picker (paid)
- Upgrade to Pro / Restore Purchases
- About / Privacy Policy

### Live Activity & Dynamic Island
- **Compact:** 🅿️ icon + countdown with color
- **Expanded:** expiry time, countdown, progress bar, location, distance
- **Lock Screen:** app icon, location, countdown, progress bar, expiry/alert times
- **Color states:** green (#4ade80) >10min, yellow (#fbbf24) <10min, red (#ff4a4a) expired
- **Unmetered:** white text, elapsed time, no progress bar
- Uses `Text(timerInterval:countsDown:)` for OS-native countdown

### Alert System
- **Free:** single local notification at 10 min before expiry
- **Paid — smart alert:** calculates walking time from current distance to car, fires notification with enough lead time to walk back (distance / 80m per minute)
- **Paid — custom timing:** user chooses 5/10/15/20/30 min before expiry
- All alerts via `UNUserNotificationCenter` — fires even when app is killed
- Sound + haptic when alert fires in foreground

## Free vs. Paid Split

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

### Paid Unlock ($4.99 one-time IAP)
- Distance-aware smart alerts
- Custom alert timing (5/10/15/20/30 min)
- Full parking history
- Extend time on running meter
- Multiple alert sound choices

### Upgrade Surfacing
- History tab: 3 most recent sessions blurred with upgrade prompt
- Settings: lock icon on smart alerts and custom timing
- No nag screens, no popups, no countdown walls
- Principle: free version genuinely solves the problem; paid solves it better

## Phases

### V1.0 — Core (this spec)
- Both parking modes (metered + unmetered)
- GPS pin + photo + walking directions
- Live Activity + Dynamic Island
- Smart alerts (distance-aware, paid)
- Parking history (paid)
- StoreKit 2 IAP
- App Store submission

### V1.1 — Polish & Expansion
- Apple Watch companion (see meter on wrist, haptic alert)
- Widgets (home screen showing active session or "last parked" quick-start)
- Siri Shortcuts ("Hey Siri, start a 1-hour parking timer")
- CarPlay integration (auto-start parking when disconnecting from CarPlay?)

### V1.2 — Social & Smart
- Share parking location with passenger/friend
- Recurring parking spots ("I park here every Tuesday") with one-tap start
- Parking cost calculator (enter rate, see total cost in history)

### V2.0 — Ideas (validate with sales first)
- NFC tag in car — tap phone to car's NFC sticker to auto-start parking
- Street cleaning schedule alerts
- Parking garage rate comparison

## Technical Constraints

- **No backend** — all data local (JSON files in app documents)
- **No accounts** — no sign-up, no login, no cloud sync
- **No AI** — deterministic logic only
- **iOS 17.0+** — required for ActivityKit
- **iPhone only** — Watch companion deferred to V1.1
- **"When In Use" location only** — no background location, no geofencing
- **StoreKit 2** — modern async API, no server-side receipt validation needed

## App Store Positioning

- **Name:** ParkTimer — Parking Meter Alert
- **Subtitle:** Never Get a Ticket Again
- **Price:** Free (with $4.99 Pro unlock)
- **Category:** Utilities (primary), Navigation (secondary)
- **Keywords:** parking timer, meter, reminder, find my car, parking alert, meter expired, parking ticket, car location
- **Privacy:** Data Not Collected (no network, no analytics, no tracking)
- **Age rating:** 4+
- **Pitch:** "ParkTimer counts down your meter on your Lock Screen and Dynamic Island, and alerts you before time runs out — even when your phone is in your pocket. Smart alerts know how far you are from your car and give you enough time to walk back."
- **Anti-subscription angle:** "Pay once, own forever. No subscriptions, no ads, no accounts."

## Success Metrics

- **Downloads:** 1,000 in first month (free tier drives volume)
- **Conversion rate:** 10-15% free → paid (industry benchmark for utilities)
- **Rating:** 4.5+ stars
- **Revenue target:** $500-$1,500/month after ramp-up
- **Zero-ticket metric:** user testimonials about avoiding tickets (social proof for marketing)

## Rejected Ideas

| Idea | Why Rejected |
|------|-------------|
| Subscription pricing | Anti-pattern for simple utility; one-time purchase is the differentiator |
| Backend/cloud sync | Adds complexity, cost, and privacy concerns for marginal value |
| Parking payment integration | Separate problem, well-served by ParkMobile/PayByPhone |
| Android version | Focus on iOS first, validate with real revenue |
| Social features in V1 | Adds complexity, validate core value first |
| "Always" location permission | Unnecessary (we use scheduled notifications, not geofences) and kills approval rate |
| Combine with RoundTimer | Different audience, different keywords, dilutes both value props |
