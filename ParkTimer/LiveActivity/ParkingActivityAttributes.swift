import ActivityKit
import Foundation

struct ParkingActivityAttributes: ActivityAttributes {
    let sessionType: String   // "metered" or "unmetered"
    let locationName: String

    struct ContentState: Codable, Hashable {
        let endDate: Date?       // nil for unmetered
        let startDate: Date      // for elapsed time (unmetered)
        let colorHex: String
        let isPaused: Bool
        let isExpired: Bool
    }
}
