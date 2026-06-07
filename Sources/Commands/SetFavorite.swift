import Foundation

enum SetFavorite {
    static func run() {
        let args = Array(CommandLine.arguments.dropFirst(2))
        let itemId = args.first ?? ""
        let favoriteStr = args.dropFirst().first ?? "true"
        let favorite = favoriteStr.lowercased() == "true" || favoriteStr == "1"

        guard !itemId.isEmpty else {
            AlfredOutput.error("Usage: set_favorite <item_id> <true|false>").printJSON()
            return
        }

        do {
            try ensureUnlocked()
            var item = try BWItems.getItem(itemId)
            item.favorite = favorite
            _ = try BWItems.updateItem(itemId, item: item)
            invalidateCacheEntry(itemId: itemId, favorite: favorite)
            _ = try? BWSync.sync()
            let label = favorite ? "Added to favorites" : "Removed from favorites"
            AlfredOutput.single(AlfredItem(
                title: label,
                subtitle: item.name,
                icon: AlfredIcon(path: "icons/favorite.png"),
                valid: false
            )).printJSON()
        } catch {
            AlfredOutput.error("Error: \(error)").printJSON()
        }
    }

    private static func invalidateCacheEntry(itemId: String, favorite: Bool) {
        guard var cache = VaultCache.load() else { return }
        if let idx = cache.items.firstIndex(where: { $0.id == itemId }) {
            cache.items[idx].favorite = favorite
            cache.save()
        }
    }
}
