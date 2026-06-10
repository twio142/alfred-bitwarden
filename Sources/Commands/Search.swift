import Foundation

enum Search {
    static func run() {
        let query = CommandLine.arguments.dropFirst(2).first ?? ""
        let env = ProcessInfo.processInfo.environment
        let syncInterval = Int(env["SyncTime"] ?? "60") ?? 60

        guard let cache = VaultCache.load() else {
            AlfredOutput.loading("Vault cache empty — syncing…").printJSON()
            return
        }

        let prefs = WorkflowPrefs.load()
        let recency = RecencyStore.load()

        var items = applyFilters(to: cache.items, prefs: prefs, env: env, query: query)

        // Browser URL matching
        let browser = URLMatcher.browserInfo()
        let browserDomain = browser.flatMap { URLMatcher.etld1(from: $0.url) }
        let browserPath = browserDomain != nil ? browser?.path : nil

        // Rank items
        items.sort { a, b in
            let aUrlMatch = browserDomain != nil && matchesDomain(item: a, domain: browserDomain!)
            let bUrlMatch = browserDomain != nil && matchesDomain(item: b, domain: browserDomain!)
            if aUrlMatch != bUrlMatch { return aUrlMatch }

            let aRecent = recency.isRecent(for: a.id)
            let bRecent = recency.isRecent(for: b.id)
            if aRecent != bRecent { return aRecent }

            if a.favorite != b.favorite { return a.favorite }
            return a.name.lowercased() < b.name.lowercased()
        }

        let alfredItems = items.map { item -> AlfredItem in
            let matchedBrowserPath = browserDomain != nil && matchesDomain(item: item, domain: browserDomain!)
                ? browserPath : nil
            return makeAlfredItem(item: item, recency: recency, browserPath: matchedBrowserPath, navStack: env["nav_stack"] ?? "")
        }

        AlfredOutput(items: makeOutputItems(alfredItems: alfredItems, navStack: env["nav_stack"] ?? "")).printJSON()

        // Background stale-cache check (T062)
        if cache.isStale(interval: syncInterval) {
            DispatchQueue.global().async {
                _ = try? BWSync.sync()
            }
            Thread.sleep(forTimeInterval: 0.05)
        }
    }

    private static func applyFilters(to items: [CachedItem], prefs: WorkflowPrefs, env: [String: String], query: String) -> [CachedItem] {
        var items = items
        if let orgId = prefs.defaultOrganizationId { items = items.filter { $0.organizationId == orgId } }
        if let colId = prefs.defaultCollectionId { items = items.filter { $0.collectionIds.contains(colId) } }
        if let folderId = env["folder_id"], !folderId.isEmpty {
            if folderId == "__NULL__" {
                items = items.filter { $0.folderId == nil }
            } else {
                items = items.filter { $0.folderId == folderId }
            }
        }
        if env["favorites"] == "true" { items = items.filter { $0.favorite } }
        if let typeRaw = env["item_type"], let typeInt = Int(typeRaw), let itemType = ItemType(rawValue: typeInt) {
            items = items.filter { $0.type == itemType }
        }
        if !query.isEmpty {
            let q = query.lowercased()
            items = items.filter {
                $0.name.lowercased().contains(q) ||
                    $0.login?.username?.lowercased().contains(q) == true ||
                    $0.login?.uris?.first?.uri?.lowercased().contains(q) == true ||
                    $0.notes?.lowercased().contains(q) == true
            }
        }
        return items
    }

    private static func matchesDomain(item: CachedItem, domain: String) -> Bool {
        guard let uris = item.login?.uris else { return false }
        return uris.contains { uri in
            guard let uri = uri.uri, let itemDomain = URLMatcher.etld1(from: uri) else { return false }
            return itemDomain == domain
        }
    }

    static func makeOutputItems(alfredItems: [AlfredItem], navStack: String) -> [AlfredItem] {
        var output = alfredItems.isEmpty
            ? [AlfredItem(title: "No items found", subtitle: "Try a different search", valid: false)]
            : alfredItems
        let (popped, remaining) = NavStack.pop(from: navStack)
        if let popped {
            output.append(AlfredItem(
                title: "Go Back",
                arg: nil,
                icon: AlfredIcon(path: "icons/back.png"),
                variables: ["next": popped, "nav_stack": remaining, "item_type": "", "folder_id": "", "favorites": ""]
            ))
        }
        return output
    }

    static func makeAlfredItem(item: CachedItem, recency: RecencyStore, browserPath: String? = nil, navStack: String = "") -> AlfredItem {
        let subtitle = buildSubtitle(item: item)
        let isRecent = recency.isRecent(for: item.id)
        let icon: AlfredIcon
        if let path = browserPath {
            icon = AlfredIcon(path: path, type: "fileicon")
        } else if isRecent {
            icon = AlfredIcon(path: "icons/clock.png")
        } else {
            icon = AlfredIcon(path: iconPath(for: item))
        }
        let quicklookurl = item.login?.uris?.first?.uri

        let pushed = NavStack.push("search", onto: navStack)
        let shiftMod: AlfredModItem? = item.hasTOTP
            ? AlfredModItem(subtitle: "Copy TOTP code",
                            arg: .multiple([item.id, "totp"]),
                            variables: ["action": "get_field"])
            : nil

        let (defaultArg, defaultVars): (AlfredArg, [String: String]) = {
            switch item.type {
            case .login: return (.multiple([item.id, "password"]), ["action": "get_field"])
            case .secureNote: return (.multiple([item.id, "notes"]), ["action": "get_field"])
            case .card: return (.multiple([item.id, "card_cvv"]), ["action": "get_field"])
            case .identity: return (.single(item.id), ["action": "show_item"])
            }
        }()

        let cmdMod: AlfredModItem? = {
            switch item.type {
            case .login:
                return AlfredModItem(subtitle: "Copy username",
                                     arg: .multiple([item.id, "username"]),
                                     valid: item.login?.username != nil,
                                     variables: ["action": "get_field"])
            case .card:
                return AlfredModItem(subtitle: "Copy card number",
                                     arg: .multiple([item.id, "card_number"]),
                                     variables: ["action": "get_field"])
            default:
                return nil
            }
        }()

        return AlfredItem(
            title: item.name,
            subtitle: subtitle,
            arg: defaultArg,
            icon: icon,
            mods: AlfredMods(
                shift: shiftMod,
                cmd: cmdMod,
                alt: AlfredModItem(subtitle: "List fields",
                                   arg: nil,
                                   variables: ["next": "list_fields", "item_id": item.id, "nav_stack": pushed]),
                fn: AlfredModItem(subtitle: "More actions…",
                                  arg: nil,
                                  variables: ["next": "more", "item_id": item.id, "nav_stack": pushed])
            ),
            variables: defaultVars,
            quicklookurl: quicklookurl
        )
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
        case .secureNote: return "icons/secret-note.png"
        case .card:
            if let brand = item.card?.brand, !brand.isEmpty {
                return "icons/\(brand).png"
            }
            return "icons/card.png"
        case .identity: return "icons/identity.png"
        }
    }
}
