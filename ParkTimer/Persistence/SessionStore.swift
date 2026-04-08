import Foundation

@MainActor
@Observable
final class SessionStore {
    private(set) var activeSession: ParkingSession?
    private let fileURL: URL

    init() {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        self.fileURL = docs.appendingPathComponent("activeSession.json")
        load()
    }

    func save(_ session: ParkingSession?) {
        activeSession = session
        if let session {
            do {
                let data = try JSONEncoder().encode(session)
                try data.write(to: fileURL, options: .atomic)
            } catch {
                print("[SessionStore] Failed to save: \(error)")
            }
        } else {
            try? FileManager.default.removeItem(at: fileURL)
        }
    }

    func clear() {
        save(nil)
    }

    private func load() {
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return }
        do {
            let data = try Data(contentsOf: fileURL)
            activeSession = try JSONDecoder().decode(ParkingSession.self, from: data)
        } catch {
            print("[SessionStore] Failed to load: \(error)")
            activeSession = nil
        }
    }
}
