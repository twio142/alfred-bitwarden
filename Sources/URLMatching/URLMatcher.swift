import AppKit
import Foundation

enum URLMatcher {
    /// Known compound public suffixes
    private static let compoundSuffixes: Set<String> = [
        "co.uk", "co.nz", "co.jp", "co.za", "co.in", "co.kr", "co.id",
        "com.au", "com.br", "com.mx", "com.ar", "com.tr", "com.sg",
        "com.hk", "com.tw", "com.my", "com.ph", "com.eg", "com.ng",
        "org.uk", "org.au", "net.au", "net.nz", "ne.jp",
        "gov.uk", "gov.au", "ac.uk", "ac.nz", "ac.jp",
        "edu.au", "edu.sg", "edu.hk",
        "or.jp", "gr.jp", "ad.jp", "ed.jp",
        "sch.uk", "plc.uk", "ltd.uk", "me.uk",
        "com.pl", "net.pl", "org.pl",
        "com.ua", "net.ua", "org.ua",
        "com.cn", "net.cn", "org.cn", "gov.cn",
        "com.ru", "net.ru", "org.ru",
        "com.de", "com.fr", "com.it", "com.es",
        "com.pe", "com.co", "com.ve", "com.cl",
    ]

    static func etld1(from urlString: String) -> String? {
        guard let components = URLComponents(string: urlString),
              let scheme = components.scheme,
              scheme == "http" || scheme == "https",
              let host = components.host,
              !host.isEmpty
        else { return nil }

        // Skip IPs, localhost, internal hostnames
        if isIPAddress(host) || host == "localhost" || !host.contains(".") {
            return nil
        }

        var h = host.lowercased()
        if h.hasPrefix("www.") { h = String(h.dropFirst(4)) }

        let labels = h.split(separator: ".").map(String.init)
        guard labels.count >= 2 else { return nil }

        let lastTwo = labels.suffix(2).joined(separator: ".")
        if labels.count >= 3, compoundSuffixes.contains(lastTwo) {
            return labels.suffix(3).joined(separator: ".")
        }
        return lastTwo
    }

    private static func isIPAddress(_ host: String) -> Bool {
        // IPv4: all labels are numeric
        let labels = host.split(separator: ".").map(String.init)
        if labels.count == 4 && labels.allSatisfy({ Int($0) != nil }) { return true }
        // IPv6: contains ":"
        if host.contains(":") { return true }
        return false
    }

    /// Browsers supported: Safari, Firefox, Chrome, Edge, Opera, Brave, Vivaldi, Arc
    static func browserInfo() -> (url: String, path: String)? {
        let browsers: [(app: String, script: String)] = [
            ("Safari", "tell application \"Safari\" to return URL of current tab of front window"),
            ("Firefox", "tell application \"Firefox\" to return URL of active tab of front window"),
            ("Google Chrome", "tell application \"Google Chrome\" to return URL of active tab of front window"),
            ("Microsoft Edge", "tell application \"Microsoft Edge\" to return URL of active tab of front window"),
            ("Opera", "tell application \"Opera\" to return URL of active tab of front window"),
            ("Brave Browser", "tell application \"Brave Browser\" to return URL of active tab of front window"),
            ("Vivaldi", "tell application \"Vivaldi\" to return URL of active tab of front window"),
            ("Arc", "tell application \"Arc\" to return URL of active tab of front window"),
        ]

        guard let app = NSWorkspace.shared.menuBarOwningApplication,
              let frontApp = app.localizedName,
              let appPath = app.bundleURL?.path
        else { return nil }

        for (name, script) in browsers {
            guard frontApp.lowercased().contains(name.lowercased().components(separatedBy: " ").first ?? name) == true
                    || frontApp == name
            else { continue }
            if let url = runAppleScript(script) { return (url, appPath) }
        }
        return nil
    }

    static func browserURL() -> String? {
        browserInfo()?.url
    }

    private static func runAppleScript(_ script: String) -> String? {
        let proc = Process()
        proc.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
        proc.arguments = ["-e", script]
        let pipe = Pipe()
        proc.standardOutput = pipe
        proc.standardError = FileHandle.nullDevice
        try? proc.run()
        proc.waitUntilExit()
        guard proc.terminationStatus == 0 else { return nil }
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let out = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines)
        return out?.isEmpty == false ? out : nil
    }
}
