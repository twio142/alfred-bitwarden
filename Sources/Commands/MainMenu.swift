import Foundation

enum MainMenu {
    static func run() {
        let state: ServerState
        do {
            if !BWServer.isRunning() {
                BWServer.start()
                Thread.sleep(forTimeInterval: 1)
            }
            state = try BWStatus.get()
        } catch {
            let items = [
                AlfredItem(
                    title: "Login to Bitwarden",
                    subtitle: "Vault server not responding — tap to login",
                    arg: .single("login"),
                    icon: AlfredIcon(path: "icons/login.png"),
                    variables: ["action": "login"]
                ),
            ]
            AlfredOutput(items: items).printJSON()
            return
        }

        if state.status == .locked {
            let email = ProcessInfo.processInfo.environment["bwuser"] ?? ""
            if let pw = try? Keychain.load(for: email), !pw.isEmpty {
                if let _ = try? BWAuth.restUnlock(password: pw) {
                    if let newState = try? BWStatus.get() {
                        return renderUnlocked(newState)
                    }
                }
            }
        }

        switch state.status {
        case .unauthenticated:
            AlfredOutput(items: [
                AlfredItem(
                    title: "Login to Bitwarden",
                    subtitle: state.userEmail.map { "Account: \($0)" } ?? "No account configured",
                    arg: .single("login"),
                    icon: AlfredIcon(path: "icons/login.png"),
                    variables: ["action": "login"]
                ),
                AlfredItem(
                    title: "Configure Workflow",
                    subtitle: "Set email, server, login method",
                    arg: .single("configure"),
                    icon: AlfredIcon(path: "icons/settings.png"),
                    valid: false
                ),
            ]).printJSON()

        case .locked:
            AlfredOutput(items: [
                AlfredItem(
                    title: "Unlock Vault",
                    subtitle: state.userEmail.map { "Unlock for \($0)" } ?? "Unlock vault",
                    arg: .single("unlock"),
                    icon: AlfredIcon(path: "icons/lock.png"),
                    variables: ["action": "unlock"]
                ),
                AlfredItem(
                    title: "Logout",
                    subtitle: "Switch account or reset",
                    arg: .single("logout"),
                    icon: AlfredIcon(path: "icons/logout.png"),
                    variables: ["action": "logout"]
                ),
                AlfredItem(
                    title: "Configure Workflow",
                    subtitle: "Set email, server, login method",
                    arg: .single("configure"),
                    icon: AlfredIcon(path: "icons/settings.png"),
                    valid: false
                ),
            ]).printJSON()

        case .unlocked:
            renderUnlocked(state)
        }
    }

    private static func renderUnlocked(_: ServerState) {
        AlfredOutput(items: [
            AlfredItem(
                title: "Search Vault",
                subtitle: "Search all items",
                arg: .single("search"),
                icon: AlfredIcon(path: "icons/search.png"),
                variables: ["next": "search"]
            ),
            AlfredItem(
                title: "Browse Folders",
                subtitle: "Browse items by folder",
                arg: .single("list_folders"),
                icon: AlfredIcon(path: "icons/folder.png"),
                variables: ["next": "list_folders"]
            ),
            AlfredItem(
                title: "Lock Vault",
                subtitle: "Lock the vault",
                arg: .single("lock"),
                icon: AlfredIcon(path: "icons/lock.png"),
                variables: ["action": "lock"]
            ),
            AlfredItem(
                title: "Filter by Vault",
                subtitle: "Set default organization",
                arg: .single("set_organization"),
                icon: AlfredIcon(path: "icons/company.png"),
                variables: ["next": "set_organization"]
            ),
            AlfredItem(
                title: "Filter by Collection",
                subtitle: "Set default collection",
                arg: .single("set_collection"),
                icon: AlfredIcon(path: "icons/collection.png"),
                variables: ["next": "set_collection"]
            ),
            AlfredItem(
                title: "Sync Vault",
                subtitle: "Refresh vault cache from server",
                arg: .single("sync_vault"),
                icon: AlfredIcon(path: "icons/sync.png"),
                variables: ["action": "sync_vault"]
            ),
            AlfredItem(
                title: "Logout",
                subtitle: "Switch account or reset",
                arg: .single("logout"),
                icon: AlfredIcon(path: "icons/logout.png"),
                variables: ["action": "logout"]
            ),
            AlfredItem(
                title: "Configure Workflow",
                subtitle: "Workflow settings",
                arg: .single("configure"),
                icon: AlfredIcon(path: "icons/settings.png"),
                valid: false
            ),
        ]).printJSON()
    }
}
