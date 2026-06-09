import Foundation

enum NavStack {
    static func push(_ command: String, onto existing: String) -> String {
        existing.isEmpty ? command : "\(command)|\(existing)"
    }

    static func pop(from stack: String) -> (command: String?, remaining: String) {
        guard !stack.isEmpty else { return (nil, "") }
        let parts = stack.split(separator: "|", maxSplits: 1)
        let command = String(parts[0])
        let remaining = parts.count > 1 ? String(parts[1]) : ""
        return (command, remaining)
    }
}
