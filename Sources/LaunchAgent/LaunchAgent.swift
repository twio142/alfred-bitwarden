import Foundation

enum LaunchAgent {
    static var label: String {
        ProcessInfo.processInfo.environment["alfred_workflow_bundleid"] ?? "com.alfred.bw-alfred.sync"
    }

    static var plistPath: String {
        let home = ProcessInfo.processInfo.environment["HOME"] ?? NSHomeDirectory()
        return "\(home)/Library/LaunchAgents/\(label).plist"
    }

    static func install() throws {
        let env = ProcessInfo.processInfo.environment
        let syncIntervalMinutes = Int(env["SyncTime"] ?? "60") ?? 60
        let startInterval = syncIntervalMinutes * 60

        guard let bundleId = env["alfred_workflow_bundleid"] else {
            throw NSError(domain: "bw-alfred", code: 1,
                          userInfo: [NSLocalizedDescriptionKey: "alfred_workflow_bundleid not set"])
        }

        let plist = """
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
        <plist version="1.0">
        <dict>
            <key>Label</key>
            <string>\(bundleId)</string>
            <key>LimitLoadToSessionType</key>
            <array>
                <string>Aqua</string>
            </array>
            <key>ProgramArguments</key>
            <array>
                <string>/usr/bin/osascript</string>
                <string>-e</string>
                <string>tell application id "com.runningwithcrayons.Alfred" to run trigger "sync_vault" in workflow "\(bundleId)"</string>
            </array>
            <key>StartInterval</key>
            <integer>\(startInterval)</integer>
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
