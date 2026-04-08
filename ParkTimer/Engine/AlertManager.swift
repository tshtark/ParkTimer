import Foundation
import UserNotifications

@MainActor
@Observable
final class AlertManager {
    static let shared = AlertManager()

    var isNotificationDenied = false

    func checkNotificationStatus() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        isNotificationDenied = settings.authorizationStatus == .denied
    }

    func requestPermission() async {
        do {
            let granted = try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound, .badge])
            print("[AlertManager] Permission \(granted ? "granted" : "denied")")
        } catch {
            print("[AlertManager] Permission error: \(error)")
        }
    }

    func scheduleAlert(for session: ParkingSession, walkingMinutes: Double? = nil) {
        guard let endDate = session.meterEndDate else { return }

        cancelAll()

        var leadMinutes = Double(session.alertMinutesBefore)

        // Smart alert: add walking time
        if session.isSmartAlertEnabled, let walking = walkingMinutes {
            leadMinutes = max(leadMinutes, walking + 2) // +2 min buffer
        }

        let alertDate = endDate.addingTimeInterval(-leadMinutes * 60)
        guard alertDate > Date() else { return }

        let content = UNMutableNotificationContent()
        content.title = "Meter Expiring Soon!"
        if let walking = walkingMinutes, walking > 1 {
            content.body = "Your meter expires in \(Int(leadMinutes)) min. It's about a \(Int(ceil(walking)))-minute walk back to your car."
        } else {
            content.body = "Your parking meter expires in \(Int(leadMinutes)) minutes. Head back to your car!"
        }
        content.sound = .default
        content.interruptionLevel = .timeSensitive

        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: alertDate.timeIntervalSince(Date()),
            repeats: false
        )

        let request = UNNotificationRequest(identifier: "parking-warning", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)

        // Also schedule an expiry notification
        let expiryContent = UNMutableNotificationContent()
        expiryContent.title = "Meter Expired!"
        expiryContent.body = "Your parking meter has expired. Move your car to avoid a ticket!"
        expiryContent.sound = .default
        expiryContent.interruptionLevel = .critical

        let expiryInterval = endDate.timeIntervalSince(Date())
        guard expiryInterval > 0 else { return }

        let expiryTrigger = UNTimeIntervalNotificationTrigger(
            timeInterval: expiryInterval,
            repeats: false
        )

        let expiryRequest = UNNotificationRequest(identifier: "parking-expired", content: expiryContent, trigger: expiryTrigger)
        UNUserNotificationCenter.current().add(expiryRequest)
    }

    func cancelAll() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
}
