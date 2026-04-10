import SwiftUI

struct SettingsView: View {
    @Bindable private var settings = SettingsManager.shared
    private var store = StoreManager.shared

    var body: some View {
        NavigationStack {
            List {
                alertsSection
                soundSection
                vehicleSection
                proSection
                aboutSection
            }
            .navigationTitle("Settings")
        }
    }

    // MARK: - Alerts

    private var alertsSection: some View {
        Section("Alerts") {
            if store.isProUnlocked {
                Picker("Alert Before Expiry", selection: $settings.alertMinutesBefore) {
                    Text("5 minutes").tag(5)
                    Text("10 minutes").tag(10)
                    Text("15 minutes").tag(15)
                    Text("20 minutes").tag(20)
                    Text("30 minutes").tag(30)
                }

                Toggle("Smart Alerts (distance-aware)", isOn: $settings.isSmartAlertsEnabled)
            } else {
                // BUG-004: locked rows are now NavigationLinks so tapping surfaces the
                // Upgrade screen — the PRD's conversion path for curious free users.
                lockedProRow(title: "Smart Alerts", subtitle: "Distance-aware")
                lockedProRow(title: "Custom Timing", subtitle: "5/10/15/20/30 min")
            }
        }
    }

    private func lockedProRow(title: String, subtitle: String) -> some View {
        NavigationLink {
            UpgradeView()
        } label: {
            HStack {
                Image(systemName: "lock.fill")
                    .foregroundStyle(.secondary)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Text("Pro")
                    .font(.caption.bold())
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Color(hex: "#4ade80").opacity(0.2))
                    .clipShape(Capsule())
            }
        }
    }

    // MARK: - Sound

    private var soundSection: some View {
        Section("Sound & Haptics") {
            if store.isProUnlocked {
                NavigationLink {
                    AlertSoundPicker(settings: settings)
                } label: {
                    HStack {
                        Text("Alert Sound")
                        Spacer()
                        Text(settings.selectedAlertSound.displayName)
                            .foregroundStyle(.secondary)
                    }
                }
            } else {
                lockedProRow(title: "Alert Sound", subtitle: "5 sounds to choose from")
            }
            Toggle("Sounds", isOn: $settings.isSoundEnabled)
            Toggle("Haptics", isOn: $settings.isHapticsEnabled)
        }
    }

    // MARK: - Vehicle

    private var vehicleSection: some View {
        Section("Vehicle") {
            ForEach(VehicleType.allCases, id: \.self) { vehicle in
                Button {
                    settings.vehicleType = vehicle
                } label: {
                    HStack {
                        Image(systemName: vehicle.iconName)
                            .font(.title3)
                            .frame(width: 32)
                        Text(vehicle.displayName)
                            .foregroundStyle(.primary)
                        Spacer()
                        if settings.vehicleType == vehicle {
                            Image(systemName: "checkmark")
                                .foregroundStyle(Color(hex: "#4ade80"))
                        }
                    }
                }
            }
        }
    }

    // MARK: - Pro

    private var proSection: some View {
        Section("Pro") {
            if store.isProUnlocked {
                Label("Pro Unlocked", systemImage: "checkmark.seal.fill")
                    .foregroundStyle(Color(hex: "#4ade80"))
            } else {
                NavigationLink {
                    UpgradeView()
                } label: {
                    Label("Upgrade to Pro", systemImage: "star.fill")
                        .foregroundStyle(Color(hex: "#4ade80"))
                }

                Button("Restore Purchases") {
                    Task { await store.restorePurchases() }
                }
            }
        }
    }

    // MARK: - About

    private var aboutSection: some View {
        Section("About") {
            HStack {
                Text("Version")
                Spacer()
                Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")
                    .foregroundStyle(.secondary)
            }

            NavigationLink("Privacy Policy") {
                PrivacyPolicyView()
            }
        }
    }
}

// MARK: - Privacy Policy

struct PrivacyPolicyView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("ParkTimer — Parking Meter Alert")
                    .font(.headline)
                Text("Last updated: April 9, 2026")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                section(
                    title: "Summary",
                    body: "ParkTimer does not collect, store, or transmit any personal data. Everything stays on your device."
                )

                section(
                    title: "Data Collection",
                    body: """
                    ParkTimer collects no data whatsoever. Specifically:

                    • No analytics — we do not track how you use the app.
                    • No advertising — there are no ads, no ad networks, no tracking pixels.
                    • No accounts — there is no sign-up, login, or user profile.
                    • No network requests — the app makes zero connections to any server. It works entirely offline.
                    • No third-party SDKs.
                    """
                )

                section(
                    title: "Data Stored on Your Device",
                    body: """
                    ParkTimer stores the following data locally on your iPhone only:

                    • Parking sessions — start time, duration, and location of your parking sessions.
                    • Photos — if you take a photo of your parking spot, it is saved locally. It is never uploaded.
                    • Settings — your preferences (alert timing, sounds, vehicle type).
                    • Purchase status — whether you have purchased ParkTimer Pro (via Apple's StoreKit).

                    This data is not accessible to us or any third party.
                    """
                )

                section(
                    title: "Location Data",
                    body: """
                    ParkTimer uses your location only when the app is open (\"When In Use\" permission) to:

                    1. Save your car's GPS coordinates when you start a session
                    2. Calculate walking distance and time back to your car
                    3. Reverse geocode your coordinates to a street address (using Apple's on-device geocoding)

                    Your location is never transmitted to any server.
                    """
                )

                section(
                    title: "Notifications",
                    body: "ParkTimer sends local notifications to alert you before your parking meter expires. These are generated entirely on your device. No push notification servers are involved."
                )

                section(
                    title: "In-App Purchases",
                    body: "ParkTimer Pro is a one-time in-app purchase processed entirely through Apple's App Store. We do not have access to your payment information."
                )

                section(
                    title: "Children's Privacy",
                    body: "ParkTimer does not knowingly collect any information from children under 13."
                )

                section(
                    title: "Contact",
                    body: "If you have questions about this privacy policy, contact us at shtark285@gmail.com."
                )
            }
            .padding()
        }
        .navigationTitle("Privacy Policy")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func section(title: String, body: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.subheadline.bold())
            Text(body)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

#Preview {
    SettingsView()
}
