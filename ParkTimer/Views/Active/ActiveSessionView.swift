import SwiftUI
import StoreKit
import MapKit

struct ActiveSessionView: View {
    let engine: ParkingEngine
    let sessionStore: SessionStore
    let historyStore: HistoryStore
    let locationManager: LocationManager

    @Environment(\.requestReview) private var requestReview
    @State private var showEndConfirmation = false
    @State private var showExtendSheet = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    countdownSection
                    if engine.session?.isMetered == true {
                        progressSection
                    }
                    infoCardsSection
                    actionButtons
                }
                .padding()
            }
            .navigationTitle(engine.session?.isMetered == true ? "Metered" : "Tracking")
            .navigationBarTitleDisplayMode(.inline)
            .confirmationDialog("End Parking?", isPresented: $showEndConfirmation) {
                Button("End Parking", role: .destructive) {
                    endSession()
                }
            } message: {
                Text("This will end your current parking session.")
            }
            .sheet(isPresented: $showExtendSheet) {
                ExtendTimeSheet { minutes in
                    extendTime(minutes: minutes)
                    showExtendSheet = false
                }
            }
        }
    }

    // MARK: - Countdown

    private var countdownSection: some View {
        VStack(spacing: 8) {
            if engine.session?.isMetered == true {
                CountdownDisplay(
                    timeRemaining: engine.timeRemaining,
                    state: engine.state
                )
            } else {
                // Unmetered: elapsed time
                Text(TimeFormatting.elapsed(engine.elapsedTime))
                    .font(.system(size: 64, weight: .bold, design: .monospaced))
                    .foregroundStyle(.primary)
                    .contentTransition(.numericText())
                    .animation(.linear(duration: 0.1), value: Int(engine.elapsedTime))

                Text("Time parked")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            if engine.state == .expired {
                Text("METER EXPIRED")
                    .font(.headline.bold())
                    .foregroundStyle(Color(hex: "#ff4a4a"))
                    .padding(.vertical, 6)
                    .padding(.horizontal, 16)
                    .background(Color(hex: "#ff4a4a").opacity(0.15))
                    .clipShape(Capsule())
            }
        }
        .padding(.top, 8)
    }

    // MARK: - Progress

    private var progressGradient: LinearGradient {
        switch engine.state {
        case .active:
            LinearGradient(colors: [Color(hex: "#4ade80")], startPoint: .leading, endPoint: .trailing)
        case .warning:
            LinearGradient(
                colors: [Color(hex: "#4ade80"), Color(hex: "#fbbf24")],
                startPoint: .leading, endPoint: .trailing
            )
        case .expired:
            LinearGradient(
                colors: [Color(hex: "#fbbf24"), Color(hex: "#ff4a4a")],
                startPoint: .leading, endPoint: .trailing
            )
        default:
            LinearGradient(colors: [.secondary], startPoint: .leading, endPoint: .trailing)
        }
    }

    private var progressSection: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color(.systemGray5))
                    .frame(height: 12)

                RoundedRectangle(cornerRadius: 6)
                    .fill(progressGradient)
                    .frame(width: max(0, geo.size.width * engine.progress), height: 12)
                    .animation(.linear(duration: 1), value: engine.progress)
                    .animation(.easeInOut(duration: 0.5), value: engine.state)
            }
        }
        .frame(height: 12)
    }

    // MARK: - Info Cards

    private var infoCardsSection: some View {
        VStack(spacing: 12) {
            // Expiry — prominent card
            if let session = engine.session, session.isMetered, let endDate = session.meterEndDate {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Expires at")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(endDate.formatted(date: .omitted, time: .shortened))
                            .font(.title2.bold())
                    }
                    Spacer()
                    Image(systemName: "clock.fill")
                        .font(.title2)
                        .foregroundStyle(engine.state.color)
                }
                .padding()
                .background(engine.state.color.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .animation(.easeInOut(duration: 0.5), value: engine.state)
            }

            // Parking cost (Pro) — BUG-020: also gate on current Pro entitlement so a
            // session that inherited a rate from a previous Pro purchase (e.g. through
            // Quick Restart or engine.resume) doesn't leak cost tracking to a now-free
            // user.
            if let session = engine.session,
               let rate = session.hourlyRate,
               rate > 0,
               StoreManager.shared.isProUnlocked {
                let elapsed = engine.elapsedTime / 3600.0
                let cost = elapsed * rate
                infoCard(
                    icon: "dollarsign.circle.fill",
                    title: "Cost so far",
                    value: String(format: "$%.2f", cost),
                    color: Color(hex: "#fbbf24")
                )
            }

            // Distance + walking time — combined, hidden when at car
            if let distance = locationManager.distanceToCar, distance > 10 {
                HStack(spacing: 16) {
                    Image(systemName: "figure.walk")
                        .foregroundStyle(.blue)
                        .frame(width: 28)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Distance to car")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        HStack(spacing: 8) {
                            Text(TimeFormatting.distanceText(distance))
                                .font(.subheadline.weight(.medium))
                            if let walkingMin = locationManager.walkingMinutesToCar {
                                Text("·  \(Int(ceil(walkingMin))) min walk")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    Spacer()
                }
                .padding()
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }

            // Pro hint when far from car
            if let distance = locationManager.distanceToCar,
               distance > 200,
               !StoreManager.shared.isProUnlocked {
                NavigationLink {
                    UpgradeView()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "sparkles")
                            .font(.caption)
                            .foregroundStyle(Color(hex: "#fbbf24"))
                        Text("Pro tip: Smart Alerts account for your walking time")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                }
            }

            // Location — tappable for Directions (BUG-015); shown for both metered and
            // unmetered sessions (BUG-018), falling back to "Location saved" when the
            // address hasn't been geocoded yet.
            if let session = engine.session {
                Button {
                    openDirectionsToCar(location: session.location)
                } label: {
                    HStack {
                        Image(systemName: "mappin.circle.fill")
                            .foregroundStyle(Color(hex: "#4ade80"))
                            .frame(width: 28)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Location")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(session.location.address ?? "Location saved")
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(.primary)
                                .lineLimit(2)
                        }
                        Spacer()
                        Image(systemName: "arrow.turn.up.right")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Color(hex: "#4ade80"))
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)
            }

            // Note
            if let note = engine.session?.note, !note.isEmpty {
                infoCard(icon: "note.text", title: "Note", value: note, color: .secondary)
            }

            // Photo thumbnail
            if let photoFilename = engine.session?.location.photoFilename,
               let image = loadPhoto(filename: photoFilename) {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(height: 120)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }

            // Unmetered: helpful reminder
            if engine.session?.isMetered == false {
                HStack(spacing: 12) {
                    Image(systemName: "checkmark.shield.fill")
                        .font(.title3)
                        .foregroundStyle(Color(hex: "#4ade80"))

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Your spot is saved")
                            .font(.subheadline.weight(.semibold))
                        Text("Tap the Find Car tab anytime to get walking directions back.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding()
                .background(Color(hex: "#4ade80").opacity(0.06))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }

    /// BUG-015: Opens Apple Maps with walking directions to the saved car location.
    /// Matches the PRD spec ("Location with 'Directions →' link") on the active session.
    private func openDirectionsToCar(location: ParkingLocation) {
        let placemark = MKPlacemark(coordinate: location.coordinate)
        let mapItem = MKMapItem(placemark: placemark)
        mapItem.name = location.address ?? "My Car"
        mapItem.openInMaps(launchOptions: [
            MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeWalking
        ])
    }

    private func loadPhoto(filename: String) -> UIImage? {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let url = docs.appendingPathComponent("photos").appendingPathComponent(filename)
        guard let data = try? Data(contentsOf: url) else { return nil }
        return UIImage(data: data)
    }

    private func infoCard(icon: String, title: String, value: String, color: Color) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundStyle(color)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.subheadline.weight(.medium))
            }
            Spacer()
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Actions

    private var actionButtons: some View {
        VStack(spacing: 12) {
            if engine.session?.isMetered == true && StoreManager.shared.isProUnlocked {
                Button {
                    showExtendSheet = true
                } label: {
                    Label("Add Time", systemImage: "plus.circle.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color(.systemGray5))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }

            Button {
                showEndConfirmation = true
            } label: {
                Text("End Parking")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color(hex: "#ff4a4a").opacity(0.15))
                    .foregroundStyle(Color(hex: "#ff4a4a"))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }

    // MARK: - Helpers

    private func endSession() {
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

        // Request review at milestones: 3rd, 10th, 25th session
        let count = historyStore.sessions.count
        if count == 3 || count == 10 || count == 25 {
            Task { @MainActor in
                try? await Task.sleep(for: .seconds(1))
                requestReview()
            }
        }
    }

    private func extendTime(minutes: Int) {
        engine.extendTime(by: minutes)
        if let session = engine.session {
            sessionStore.save(session)
            ParkingActivityManager.shared.update(state: engine.state, session: session)
            AlertManager.shared.scheduleAlert(
                for: session,
                walkingMinutes: locationManager.walkingMinutesToCar
            )
        }
    }
}

// MARK: - Extend Time Sheet

struct ExtendTimeSheet: View {
    let onExtend: (Int) -> Void
    @Environment(\.dismiss) private var dismiss

    private let options = [15, 30, 60, 120]

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Text("Add Time")
                    .font(.headline)

                ForEach(options, id: \.self) { minutes in
                    Button {
                        onExtend(minutes)
                    } label: {
                        Text("+ \(TimeFormatting.durationText(TimeInterval(minutes * 60)))")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color(.systemGray5))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
            }
            .padding()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium])
    }
}
