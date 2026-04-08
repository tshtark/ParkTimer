import Foundation

@MainActor
@Observable
final class HistoryStore {
    private(set) var sessions: [ParkingSession] = []
    private let fileURL: URL

    init() {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        self.fileURL = docs.appendingPathComponent("history.json")
        load()
    }

    func add(_ session: ParkingSession) {
        sessions.insert(session, at: 0)
        save()
    }

    func delete(at offsets: IndexSet) {
        sessions.remove(atOffsets: offsets)
        save()
    }

    func clearAll() {
        sessions = []
        try? FileManager.default.removeItem(at: fileURL)
    }

    private func load() {
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return }
        do {
            let data = try Data(contentsOf: fileURL)
            sessions = try JSONDecoder().decode([ParkingSession].self, from: data)
        } catch {
            print("[HistoryStore] Failed to load: \(error)")
            sessions = []
        }
    }

    private func save() {
        do {
            let data = try JSONEncoder().encode(sessions)
            try data.write(to: fileURL, options: .atomic)
        } catch {
            print("[HistoryStore] Failed to save: \(error)")
        }
    }
}
