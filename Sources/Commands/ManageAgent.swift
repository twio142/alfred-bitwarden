import Foundation

enum ManageAgent {
    static func run() {
        let installed = LaunchAgent.isInstalled
        let items: [AlfredItem] = [
            AlfredItem(
                title: installed ? "Uninstall Auto Sync" : "Install Auto Sync",
                subtitle: installed
                    ? "Remove the background sync agent"
                    : "Install background sync agent",
                arg: .single(installed ? "uninstall_agent" : "install_agent"),
                icon: AlfredIcon(path: "icons/sync.png"),
                variables: ["next": installed ? "uninstall_agent" : "install_agent"]
            ),
        ]
        AlfredOutput(items: items).printJSON()
    }

    static func install() {
        do {
            try LaunchAgent.install()
            AlfredOutput.single(AlfredItem(
                title: "Auto sync installed",
                subtitle: "Background sync agent is now active",
                icon: AlfredIcon(path: "icons/sync.png"),
                valid: false
            )).printJSON()
        } catch {
            AlfredOutput.error("Install failed: \(error)").printJSON()
        }
    }

    static func uninstall() {
        LaunchAgent.uninstall()
        AlfredOutput.single(AlfredItem(
            title: "Auto sync removed",
            subtitle: "Background sync agent has been uninstalled",
            icon: AlfredIcon(path: "icons/sync.png"),
            valid: false
        )).printJSON()
    }
}
