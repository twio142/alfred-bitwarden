import Foundation

struct ServerState {
    var serverURL: String
    var userEmail: String?
    var status: VaultStatus
}

enum BWStatus {
    static func get() throws -> ServerState {
        let data = try BWClient.shared.get("/status")
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let dataObj = json["data"] as? [String: Any],
              let template = dataObj["template"] as? [String: Any]
        else {
            return ServerState(serverURL: "", status: .unauthenticated)
        }
        let statusStr = template["status"] as? String ?? "unauthenticated"
        let status = VaultStatus(rawValue: statusStr) ?? .unauthenticated
        let userEmail = template["userEmail"] as? String
        let serverURL = template["serverURL"] as? String ?? ""
        return ServerState(serverURL: serverURL, userEmail: userEmail, status: status)
    }
}
