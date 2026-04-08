import SwiftUI

struct CountdownDisplay: View {
    let timeRemaining: TimeInterval
    let state: ParkingState

    @State private var pulseScale: CGFloat = 1.0

    var body: some View {
        VStack(spacing: 8) {
            Text(TimeFormatting.countdown(timeRemaining))
                .font(.system(size: 64, weight: .bold, design: .monospaced))
                .foregroundStyle(state.color)
                .contentTransition(.numericText())
                .animation(.linear(duration: 0.1), value: Int(timeRemaining))
                .scaleEffect(pulseScale)
                .animation(.easeInOut(duration: 0.5), value: state)

            Text("remaining")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .onChange(of: state) { oldState, newState in
            // Pulse when transitioning to warning or expired
            if (oldState == .active && newState == .warning) ||
               (oldState == .warning && newState == .expired) {
                withAnimation(.easeInOut(duration: 0.15)) {
                    pulseScale = 1.12
                }
                withAnimation(.easeInOut(duration: 0.3).delay(0.15)) {
                    pulseScale = 1.0
                }
            }
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
