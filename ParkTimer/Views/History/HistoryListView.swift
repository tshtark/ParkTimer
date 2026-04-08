import SwiftUI

struct HistoryListView: View {
    let historyStore: HistoryStore

    @State private var selectedSession: ParkingSession?

    private var isPro: Bool { StoreManager.shared.isProUnlocked }

    var body: some View {
        NavigationStack {
            Group {
                if historyStore.sessions.isEmpty {
                    emptyView
                } else {
                    sessionList
                }
            }
            .navigationTitle("History")
            .sheet(item: $selectedSession) { session in
                SessionDetailView(session: session)
            }
        }
    }

    private var emptyView: some View {
        VStack(spacing: 16) {
            Image(systemName: "clock.fill")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text("No History Yet")
                .font(.title3.bold())
            Text("Your completed parking sessions will appear here.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }

    private var sessionList: some View {
        List {
            ForEach(Array(historyStore.sessions.enumerated()), id: \.element.id) { index, session in
                Button {
                    if isPro || index < 3 {
                        selectedSession = session
                    }
                } label: {
                    sessionRow(session: session, index: index)
                }
                .listRowBackground(Color(.systemBackground))
            }

            if !isPro && historyStore.sessions.count > 3 {
                upgradePrompt
            }
        }
        .listStyle(.plain)
    }

    private func sessionRow(session: ParkingSession, index: Int) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(session.formattedAddress)
                    .font(.subheadline.weight(.medium))
                    .lineLimit(1)

                HStack(spacing: 8) {
                    Text(session.startDate.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    if session.isMetered {
                        let wasExpired = session.endedDate.map { ended in
                            session.meterEndDate.map { ended > $0 } ?? false
                        } ?? false

                        Text(TimeFormatting.durationText(session.duration ?? 0))
                            .font(.caption.bold())
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background((wasExpired ? Color(hex: "#ff4a4a") : Color(hex: "#4ade80")).opacity(0.2))
                            .clipShape(Capsule())

                        if wasExpired {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.caption2)
                                .foregroundStyle(Color(hex: "#ff4a4a"))
                        }
                    } else {
                        Text("Unmetered")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Spacer()

            if !isPro && index >= 3 {
                Image(systemName: "lock.fill")
                    .foregroundStyle(.secondary)
            } else {
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
        .blur(radius: !isPro && index >= 3 ? 4 : 0)
    }

    private var upgradePrompt: some View {
        VStack(spacing: 8) {
            Image(systemName: "lock.circle.fill")
                .font(.title2)
                .foregroundStyle(Color(hex: "#4ade80"))

            Text("Unlock Full History")
                .font(.subheadline.bold())

            Text("Upgrade to Pro to see all past sessions.")
                .font(.caption)
                .foregroundStyle(.secondary)

            NavigationLink {
                UpgradeView()
            } label: {
                Text("Upgrade — $4.99")
                    .font(.subheadline.bold())
                    .padding(.horizontal, 20)
                    .padding(.vertical, 8)
                    .background(Color(hex: "#4ade80"))
                    .foregroundStyle(.black)
                    .clipShape(Capsule())
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .listRowBackground(Color(.systemBackground))
    }
}
