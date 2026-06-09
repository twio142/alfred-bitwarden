import Foundation

enum ManageAgent {
    static func run() {
        let env = ProcessInfo.processInfo.environment
        let installed = LaunchAgent.isInstalled
        var items: [AlfredItem] = [
            AlfredItem(
                title: installed ? "Uninstall Auto Sync" : "Install Auto Sync",
                subtitle: installed
                    ? "Remove the background sync agent"
                    : "Install background sync agent",
                arg: .single(installed ? "uninstall_agent" : "install_agent"),
                variables: ["next": installed ? "uninstall_agent" : "install_agent"]
            ),
        ]
        let (popped, remaining) = NavStack.pop(from: env["nav_stack"] ?? "")
        if let popped {
            items.append(AlfredItem(
                title: "Go Back",
                arg: nil,
                icon: AlfredIcon(path: "icons/back.png"),
                variables: ["next": popped, "nav_stack": remaining]
            ))
        }
        AlfredOutput(items: items).printJSON()
    }

    static func install() {
        do {
            try LaunchAgent.install()
            AlfredOutput.single(AlfredItem(
                title: "Auto sync installed",
                subtitle: "Background sync agent is now active",
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
