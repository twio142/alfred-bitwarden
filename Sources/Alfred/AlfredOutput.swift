import Foundation

struct AlfredOutput: Codable {
    var items: [AlfredItem]
    var variables: [String: String]?
    var rerun: Double?

    func printJSON() {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .withoutEscapingSlashes
        if let data = try? encoder.encode(self),
           let str = String(data: data, encoding: .utf8) {
            print(str)
        }
    }
}

struct AlfredItem: Codable {
    var uid: String?
    var title: String
    var subtitle: String?
    var arg: String?
    var icon: AlfredIcon?
    var valid: Bool = true
    var autocomplete: String?
    var mods: AlfredMods?
    var text: AlfredText?
    var variables: [String: String]?

    enum CodingKeys: String, CodingKey {
        case uid, title, subtitle, arg, icon, valid, autocomplete, mods, text, variables
    }
}

struct AlfredIcon: Codable {
    var path: String?
    var type: String?
}

struct AlfredMods: Codable {
    var ctrl: AlfredModItem?
    var shift: AlfredModItem?
    var cmd: AlfredModItem?
    var alt: AlfredModItem?
    var fn: AlfredModItem?
}

struct AlfredModItem: Codable {
    var subtitle: String?
    var arg: String?
    var valid: Bool = true
    var variables: [String: String]?
}

struct AlfredText: Codable {
    var copy: String?
    var largetype: String?
}
