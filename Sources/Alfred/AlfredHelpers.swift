import Foundation

extension AlfredOutput {
    static func error(_ message: String) -> AlfredOutput {
        AlfredOutput(items: [
            AlfredItem(
                title: "Error",
                subtitle: message,
                icon: AlfredIcon(path: "icons/error.png"),
                valid: false
            )
        ])
    }

    static func loading(_ message: String = "Loading…") -> AlfredOutput {
        AlfredOutput(
            items: [
                AlfredItem(
                    title: message,
                    icon: AlfredIcon(path: "icons/sync.png"),
                    valid: false
                )
            ],
            rerun: 0.5
        )
    }

    static func single(_ item: AlfredItem) -> AlfredOutput {
        AlfredOutput(items: [item])
    }
}
