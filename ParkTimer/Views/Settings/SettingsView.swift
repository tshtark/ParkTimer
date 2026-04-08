import SwiftUI

struct SettingsView: View {
    @Bindable private var settings = SettingsManager.shared
    private var store = StoreManager.shared

    var body: some View {
        NavigationStack {
            List {
                alertsSection
                soundSection
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
                HStack {
                    Text("Alert Before Expiry")
                    Spacer()
                    Text("10 minutes")
                        .foregroundStyle(.secondary)
                }

                HStack {
                    Label("Smart Alerts", systemImage: "lock.fill")
                    Spacer()
                    Text("Pro")
                        .font(.caption.bold())
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color(hex: "#4ade80").opacity(0.2))
                        .clipShape(Capsule())
                }
                .foregroundStyle(.secondary)

                HStack {
                    Label("Custom Timing", systemImage: "lock.fill")
                    Spacer()
                    Text("Pro")
                        .font(.caption.bold())
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color(hex: "#4ade80").opacity(0.2))
                        .clipShape(Capsule())
                }
                .foregroundStyle(.secondary)
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
                HStack {
                    Label("Alert Sound", systemImage: "lock.fill")
                    Spacer()
                    Text("Pro")
                        .font(.caption.bold())
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color(hex: "#4ade80").opacity(0.2))
                        .clipShape(Capsule())
                }
                .foregroundStyle(.secondary)
            }
            Toggle("Sounds", isOn: $settings.isSoundEnabled)
            Toggle("Haptics", isOn: $settings.isHapticsEnabled)
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

            Link("Privacy Policy", destination: URL(string: "https://parktimer.app/privacy")!)
        }
    }
}

#Preview {
    SettingsView()
}
