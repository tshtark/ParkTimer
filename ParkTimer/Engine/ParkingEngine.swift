import Foundation

@MainActor
@Observable
final class ParkingEngine {
    // Observable state
    var state: ParkingState = .idle
    var timeRemaining: TimeInterval = 0
    var elapsedTime: TimeInterval = 0
    var session: ParkingSession?

    // Callbacks
    var onWarning: (() -> Void)?
    var onExpired: (() -> Void)?
    var onTick: (() -> Void)?

    // Private
    private var timer: Timer?
    private var warningFired = false

    var progress: Double {
        guard let session, let duration = session.duration, duration > 0 else { return 0 }
        return max(0, min(1, timeRemaining / duration))
    }

    var isActive: Bool {
        state != .idle
    }

    // MARK: - Start

    func startMetered(duration: TimeInterval, location: ParkingLocation, note: String?,
                      alertMinutes: Int, smartAlert: Bool, hourlyRate: Double? = nil) {
        let now = Date()
        session = ParkingSession(
            id: UUID(),
            startDate: now,
            meterEndDate: now.addingTimeInterval(duration),
            duration: duration,
            location: location,
            note: note,
            alertMinutesBefore: alertMinutes,
            isSmartAlertEnabled: smartAlert,
            endedDate: nil,
            hourlyRate: hourlyRate
        )
        warningFired = false
        state = .active
        timeRemaining = duration
        startTick()
    }

    func startUnmetered(location: ParkingLocation, note: String?, hourlyRate: Double? = nil) {
        session = ParkingSession(
            id: UUID(),
            startDate: Date(),
            meterEndDate: nil,
            duration: nil,
            location: location,
            note: note,
            alertMinutesBefore: 0,
            isSmartAlertEnabled: false,
            endedDate: nil,
            hourlyRate: hourlyRate
        )
        state = .tracking
        elapsedTime = 0
        startTick()
    }

    // MARK: - Resume (from persistence)

    func resume(session: ParkingSession) {
        self.session = session
        warningFired = false

        if let endDate = session.meterEndDate {
            let remaining = endDate.timeIntervalSince(Date())
            timeRemaining = max(0, remaining)
            elapsedTime = Date().timeIntervalSince(session.startDate)

            if remaining <= 0 {
                state = .expired
                warningFired = true
            } else if remaining <= 600 {
                state = .warning
                warningFired = true
            } else {
                state = .active
            }
        } else {
            state = .tracking
            elapsedTime = Date().timeIntervalSince(session.startDate)
        }
        startTick()
    }

    // MARK: - Extend Time (paid)

    func extendTime(by minutes: Int) {
        guard var updatedSession = session,
              updatedSession.isMetered,
              let oldEnd = updatedSession.meterEndDate else { return }

        let extra = TimeInterval(minutes * 60)
        updatedSession.meterEndDate = oldEnd.addingTimeInterval(extra)
        updatedSession.duration = (updatedSession.duration ?? 0) + extra
        session = updatedSession
        timeRemaining = updatedSession.meterEndDate!.timeIntervalSince(Date())

        // Reset state if was expired/warning
        if timeRemaining > 600 {
            state = .active
            warningFired = false
        } else if timeRemaining > 0 {
            state = .warning
        }
    }

    // MARK: - Stop

    func stop() -> ParkingSession? {
        timer?.invalidate()
        timer = nil

        var completed = session
        completed?.endedDate = Date()

        session = nil
        state = .idle
        timeRemaining = 0
        elapsedTime = 0
        warningFired = false

        return completed
    }

    // MARK: - Timer

    private func startTick() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated {
                self?.tick()
            }
        }
    }

    private func tick() {
        guard let session else { return }

        if let endDate = session.meterEndDate {
            // Metered: wall-clock countdown
            timeRemaining = max(0, endDate.timeIntervalSince(Date()))
            elapsedTime = Date().timeIntervalSince(session.startDate)

            if timeRemaining <= 0 && state != .expired {
                state = .expired
                onExpired?()
            } else if timeRemaining <= 600 && state == .active {
                state = .warning
                if !warningFired {
                    warningFired = true
                    onWarning?()
                }
            }
        } else {
            // Unmetered: count up
            elapsedTime = Date().timeIntervalSince(session.startDate)
        }

        onTick?()
    }
}
