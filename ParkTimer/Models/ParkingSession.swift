import Foundation

struct ParkingSession: Codable, Identifiable, Sendable {
    let id: UUID
    let startDate: Date
    var meterEndDate: Date?          // nil = unmetered (count-up mode)
    var duration: TimeInterval?      // how long was purchased (metered only)
    var location: ParkingLocation    // mutable so late-arriving GPS can update the address
    let note: String?
    var alertMinutesBefore: Int      // default 10, configurable (paid)
    var isSmartAlertEnabled: Bool    // distance-aware (paid)
    var endedDate: Date?             // when user ended the session
    var hourlyRate: Double?          // parking cost per hour (Pro)

    var isMetered: Bool { meterEndDate != nil }

    var totalCost: Double? {
        guard let rate = hourlyRate, rate > 0 else { return nil }
        let hours = displayDuration / 3600.0
        return hours * rate
    }

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
