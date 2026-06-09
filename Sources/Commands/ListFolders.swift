import Foundation

enum ListFolders {
    static func run() {
        let env = ProcessInfo.processInfo.environment
        guard let cache = VaultCache.load() else {
            AlfredOutput.error("No vault cache — please sync first").printJSON()
            return
        }
        AlfredOutput(items: makeItems(cache: cache, env: env)).printJSON()
    }

    static func makeItems(cache: VaultCache, env: [String: String]) -> [AlfredItem] {
        let navStack = env["nav_stack"] ?? ""
        let pushed = NavStack.push("list_folders", onto: navStack)

        if cache.folders.isEmpty {
            var items = [AlfredItem(title: "No folders found", subtitle: "Your vault has no folders", valid: false)]
            let (popped, remaining) = NavStack.pop(from: navStack)
            if let popped {
                items.append(AlfredItem(
                    title: "Go Back",
                    arg: nil,
                    icon: AlfredIcon(path: "icons/back.png"),
                    variables: ["next": popped, "nav_stack": remaining, "folder_id": "", "favorites": ""]
                ))
            }
            return items
        }

        let favoritesItem = AlfredItem(
            title: "Favorites",
            subtitle: "Show favorite items",
            icon: AlfredIcon(path: "icons/heart.png"),
            variables: ["next": "search", "favorites": "true", "folder_id": "", "nav_stack": pushed]
        )
        let folderItems = cache.folders.map { folder in
            AlfredItem(
                title: folder.name,
                subtitle: "Search in \(folder.name)",
                icon: AlfredIcon(path: "icons/folder.png"),
                variables: ["next": "search", "folder_id": folder.id, "favorites": "", "nav_stack": pushed]
            )
        }

        var items = [favoritesItem] + folderItems
        let (popped, remaining) = NavStack.pop(from: navStack)
        if let popped {
            items.append(AlfredItem(
                title: "Go Back",
                arg: nil,
                icon: AlfredIcon(path: "icons/back.png"),
                variables: ["next": popped, "nav_stack": remaining, "folder_id": "", "favorites": ""]
            ))
        }
        return items
    }
}
