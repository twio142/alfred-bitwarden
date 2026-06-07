import Foundation

struct RecencyStore: Codable {
    var lastItemId: String?
    var lastField: String?
    var lastCopiedAt: Date?

    static func load() -> RecencyStore {
        guard let dir = ProcessInfo.processInfo.environment["alfred_workflow_data"],
              let data = try? Data(contentsOf: URL(fileURLWithPath: dir + "/recency.json")),
              let store = try? JSONDecoder().decode(RecencyStore.self, from: data)
        else {
            return RecencyStore()
        }
        return store
    }

    func save() {
        guard let dir = ProcessInfo.processInfo.environment["alfred_workflow_data"] else { return }
        let url = URL(fileURLWithPath: dir + "/recency.json")
        try? FileManager.default.createDirectory(
            at: URL(fileURLWithPath: dir),
            withIntermediateDirectories: true
        )
        if let data = try? JSONEncoder().encode(self) {
            try? data.write(to: url)
        }
    }

    func isRecent(for itemId: String, maxAge: TimeInterval = 300) -> Bool {
        guard lastItemId == itemId, let lastCopiedAt else { return false }
        return Date().timeIntervalSince(lastCopiedAt) < maxAge
    }

    func shouldRotateToTOTP(for itemId: String) -> Bool {
        guard lastItemId == itemId,
              lastField == "password",
              let lastCopiedAt = lastCopiedAt
        else { return false }
        return Date().timeIntervalSince(lastCopiedAt) < 15
    }
}
