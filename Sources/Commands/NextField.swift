import Foundation

struct NextField {
    static func run() {
        let args = Array(CommandLine.arguments.dropFirst(2))
        guard let itemId = args.first else {
            AlfredOutput.error("Usage: next_field <item_id>").printJSON()
            return
        }

        let recency = RecencyStore.load()
        let field = recency.shouldRotateToTOTP(for: itemId) ? "totp" : "password"

        // Inject the field into argv and delegate to GetField
        // We do this by directly calling the copy logic
        do {
            try ensureUnlocked()
            try GetField.copyField(itemId: itemId, field: field)
        } catch {
            AlfredOutput.error("Error: \(error)").printJSON()
        }
    }
}
