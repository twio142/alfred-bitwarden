import Foundation

enum SyncVault {
    static func run() {
        do {
            try ensureUnlocked()
            let cache = try BWSync.sync()
            let formatter = DateFormatter()
            formatter.dateStyle = .short
            formatter.timeStyle = .medium
            let timestamp = formatter.string(from: cache.lastSyncedAt)
            AlfredOutput.single(AlfredItem(
                title: "Vault synced",
                subtitle: "\(cache.items.count) items synced at \(timestamp)",
                icon: AlfredIcon(path: "icons/sync.png"),
                valid: false
            )).printJSON()
        } catch {
            AlfredOutput.error("Sync failed: \(error)").printJSON()
        }
    }
}
