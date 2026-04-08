import SwiftUI

enum ParkingState: String, Codable, Sendable {
    case idle
    case active      // metered, >10 min remaining
    case warning     // metered, <=10 min remaining
    case expired     // metered, past end date
    case tracking    // unmetered, counting up

    var color: Color {
        switch self {
        case .idle: .secondary
        case .active: Color(hex: "#4ade80")
        case .warning: Color(hex: "#fbbf24")
        case .expired: Color(hex: "#ff4a4a")
        case .tracking: .white
        }
    }

    var colorHex: String {
        switch self {
        case .idle: "#8E8E93"
        case .active: "#4ade80"
        case .warning: "#fbbf24"
        case .expired: "#ff4a4a"
        case .tracking: "#FFFFFF"
        }
    }

    var label: String {
        switch self {
        case .idle: "Ready"
        case .active: "Active"
        case .warning: "Warning"
        case .expired: "Expired"
        case .tracking: "Tracking"
        }
    }
}

// MARK: - Color Hex Extension

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r = Double((int >> 16) & 0xFF) / 255.0
        let g = Double((int >> 8) & 0xFF) / 255.0
        let b = Double(int & 0xFF) / 255.0
        self.init(red: r, green: g, blue: b)
    }
}
