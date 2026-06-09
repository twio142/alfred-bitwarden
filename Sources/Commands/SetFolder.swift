import Foundation

enum SetFolder {
    static func run() {
        let args = Array(CommandLine.arguments.dropFirst(2))
        let env = ProcessInfo.processInfo.environment
        let itemId = args.first ?? env["item_id"] ?? ""
        let folderId = args.dropFirst().first

        guard !itemId.isEmpty else {
            AlfredOutput.error("Usage: set_folder <item_id> [folder_id]").printJSON()
            return
        }

        guard let folderId else {
            showFolderList(for: itemId)
            return
        }

        do {
            try ensureUnlocked()
            var item = try BWItems.getItem(itemId)
            item.folderId = folderId == "null" ? nil : folderId
            _ = try BWItems.updateItem(itemId, item: item)
            if var cache = VaultCache.load(), let idx = cache.items.firstIndex(where: { $0.id == itemId }) {
                cache.items[idx].folderId = item.folderId
                cache.save()
            }
            _ = try? BWSync.sync()
            AlfredOutput.single(AlfredItem(
                title: "Folder updated",
                subtitle: "Item moved successfully",
                icon: AlfredIcon(path: "icons/folder.png"),
                valid: false
            )).printJSON()
        } catch {
            AlfredOutput.error("Error: \(error)").printJSON()
        }
    }

    private static func showFolderList(for itemId: String) {
        guard let cache = VaultCache.load() else {
            AlfredOutput.error("No vault cache").printJSON()
            return
        }
        let env = ProcessInfo.processInfo.environment
        var items: [AlfredItem] = [
            AlfredItem(
                title: "No Folder",
                subtitle: "Remove from all folders",
                arg: .multiple([itemId, "null"]),
                icon: AlfredIcon(path: "icons/cancel.png"),
                variables: ["action": "set_folder"]
            ),
        ]
        items += cache.folders.map { folder in
            AlfredItem(
                title: folder.name,
                arg: .multiple([itemId, folder.id]),
                icon: AlfredIcon(path: "icons/folder.png"),
                variables: ["action": "set_folder"]
            )
        }
        let (popped, remaining) = NavStack.pop(from: env["nav_stack"] ?? "")
        if let popped {
            items.append(AlfredItem(
                title: "Go Back",
                arg: nil,
                icon: AlfredIcon(path: "icons/back.png"),
                variables: ["next": popped, "nav_stack": remaining]
            ))
        }
        AlfredOutput(items: items).printJSON()
    }
}
