import Foundation
import CoreLocation

struct ParkingLocation: Codable, Sendable {
    let latitude: Double
    let longitude: Double
    let address: String?
    let photoFilename: String?

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    var clLocation: CLLocation {
        CLLocation(latitude: latitude, longitude: longitude)
    }
}
