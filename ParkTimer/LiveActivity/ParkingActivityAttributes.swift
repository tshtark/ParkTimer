import ActivityKit
import Foundation

struct ParkingActivityAttributes: ActivityAttributes {
    let sessionId: String     // stable UUID so we can find our activity after relaunch
    let sessionType: String   // "metered" or "unmetered"

    struct ContentState: Codable, Hashable {
        let endDate: Date?       // nil for unmetered
        let startDate: Date      // for elapsed time (unmetered)
        let locationName: String // mutable so GPS resolving late still updates the Live Activity
        let colorHex: String
        let isPaused: Bool
        let isExpired: Bool
    }
}
