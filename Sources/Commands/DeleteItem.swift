import Foundation

enum DeleteItem {
    static func run() {
        let args = Array(CommandLine.arguments.dropFirst(2))
        let itemId = args.first ?? ""

        guard !itemId.isEmpty else {
            AlfredOutput.error("Usage: rm <item_id>").printJSON()
            return
        }

        let itemName: String
        if let cache = VaultCache.load(), let item = cache.items.first(where: { $0.id == itemId }) {
            itemName = item.name
        } else {
            itemName = itemId
        }

        let confirmed = showConfirmDialog(itemName: itemName)
        guard confirmed else { return }

        do {
            try ensureUnlocked()
            try BWItems.deleteItem(itemId)
            if var cache = VaultCache.load() {
                cache.items.removeAll { $0.id == itemId }
                cache.save()
            }
            _ = try? BWSync.sync()
            AlfredOutput.single(AlfredItem(
                title: "Item deleted",
                subtitle: "\(itemName) moved to Trash",
                icon: AlfredIcon(path: "icons/delete.png"),
                valid: false
            )).printJSON()
        } catch {
            AlfredOutput.error("Delete failed: \(error)").printJSON()
        }
    }

    private static func showConfirmDialog(itemName: String) -> Bool {
        let safeName = itemName.replacingOccurrences(of: "\"", with: "\\\"")
        let script = """
        tell application "System Events"
            activate
            set result to display dialog "THIS ACTION CANNOT BE UNDONE\\n\\nMove \\"\(safeName)\\" to Trash?" ¬
                with title "Bitwarden — Delete Item" ¬
                with icon caution ¬
                buttons {"Cancel", "Delete"} ¬
                default button "Cancel"
            return button returned of result
        end tell
        """
        let proc = Process()
        proc.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
        proc.arguments = ["-e", script]
        let pipe = Pipe()
        proc.standardOutput = pipe
        proc.standardError = FileHandle.nullDevice
        try? proc.run()
        proc.waitUntilExit()
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let out = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines)
        return out == "Delete"
    }
}
