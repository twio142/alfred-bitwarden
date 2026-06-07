import Foundation

enum ListFields {
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

        let alfredItems = makeItems(for: item, itemId: itemId)
        if alfredItems.isEmpty {
            AlfredOutput(items: [AlfredItem(title: "No fields available", valid: false)]).printJSON()
        } else {
            AlfredOutput(items: alfredItems).printJSON()
        }
    }

    private static func makeItems(for item: CachedItem, itemId: String) -> [AlfredItem] {
        let action = ["action": "get_field"]
        var items: [AlfredItem] = []

        if let username = item.login?.username, !username.isEmpty {
            items.append(AlfredItem(title: "Username", subtitle: username, arg: .multiple([itemId, "username"]),
                                    icon: AlfredIcon(path: "icons/user.png"), variables: action))
        }

        if item.type == .login {
            items.append(AlfredItem(title: "Password", subtitle: "********", arg: .multiple([itemId, "password"]),
                                    icon: AlfredIcon(path: "icons/password.png"), variables: action))
        }

        if item.hasTOTP {
            items.append(AlfredItem(title: "TOTP Code", subtitle: "Generate TOTP code", arg: .multiple([itemId, "totp"]),
                                    icon: AlfredIcon(path: "icons/totp.png"), variables: action))
        }

        if let notes = item.notes, !notes.isEmpty {
            items.append(AlfredItem(title: "Notes", subtitle: String(notes.prefix(60)), arg: .multiple([itemId, "notes"]),
                                    icon: AlfredIcon(path: "icons/icon.png"), variables: action))
        }

        for (index, uri) in (item.login?.uris ?? []).enumerated() {
            if let u = uri.uri {
                items.append(AlfredItem(title: "URL", subtitle: u, arg: .multiple([itemId, "url:\(index)"]),
                                        icon: AlfredIcon(path: "icons/url.png"), variables: action))
            }
        }

        if let fields = item.fields {
            for field in fields where field.type == .text {
                if let name = field.name, let value = field.value {
                    items.append(AlfredItem(title: name, subtitle: value, arg: .multiple([itemId, "custom:\(name)"]),
                                            icon: AlfredIcon(path: "icons/icon.png"), variables: action))
                }
            }
        }

        return items
    }
}
