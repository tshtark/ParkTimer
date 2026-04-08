import SwiftUI

struct ContentView: View {
    @State private var engine = ParkingEngine()
    @State private var sessionStore = SessionStore()
    @State private var historyStore = HistoryStore()
    @State private var locationManager = LocationManager()
    @State private var selectedTab = 0
    @State private var showNearCarPrompt = false
    @State private var nearCarPromptDismissed = false
    @State private var hasBeenAwayFromCar = false

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
                        locationManager: locationManager
                    )
                }
            }
            .tabItem { Label("Park", systemImage: "car.fill") }
            .tag(0)

            FindCarView(
                engine: engine,
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
        .alert("Back at your car?", isPresented: $showNearCarPrompt) {
            Button("End Parking", role: .destructive) {
                if let completed = engine.stop() {
                    historyStore.add(completed)
                }
                sessionStore.clear()
                ParkingActivityManager.shared.end()
                AlertManager.shared.cancelAll()
                HapticManager.shared.successFeedback()
                nearCarPromptDismissed = true
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
            locationManager.requestPermission()

            // Resume active session from persistence
            if let saved = sessionStore.activeSession {
                engine.resume(session: saved)
            }

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
                await AlertManager.shared.requestPermission()
                await AlertManager.shared.checkNotificationStatus()
                await StoreManager.shared.loadProduct()
            }
        }
    }
}

#Preview {
    ContentView()
}
