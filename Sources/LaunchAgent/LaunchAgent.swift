import Foundation

struct LaunchAgent {
    static let label = "com.alfred.bw-alfred.sync"
    static var plistPath: String {
        let home = ProcessInfo.processInfo.environment["HOME"] ?? NSHomeDirectory()
        return "\(home)/Library/LaunchAgents/\(label).plist"
    }

    static func install() throws {
        let env = ProcessInfo.processInfo.environment
        let syncIntervalMinutes = Int(env["bw_sync_interval"] ?? "60") ?? 60
        let syncIntervalSeconds = syncIntervalMinutes * 60

        guard let binaryPath = Bundle.main.executableURL?.path
                ?? ProcessInfo.processInfo.arguments.first
        else {
            throw NSError(domain: "bw-alfred", code: 1,
                          userInfo: [NSLocalizedDescriptionKey: "Cannot determine binary path"])
        }

        let plist = """
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
        <plist version="1.0">
        <dict>
            <key>Label</key>
            <string>\(label)</string>
            <key>ProgramArguments</key>
            <array>
                <string>\(binaryPath)</string>
                <string>sync_vault</string>
            </array>
            <key>StartInterval</key>
            <integer>\(syncIntervalSeconds)</integer>
            <key>RunAtLoad</key>
            <false/>
        </dict>
        </plist>
        """

        let dir = URL(fileURLWithPath: plistPath).deletingLastPathComponent().path
        try FileManager.default.createDirectory(atPath: dir, withIntermediateDirectories: true)
        try plist.write(toFile: plistPath, atomically: true, encoding: .utf8)

        let uid = getuid()
        runLaunchctl(["bootstrap", "gui/\(uid)", plistPath])
    }

    static func uninstall() {
        let uid = getuid()
        runLaunchctl(["bootout", "gui/\(uid)/\(label)"])
        try? FileManager.default.removeItem(atPath: plistPath)
    }

    static var isInstalled: Bool {
        FileManager.default.fileExists(atPath: plistPath)
    }

    private static func runLaunchctl(_ args: [String]) {
        let proc = Process()
        proc.executableURL = URL(fileURLWithPath: "/bin/launchctl")
        proc.arguments = args
        proc.standardOutput = FileHandle.nullDevice
        proc.standardError = FileHandle.nullDevice
        try? proc.run()
        proc.waitUntilExit()
    }
}
