import Foundation

struct WorkflowPrefs: Codable {
    var defaultOrganizationId: String?
    var defaultCollectionId: String?
    var defaultFolderId: String?

    static func load() -> WorkflowPrefs {
        guard let dir = ProcessInfo.processInfo.environment["alfred_workflow_data"],
              let data = try? Data(contentsOf: URL(fileURLWithPath: dir + "/prefs.json")),
              let prefs = try? JSONDecoder().decode(WorkflowPrefs.self, from: data)
        else {
            return WorkflowPrefs()
        }
        return prefs
    }

    func save() {
        guard let dir = ProcessInfo.processInfo.environment["alfred_workflow_data"] else { return }
        let url = URL(fileURLWithPath: dir + "/prefs.json")
        try? FileManager.default.createDirectory(
            at: URL(fileURLWithPath: dir),
            withIntermediateDirectories: true
        )
        if let data = try? JSONEncoder().encode(self) {
            try? data.write(to: url)
        }
    }
}
