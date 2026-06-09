import Foundation

enum ListAttachments {
    static func run() {
        let args = Array(CommandLine.arguments.dropFirst(2))
        let env = ProcessInfo.processInfo.environment
        let itemId = args.first ?? env["item_id"] ?? ""
        guard !itemId.isEmpty else {
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
                AlfredItem(title: "No attachments", subtitle: "This item has no attachments", valid: false),
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
                    AlfredItem(title: "No attachments found", valid: false),
                ]).printJSON()
                return
            }

            var alfredItems = attachments.map { att in
                AlfredItem(
                    title: att.fileName ?? att.id,
                    subtitle: att.sizeName ?? att.size ?? "Unknown size",
                    arg: .multiple([itemId, att.id]),
                    variables: ["action": "get_attachment"]
                )
            }
            let (popped, remaining) = NavStack.pop(from: env["nav_stack"] ?? "")
            if let popped {
                alfredItems.append(AlfredItem(
                    title: "Go Back",
                    subtitle: "Return to previous menu",
                    arg: nil,
                    variables: ["next": popped, "nav_stack": remaining]
                ))
            }
            AlfredOutput(items: alfredItems).printJSON()
        } catch {
            AlfredOutput.error("Error fetching attachments: \(error)").printJSON()
        }
    }
}
