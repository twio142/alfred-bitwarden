import Foundation

enum ListFolders {
    static func run() {
        guard let cache = VaultCache.load() else {
            AlfredOutput.error("No vault cache — please sync first").printJSON()
            return
        }

        if cache.folders.isEmpty {
            AlfredOutput(items: [
                AlfredItem(title: "No folders found", subtitle: "Your vault has no folders", valid: false),
            ]).printJSON()
            return
        }

        let items = cache.folders.map { folder in
            AlfredItem(
                title: folder.name,
                subtitle: "Search in \(folder.name)",
                arg: .single(folder.id),
                icon: AlfredIcon(path: "icons/folder.png"),
                variables: ["next": "search", "folder_id": folder.id]
            )
        }
        AlfredOutput(items: items).printJSON()
    }
}
