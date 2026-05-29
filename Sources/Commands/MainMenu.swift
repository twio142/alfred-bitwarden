import Foundation

struct MainMenu {
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
                    arg: "login",
                    icon: AlfredIcon(path: "icons/login.png"),
                    variables: ["next_command": "login"]
                )
            ]
            AlfredOutput(items: items).printJSON()
            return
        }

        switch state.status {
        case .unauthenticated:
            AlfredOutput(items: [
                AlfredItem(
                    title: "Login to Bitwarden",
                    subtitle: state.userEmail.map { "Account: \($0)" } ?? "No account configured",
                    arg: "login",
                    icon: AlfredIcon(path: "icons/login.png"),
                    variables: ["next_command": "login"]
                ),
                AlfredItem(
                    title: "Configure Workflow",
                    subtitle: "Set email, server, login method",
                    arg: "configure",
                    icon: AlfredIcon(path: "icons/settings.png"),
                    valid: false
                )
            ]).printJSON()

        case .locked:
            AlfredOutput(items: [
                AlfredItem(
                    title: "Unlock Vault",
                    subtitle: state.userEmail.map { "Unlock for \($0)" } ?? "Unlock vault",
                    arg: "unlock",
                    icon: AlfredIcon(path: "icons/lock.png"),
                    variables: ["next_command": "unlock"]
                ),
                AlfredItem(
                    title: "Logout",
                    subtitle: "Switch account or reset",
                    arg: "logout",
                    icon: AlfredIcon(path: "icons/logout.png"),
                    variables: ["next_command": "logout"]
                ),
                AlfredItem(
                    title: "Configure Workflow",
                    subtitle: "Set email, server, login method",
                    arg: "configure",
                    icon: AlfredIcon(path: "icons/settings.png"),
                    valid: false
                )
            ]).printJSON()

        case .unlocked:
            AlfredOutput(items: [
                AlfredItem(
                    title: "Search Vault",
                    subtitle: "Search all items",
                    arg: "search",
                    icon: AlfredIcon(path: "icons/search.png"),
                    variables: ["next_command": "search"]
                ),
                AlfredItem(
                    title: "Browse Folders",
                    subtitle: "Browse items by folder",
                    arg: "list_folders",
                    icon: AlfredIcon(path: "icons/folder.png"),
                    variables: ["next_command": "list_folders"]
                ),
                AlfredItem(
                    title: "Lock Vault",
                    subtitle: "Lock the vault",
                    arg: "lock",
                    icon: AlfredIcon(path: "icons/lock.png"),
                    variables: ["next_command": "lock"]
                ),
                AlfredItem(
                    title: "Filter by Vault",
                    subtitle: "Set default organization",
                    arg: "set_organization",
                    icon: AlfredIcon(path: "icons/org.png"),
                    variables: ["next_command": "set_organization"]
                ),
                AlfredItem(
                    title: "Filter by Collection",
                    subtitle: "Set default collection",
                    arg: "set_collection",
                    icon: AlfredIcon(path: "icons/collection.png"),
                    variables: ["next_command": "set_collection"]
                ),
                AlfredItem(
                    title: "Sync Vault",
                    subtitle: "Refresh vault cache from server",
                    arg: "sync_vault",
                    icon: AlfredIcon(path: "icons/sync.png"),
                    variables: ["next_command": "sync_vault"]
                ),
                AlfredItem(
                    title: "Logout",
                    subtitle: "Switch account or reset",
                    arg: "logout",
                    icon: AlfredIcon(path: "icons/logout.png"),
                    variables: ["next_command": "logout"]
                ),
                AlfredItem(
                    title: "Configure Workflow",
                    subtitle: "Workflow settings",
                    arg: "configure",
                    icon: AlfredIcon(path: "icons/settings.png"),
                    valid: false
                )
            ]).printJSON()
        }
    }
}
