import Foundation

enum SetOrganization {
    static func run() {
        let args = Array(CommandLine.arguments.dropFirst(2))
        let orgId = args.first

        if let id = orgId {
            var prefs = WorkflowPrefs.load()
            prefs.defaultOrganizationId = (id == "all" || id == "null") ? nil : id
            prefs.defaultCollectionId = nil
            prefs.save()
            AlfredOutput.single(AlfredItem(
                title: id == "all" ? "Showing all vaults" : "Vault filter set",
                subtitle: id == "all" ? "No organization filter applied" : "Filtered to organization",
                icon: AlfredIcon(path: "icons/company.png"),
                valid: false
            )).printJSON()
            return
        }

        guard let cache = VaultCache.load() else {
            AlfredOutput.error("No vault cache — please sync first").printJSON()
            return
        }

        let env = ProcessInfo.processInfo.environment
        var items: [AlfredItem] = [
            AlfredItem(
                title: "All Vaults",
                subtitle: "Show items from all organizations",
                arg: .single("all"),
                icon: AlfredIcon(path: "icons/company.png"),
                variables: ["next": "set_organization", "org_id": "all"]
            ),
        ]
        items += cache.organizations.map { org in
            AlfredItem(
                title: org.name,
                subtitle: "Filter to this organization",
                arg: .single(org.id),
                icon: AlfredIcon(path: "icons/company.png"),
                variables: ["next": "set_organization", "org_id": org.id]
            )
        }
        let (popped, remaining) = NavStack.pop(from: env["nav_stack"] ?? "")
        if let popped {
            items.append(AlfredItem(
                title: "Go Back",
                arg: nil,
                icon: AlfredIcon(path: "icons/back.png"),
                variables: ["next": popped, "nav_stack": remaining]
            ))
        }
        AlfredOutput(items: items).printJSON()
    }
}
