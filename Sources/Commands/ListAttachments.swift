import Foundation

struct ListAttachments {
    static func run() {
        let args = Array(CommandLine.arguments.dropFirst(2))
        guard let itemId = args.first else {
            AlfredOutput.error("Usage: list_attachments <item_id>").printJSON()
            return
        }

        guard let cache = VaultCache.load(),
              let item = cache.items.first(where: { $0.id == itemId })
        else {
            AlfredOutput.error("Item not found in cache").printJSON()
            return
        }

        guard item.hasAttachments else {
            AlfredOutput(items: [
                AlfredItem(title: "No attachments", subtitle: "This item has no attachments", valid: false)
            ]).printJSON()
            return
        }

        // Fetch live item for actual attachment list
        do {
            try ensureUnlocked()
            let liveItem = try BWItems.getItem(itemId)
            let attachments = liveItem.attachments ?? []

            if attachments.isEmpty {
                AlfredOutput(items: [
                    AlfredItem(title: "No attachments found", valid: false)
                ]).printJSON()
                return
            }

            let alfredItems = attachments.map { att in
                AlfredItem(
                    title: att.fileName ?? att.id,
                    subtitle: att.sizeName ?? att.size ?? "Unknown size",
                    arg: att.id,
                    icon: AlfredIcon(path: "icons/attachment.png"),
                    variables: ["next_command": "get_attachment", "item_id": itemId, "attachment_id": att.id]
                )
            }
            AlfredOutput(items: alfredItems).printJSON()
        } catch {
            AlfredOutput.error("Error fetching attachments: \(error)").printJSON()
        }
    }
}
