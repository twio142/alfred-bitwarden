import Foundation

enum GetAttachment {
    static func run() {
        let args = Array(CommandLine.arguments.dropFirst(2))
        let env = ProcessInfo.processInfo.environment
        let itemId = args.first ?? ""
        let attachmentId = args.dropFirst().first ?? ""

        guard !itemId.isEmpty, !attachmentId.isEmpty else {
            AlfredOutput.error("Usage: get_attachment <item_id> <attachment_id>").printJSON()
            return
        }

        var downloadsFolder = env["downloadFolder"] ?? ""
        if downloadsFolder.isEmpty {
            guard let prompted = promptDownloadFolder() else {
                AlfredOutput.error("No download folder specified").printJSON()
                return
            }
            downloadsFolder = prompted
        }

        do {
            try ensureUnlocked()
            let liveItem = try BWItems.getItem(itemId)
            guard let attachment = liveItem.attachments?.first(where: { $0.id == attachmentId }) else {
                AlfredOutput.error("Attachment not found").printJSON()
                return
            }
            let data = try BWAttachments.download(attachmentId: attachmentId, itemId: itemId)
            let fileName = attachment.fileName ?? attachmentId
            let destURL = URL(fileURLWithPath: downloadsFolder).appendingPathComponent(fileName)
            try FileManager.default.createDirectory(
                at: URL(fileURLWithPath: downloadsFolder),
                withIntermediateDirectories: true
            )
            try data.write(to: destURL)
            Notifier.notify(title: "Bitwarden", message: "Downloaded \(fileName)")
            AlfredOutput.single(AlfredItem(
                title: "Downloaded \(fileName)",
                subtitle: destURL.path,
                icon: AlfredIcon(path: "icons/attachment.png"),
                valid: false
            )).printJSON()
        } catch {
            AlfredOutput.error("Download failed: \(error)").printJSON()
        }
    }

    private static func promptDownloadFolder() -> String? {
        let home = ProcessInfo.processInfo.environment["HOME"] ?? NSHomeDirectory()
        let defaultFolder = home + "/Downloads"
        let script = """
        tell application "System Events"
            activate
            set result to display dialog "Enter download folder path:" ¬
                default answer "\(defaultFolder)" ¬
                with title "Bitwarden — Download Attachment" ¬
                buttons {"Cancel", "Download"} ¬
                default button "Download"
            if button returned of result is "Download" then
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
        let out = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines)
        return out?.isEmpty == false ? out : nil
    }
}
