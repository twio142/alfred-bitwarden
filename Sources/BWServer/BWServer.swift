import Foundation

enum BWServer {
    static var pidFile: String {
        guard let dir = ProcessInfo.processInfo.environment["alfred_workflow_cache"] else {
            AlfredOutput.error("alfred_workflow_cache is not set").printJSON()
            exit(1)
        }
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
        proc.environment = ProcessInfo.processInfo.environment
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
        let path = pidFile
        let dir = (path as NSString).deletingLastPathComponent
        try? FileManager.default.createDirectory(atPath: dir, withIntermediateDirectories: true)
        try? "\(pid)".write(toFile: path, atomically: true, encoding: .utf8)
    }

    private static func cleanupStalePID() {
        try? FileManager.default.removeItem(atPath: pidFile)
    }

    /// True if the process exists and is not a zombie (`kill(pid, 0)` alone succeeds for zombies).
    private static func isProcessRunning(_ pid: pid_t) -> Bool {
        var info = kinfo_proc()
        var size = MemoryLayout<kinfo_proc>.stride
        var mib: [Int32] = [CTL_KERN, KERN_PROC, KERN_PROC_PID, pid]
        guard sysctl(&mib, UInt32(mib.count), &info, &size, nil, 0) == 0,
              size > 0
        else { return false }
        return Int32(info.kp_proc.p_stat) != SZOMB
    }
}
