import Foundation

enum MoreMenu {
    static func run() {
        let args = Array(CommandLine.arguments.dropFirst(2))
        let env = ProcessInfo.processInfo.environment
        let itemId = args.first ?? env["item_id"] ?? ""
        guard !itemId.isEmpty else {
            AlfredOutput.error("Usage: more <item_id>").printJSON()
            return
        }

        guard let cache = VaultCache.load(),
              let item = cache.items.first(where: { $0.id == itemId })
        else {
            AlfredOutput.error("Item not found in cache").printJSON()
            return
        }

        AlfredOutput(items: makeItems(itemId: itemId, item: item, env: env)).printJSON()
    }

    static func makeItems(itemId: String, item: CachedItem, env: [String: String]) -> [AlfredItem] {
        let navStack = env["nav_stack"] ?? ""
        let pushed = NavStack.push("more", onto: navStack)
        let isFavorite = item.favorite
        var items: [AlfredItem] = [
            AlfredItem(
                title: isFavorite ? "Remove from Favorites" : "Mark as Favorite",
                subtitle: isFavorite ? "Remove this item from favorites" : "Add this item to favorites",
                arg: .multiple([itemId, isFavorite ? "false" : "true"]),
                icon: AlfredIcon(path: isFavorite ? "icons/cancel.png" : "icons/heart.png"),
                variables: ["action": "set_favorite"]
            ),
            AlfredItem(
                title: "Move to Folder",
                subtitle: "Change the folder for this item",
                arg: nil,
                icon: AlfredIcon(path: "icons/folder.png"),
                variables: ["next": "set_folder", "item_id": itemId, "nav_stack": pushed]
            ),
        ]

        if item.hasAttachments {
            items.append(AlfredItem(
                title: "Download Attachment",
                subtitle: "Download an attachment",
                arg: nil,
                icon: AlfredIcon(path: "icons/attachment.png"),
                variables: ["next": "list_attachments", "item_id": itemId, "nav_stack": pushed]
            ))
        }

        items.append(AlfredItem(
            title: "Delete Item",
            subtitle: "Move this item to Trash",
            arg: .single(itemId),
            icon: AlfredIcon(path: "icons/trash.png"),
            variables: ["action": "delete_item"]
        ))

        let (popped, remaining) = NavStack.pop(from: navStack)
        if let popped {
            items.append(AlfredItem(
                title: "Go Back",
                arg: nil,
                icon: AlfredIcon(path: "icons/back.png"),
                variables: ["next": popped, "nav_stack": remaining]
            ))
        }

        return items
    }
}
