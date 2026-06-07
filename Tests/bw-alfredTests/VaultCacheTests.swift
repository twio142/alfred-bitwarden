@testable import bw_alfred
import Foundation
import Testing

struct VaultCacheTests {
    @Test("isStale returns true when lastSyncedAt is too old")
    func isStaleTrue() {
        let lastSyncedAt = Date().addingTimeInterval(-3601) // 1 hour + 1 second ago
        let cache = VaultCache(
            schemaVersion: 1,
            lastSyncedAt: lastSyncedAt,
            items: [],
            folders: [],
            collections: [],
            organizations: []
        )
        #expect(cache.isStale(interval: 60) == true)
    }

    @Test("isStale returns false when lastSyncedAt is recent")
    func isStaleFalse() {
        let lastSyncedAt = Date().addingTimeInterval(-3599) // 1 hour - 1 second ago
        let cache = VaultCache(
            schemaVersion: 1,
            lastSyncedAt: lastSyncedAt,
            items: [],
            folders: [],
            collections: [],
            organizations: []
        )
        #expect(cache.isStale(interval: 60) == false)
    }

    @Test("isStale with 0 interval is always stale if synchronized in the past")
    func isStaleZeroInterval() {
        let lastSyncedAt = Date().addingTimeInterval(-1)
        let cache = VaultCache(
            schemaVersion: 1,
            lastSyncedAt: lastSyncedAt,
            items: [],
            folders: [],
            collections: [],
            organizations: []
        )
        #expect(cache.isStale(interval: 0) == true)
    }
}
