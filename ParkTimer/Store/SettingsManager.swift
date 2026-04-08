import Foundation

@MainActor
@Observable
final class SettingsManager {
    static let shared = SettingsManager()

    private static let keySound = "settings.soundEnabled"
    private static let keyHaptics = "settings.hapticsEnabled"
    private static let keyAlertMinutes = "settings.alertMinutes"
    private static let keySmartAlerts = "settings.smartAlerts"
    private static let keyAlertSound = "settings.alertSound"

    var isSoundEnabled: Bool {
        didSet { UserDefaults.standard.set(isSoundEnabled, forKey: Self.keySound) }
    }

    var isHapticsEnabled: Bool {
        didSet { UserDefaults.standard.set(isHapticsEnabled, forKey: Self.keyHaptics) }
    }

    var alertMinutesBefore: Int {
        didSet { UserDefaults.standard.set(alertMinutesBefore, forKey: Self.keyAlertMinutes) }
    }

    var isSmartAlertsEnabled: Bool {
        didSet { UserDefaults.standard.set(isSmartAlertsEnabled, forKey: Self.keySmartAlerts) }
    }

    var selectedAlertSound: AlertSound {
        didSet { UserDefaults.standard.set(selectedAlertSound.rawValue, forKey: Self.keyAlertSound) }
    }

    private init() {
        let defaults = UserDefaults.standard

        // Register defaults
        defaults.register(defaults: [
            Self.keySound: true,
            Self.keyHaptics: true,
            Self.keyAlertMinutes: 10,
            Self.keySmartAlerts: false,
        ])

        isSoundEnabled = defaults.bool(forKey: Self.keySound)
        isHapticsEnabled = defaults.bool(forKey: Self.keyHaptics)
        alertMinutesBefore = defaults.integer(forKey: Self.keyAlertMinutes)
        isSmartAlertsEnabled = defaults.bool(forKey: Self.keySmartAlerts)
        selectedAlertSound = AlertSound(rawValue: defaults.string(forKey: Self.keyAlertSound) ?? "") ?? .standard
    }
}
