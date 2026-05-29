import Foundation

struct ListFields {
    static func run() {
        let args = Array(CommandLine.arguments.dropFirst(2))
        guard let itemId = args.first else {
            AlfredOutput.error("Usage: list_fields <item_id>").printJSON()
            return
        }

        guard let cache = VaultCache.load(),
              let item = cache.items.first(where: { $0.id == itemId })
        else {
            AlfredOutput.error("Item not found in cache").printJSON()
            return
        }

        var alfredItems: [AlfredItem] = []
        let vars: [String: String] = ["next_command": "get_field", "item_id": itemId]

        if let username = item.login?.username, !username.isEmpty {
            alfredItems.append(AlfredItem(
                title: "Username",
                subtitle: username,
                arg: "username",
                icon: AlfredIcon(path: "icons/login.png"),
                variables: vars
            ))
        }

        if item.hasTOTP {
            alfredItems.append(AlfredItem(
                title: "TOTP Code",
                subtitle: "Generate TOTP code",
                arg: "totp",
                icon: AlfredIcon(path: "icons/totp.png"),
                variables: vars
            ))
        }

        if let notes = item.notes, !notes.isEmpty {
            alfredItems.append(AlfredItem(
                title: "Notes",
                subtitle: String(notes.prefix(60)),
                arg: "notes",
                icon: AlfredIcon(path: "icons/note.png"),
                variables: vars
            ))
        }

        if let fields = item.fields {
            for field in fields where field.type == .text {
                if let name = field.name, let value = field.value {
                    alfredItems.append(AlfredItem(
                        title: name,
                        subtitle: value,
                        arg: "custom:\(name)",
                        icon: AlfredIcon(path: "icons/field.png"),
                        variables: vars
                    ))
                }
            }
        }

        if alfredItems.isEmpty {
            AlfredOutput(items: [AlfredItem(title: "No fields available", valid: false)]).printJSON()
        } else {
            AlfredOutput(items: alfredItems).printJSON()
        }
    }
}
