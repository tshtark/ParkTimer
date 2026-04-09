import SwiftUI
import PhotosUI
import ActivityKit

struct StartParkingView: View {
    let engine: ParkingEngine
    let sessionStore: SessionStore
    let historyStore: HistoryStore
    let locationManager: LocationManager

    @State private var selectedDuration: TimeInterval?
    @State private var customMinutes: Int = 60
    @State private var showCustomPicker = false
    @State private var note: String = ""
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var photoData: Data?
    @State private var geocodedAddress: String?
    @State private var isGeocodingAddress = false
    // BUG-006: persist across launches so a user who taps the X isn't nagged again.
    @State private var proNudgeDismissed: Bool = UserDefaults.standard.bool(forKey: Self.proNudgeDismissedKey)
    // BUG-016: sanitize the stored value on load too, in case an earlier session saved
    // garbage (e.g. simulator hardware-keyboard input) before we added the filter.
    @State private var hourlyRateText: String = Self.sanitizeRate(SettingsManager.shared.lastHourlyRate)

    private static let proNudgeDismissedKey = "proNudgeDismissed"

    private let presets: [(String, TimeInterval)] = [
        ("15m", 15 * 60),
        ("30m", 30 * 60),
        ("1h", 60 * 60),
        ("2h", 120 * 60),
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    headerSection
                    warningBanners
                    quickRestartSection
                    durationSection
                    startButton
                    unmeeteredButton
                    proNudgeCard
                    locationSection
                    noteSection
                    rateSection
                    photoSection
                }
                .padding()
            }
            .navigationTitle("ParkTimer")
            .sheet(isPresented: $showCustomPicker) {
                DurationPicker(minutes: $customMinutes) {
                    selectedDuration = TimeInterval(customMinutes * 60)
                    showCustomPicker = false
                }
            }
        }
        .onAppear {
            // BUG-002: `requestLocation()` falls back to `requestPermission()` when
            // status is `.notDetermined`, which triggers the system dialog. That fires
            // on top of the first-launch Welcome sheet. Only request the one-shot
            // location once the user has already granted permission; ContentView
            // handles the initial permission prompt after Welcome is dismissed.
            if locationManager.isAuthorized {
                locationManager.requestLocation()
            }
            geocodeCurrentLocation()
            // BUG-016: if SettingsManager had a pre-existing malformed value, flush the
            // sanitized version back so it never reappears in future launches.
            if SettingsManager.shared.lastHourlyRate != hourlyRateText {
                SettingsManager.shared.lastHourlyRate = hourlyRateText
            }
        }
    }

    // MARK: - Pro Nudge

    private var shouldShowProNudge: Bool {
        guard !StoreManager.shared.isProUnlocked else { return false }
        guard !proNudgeDismissed else { return false }
        let meteredCount = historyStore.sessions.filter(\.isMetered).count
        return meteredCount >= 3
    }

    @ViewBuilder
    private var proNudgeCard: some View {
        if shouldShowProNudge {
            HStack(spacing: 12) {
                Image(systemName: "sparkles")
                    .font(.title3)
                    .foregroundStyle(Color(hex: "#fbbf24"))

                VStack(alignment: .leading, spacing: 2) {
                    Text("Never get caught off guard")
                        .font(.subheadline.weight(.semibold))
                    Text("Pro alerts know how far you are and warn you in time to walk back.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer(minLength: 0)

                VStack(spacing: 8) {
                    Button {
                        proNudgeDismissed = true
                        UserDefaults.standard.set(true, forKey: Self.proNudgeDismissedKey)
                    } label: {
                        Image(systemName: "xmark")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }

                    NavigationLink {
                        UpgradeView()
                    } label: {
                        Text("Learn more")
                            .font(.caption.bold())
                            .foregroundStyle(Color(hex: "#4ade80"))
                    }
                }
            }
            .padding(12)
            .background(Color(hex: "#fbbf24").opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .transition(.opacity.combined(with: .move(edge: .top)))
        }
    }

    // MARK: - Quick Restart

    @ViewBuilder
    private var quickRestartSection: some View {
        if let lastMetered = historyStore.sessions.first(where: { $0.isMetered && $0.duration != nil }) {
            Button {
                quickRestart(from: lastMetered)
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "arrow.clockwise.circle.fill")
                        .font(.title2)
                        .foregroundStyle(Color(hex: "#4ade80"))

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Quick Restart")
                            .font(.subheadline.weight(.semibold))
                        Text("\(TimeFormatting.durationText(lastMetered.duration!)) · \(lastMetered.formattedAddress)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding()
                .background(Color(hex: "#4ade80").opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }

    private func quickRestart(from session: ParkingSession) {
        guard let duration = session.duration else { return }
        let location = makeLocation()
        let loc = ParkingLocation(
            latitude: location.latitude,
            longitude: location.longitude,
            address: geocodedAddress ?? session.location.address,
            photoFilename: nil
        )

        let settings = SettingsManager.shared
        // BUG-020: Quick Restart inherits the prior session's `hourlyRate`, but cost
        // tracking is a Pro feature. If the user has downgraded since that session,
        // drop the rate so the active session doesn't leak a Cost-so-far card.
        let inheritedRate = StoreManager.shared.isProUnlocked ? session.hourlyRate : nil
        engine.startMetered(
            duration: duration,
            location: loc,
            note: nil,
            alertMinutes: settings.alertMinutesBefore,
            smartAlert: settings.isSmartAlertsEnabled && StoreManager.shared.isProUnlocked,
            hourlyRate: inheritedRate
        )

        if let newSession = engine.session {
            sessionStore.save(newSession)
            ParkingActivityManager.shared.start(session: newSession)
            AlertManager.shared.scheduleAlert(
                for: newSession,
                walkingMinutes: locationManager.walkingMinutesToCar
            )
        }

        HapticManager.shared.successFeedback()
    }

    // MARK: - Warnings

    @ViewBuilder
    private var warningBanners: some View {
        if AlertManager.shared.isNotificationDenied {
            warningBanner(
                icon: "bell.slash.fill",
                message: "Notifications are disabled. You won't receive parking alerts when the app is in the background.",
                action: "Open Settings",
                onTap: {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
            )
        }

        if locationManager.isDenied {
            warningBanner(
                icon: "location.slash.fill",
                message: "Location is disabled. Your car's position won't be saved.",
                action: "Open Settings",
                onTap: {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
            )
        }

        // BUG-014: surface a recovery path when the user has declined the iOS system
        // dialog for Live Activities. Without this banner, the app's primary
        // differentiator is silently broken and the user has no idea why.
        if !ActivityAuthorizationInfo().areActivitiesEnabled {
            warningBanner(
                icon: "rectangle.on.rectangle.slash",
                message: "Live Activities are off. Enable them to see your countdown on the Lock Screen.",
                action: "Open Settings",
                onTap: {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
            )
        }
    }

    private func warningBanner(icon: String, message: String, action: String, onTap: @escaping () -> Void) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .foregroundStyle(Color(hex: "#fbbf24"))

            Text(message)
                .font(.caption)
                .foregroundStyle(.secondary)

            Spacer()

            Button(action) { onTap() }
                .font(.caption.bold())
                .foregroundStyle(Color(hex: "#4ade80"))
        }
        .padding(12)
        .background(Color(hex: "#fbbf24").opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    // MARK: - Sections

    private var headerSection: some View {
        VStack(spacing: 8) {
            Image(systemName: SettingsManager.shared.vehicleType.iconName)
                .font(.system(size: 48))
                .foregroundStyle(Color(hex: "#4ade80"))

            Text("How long are you parked?")
                .font(.title2.bold())
        }
        .padding(.top, 8)
    }

    private var durationSection: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                ForEach(presets, id: \.1) { preset in
                    Button {
                        selectedDuration = preset.1
                        HapticManager.shared.tapFeedback()
                    } label: {
                        Text(preset.0)
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(selectedDuration == preset.1
                                        ? Color(hex: "#4ade80")
                                        : Color(.systemGray5))
                            .foregroundStyle(selectedDuration == preset.1 ? .black : .primary)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
            }

            Button {
                showCustomPicker = true
                HapticManager.shared.tapFeedback()
            } label: {
                HStack {
                    Image(systemName: "slider.horizontal.3")
                    Text(selectedDuration != nil && !presets.contains(where: { $0.1 == selectedDuration })
                         ? "Custom: \(TimeFormatting.durationText(selectedDuration!))"
                         : "Custom Duration")
                }
                .font(.subheadline.weight(.medium))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color(.systemGray5))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }

    private var locationSection: some View {
        HStack {
            Image(systemName: "mappin.circle.fill")
                .foregroundStyle(Color(hex: "#4ade80"))
                .font(.title3)

            VStack(alignment: .leading, spacing: 2) {
                Text("Car Location")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if isGeocodingAddress {
                    Text("Detecting location...")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } else if let address = geocodedAddress {
                    Text(address)
                        .font(.subheadline)
                } else if locationManager.isDenied {
                    Text("Location denied — tap to enable")
                        .font(.subheadline)
                        .foregroundStyle(Color(hex: "#fbbf24"))
                } else {
                    Text("Location unavailable")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            // BUG-003: only show the green checkmark once we actually have an address
            // to display. Showing ✓ next to "Location unavailable" was misleading.
            if geocodedAddress != nil {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
            } else if isGeocodingAddress || (locationManager.currentLocation != nil && !locationManager.isDenied) {
                ProgressView()
                    .controlSize(.small)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var noteSection: some View {
        HStack {
            Image(systemName: "note.text")
                .foregroundStyle(.secondary)
            TextField("Note (e.g., Level 3, Row B)", text: $note)
                .font(.subheadline)
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    @ViewBuilder
    private var rateSection: some View {
        if StoreManager.shared.isProUnlocked {
            HStack {
                Image(systemName: "dollarsign.circle")
                    .foregroundStyle(.secondary)
                TextField("Hourly rate (e.g., 3.00)", text: $hourlyRateText)
                    .font(.subheadline)
                    .keyboardType(.decimalPad)
                    // BUG-016: decimalPad doesn't stop hardware keyboards (simulator,
                    // Bluetooth keyboards), so filter client-side to digits + one dot.
                    .onChange(of: hourlyRateText) { _, newValue in
                        hourlyRateText = Self.sanitizeRate(newValue)
                    }
            }
            .padding()
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    /// Keep only digits and at most one decimal point. Drops everything else so a user
    /// who pastes or types letters silently sees them disappear.
    private static func sanitizeRate(_ input: String) -> String {
        var seenDot = false
        var out = ""
        for character in input {
            if character.isNumber {
                out.append(character)
            } else if character == "." && !seenDot {
                seenDot = true
                out.append(character)
            }
        }
        return out
    }

    private var photoSection: some View {
        let hasPhoto = photoData != nil
        return PhotosPicker(selection: $selectedPhoto, matching: .images) {
            PhotoPickerLabel(hasPhoto: hasPhoto)
        }
        .onChange(of: selectedPhoto) { _, newValue in
            Task { @MainActor in
                if let data = try? await newValue?.loadTransferable(type: Data.self) {
                    photoData = data
                }
            }
        }
    }

    private var startButton: some View {
        Button {
            startMeteredSession()
        } label: {
            Text("Start Parking")
                .font(.title3.bold())
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(selectedDuration != nil
                            ? Color(hex: "#4ade80")
                            : Color(.systemGray4))
                .foregroundStyle(selectedDuration != nil ? .black : .secondary)
                .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .disabled(selectedDuration == nil)
    }

    private var unmeeteredButton: some View {
        Button {
            startUnmeteredSession()
        } label: {
            Text("No meter — just save my spot")
                .font(.subheadline)
                .foregroundStyle(Color(hex: "#4ade80"))
        }
        .padding(.bottom, 8)
    }

    // MARK: - Actions

    private func startMeteredSession() {
        guard let duration = selectedDuration else { return }
        let location = makeLocation()

        let photoFilename = savePhoto()
        let loc = ParkingLocation(
            latitude: location.latitude,
            longitude: location.longitude,
            address: geocodedAddress,
            photoFilename: photoFilename
        )

        let settings = SettingsManager.shared
        let rate = StoreManager.shared.isProUnlocked ? Double(hourlyRateText) : nil
        if StoreManager.shared.isProUnlocked && !hourlyRateText.isEmpty {
            settings.lastHourlyRate = hourlyRateText
        }
        engine.startMetered(
            duration: duration,
            location: loc,
            note: note.isEmpty ? nil : note,
            alertMinutes: settings.alertMinutesBefore,
            smartAlert: settings.isSmartAlertsEnabled && StoreManager.shared.isProUnlocked,
            hourlyRate: rate
        )

        if let session = engine.session {
            sessionStore.save(session)
            ParkingActivityManager.shared.start(session: session)
            AlertManager.shared.scheduleAlert(
                for: session,
                walkingMinutes: locationManager.walkingMinutesToCar
            )
        }

        HapticManager.shared.successFeedback()
    }

    private func startUnmeteredSession() {
        let location = makeLocation()
        let photoFilename = savePhoto()
        let loc = ParkingLocation(
            latitude: location.latitude,
            longitude: location.longitude,
            address: geocodedAddress,
            photoFilename: photoFilename
        )

        engine.startUnmetered(location: loc, note: note.isEmpty ? nil : note)

        if let session = engine.session {
            sessionStore.save(session)
            ParkingActivityManager.shared.start(session: session)
        }

        HapticManager.shared.successFeedback()
    }

    private func makeLocation() -> (latitude: Double, longitude: Double) {
        if let loc = locationManager.currentLocation {
            return (loc.coordinate.latitude, loc.coordinate.longitude)
        }
        return (0, 0)
    }

    private func savePhoto() -> String? {
        guard let data = photoData else { return nil }
        let filename = "\(UUID().uuidString).jpg"
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let photosDir = docs.appendingPathComponent("photos")
        try? FileManager.default.createDirectory(at: photosDir, withIntermediateDirectories: true)
        let fileURL = photosDir.appendingPathComponent(filename)
        try? data.write(to: fileURL)
        return filename
    }

    private func geocodeCurrentLocation() {
        guard let loc = locationManager.currentLocation else {
            // Retry after a short delay if location not ready
            Task {
                try? await Task.sleep(for: .seconds(2))
                if let loc = locationManager.currentLocation {
                    isGeocodingAddress = true
                    geocodedAddress = await locationManager.reverseGeocode(
                        latitude: loc.coordinate.latitude,
                        longitude: loc.coordinate.longitude
                    )
                    isGeocodingAddress = false
                }
            }
            return
        }
        isGeocodingAddress = true
        Task {
            geocodedAddress = await locationManager.reverseGeocode(
                latitude: loc.coordinate.latitude,
                longitude: loc.coordinate.longitude
            )
            isGeocodingAddress = false
        }
    }
}

// Extracted to avoid Swift 6 Sendable warning in PhotosPicker label closure
struct PhotoPickerLabel: View {
    let hasPhoto: Bool

    var body: some View {
        HStack {
            Image(systemName: hasPhoto ? "photo.fill" : "camera.fill")
                .foregroundStyle(hasPhoto ? Color(hex: "#4ade80") : .secondary)
            Text(hasPhoto ? "Photo added" : "Photo of parking spot")
                .font(.subheadline)
                .foregroundStyle(hasPhoto ? .primary : .secondary)
            Spacer()
            if hasPhoto {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
