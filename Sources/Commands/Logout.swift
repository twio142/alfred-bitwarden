import Foundation

struct Logout {
    static func run() {
        let email = ProcessInfo.processInfo.environment["bw_email"] ?? ""
        _ = try? BWAuth.restLock()
        BWAuth.logout()
        try? Keychain.delete(for: email)
        AlfredOutput.single(AlfredItem(
            title: "Logged out",
            subtitle: "Successfully logged out of Bitwarden",
            icon: AlfredIcon(path: "icons/logout.png"),
            valid: false
        )).printJSON()
    }
}
