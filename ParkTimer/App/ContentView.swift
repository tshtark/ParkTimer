import SwiftUI
import StoreKit

struct ContentView: View {
    @State private var engine = ParkingEngine()
    @State private var sessionStore = SessionStore()
    @State private var historyStore = HistoryStore()
    @State private var locationManager = LocationManager()
    @State private var selectedTab = 0
    @State private var showNearCarPrompt = false
    @State private var nearCarPromptDismissed = false
    @State private var hasBeenAwayFromCar = false
    @State private var hasRetriedLocationForSession: UUID?
    @State private var showWelcome = !UserDefaults.standard.bool(forKey: "hasSeenWelcome")
    @Environment(\.requestReview) private var requestReview

    var body: some View {
        TabView(selection: $selectedTab) {
            Group {
                if engine.isActive {
                    ActiveSessionView(
                        engine: engine,
                        sessionStore: sessionStore,
                        historyStore: historyStore,
                        locationManager: locationManager
                    )
                } else {
                    StartParkingView(
                        engine: engine,
                        sessionStore: sessionStore,
                        historyStore: historyStore,
                        locationManager: locationManager
                    )
                }
            }
            .tabItem { Label("Park", systemImage: "car.fill") }
            .tag(0)

            FindCarView(
                engine: engine,
                historyStore: historyStore,
                locationManager: locationManager
            )
            .tabItem { Label("Find Car", systemImage: "map.fill") }
            .tag(1)

            HistoryListView(historyStore: historyStore)
                .tabItem { Label("History", systemImage: "clock.fill") }
                .tag(2)

            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
                .tag(3)
        }
        .tint(Color(hex: "#4ade80"))
        .sheet(isPresented: $showWelcome) {
            WelcomeSheet {
                UserDefaults.standard.set(true, forKey: "hasSeenWelcome")
                showWelcome = false
                // BUG-002: defer permission prompts until after welcome sheet is dismissed
                // so system dialogs don't overlap the "What is this app?" content.
                requestSystemPermissions()
            }
        }
        .alert("Back at your car?", isPresented: $showNearCarPrompt) {
            Button("End Parking", role: .destructive) {
                let endedSession = engine.session
                if let completed = engine.stop() {
                    historyStore.add(completed)
                }
                sessionStore.clear()
                if let endedSession {
                    ParkingActivityManager.shared.end(session: endedSession)
                }
                AlertManager.shared.cancelAll()
                HapticManager.shared.successFeedback()
                nearCarPromptDismissed = true
                // Request review at milestones
                let count = historyStore.sessions.count
                if count == 3 || count == 10 || count == 25 {
                    Task { @MainActor in
                        try? await Task.sleep(for: .seconds(1))
                        requestReview()
                    }
                }
            }
            Button("Not yet", role: .cancel) {
                nearCarPromptDismissed = true
            }
        } message: {
            Text("It looks like you're near your car. Would you like to end your parking session?")
        }
        .onChange(of: engine.isActive) { _, isActive in
            if isActive {
                nearCarPromptDismissed = false
                hasBeenAwayFromCar = false
            }
        }
        .onAppear {
            AudioManager.shared.configure()
            HapticManager.shared.prepare()

            // BUG-002: only request location/notification permissions if the welcome
            // sheet isn't about to appear. First-launch permissions get requested from
            // the welcome sheet's "Get Started" button instead.
            if !showWelcome {
                requestSystemPermissions()
            }

            // Resume active session from persistence
            if let saved = sessionStore.activeSession {
                engine.resume(session: saved)
            }

            // Reconcile Live Activities: end orphans from prior processes and, if the
            // resumed session has no Live Activity (e.g. after a reboot), recreate it.
            ParkingActivityManager.shared.reclaimOrCleanup(activeSession: engine.session)

            // Wire up engine callbacks
            engine.onWarning = {
                AudioManager.shared.play(.warning)
                HapticManager.shared.warningFeedback()
            }
            engine.onExpired = {
                AudioManager.shared.play(.expired)
                HapticManager.shared.expiredFeedback()
                if let session = engine.session {
                    ParkingActivityManager.shared.update(state: .expired, session: session)
                }
            }
            engine.onTick = {
                // Persist session on each tick (crash safety)
                if let session = engine.session {
                    sessionStore.save(session)
                }

                // Update Live Activity on state changes
                if let session = engine.session {
                    ParkingActivityManager.shared.update(state: engine.state, session: session)
                }

                // BUG-008 fallback: if the session was saved before GPS resolved, retroactively
                // fill in coords + address when the fix finally arrives. Runs once per session.
                if let session = engine.session,
                   session.location.address == nil,
                   let current = locationManager.currentLocation,
                   hasRetriedLocationForSession != session.id {
                    hasRetriedLocationForSession = session.id
                    engine.updateLocation(
                        latitude: current.coordinate.latitude,
                        longitude: current.coordinate.longitude
                    )
                    Task { @MainActor in
                        let address = await locationManager.reverseGeocode(
                            latitude: current.coordinate.latitude,
                            longitude: current.coordinate.longitude
                        )
                        if let address {
                            engine.updateLocation(address: address)
                            if let updated = engine.session {
                                sessionStore.save(updated)
                                ParkingActivityManager.shared.update(state: engine.state, session: updated)
                            }
                        }
                    }
                }

                // Update distance to car + auto-suggest end
                if let session = engine.session {
                    locationManager.updateDistanceToCar(carLocation: session.location)

                    if let distance = locationManager.distanceToCar {
                        // Track if user has walked away from car (>100m)
                        if distance > 100 {
                            hasBeenAwayFromCar = true
                        }

                        // Only prompt when user has been away AND returned close
                        if distance < 50,
                           hasBeenAwayFromCar,
                           !nearCarPromptDismissed,
                           !showNearCarPrompt {
                            showNearCarPrompt = true
                        }
                    }
                }
            }

            Task {
                await AlertManager.shared.checkNotificationStatus()
                await StoreManager.shared.loadProduct()
                await StoreManager.shared.checkEntitlements()
            }
        }
    }

    /// Requests location + notification permissions. Called on launch when the welcome
    /// sheet is not shown, and from the welcome sheet's Get Started button on first
    /// launch so system dialogs don't obscure the welcome content (BUG-002).
    private func requestSystemPermissions() {
        locationManager.requestPermission()
        Task {
            await AlertManager.shared.requestPermission()
            await AlertManager.shared.checkNotificationStatus()
        }
    }
}

#Preview {
    ContentView()
}
