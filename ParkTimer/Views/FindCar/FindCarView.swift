import SwiftUI
import MapKit

struct FindCarView: View {
    let engine: ParkingEngine
    let locationManager: LocationManager

    @State private var cameraPosition: MapCameraPosition = .automatic

    var body: some View {
        NavigationStack {
            Group {
                if let session = engine.session {
                    activeView(session: session)
                } else {
                    emptyView
                }
            }
            .navigationTitle("Find Car")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    // MARK: - Active

    private func activeView(session: ParkingSession) -> some View {
        VStack(spacing: 0) {
            Map(position: $cameraPosition) {
                // Car pin
                Annotation("My \(SettingsManager.shared.vehicleType.displayName)", coordinate: session.location.coordinate) {
                    Image(systemName: SettingsManager.shared.vehicleType.iconName)
                        .font(.title2)
                        .foregroundStyle(.white)
                        .padding(8)
                        .background(Color(hex: "#4ade80"))
                        .clipShape(Circle())
                }

                // User location
                UserAnnotation()
            }
            .mapControls {
                MapUserLocationButton()
                MapCompass()
            }
            .frame(maxHeight: .infinity)

            // Bottom card
            VStack(spacing: 12) {
                if let address = session.location.address {
                    HStack {
                        Image(systemName: "mappin.circle.fill")
                            .foregroundStyle(Color(hex: "#4ade80"))
                        Text(address)
                            .font(.subheadline)
                        Spacer()
                    }
                }

                if let distance = locationManager.distanceToCar {
                    HStack {
                        Image(systemName: "figure.walk")
                            .foregroundStyle(.blue)
                        Text(TimeFormatting.distanceText(distance))
                            .font(.subheadline)
                        if let minutes = locationManager.walkingMinutesToCar {
                            Text("(\(Int(ceil(minutes))) min walk)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                    }
                }

                if let note = session.note, !note.isEmpty {
                    HStack {
                        Image(systemName: "note.text")
                            .foregroundStyle(.secondary)
                        Text(note)
                            .font(.subheadline)
                        Spacer()
                    }
                }

                // Photo thumbnail
                if let photoFilename = session.location.photoFilename,
                   let image = loadPhoto(filename: photoFilename) {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: 120)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }

                HStack(spacing: 12) {
                    Button {
                        openInMaps(location: session.location)
                    } label: {
                        Label("Directions", systemImage: "arrow.triangle.turn.up.right.diamond.fill")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color(hex: "#4ade80"))
                            .foregroundStyle(.black)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }

                    ShareLink(item: shareText(for: session)) {
                        Label("Share", systemImage: "square.and.arrow.up")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color(.systemGray5))
                            .foregroundStyle(.primary)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
            }
            .padding()
            .background(Color(.systemBackground))
        }
        .onAppear {
            locationManager.startUpdating()
            if let session = engine.session {
                locationManager.updateDistanceToCar(carLocation: session.location)
            }
        }
        .onDisappear {
            locationManager.stopUpdating()
        }
    }

    // MARK: - Empty

    private var emptyView: some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: "mappin.slash")
                .font(.system(size: 56))
                .foregroundStyle(Color(hex: "#4ade80").opacity(0.4))

            Text("No Car Saved")
                .font(.title2.bold())

            Text("When you start a parking session,\nyour car's location will appear here\nwith walking directions.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .lineSpacing(2)

            Spacer()
        }
        .padding()
    }

    // MARK: - Helpers

    private func shareText(for session: ParkingSession) -> String {
        let address = session.formattedAddress
        let lat = session.location.latitude
        let lng = session.location.longitude
        let mapsURL = "https://maps.apple.com/?ll=\(lat),\(lng)&q=My%20Car"

        if let note = session.note, !note.isEmpty {
            return "My car is parked at \(address) (\(note))\n\(mapsURL)"
        }
        return "My car is parked at \(address)\n\(mapsURL)"
    }

    private func openInMaps(location: ParkingLocation) {
        let placemark = MKPlacemark(coordinate: location.coordinate)
        let item = MKMapItem(placemark: placemark)
        item.name = "My Car"
        item.openInMaps(launchOptions: [
            MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeWalking
        ])
    }

    private func loadPhoto(filename: String) -> UIImage? {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let url = docs.appendingPathComponent("photos").appendingPathComponent(filename)
        guard let data = try? Data(contentsOf: url) else { return nil }
        return UIImage(data: data)
    }
}
