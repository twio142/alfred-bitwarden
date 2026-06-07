import Foundation

enum Notifier {
    static func notify(title: String, message: String) {
        let enabled = ProcessInfo.processInfo.environment["PostNotification"] ?? "0"
        guard enabled == "1" || enabled.lowercased() == "true" else { return }

        let script = """
        display notification "\(message.replacingOccurrences(of: "\"", with: "\\\""))" ¬
            with title "\(title.replacingOccurrences(of: "\"", with: "\\\""))"
        """
        let proc = Process()
        proc.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
        proc.arguments = ["-e", script]
        proc.standardOutput = FileHandle.nullDevice
        proc.standardError = FileHandle.nullDevice
        try? proc.run()
    }
}
