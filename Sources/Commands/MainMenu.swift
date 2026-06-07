import Foundation

enum MainMenu {
    static func run() {
        let state: ServerState
        do {
            state = try BWStatus.getOrStart()
        } catch {
            AlfredOutput(items: [
                AlfredItem(
                    title: "Login to Bitwarden",
                    subtitle: "Vault server not responding — tap to login",
                    arg: .single("login"),
                    icon: AlfredIcon(path: "icons/login.png"),
                    variables: ["action": "login"]
                ),
            ]).printJSON()
            return
        }

        if state.status == .locked {
            let email = ProcessInfo.processInfo.environment["bwuser"] ?? ""
            if let pw = try? Keychain.load(for: email), !pw.isEmpty {
                if (try? BWAuth.restUnlock(password: pw)) != nil {
                    if let newState = try? BWStatus.get() {
                        return renderUnlocked(newState)
                    }
                }
            }
        }

        switch state.status {
        case .unauthenticated: renderUnauthenticated(state)
        case .locked: renderLocked(state)
        case .unlocked: renderUnlocked(state)
        }
    }

    private static func renderUnauthenticated(_ state: ServerState) {
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
                valid: false
            ),
        ]).printJSON()
    }

    private static func renderLocked(_ state: ServerState) {
        AlfredOutput(items: [
            AlfredItem(
                title: "Unlock Vault",
                subtitle: state.userEmail.map { "Unlock for \($0)" } ?? "Unlock vault",
                arg: .single("unlock"),
                variables: ["action": "unlock"]
            ),
            AlfredItem(
                title: "Logout",
                subtitle: "Switch account or reset",
                arg: .single("logout"),
                variables: ["action": "logout"]
            ),
            AlfredItem(
                title: "Configure Workflow",
                subtitle: "Set email, server, login method",
                arg: .single("configure"),
                valid: false
            ),
        ]).printJSON()
    }

    private static func renderUnlocked(_: ServerState) {
        AlfredOutput(items: unlockedMenuItems()).printJSON()
    }

    private static func unlockedMenuItems() -> [AlfredItem] {
        [
            AlfredItem(title: "Search Vault", subtitle: "Search all items",
                       arg: .single("search"), variables: ["next": "search"]),
            AlfredItem(title: "Browse Folders", subtitle: "Browse items by folder",
                       arg: .single("list_folders"), icon: AlfredIcon(path: "icons/folder.png"),
                       variables: ["next": "list_folders"]),
            AlfredItem(title: "Lock Vault", subtitle: "Lock the vault",
                       arg: .single("lock"), variables: ["action": "lock"]),
            AlfredItem(title: "Filter by Vault", subtitle: "Set default organization",
                       arg: .single("set_organization"), icon: AlfredIcon(path: "icons/company.png"),
                       variables: ["next": "set_organization"]),
            AlfredItem(title: "Filter by Collection", subtitle: "Set default collection",
                       arg: .single("set_collection"), variables: ["next": "set_collection"]),
            AlfredItem(title: "Sync Vault", subtitle: "Refresh vault cache from server",
                       arg: .single("sync_vault"), variables: ["action": "sync_vault"]),
            AlfredItem(title: "Logout", subtitle: "Switch account or reset",
                       arg: .single("logout"), variables: ["action": "logout"]),
            AlfredItem(title: "Manage Sync Agent", subtitle: "Install or uninstall background sync",
                       arg: .single("manage_agent"), variables: ["next": "manage_agent"]),
            AlfredItem(title: "Configure Workflow", subtitle: "Workflow settings",
                       arg: .single("configure"), valid: false),
        ]
    }
}

