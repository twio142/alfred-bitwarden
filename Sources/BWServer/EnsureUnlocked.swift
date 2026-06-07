import Foundation

enum EnsureUnlockedError: Error {
    case timeout
    case authenticationFailed(String)
}

func ensureUnlocked() throws {
    if !BWServer.isRunning() {
        BWServer.start()
        try waitForServer(timeout: 3)
    }

    let state = try BWStatus.get()

    switch state.status {
    case .unauthenticated:
        try handleLogin()
        let newState = try BWStatus.get()
        if newState.status == .locked {
            try handleUnlock()
        }
    case .locked:
        try handleUnlock()
    case .unlocked:
        break
    }
}

private func waitForServer(timeout: TimeInterval) throws {
    let deadline = Date().addingTimeInterval(timeout)
    while Date() < deadline {
        if let _ = try? BWStatus.get() {
            return
        }
        Thread.sleep(forTimeInterval: 0.2)
    }
    throw EnsureUnlockedError.timeout
}

private func handleLogin() throws {
    let env = ProcessInfo.processInfo.environment
    let email = env["bwuser"] ?? ""

    var password: String?
    if let stored = try? Keychain.load(for: email), !stored.isEmpty {
        password = stored
    } else {
        password = promptPassword(prompt: "Enter Bitwarden master password:")
        if let p = password, !p.isEmpty {
            try? Keychain.save(password: p, for: email)
        }
    }

    _ = try BWAuth.login(password: password)
}

private func handleUnlock() throws {
    let env = ProcessInfo.processInfo.environment
    let email = env["bwuser"] ?? ""

    if let stored = try? Keychain.load(for: email), !stored.isEmpty {
        if let _ = try? BWAuth.restUnlock(password: stored) {
            return
        }
    }

    guard let password = promptPassword(prompt: "Enter Bitwarden master password to unlock:"),
          !password.isEmpty
    else {
        throw EnsureUnlockedError.authenticationFailed("No password provided")
    }

    _ = try BWAuth.restUnlock(password: password)
    try? Keychain.save(password: password, for: email)
}

func promptPassword(prompt: String) -> String? {
    let script = """
    tell application "System Events"
        activate
        set result to display dialog "\(prompt.replacingOccurrences(of: "\"", with: "\\\""))" ¬
            with hidden answer ¬
            default answer "" ¬
            with title "Bitwarden" ¬
            buttons {"Cancel", "OK"} ¬
            default button "OK"
        if button returned of result is "OK" then
            return text returned of result
        end if
    end tell
    """
    let proc = Process()
    proc.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
    proc.arguments = ["-e", script]
    let pipe = Pipe()
    proc.standardOutput = pipe
    proc.standardError = FileHandle.nullDevice
    try? proc.run()
    proc.waitUntilExit()
    let data = pipe.fileHandleForReading.readDataToEndOfFile()
    let output = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines)
    return output?.isEmpty == false ? output : nil
}
