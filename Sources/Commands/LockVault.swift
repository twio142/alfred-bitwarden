import Foundation

enum LockVault {
    static func run() {
        do {
            try BWAuth.restLock()
            AlfredOutput.single(AlfredItem(
                title: "Vault locked",
                subtitle: "Vault has been locked",
                valid: false
            )).printJSON()
        } catch {
            AlfredOutput.error("Lock failed: \(error)").printJSON()
        }
    }
}
