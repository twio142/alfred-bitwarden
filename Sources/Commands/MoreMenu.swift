import Foundation

enum MoreMenu {
    static func run() {
        let args = Array(CommandLine.arguments.dropFirst(2))
        guard let itemId = args.first else {
            AlfredOutput.error("Usage: more <item_id>").printJSON()
            return
        }

        guard let cache = VaultCache.load(),
              let item = cache.items.first(where: { $0.id == itemId })
        else {
            AlfredOutput.error("Item not found in cache").printJSON()
            return
        }

        let isFavorite = item.favorite
        var alfredItems: [AlfredItem] = [
            AlfredItem(
                title: isFavorite ? "Remove from Favorites" : "Mark as Favorite",
                subtitle: isFavorite ? "Remove this item from favorites" : "Add this item to favorites",
                arg: .multiple([itemId, isFavorite ? "false" : "true"]),
                variables: ["action": "set_favorite"]
            ),
            AlfredItem(
                title: "Move to Folder",
                subtitle: "Change the folder for this item",
                arg: nil,
                icon: AlfredIcon(path: "icons/folder.png"),
                variables: ["next": "set_folder", "item_id": itemId]
            ),
        ]

        if item.hasAttachments {
            alfredItems.append(AlfredItem(
                title: "Download Attachment",
                subtitle: "Download an attachment",
                arg: nil,
                variables: ["next": "list_attachments", "item_id": itemId]
            ))
        }

        alfredItems.append(AlfredItem(
            title: "Delete Item",
            subtitle: "Move this item to Trash",
            arg: .single(itemId),
            variables: ["action": "delete_item"]
        ))

        AlfredOutput(items: alfredItems).printJSON()
    }
}
