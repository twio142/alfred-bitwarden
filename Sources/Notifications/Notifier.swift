import Foundation

struct Notifier {
    static func notify(title: String, message: String) {
        let enabled = ProcessInfo.processInfo.environment["bw_notifications"] ?? "true"
        guard enabled.lowercased() != "false" && enabled != "0" else { return }

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
