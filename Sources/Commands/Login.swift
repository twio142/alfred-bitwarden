import Foundation

struct Login {
    static func run() {
        do {
            try ensureUnlocked()
            AlfredOutput.single(AlfredItem(
                title: "Logged in successfully",
                subtitle: "Vault is unlocked",
                icon: AlfredIcon(path: "icons/unlock.png"),
                valid: false
            )).printJSON()
        } catch {
            AlfredOutput.error("Login failed: \(error)").printJSON()
        }
    }
}
