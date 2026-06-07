import Foundation

enum BWItems {
    static func listItems(search: String? = nil) throws -> [BWItem] {
        var path = "/list/object/items"
        if let q = search, !q.isEmpty {
            let encoded = q.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? q
            path += "?search=\(encoded)"
        }
        return try decodeList(path: path, key: "data.data")
    }

    static func listFolders() throws -> [CachedFolder] {
        let data = try BWClient.shared.get("/list/object/folders")
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let dataObj = json["data"] as? [String: Any],
              let arr = dataObj["data"] as? [[String: Any]]
        else { return [] }
        return arr.compactMap { dict in
            guard let id = dict["id"] as? String, let name = dict["name"] as? String else { return nil }
            return CachedFolder(id: id, name: name)
        }
    }

    static func listCollections() throws -> [CachedCollection] {
        let data = try BWClient.shared.get("/list/object/collections")
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let dataObj = json["data"] as? [String: Any],
              let arr = dataObj["data"] as? [[String: Any]]
        else { return [] }
        return arr.compactMap { dict in
            guard let id = dict["id"] as? String, let name = dict["name"] as? String else { return nil }
            return CachedCollection(id: id, name: name, organizationId: dict["organizationId"] as? String)
        }
    }

    static func listOrganizations() throws -> [CachedOrganization] {
        let data = try BWClient.shared.get("/list/object/organizations")
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let dataObj = json["data"] as? [String: Any],
              let arr = dataObj["data"] as? [[String: Any]]
        else { return [] }
        return arr.compactMap { dict in
            guard let id = dict["id"] as? String, let name = dict["name"] as? String else { return nil }
            return CachedOrganization(id: id, name: name)
        }
    }

    static func getItem(_ id: String) throws -> BWItem {
        let data = try BWClient.shared.get("/object/item/\(id)")
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let dataObj = json["data"] as? [String: Any]
        else { throw BWClientError.noData }
        let itemData = try JSONSerialization.data(withJSONObject: dataObj)
        return try JSONDecoder().decode(BWItem.self, from: itemData)
    }

    static func updateItem(_ id: String, item: BWItem) throws -> BWItem {
        let body = try JSONEncoder().encode(item)
        let data = try BWClient.shared.put("/object/item/\(id)", body: body)
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let dataObj = json["data"] as? [String: Any]
        else { throw BWClientError.noData }
        let itemData = try JSONSerialization.data(withJSONObject: dataObj)
        return try JSONDecoder().decode(BWItem.self, from: itemData)
    }

    static func deleteItem(_ id: String) throws {
        _ = try BWClient.shared.delete("/object/item/\(id)")
    }

    private static func decodeList(path: String, key _: String) throws -> [BWItem] {
        let data = try BWClient.shared.get(path)
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let dataObj = json["data"] as? [String: Any],
              let arr = dataObj["data"] as? [[String: Any]]
        else { return [] }
        let decoder = JSONDecoder()
        return arr.compactMap { dict in
            guard let itemData = try? JSONSerialization.data(withJSONObject: dict) else { return nil }
            return try? decoder.decode(BWItem.self, from: itemData)
        }
    }
}
