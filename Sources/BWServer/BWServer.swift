import Foundation

struct BWServer {
    static var pidFile: String {
        let dir = ProcessInfo.processInfo.environment["alfred_workflow_cache"] ?? "/tmp"
        return dir + "/bw-serve.pid"
    }

    static func start() {
        if let pid = readPID(), isProcessRunning(pid) {
            return
        }
        cleanupStalePID()

        let proc = Process()
        proc.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        proc.arguments = ["bw", "serve", "--port", "8087"]
        if let token = BWClient.shared.sessionToken {
            proc.environment = ProcessInfo.processInfo.environment.merging(
                ["BW_SESSION": token]) { _, new in new }
        } else {
            proc.environment = ProcessInfo.processInfo.environment
        }
        proc.standardOutput = FileHandle.nullDevice
        proc.standardError = FileHandle.nullDevice
        try? proc.run()
        writePID(proc.processIdentifier)
    }

    static func stop() {
        guard let pid = readPID() else { return }
        kill(pid, SIGTERM)
        try? FileManager.default.removeItem(atPath: pidFile)
    }

    static func isRunning() -> Bool {
        guard let pid = readPID() else { return false }
        return isProcessRunning(pid)
    }

    private static func readPID() -> pid_t? {
        guard let str = try? String(contentsOfFile: pidFile, encoding: .utf8),
              let pid = pid_t(str.trimmingCharacters(in: .whitespacesAndNewlines))
        else { return nil }
        return pid
    }

    private static func writePID(_ pid: pid_t) {
        let dir = ProcessInfo.processInfo.environment["alfred_workflow_cache"] ?? "/tmp"
        try? FileManager.default.createDirectory(
            atPath: dir, withIntermediateDirectories: true
        )
        try? "\(pid)".write(toFile: pidFile, atomically: true, encoding: .utf8)
    }

    private static func cleanupStalePID() {
        try? FileManager.default.removeItem(atPath: pidFile)
    }

    private static func isProcessRunning(_ pid: pid_t) -> Bool {
        kill(pid, 0) == 0
    }
}
