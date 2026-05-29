import Foundation

struct Search {
    static func run() {
        let query = CommandLine.arguments.dropFirst(2).first ?? ""
        let env = ProcessInfo.processInfo.environment
        let syncInterval = Int(env["bw_sync_interval"] ?? "60") ?? 60

        guard let cache = VaultCache.load() else {
            AlfredOutput.loading("Vault cache empty — syncing…").printJSON()
            return
        }

        let prefs = WorkflowPrefs.load()
        let recency = RecencyStore.load()

        var items = cache.items

        // Apply org filter
        if let orgId = prefs.defaultOrganizationId {
            items = items.filter { $0.organizationId == orgId }
        }
        // Apply collection filter
        if let colId = prefs.defaultCollectionId {
            items = items.filter { $0.collectionIds.contains(colId) }
        }

        // Apply text query filter
        if !query.isEmpty {
            let q = query.lowercased()
            items = items.filter { item in
                item.name.lowercased().contains(q) ||
                item.login?.username?.lowercased().contains(q) == true ||
                item.login?.uris?.first?.uri?.lowercased().contains(q) == true ||
                item.notes?.lowercased().contains(q) == true
            }
        }

        // Browser URL matching
        let browserDomain = URLMatcher.browserURL().flatMap { URLMatcher.etld1(from: $0) }

        // Rank items
        items.sort { a, b in
            let aUrlMatch = browserDomain != nil && matchesDomain(item: a, domain: browserDomain!)
            let bUrlMatch = browserDomain != nil && matchesDomain(item: b, domain: browserDomain!)
            if aUrlMatch != bUrlMatch { return aUrlMatch }

            let aRecent = a.id == recency.lastItemId
            let bRecent = b.id == recency.lastItemId
            if aRecent != bRecent { return aRecent }

            if a.favorite != b.favorite { return a.favorite }
            return a.name.lowercased() < b.name.lowercased()
        }

        let alfredItems = items.map { item -> AlfredItem in
            makeAlfredItem(item: item, recency: recency)
        }

        let output = alfredItems.isEmpty
            ? AlfredOutput(items: [AlfredItem(title: "No items found", subtitle: "Try a different search", valid: false)])
            : AlfredOutput(items: alfredItems)
        output.printJSON()

        // Background stale-cache check (T062)
        if cache.isStale(interval: syncInterval) {
            DispatchQueue.global().async {
                _ = try? BWSync.sync()
            }
            Thread.sleep(forTimeInterval: 0.05)
        }
    }

    private static func matchesDomain(item: CachedItem, domain: String) -> Bool {
        guard let uris = item.login?.uris else { return false }
        return uris.contains { uri in
            guard let u = uri.uri, let itemDomain = URLMatcher.etld1(from: u) else { return false }
            return itemDomain == domain
        }
    }

    static func makeAlfredItem(item: CachedItem, recency: RecencyStore) -> AlfredItem {
        let subtitle = buildSubtitle(item: item)
        let icon = iconPath(for: item)

        let shiftMod: AlfredModItem? = item.hasTOTP
            ? AlfredModItem(subtitle: "Copy TOTP code", arg: item.id, valid: true,
                           variables: ["next_command": "get_field", "field": "totp"])
            : nil

        let defaultArg = item.id
        let defaultVars: [String: String] = [
            "item_id": item.id,
            "item_type": "\(item.type.rawValue)",
            "has_totp": item.hasTOTP ? "1" : "0",
            "next_command": "get_field",
            "field": defaultField(for: item)
        ]

        return AlfredItem(
            uid: item.id,
            title: item.name,
            subtitle: subtitle,
            arg: defaultArg,
            icon: AlfredIcon(path: icon),
            mods: AlfredMods(
                ctrl: AlfredModItem(subtitle: "Copy username", arg: item.id, valid: item.login?.username != nil,
                                   variables: ["next_command": "get_field", "field": "username"]),
                shift: shiftMod,
                cmd: AlfredModItem(subtitle: "Copy notes", arg: item.id, valid: item.notes != nil,
                                  variables: ["next_command": "get_field", "field": "notes"]),
                alt: AlfredModItem(subtitle: "More actions…", arg: item.id, valid: true,
                                  variables: ["next_command": "more"]),
                fn: AlfredModItem(subtitle: "Show all fields", arg: item.id, valid: true,
                                 variables: ["next_command": "show_item"])
            ),
            variables: defaultVars
        )
    }

    private static func defaultField(for item: CachedItem) -> String {
        switch item.type {
        case .login: return "password"
        case .secureNote: return "notes"
        case .card, .identity: return "show"
        }
    }

    private static func buildSubtitle(item: CachedItem) -> String {
        switch item.type {
        case .login:
            var parts: [String] = []
            if let user = item.login?.username, !user.isEmpty { parts.append(user) }
            if let uri = item.login?.uris?.first?.uri,
               let domain = URLMatcher.etld1(from: uri) { parts.append(domain) }
            return parts.joined(separator: " · ")
        case .card:
            let brand = item.card?.brand ?? "Card"
            let exp = [item.card?.expMonth, item.card?.expYear].compactMap { $0 }.joined(separator: "/")
            return exp.isEmpty ? brand : "\(brand) · \(exp)"
        case .identity:
            let name = [item.identity?.firstName, item.identity?.lastName].compactMap { $0 }.joined(separator: " ")
            return name.isEmpty ? "Identity" : name
        case .secureNote:
            return "Secure Note"
        }
    }

    private static func iconPath(for item: CachedItem) -> String {
        switch item.type {
        case .login: return "icons/login.png"
        case .secureNote: return "icons/note.png"
        case .card: return "icons/card.png"
        case .identity: return "icons/identity.png"
        }
    }
}

