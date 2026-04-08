import SwiftUI

struct CountdownDisplay: View {
    let timeRemaining: TimeInterval
    let state: ParkingState

    var body: some View {
        VStack(spacing: 8) {
            Text(TimeFormatting.countdown(timeRemaining))
                .font(.system(size: 64, weight: .bold, design: .monospaced))
                .foregroundStyle(state.color)
                .contentTransition(.numericText())
                .animation(.linear(duration: 0.1), value: Int(timeRemaining))

            Text("remaining")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    VStack(spacing: 40) {
        CountdownDisplay(timeRemaining: 3600, state: .active)
        CountdownDisplay(timeRemaining: 300, state: .warning)
        CountdownDisplay(timeRemaining: 0, state: .expired)
    }
    .padding()
    .background(Color(.systemBackground))
}
