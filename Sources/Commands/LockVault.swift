import Foundation

struct LockVault {
    static func run() {
        do {
            try BWAuth.restLock()
            AlfredOutput.single(AlfredItem(
                title: "Vault locked",
                subtitle: "Vault has been locked",
                icon: AlfredIcon(path: "icons/lock.png"),
                valid: false
            )).printJSON()
        } catch {
            AlfredOutput.error("Lock failed: \(error)").printJSON()
        }
    }
}
