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
                Annotation("My Car", coordinate: session.location.coordinate) {
                    Image(systemName: "car.fill")
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

                Button {
                    openInMaps(location: session.location)
                } label: {
                    Label("Open in Apple Maps", systemImage: "arrow.triangle.turn.up.right.diamond.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color(hex: "#4ade80"))
                        .foregroundStyle(.black)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
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
        VStack(spacing: 16) {
            Image(systemName: "car.fill")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text("No Active Session")
                .font(.title3.bold())
            Text("Start parking to save your car's location.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }

    // MARK: - Helpers

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
