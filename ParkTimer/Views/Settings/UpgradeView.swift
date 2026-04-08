import SwiftUI

struct UpgradeView: View {
    private var store = StoreManager.shared

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                headerSection
                featuresSection
                purchaseButton
                restoreButton
            }
            .padding()
        }
        .navigationTitle("Upgrade to Pro")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var headerSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "star.circle.fill")
                .font(.system(size: 64))
                .foregroundStyle(Color(hex: "#4ade80"))

            Text("ParkTimer Pro")
                .font(.title.bold())

            Text("Pay once, own forever.\nNo subscriptions, no ads.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
    }

    private var featuresSection: some View {
        VStack(spacing: 12) {
            featureRow(icon: "location.circle.fill", title: "Smart Alerts",
                       description: "Distance-aware alerts that account for walking time")

            featureRow(icon: "slider.horizontal.3", title: "Custom Timing",
                       description: "Choose 5, 10, 15, 20, or 30 min before expiry")

            featureRow(icon: "clock.arrow.circlepath", title: "Full History",
                       description: "Access all your past parking sessions")

            featureRow(icon: "dollarsign.circle.fill", title: "Parking Cost Tracker",
                       description: "Track what you spend — per session and monthly totals")

            featureRow(icon: "chart.bar.fill", title: "Monthly Statistics",
                       description: "Sessions, hours parked, and total cost at a glance")

            featureRow(icon: "plus.circle.fill", title: "Extend Time",
                       description: "Add time to a running meter without restarting")

            featureRow(icon: "speaker.wave.2.fill", title: "Sound Choices",
                       description: "Multiple alert sounds to choose from")
        }
    }

    private func featureRow(icon: String, title: String, description: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(Color(hex: "#4ade80"))
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var purchaseButton: some View {
        VStack(spacing: 8) {
            Button {
                Task { await store.purchase() }
            } label: {
                VStack(spacing: 4) {
                    Text("Unlock Pro")
                        .font(.headline)
                    if let product = store.product {
                        Text(product.displayPrice)
                            .font(.subheadline)
                    } else {
                        Text("$4.99")
                            .font(.subheadline)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color(hex: "#4ade80"))
                .foregroundStyle(.black)
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }

            if let error = store.purchaseError {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
            }
        }
    }

    private var restoreButton: some View {
        Button("Restore Purchases") {
            Task { await store.restorePurchases() }
        }
        .font(.subheadline)
    }
}

#Preview {
    NavigationStack {
        UpgradeView()
    }
}
