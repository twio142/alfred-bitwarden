import Foundation

enum Unlock {
    static func run() {
        let env = ProcessInfo.processInfo.environment
        let email = env["bwuser"] ?? ""

        do {
            // Try Keychain first
            if let password = try? Keychain.load(for: email), !password.isEmpty {
                _ = try BWAuth.restUnlock(password: password)
            } else {
                guard let password = promptPassword(prompt: "Enter Bitwarden master password to unlock:"),
                      !password.isEmpty
                else {
                    AlfredOutput.error("No password provided").printJSON()
                    return
                }
                _ = try BWAuth.restUnlock(password: password)
                try? Keychain.save(password: password, for: email)
            }
            AlfredOutput.single(AlfredItem(
                title: "Vault unlocked",
                subtitle: "Vault is now unlocked",
                icon: AlfredIcon(path: "icons/unlock.png"),
                valid: false
            )).printJSON()
        } catch {
            AlfredOutput.error("Unlock failed: \(error)").printJSON()
        }
    }
}
