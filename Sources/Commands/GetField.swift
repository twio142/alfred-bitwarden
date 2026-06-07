import AppKit
import Foundation

enum GetField {
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
        if field.hasPrefix("url:"), let index = Int(field.dropFirst(4)) {
            value = try fetchURL(itemId, index: index)
        } else if field.hasPrefix("custom:") {
            value = try fetchCustomField(itemId, name: String(field.dropFirst(7)))
        } else {
            switch field {
            case "password": value = try fetchPassword(itemId)
            case "totp": value = try fetchTOTP(itemId)
            case "username": value = try fetchUsername(itemId)
            case "notes": value = try fetchNotes(itemId)
            case "card_number": value = try fetchCardNumber(itemId)
            default:
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

        let clipboardTime = Int(ProcessInfo.processInfo.environment["ClipboardTime"] ?? "30") ?? 30
        scheduleClipboardRestore(after: clipboardTime)
    }

    private static func fetchPassword(_ itemId: String) throws -> String {
        let liveItem = try BWItems.getItem(itemId)
        guard let pwd = liveItem.login?.password else {
            throw NSError(domain: "bw-alfred", code: 1, userInfo: [NSLocalizedDescriptionKey: "No password found"])
        }
        return pwd
    }

    private static func fetchTOTP(_ itemId: String) throws -> String {
        let liveItem = try BWItems.getItem(itemId)
        if let nativeTotp = liveItem.login?.totp, !nativeTotp.isEmpty {
            guard let code = TOTPGenerator.generate(base32Secret: nativeTotp) else {
                throw NSError(domain: "bw-alfred", code: 2, userInfo: [NSLocalizedDescriptionKey: "TOTP generation failed"])
            }
            return code
        }
        if let totpField = liveItem.fields?.first(where: { $0.name?.lowercased() == "totp" && $0.type == .hidden }),
           let secret = totpField.value, !secret.isEmpty
        {
            guard let code = TOTPGenerator.generate(base32Secret: secret) else {
                throw NSError(domain: "bw-alfred", code: 2, userInfo: [NSLocalizedDescriptionKey: "TOTP generation failed"])
            }
            return code
        }
        throw NSError(domain: "bw-alfred", code: 3, userInfo: [NSLocalizedDescriptionKey: "No TOTP secret found"])
    }

    private static func fetchUsername(_ itemId: String) throws -> String {
        guard let cache = VaultCache.load(),
              let item = cache.items.first(where: { $0.id == itemId }),
              let username = item.login?.username
        else {
            throw NSError(domain: "bw-alfred", code: 4, userInfo: [NSLocalizedDescriptionKey: "No username found"])
        }
        return username
    }

    private static func fetchNotes(_ itemId: String) throws -> String {
        guard let cache = VaultCache.load(),
              let item = cache.items.first(where: { $0.id == itemId }),
              let notes = item.notes
        else {
            throw NSError(domain: "bw-alfred", code: 5, userInfo: [NSLocalizedDescriptionKey: "No notes found"])
        }
        return notes
    }

    private static func fetchCardNumber(_ itemId: String) throws -> String {
        let liveItem = try BWItems.getItem(itemId)
        guard let number = liveItem.card?.number else {
            throw NSError(domain: "bw-alfred", code: 9, userInfo: [NSLocalizedDescriptionKey: "No card number found"])
        }
        return number
    }

    private static func fetchURL(_ itemId: String, index: Int) throws -> String {
        guard let cache = VaultCache.load(),
              let item = cache.items.first(where: { $0.id == itemId }),
              let uris = item.login?.uris, index < uris.count,
              let uri = uris[index].uri
        else {
            throw NSError(domain: "bw-alfred", code: 8, userInfo: [NSLocalizedDescriptionKey: "URL not found"])
        }
        return uri
    }

    private static func fetchCustomField(_ itemId: String, name: String) throws -> String {
        guard let cache = VaultCache.load(),
              let item = cache.items.first(where: { $0.id == itemId }),
              let customField = item.fields?.first(where: { $0.name == name && $0.type == .text }),
              let v = customField.value
        else {
            throw NSError(domain: "bw-alfred", code: 6, userInfo: [NSLocalizedDescriptionKey: "Custom field not found"])
        }
        return v
    }

    private static func writeToClipboard(_ value: String) {
        let pb = NSPasteboard.general
        pb.declareTypes([.string], owner: nil)
        pb.setString(value, forType: .string)
    }

    private static func scheduleClipboardRestore(after seconds: Int) {
        guard seconds > 0 else { return }
        let proc = Process()
        proc.executableURL = URL(fileURLWithPath: "/bin/sh")
        proc.arguments = ["-c", "sleep \(seconds) && echo -n '' | pbcopy"]
        proc.standardOutput = FileHandle.nullDevice
        proc.standardError = FileHandle.nullDevice
        try? proc.run()
    }
}
