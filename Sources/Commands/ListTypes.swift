import Foundation

enum ListTypes {
    static func run() {
        let env = ProcessInfo.processInfo.environment
        AlfredOutput(items: makeItems(env: env)).printJSON()
    }

    static func makeItems(env: [String: String]) -> [AlfredItem] {
        let navStack = env["nav_stack"] ?? ""
        let pushed = NavStack.push("list_types", onto: navStack)

        let types: [(title: String, subtitle: String, icon: String, rawValue: Int)] = [
            ("Logins", "Search login items", "icons/login.png", ItemType.login.rawValue),
            ("Cards", "Search card items", "icons/card.png", ItemType.card.rawValue),
            ("Identities", "Search identity items", "icons/identity.png", ItemType.identity.rawValue),
            ("Secure Notes", "Search secure note items", "icons/secret-note.png", ItemType.secureNote.rawValue),
        ]

        var items = types.map { t in
            AlfredItem(
                title: t.title,
                subtitle: t.subtitle,
                icon: AlfredIcon(path: t.icon),
                variables: ["next": "search", "item_type": String(t.rawValue), "folder_id": "", "favorites": "", "nav_stack": pushed]
            )
        }

        let (popped, remaining) = NavStack.pop(from: navStack)
        if let popped {
            items.append(AlfredItem(
                title: "Go Back",
                arg: nil,
                icon: AlfredIcon(path: "icons/back.png"),
                variables: ["next": popped, "nav_stack": remaining, "item_type": "", "folder_id": "", "favorites": ""]
            ))
        }
        return items
    }
}

