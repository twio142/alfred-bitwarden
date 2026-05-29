import Foundation
import AppKit

struct GetField {
    static func run() {
        let args = Array(CommandLine.arguments.dropFirst(2))
        guard args.count >= 2 else {
            AlfredOutput.error("Usage: get_field <item_id> <field>").printJSON()
            return
        }
        let itemId = args[0]
        let field = args[1]

        do {
            try ensureUnlocked()
            try copyField(itemId: itemId, field: field)
        } catch {
            AlfredOutput.error("Error: \(error)").printJSON()
        }
    }

    static func copyField(itemId: String, field: String) throws {
        let value: String

        switch field {
        case "password":
            let liveItem = try BWItems.getItem(itemId)
            guard let pwd = liveItem.login?.password else {
                throw NSError(domain: "bw-alfred", code: 1, userInfo: [NSLocalizedDescriptionKey: "No password found"])
            }
            value = pwd

        case "totp":
            let liveItem = try BWItems.getItem(itemId)
            if let nativeTotp = liveItem.login?.totp, !nativeTotp.isEmpty {
                guard let code = TOTPGenerator.generate(base32Secret: nativeTotp) else {
                    throw NSError(domain: "bw-alfred", code: 2, userInfo: [NSLocalizedDescriptionKey: "TOTP generation failed"])
                }
                value = code
            } else if let totpField = liveItem.fields?.first(where: { $0.name?.lowercased() == "totp" && $0.type == .hidden }),
                      let secret = totpField.value, !secret.isEmpty {
                guard let code = TOTPGenerator.generate(base32Secret: secret) else {
                    throw NSError(domain: "bw-alfred", code: 2, userInfo: [NSLocalizedDescriptionKey: "TOTP generation failed"])
                }
                value = code
            } else {
                throw NSError(domain: "bw-alfred", code: 3, userInfo: [NSLocalizedDescriptionKey: "No TOTP secret found"])
            }

        case "username":
            guard let cache = VaultCache.load(),
                  let item = cache.items.first(where: { $0.id == itemId }),
                  let username = item.login?.username
            else {
                throw NSError(domain: "bw-alfred", code: 4, userInfo: [NSLocalizedDescriptionKey: "No username found"])
            }
            value = username

        case "notes":
            guard let cache = VaultCache.load(),
                  let item = cache.items.first(where: { $0.id == itemId }),
                  let notes = item.notes
            else {
                throw NSError(domain: "bw-alfred", code: 5, userInfo: [NSLocalizedDescriptionKey: "No notes found"])
            }
            value = notes

        default:
            // custom:<name>
            if field.hasPrefix("custom:") {
                let name = String(field.dropFirst(7))
                guard let cache = VaultCache.load(),
                      let item = cache.items.first(where: { $0.id == itemId }),
                      let customField = item.fields?.first(where: { $0.name == name && $0.type == .text }),
                      let v = customField.value
                else {
                    throw NSError(domain: "bw-alfred", code: 6, userInfo: [NSLocalizedDescriptionKey: "Custom field not found"])
                }
                value = v
            } else {
                throw NSError(domain: "bw-alfred", code: 7, userInfo: [NSLocalizedDescriptionKey: "Unknown field: \(field)"])
            }
        }

        writeToClipboard(value)
        Notifier.notify(title: "Bitwarden", message: "Copied \(field) to clipboard")

        var recency = RecencyStore.load()
        recency.lastItemId = itemId
        recency.lastField = field
        recency.lastCopiedAt = Date()
        recency.save()

        let clipboardTime = Int(ProcessInfo.processInfo.environment["bw_clipboard_time"] ?? "30") ?? 30
        scheduleClipboardRestore(after: clipboardTime)
    }

    private static func writeToClipboard(_ value: String) {
        let pb = NSPasteboard.general
        pb.declareTypes([.string], owner: nil)
        pb.setString(value, forType: .string)
    }

    private static func scheduleClipboardRestore(after seconds: Int) {
        guard seconds > 0 else { return }
        // Spawn a detached background process to clear clipboard after delay
        let proc = Process()
        proc.executableURL = URL(fileURLWithPath: "/bin/sh")
        proc.arguments = ["-c", "sleep \(seconds) && echo -n '' | pbcopy"]
        proc.standardOutput = FileHandle.nullDevice
        proc.standardError = FileHandle.nullDevice
        try? proc.run()
    }
}
