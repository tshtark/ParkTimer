import Foundation

struct ParkingSession: Codable, Identifiable, Sendable {
    let id: UUID
    let startDate: Date
    var meterEndDate: Date?          // nil = unmetered (count-up mode)
    var duration: TimeInterval?      // how long was purchased (metered only)
    let location: ParkingLocation
    let note: String?
    var alertMinutesBefore: Int      // default 10, configurable (paid)
    var isSmartAlertEnabled: Bool    // distance-aware (paid)
    var endedDate: Date?             // when user ended the session

    var isMetered: Bool { meterEndDate != nil }

    var displayDuration: TimeInterval {
        if let endedDate {
            return endedDate.timeIntervalSince(startDate)
        }
        return Date().timeIntervalSince(startDate)
    }

    var formattedAddress: String {
        location.address ?? "Unknown Location"
    }
}
