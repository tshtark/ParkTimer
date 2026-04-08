import ActivityKit
import WidgetKit
import SwiftUI

struct ParkingLiveActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: ParkingActivityAttributes.self) { context in
            // Lock Screen Live Activity
            lockScreenView(context: context)
                .padding()
                .activityBackgroundTint(Color.black.opacity(0.8))
        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded
                DynamicIslandExpandedRegion(.leading) {
                    Label(context.attributes.locationName, systemImage: "mappin.circle.fill")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    if context.state.isExpired {
                        Text("EXPIRED")
                            .font(.caption.bold())
                            .foregroundStyle(Color(hex: "#ff4a4a"))
                    }
                }
                DynamicIslandExpandedRegion(.center) {
                    timerDisplay(context: context)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    if let endDate = context.state.endDate, !context.state.isExpired {
                        ProgressView(
                            timerInterval: context.state.startDate...endDate,
                            countsDown: true
                        )
                        .tint(Color(hex: context.state.colorHex))
                    }
                }
            } compactLeading: {
                Image(systemName: "car.fill")
                    .foregroundStyle(Color(hex: context.state.colorHex))
            } compactTrailing: {
                if let endDate = context.state.endDate, !context.state.isExpired {
                    Text(timerInterval: Date()...endDate, countsDown: true)
                        .monospacedDigit()
                        .font(.caption2)
                        .foregroundStyle(Color(hex: context.state.colorHex))
                        .frame(width: 44)
                } else if context.state.isExpired {
                    Text("0:00")
                        .monospacedDigit()
                        .font(.caption2)
                        .foregroundStyle(Color(hex: "#ff4a4a"))
                } else {
                    // Unmetered: count up
                    Text(timerInterval: context.state.startDate...Date().addingTimeInterval(3600 * 24), countsDown: false)
                        .monospacedDigit()
                        .font(.caption2)
                        .foregroundStyle(.white)
                        .frame(width: 44)
                }
            } minimal: {
                Image(systemName: "car.fill")
                    .foregroundStyle(Color(hex: context.state.colorHex))
            }
        }
    }

    @ViewBuilder
    private func lockScreenView(context: ActivityViewContext<ParkingActivityAttributes>) -> some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "car.fill")
                    .foregroundStyle(Color(hex: context.state.colorHex))
                Text("ParkTimer")
                    .font(.headline)
                Spacer()
                Text(context.attributes.locationName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            timerDisplay(context: context)

            if let endDate = context.state.endDate, !context.state.isExpired {
                ProgressView(
                    timerInterval: context.state.startDate...endDate,
                    countsDown: true
                )
                .tint(Color(hex: context.state.colorHex))

                HStack {
                    Text("Expires")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(endDate, style: .time)
                        .font(.caption.bold())
                }
            }

            if context.state.isExpired {
                Text("METER EXPIRED — Move your car!")
                    .font(.caption.bold())
                    .foregroundStyle(Color(hex: "#ff4a4a"))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 4)
                    .background(Color(hex: "#ff4a4a").opacity(0.2))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
            }
        }
    }

    @ViewBuilder
    private func timerDisplay(context: ActivityViewContext<ParkingActivityAttributes>) -> some View {
        if let endDate = context.state.endDate, !context.state.isExpired {
            Text(timerInterval: Date()...endDate, countsDown: true)
                .font(.system(size: 36, weight: .bold, design: .monospaced))
                .foregroundStyle(Color(hex: context.state.colorHex))
                .contentTransition(.numericText())
        } else if context.state.isExpired {
            Text("0:00")
                .font(.system(size: 36, weight: .bold, design: .monospaced))
                .foregroundStyle(Color(hex: "#ff4a4a"))
        } else {
            // Unmetered elapsed
            Text(context.state.startDate, style: .timer)
                .font(.system(size: 36, weight: .bold, design: .monospaced))
                .foregroundStyle(.white)
        }
    }
}
