import SwiftUI
import MapKit

struct SessionDetailView: View {
    let session: ParkingSession

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    mapSection
                    detailsSection
                    photoSection
                }
                .padding()
            }
            .navigationTitle("Session Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private var mapSection: some View {
        Map {
            Annotation("Car", coordinate: session.location.coordinate) {
                Image(systemName: "car.fill")
                    .font(.title3)
                    .foregroundStyle(.white)
                    .padding(6)
                    .background(Color(hex: "#4ade80"))
                    .clipShape(Circle())
            }
        }
        .frame(height: 200)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var detailsSection: some View {
        VStack(spacing: 12) {
            detailRow(icon: "mappin.circle.fill", label: "Location", value: session.formattedAddress)

            detailRow(
                icon: "calendar",
                label: "Date",
                value: session.startDate.formatted(date: .abbreviated, time: .shortened)
            )

            if session.isMetered {
                detailRow(
                    icon: "timer",
                    label: "Duration",
                    value: TimeFormatting.durationText(session.duration ?? 0)
                )

                if let endedDate = session.endedDate, let meterEnd = session.meterEndDate {
                    let wasExpired = endedDate > meterEnd
                    detailRow(
                        icon: wasExpired ? "exclamationmark.triangle.fill" : "checkmark.circle.fill",
                        label: "Status",
                        value: wasExpired ? "Expired" : "Ended on time"
                    )
                }
            } else {
                detailRow(
                    icon: "timer",
                    label: "Time Parked",
                    value: TimeFormatting.durationText(session.displayDuration)
                )
            }

            if let note = session.note, !note.isEmpty {
                detailRow(icon: "note.text", label: "Note", value: note)
            }
        }
    }

    private func detailRow(icon: String, label: String, value: String) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundStyle(Color(hex: "#4ade80"))
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.subheadline)
            }
            Spacer()
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var photoSection: some View {
        Group {
            if let filename = session.location.photoFilename,
               let image = loadPhoto(filename: filename) {
                VStack(alignment: .leading) {
                    Text("Parking Photo")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
        }
    }

    private func loadPhoto(filename: String) -> UIImage? {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let url = docs.appendingPathComponent("photos").appendingPathComponent(filename)
        guard let data = try? Data(contentsOf: url) else { return nil }
        return UIImage(data: data)
    }
}
