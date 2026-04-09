import ActivityKit
import Foundation

@MainActor
final class ParkingActivityManager {
    static let shared = ParkingActivityManager()

    /// Finds the currently-known activity for the given session. Works across process
    /// restarts because we look it up by the sessionId embedded in attributes, not an
    /// in-memory cache that dies with the app.
    private func activity(for sessionId: UUID) -> Activity<ParkingActivityAttributes>? {
        let target = sessionId.uuidString
        return Activity<ParkingActivityAttributes>.activities.first { $0.attributes.sessionId == target }
    }

    /// End every live ParkTimer activity — including orphans from previous app processes.
    /// Uses `.immediate` so nothing lingers on the Lock Screen.
    private func endAllActivities() async {
        for activity in Activity<ParkingActivityAttributes>.activities {
            nonisolated(unsafe) let target = activity
            await target.end(nil, dismissalPolicy: .immediate)
        }
    }

    /// Start a Live Activity for the given session. Any pre-existing activities (including
    /// orphans from prior processes) are ended first so the Lock Screen never shows stale
    /// data from a previous session.
    func start(session: ParkingSession) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }

        let attributes = ParkingActivityAttributes(
            sessionId: session.id.uuidString,
            sessionType: session.isMetered ? "metered" : "unmetered"
        )

        let state = ParkingActivityAttributes.ContentState(
            endDate: session.meterEndDate,
            startDate: session.startDate,
            locationName: session.formattedAddress,
            colorHex: ParkingState.active.colorHex,
            isPaused: false,
            isExpired: false
        )

        // End every existing activity synchronously-ish before requesting a new one, so
        // we don't race the user locking their phone.
        let existing = Activity<ParkingActivityAttributes>.activities
        for activity in existing {
            nonisolated(unsafe) let orphan = activity
            Task { await orphan.end(nil, dismissalPolicy: .immediate) }
        }

        do {
            _ = try Activity.request(
                attributes: attributes,
                content: .init(state: state, staleDate: session.meterEndDate)
            )
        } catch {
            print("[LiveActivity] Start failed: \(error)")
        }
    }

    func update(state: ParkingState, session: ParkingSession) {
        guard let activity = activity(for: session.id) else { return }

        let contentState = ParkingActivityAttributes.ContentState(
            endDate: session.meterEndDate,
            startDate: session.startDate,
            locationName: session.formattedAddress,
            colorHex: state.colorHex,
            isPaused: false,
            isExpired: state == .expired
        )

        let content = ActivityContent(state: contentState, staleDate: session.meterEndDate)
        nonisolated(unsafe) let unsafeActivity = activity
        Task { await unsafeActivity.update(content) }
    }

    /// End the Live Activity for this session. Uses `.immediate` so the activity vanishes
    /// from the Lock Screen as soon as the user ends parking.
    func end(session: ParkingSession) {
        guard let activity = activity(for: session.id) else {
            // No activity for this session id — still clean up any orphans so nothing lingers.
            Task { await endAllActivities() }
            return
        }

        nonisolated(unsafe) let unsafeActivity = activity
        Task {
            await unsafeActivity.end(nil, dismissalPolicy: .immediate)
        }
    }

    /// Called on app launch after the engine has resumed any persisted session.
    /// Reconciles live activities with the current engine state:
    /// - If the engine has an active session and there's a matching activity → keep it (reclaim).
    /// - If the engine has an active session but no matching activity → start a fresh one.
    /// - Any activities that don't match (orphans from prior processes) → end immediately.
    /// - If the engine has no session → end everything.
    func reclaimOrCleanup(activeSession: ParkingSession?) {
        let targetId = activeSession?.id.uuidString
        let existing = Activity<ParkingActivityAttributes>.activities

        var hasMatching = false
        for activity in existing {
            if let targetId, activity.attributes.sessionId == targetId {
                hasMatching = true
                continue
            }
            nonisolated(unsafe) let orphan = activity
            Task { await orphan.end(nil, dismissalPolicy: .immediate) }
        }

        // Active session with no matching activity → recreate so the Lock Screen doesn't
        // fall silent on a session that's still running.
        if let activeSession, !hasMatching {
            start(session: activeSession)
        }
    }
}
