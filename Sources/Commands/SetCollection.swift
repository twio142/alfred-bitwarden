import Foundation

enum SetCollection {
    static func run() {
        let args = Array(CommandLine.arguments.dropFirst(2))
        let collectionId = args.first

        if let id = collectionId {
            var prefs = WorkflowPrefs.load()
            prefs.defaultCollectionId = (id == "all" || id == "null") ? nil : id
            prefs.save()
            AlfredOutput.single(AlfredItem(
                title: id == "all" ? "Showing all collections" : "Collection filter set",
                subtitle: id == "all" ? "No collection filter applied" : "Filtered to collection",
                icon: AlfredIcon(path: "icons/collection.png"),
                valid: false
            )).printJSON()
            return
        }

        guard let cache = VaultCache.load() else {
            AlfredOutput.error("No vault cache — please sync first").printJSON()
            return
        }

        let prefs = WorkflowPrefs.load()
        var collections = cache.collections
        if let orgId = prefs.defaultOrganizationId {
            collections = collections.filter { $0.organizationId == orgId }
        }

        var items: [AlfredItem] = [
            AlfredItem(
                title: "All Collections",
                subtitle: "Show items from all collections",
                arg: .single("all"),
                icon: AlfredIcon(path: "icons/collection.png"),
                variables: ["next": "set_collection", "collection_id": "all"]
            ),
        ]
        items += collections.map { col in
            AlfredItem(
                title: col.name,
                subtitle: "Filter to this collection",
                arg: .single(col.id),
                icon: AlfredIcon(path: "icons/collection.png"),
                variables: ["next": "set_collection", "collection_id": col.id]
            )
        }
        AlfredOutput(items: items).printJSON()
    }
}
