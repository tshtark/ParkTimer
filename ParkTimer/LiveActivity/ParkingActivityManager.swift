import ActivityKit
import Foundation

@MainActor
final class ParkingActivityManager {
    static let shared = ParkingActivityManager()

    private var activityId: String?

    func start(session: ParkingSession) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }

        let attributes = ParkingActivityAttributes(
            sessionType: session.isMetered ? "metered" : "unmetered",
            locationName: session.formattedAddress
        )

        let state = ParkingActivityAttributes.ContentState(
            endDate: session.meterEndDate,
            startDate: session.startDate,
            colorHex: ParkingState.active.colorHex,
            isPaused: false,
            isExpired: false
        )

        do {
            let activity = try Activity.request(
                attributes: attributes,
                content: .init(state: state, staleDate: session.meterEndDate)
            )
            activityId = activity.id
        } catch {
            print("[LiveActivity] Start failed: \(error)")
        }
    }

    func update(state: ParkingState, session: ParkingSession) {
        guard let activityId,
              let activity = Activity<ParkingActivityAttributes>.activities.first(where: { $0.id == activityId })
        else { return }

        let contentState = ParkingActivityAttributes.ContentState(
            endDate: session.meterEndDate,
            startDate: session.startDate,
            colorHex: state.colorHex,
            isPaused: false,
            isExpired: state == .expired
        )

        let content = ActivityContent(state: contentState, staleDate: session.meterEndDate)
        nonisolated(unsafe) let unsafeActivity = activity
        Task { await unsafeActivity.update(content) }
    }

    func end() {
        guard let activityId,
              let activity = Activity<ParkingActivityAttributes>.activities.first(where: { $0.id == activityId })
        else {
            self.activityId = nil
            return
        }

        nonisolated(unsafe) let unsafeActivity = activity
        Task {
            await unsafeActivity.end(nil, dismissalPolicy: .default)
        }
        self.activityId = nil
    }
}
