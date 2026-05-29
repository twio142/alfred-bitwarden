import Foundation

struct ShowItem {
    static func run() {
        let args = Array(CommandLine.arguments.dropFirst(2))
        guard let itemId = args.first else {
            AlfredOutput.error("Usage: show_item <item_id>").printJSON()
            return
        }

        guard let cache = VaultCache.load(),
              let item = cache.items.first(where: { $0.id == itemId })
        else {
            AlfredOutput.error("Item not found in cache").printJSON()
            return
        }

        let details = buildDetails(item: item)
        let script = """
        tell application "System Events"
            activate
            display dialog "\(details.replacingOccurrences(of: "\\", with: "\\\\").replacingOccurrences(of: "\"", with: "\\\""))" ¬
                with title "\(item.name.replacingOccurrences(of: "\"", with: "\\\""))" ¬
                buttons {"Close"} ¬
                default button "Close"
        end tell
        """
        let proc = Process()
        proc.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
        proc.arguments = ["-e", script]
        proc.standardOutput = FileHandle.nullDevice
        proc.standardError = FileHandle.nullDevice
        try? proc.run()
        proc.waitUntilExit()
    }

    private static func buildDetails(item: CachedItem) -> String {
        var lines: [String] = []
        lines.append("Name: \(item.name)")

        switch item.type {
        case .login:
            if let username = item.login?.username { lines.append("Username: \(username)") }
            if item.hasTOTP { lines.append("TOTP: [available]") }
            if let uris = item.login?.uris {
                for (i, uri) in uris.enumerated() {
                    if let u = uri.uri { lines.append("URL \(i + 1): \(u)") }
                }
            }
        case .card:
            if let name = item.card?.cardholderName { lines.append("Cardholder: \(name)") }
            if let brand = item.card?.brand { lines.append("Brand: \(brand)") }
            let exp = [item.card?.expMonth, item.card?.expYear].compactMap { $0 }.joined(separator: "/")
            if !exp.isEmpty { lines.append("Expires: \(exp)") }
        case .identity:
            if let id = item.identity {
                let name = [id.firstName, id.middleName, id.lastName].compactMap { $0 }.joined(separator: " ")
                if !name.isEmpty { lines.append("Name: \(name)") }
                if let email = id.email { lines.append("Email: \(email)") }
                if let phone = id.phone { lines.append("Phone: \(phone)") }
                if let company = id.company { lines.append("Company: \(company)") }
            }
        case .secureNote:
            break
        }

        if let notes = item.notes, !notes.isEmpty {
            lines.append("Notes: \(notes.prefix(200))")
        }

        if let fields = item.fields {
            for field in fields where field.type != .hidden {
                if let name = field.name, let value = field.value {
                    lines.append("\(name): \(value)")
                }
            }
        }

        return lines.joined(separator: "\n")
    }
}
