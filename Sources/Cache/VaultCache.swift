import Foundation

extension VaultCache {
    static let currentSchemaVersion = 1

    static var cacheURL: URL {
        let dir = ProcessInfo.processInfo.environment["alfred_workflow_cache"] ?? "/tmp"
        return URL(fileURLWithPath: dir + "/vault-cache.json")
    }

    static func load() -> VaultCache? {
        guard let data = try? Data(contentsOf: cacheURL) else { return nil }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .secondsSince1970
        guard let cache = try? decoder.decode(VaultCache.self, from: data) else { return nil }
        if cache.schemaVersion != currentSchemaVersion { return nil }
        return cache
    }

    func save() {
        let dir = ProcessInfo.processInfo.environment["alfred_workflow_cache"] ?? "/tmp"
        try? FileManager.default.createDirectory(
            atPath: dir, withIntermediateDirectories: true
        )
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .secondsSince1970
        if let data = try? encoder.encode(self) {
            try? data.write(to: VaultCache.cacheURL)
        }
    }

    func isStale(interval: Int) -> Bool {
        let intervalSeconds = TimeInterval(interval * 60)
        return Date().timeIntervalSince(lastSyncedAt) > intervalSeconds
    }
}
