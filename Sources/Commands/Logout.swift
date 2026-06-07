import Foundation

enum Logout {
    static func run() {
        let email = ProcessInfo.processInfo.environment["bwuser"] ?? ""
        _ = try? BWAuth.restLock()
        BWAuth.logout()
        try? Keychain.delete(for: email)
        AlfredOutput.single(AlfredItem(
            title: "Logged out",
            subtitle: "Successfully logged out of Bitwarden",
            valid: false
        )).printJSON()
    }
}
