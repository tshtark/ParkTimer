import SwiftUI

struct WelcomeSheet: View {
    let onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            // App icon
            Image(systemName: "car.fill")
                .font(.system(size: 56))
                .foregroundStyle(Color(hex: "#4ade80"))

            Text("Welcome to ParkTimer")
                .font(.title2.bold())

            Text("Never get a parking ticket again.")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            // Free features
            VStack(alignment: .leading, spacing: 10) {
                featureRow(icon: "timer", text: "Countdown timer on your Lock Screen")
                featureRow(icon: "mappin.circle.fill", text: "Save your car's location automatically")
                featureRow(icon: "camera.fill", text: "Photo of your parking spot")
                featureRow(icon: "bell.fill", text: "Alert before your meter expires")
            }
            .padding()
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 16))

            // Pro teaser
            HStack(spacing: 10) {
                Image(systemName: "sparkles")
                    .foregroundStyle(Color(hex: "#fbbf24"))
                VStack(alignment: .leading, spacing: 2) {
                    Text("ParkTimer Pro")
                        .font(.subheadline.bold())
                    Text("Smart alerts based on walking distance, custom timing, full history, and more.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding()
            .background(Color(hex: "#fbbf24").opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 12))

            Spacer()

            Button {
                onDismiss()
            } label: {
                Text("Get Started")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color(hex: "#4ade80"))
                    .foregroundStyle(.black)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            }
        }
        .padding(24)
        .interactiveDismissDisabled()
    }

    private func featureRow(icon: String, text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(Color(hex: "#4ade80"))
                .frame(width: 24)
            Text(text)
                .font(.subheadline)
        }
    }
}
