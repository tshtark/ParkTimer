import UIKit

@MainActor
final class HapticManager {
    static let shared = HapticManager()

    private let heavy = UIImpactFeedbackGenerator(style: .heavy)
    private let medium = UIImpactFeedbackGenerator(style: .medium)
    private let light = UIImpactFeedbackGenerator(style: .light)
    private let notification = UINotificationFeedbackGenerator()

    func prepare() {
        heavy.prepare()
        medium.prepare()
        light.prepare()
        notification.prepare()
    }

    func warningFeedback() {
        guard SettingsManager.shared.isHapticsEnabled else { return }
        medium.impactOccurred()
    }

    func expiredFeedback() {
        guard SettingsManager.shared.isHapticsEnabled else { return }
        heavy.impactOccurred()
        notification.notificationOccurred(.error)
    }

    func tapFeedback() {
        guard SettingsManager.shared.isHapticsEnabled else { return }
        light.impactOccurred()
    }

    func successFeedback() {
        guard SettingsManager.shared.isHapticsEnabled else { return }
        notification.notificationOccurred(.success)
    }
}
