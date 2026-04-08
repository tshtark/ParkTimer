import Foundation
import CoreLocation

@MainActor
@Observable
final class LocationManager: NSObject {
    var currentLocation: CLLocation?
    var authorizationStatus: CLAuthorizationStatus = .notDetermined
    var distanceToCar: CLLocationDistance?
    var walkingMinutesToCar: Double?

    private let manager = CLLocationManager()
    private let geocoder = CLGeocoder()

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        authorizationStatus = manager.authorizationStatus
    }

    func requestPermission() {
        manager.requestWhenInUseAuthorization()
    }

    func requestLocation() {
        guard authorizationStatus == .authorizedWhenInUse ||
              authorizationStatus == .authorizedAlways else {
            requestPermission()
            return
        }
        manager.requestLocation()
    }

    func startUpdating() {
        manager.startUpdatingLocation()
    }

    func stopUpdating() {
        manager.stopUpdatingLocation()
    }

    func updateDistanceToCar(carLocation: ParkingLocation) {
        guard let current = currentLocation else {
            distanceToCar = nil
            walkingMinutesToCar = nil
            return
        }
        let distance = current.distance(from: carLocation.clLocation)
        distanceToCar = distance
        walkingMinutesToCar = distance / 80.0 // 80 meters per minute walking speed
    }

    func reverseGeocode(latitude: Double, longitude: Double) async -> String? {
        let location = CLLocation(latitude: latitude, longitude: longitude)
        do {
            let placemarks = try await geocoder.reverseGeocodeLocation(location)
            if let placemark = placemarks.first {
                var parts: [String] = []
                if let name = placemark.name { parts.append(name) }
                if let locality = placemark.locality { parts.append(locality) }
                return parts.isEmpty ? nil : parts.joined(separator: ", ")
            }
        } catch {
            print("[LocationManager] Geocode failed: \(error)")
        }
        return nil
    }
}

// MARK: - CLLocationManagerDelegate

extension LocationManager: @preconcurrency CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        currentLocation = locations.last
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("[LocationManager] Error: \(error.localizedDescription)")
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
        if authorizationStatus == .authorizedWhenInUse {
            manager.requestLocation()
        }
    }
}
