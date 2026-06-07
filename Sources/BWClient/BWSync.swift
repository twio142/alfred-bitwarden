import Foundation

enum BWSync {
    @discardableResult
    static func sync() throws -> VaultCache {
        _ = try? BWClient.shared.post("/sync")

        let items = try BWItems.listItems()
        let folders = try BWItems.listFolders()
        let collections = try BWItems.listCollections()
        let organizations = try BWItems.listOrganizations()

        let cachedItems = items.map { CacheBuilder.build(from: $0) }
        let cache = VaultCache(
            schemaVersion: VaultCache.currentSchemaVersion,
            lastSyncedAt: Date(),
            items: cachedItems,
            folders: folders,
            collections: collections,
            organizations: organizations
        )
        cache.save()
        return cache
    }
}
