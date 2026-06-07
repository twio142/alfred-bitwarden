import Foundation

enum AuthError: Error {
    case loginFailed(String)
    case unlockFailed(String)
    case noSessionToken
}

enum BWAuth {
    static func login(password: String? = nil) throws -> String {
        let env = ProcessInfo.processInfo.environment
        let method = env["loginMethod"] ?? "password"
        let email = env["bwuser"] ?? ""

        if let serverUrl = env["serverUrl"], !serverUrl.isEmpty {
            _ = runProcess("bw", args: ["config", "server", serverUrl])
        }

        var args: [String]
        var processEnv: [String: String] = env

        if method == "api_key" {
            args = ["login", "--apikey"]
            processEnv["BW_CLIENTID"] = env["BW_CLIENTID"]
            processEnv["BW_CLIENTSECRET"] = env["BW_CLIENTSECRET"]
        } else {
            args = ["login", email, "--passwordenv", "BW_PASSWORD", "--raw"]
            if let p = password {
                processEnv["BW_PASSWORD"] = p
            }
            if let twoFA = env["twoStepMethod"], !twoFA.isEmpty {
                args += ["--method", twoFA]
            }
        }

        let (output, exitCode) = runProcess("bw", args: args, env: processEnv)
        guard exitCode == 0 else {
            throw AuthError.loginFailed(output)
        }
        return output.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    static func logout() {
        _ = try? runProcess("bw", args: ["logout"]).0
    }

    static func unlock(password: String) throws -> String {
        let (output, exitCode) = runProcess("bw", args: ["unlock", password, "--raw"])
        guard exitCode == 0 else {
            throw AuthError.unlockFailed(output)
        }
        let token = output.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !token.isEmpty else { throw AuthError.noSessionToken }
        return token
    }

    @discardableResult
    private static func runProcess(_ command: String, args: [String], env: [String: String]? = nil) -> (String, Int32) {
        let proc = Process()
        proc.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        proc.arguments = [command] + args
        if let env = env {
            proc.environment = env
        }
        let pipe = Pipe()
        proc.standardOutput = pipe
        proc.standardError = pipe
        try? proc.run()
        proc.waitUntilExit()
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: .utf8) ?? ""
        return (output, proc.terminationStatus)
    }
}

extension BWAuth {
    static func restUnlock(password: String) throws -> String {
        let body = try JSONSerialization.data(withJSONObject: ["password": password])
        let data = try BWClient.shared.post("/unlock", body: body)
        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let dataObj = json["data"] as? [String: Any],
           let raw = dataObj["raw"] as? String
        {
            return raw
        }
        throw AuthError.noSessionToken
    }

    static func restLock() throws {
        _ = try BWClient.shared.post("/lock")
    }
}
