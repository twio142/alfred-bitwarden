import Foundation

struct SetFolder {
    static func run() {
        let args = Array(CommandLine.arguments.dropFirst(2))
        let env = ProcessInfo.processInfo.environment
        let itemId = args.first ?? env["item_id"] ?? ""
        let folderId = args.dropFirst().first

        guard !itemId.isEmpty else {
            AlfredOutput.error("Usage: set_folder <item_id> [folder_id]").printJSON()
            return
        }

        if folderId == nil {
            // Show folder list
            guard let cache = VaultCache.load() else {
                AlfredOutput.error("No vault cache").printJSON()
                return
            }
            var items: [AlfredItem] = [
                AlfredItem(
                    title: "No Folder",
                    subtitle: "Remove from all folders",
                    arg: itemId,
                    icon: AlfredIcon(path: "icons/folder.png"),
                    variables: ["next_command": "set_folder", "item_id": itemId, "folder_id": "null"]
                )
            ]
            items += cache.folders.map { folder in
                AlfredItem(
                    title: folder.name,
                    arg: itemId,
                    icon: AlfredIcon(path: "icons/folder.png"),
                    variables: ["next_command": "set_folder", "item_id": itemId, "folder_id": folder.id]
                )
            }
            AlfredOutput(items: items).printJSON()
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
}
