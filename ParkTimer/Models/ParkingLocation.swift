import Foundation
import CoreLocation

struct ParkingLocation: Codable, Sendable {
    var latitude: Double
    var longitude: Double
    var address: String?
    var photoFilename: String?

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    var clLocation: CLLocation {
        CLLocation(latitude: latitude, longitude: longitude)
    }
}
