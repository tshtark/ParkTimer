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
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 56))
                .foregroundStyle(Color(hex: "#4ade80").opacity(0.4))

            Text("No Sessions Yet")
                .font(.title2.bold())

            Text("Your completed parking sessions\nwill appear here with location,\nduration, and details.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .lineSpacing(2)

            Spacer()
        }
        .padding()
    }

    // MARK: - Monthly Stats

    private var monthlyStats: (sessions: Int, hours: Double, cost: Double) {
        let calendar = Calendar.current
        let now = Date()
        let thisMonth = historyStore.sessions.filter {
            calendar.isDate($0.startDate, equalTo: now, toGranularity: .month)
        }
        let totalHours = thisMonth.reduce(0.0) { $0 + $1.displayDuration } / 3600.0
        let totalCost = thisMonth.compactMap(\.totalCost).reduce(0.0, +)
        return (thisMonth.count, totalHours, totalCost)
    }

    @ViewBuilder
    private var statsCard: some View {
        if !historyStore.sessions.isEmpty {
            let stats = monthlyStats
            VStack(spacing: 8) {
                Text("This Month")
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                HStack(spacing: 0) {
                    statItem(value: "\(stats.sessions)", label: "sessions")
                    Divider().frame(height: 32)
                    statItem(value: String(format: "%.1fh", stats.hours), label: "parked")
                    if stats.cost > 0 {
                        Divider().frame(height: 32)
                        statItem(value: String(format: "$%.0f", stats.cost), label: "spent")
                    }
                }
            }
            .padding()
            .background(Color(hex: "#4ade80").opacity(0.06))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .listRowSeparator(.hidden)
            .listRowBackground(Color(.systemBackground))
            .blur(radius: isPro ? 0 : 3)
            .overlay {
                if !isPro {
                    NavigationLink {
                        UpgradeView()
                    } label: {
                        Label("Unlock Stats", systemImage: "lock.fill")
                            .font(.caption.bold())
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(.ultraThinMaterial)
                            .clipShape(Capsule())
                    }
                }
            }
        }
    }

    private func statItem(value: String, label: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.title3.bold())
                .foregroundStyle(Color(hex: "#4ade80"))
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    private var sessionList: some View {
        List {
            statsCard

            // Unlocked items (deletable)
            if isPro {
                ForEach(Array(historyStore.sessions.enumerated()), id: \.element.id) { index, session in
                    Button {
                        selectedSession = session
                    } label: {
                        sessionRow(session: session, isLocked: false)
                    }
                    .listRowBackground(Color(.systemBackground))
                }
                .onDelete { offsets in
                    historyStore.delete(at: offsets)
                }
            } else {
                // Free: first 3 unlocked (deletable)
                ForEach(Array(historyStore.sessions.prefix(3).enumerated()), id: \.element.id) { _, session in
                    Button {
                        selectedSession = session
                    } label: {
                        sessionRow(session: session, isLocked: false)
                    }
                    .listRowBackground(Color(.systemBackground))
                }
                .onDelete { offsets in
                    historyStore.delete(at: offsets)
                }

                // Free: next 3 blurred (not deletable, not tappable)
                ForEach(Array(historyStore.sessions.dropFirst(3).prefix(3).enumerated()), id: \.element.id) { _, session in
                    sessionRow(session: session, isLocked: true)
                        .listRowBackground(Color(.systemBackground))
                }

                if historyStore.sessions.count > 3 {
                    upgradePrompt
                }
            }
        }
        .listStyle(.plain)
    }

    private func sessionRow(session: ParkingSession, isLocked: Bool) -> some View {
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

                    if let cost = session.totalCost {
                        Text(String(format: "$%.2f", cost))
                            .font(.caption.bold())
                            .foregroundStyle(Color(hex: "#fbbf24"))
                    }
                }
            }

            Spacer()

            if isLocked {
                Image(systemName: "lock.fill")
                    .foregroundStyle(.secondary)
            } else {
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
        .blur(radius: isLocked ? 4 : 0)
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
