@testable import bw_alfred
import Foundation
import Testing

struct AlfredOutputTests {
    func encodeJSON(_ output: AlfredOutput) throws -> [String: Any] {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .withoutEscapingSlashes
        let data = try encoder.encode(output)
        return try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])
    }

    @Test("Basic item encodes with title, subtitle, arg")
    func basicItem() throws {
        let item = AlfredItem(title: "Test Item", subtitle: "Sub", arg: .single("arg1"))
        let output = AlfredOutput(items: [item])
        let json = try encodeJSON(output)
        let items = json["items"] as? [[String: Any]]
        #expect(items?.count == 1)
        let firstItem = items?.first
        #expect(firstItem?["title"] as? String == "Test Item")
        #expect(firstItem?["subtitle"] as? String == "Sub")
        #expect(firstItem?["arg"] as? String == "arg1")
    }

    @Test("valid defaults to true")
    func validDefault() throws {
        let item = AlfredItem(title: "Item")
        let json = try encodeJSON(AlfredOutput(items: [item]))
        let items = json["items"] as? [[String: Any]]
        let firstItem = items?.first
        #expect(firstItem?["valid"] as? Bool == true)
    }

    @Test("Mods encode with correct keys")
    func modsEncoding() throws {
        var item = AlfredItem(title: "With Mods")
        item.mods = AlfredMods(ctrl: AlfredModItem(subtitle: "Copy username", arg: .single("username"), valid: true))
        let json = try encodeJSON(AlfredOutput(items: [item]))
        let items = json["items"] as? [[String: Any]]
        let firstItem = items?.first
        let mods = firstItem?["mods"] as? [String: Any]
        let ctrl = mods?["ctrl"] as? [String: Any]
        #expect(ctrl?["subtitle"] as? String == "Copy username")
        #expect(ctrl?["arg"] as? String == "username")
    }

    @Test("Item-level variables encode correctly")
    func variablesEncoding() throws {
        var item = AlfredItem(title: "Item with vars")
        item.variables = ["item_id": "abc123", "field": "password"]
        let json = try encodeJSON(AlfredOutput(items: [item]))
        let items = json["items"] as? [[String: Any]]
        let firstItem = items?.first
        let vars = firstItem?["variables"] as? [String: String]
        #expect(vars?["item_id"] == "abc123")
        #expect(vars?["field"] == "password")
    }

    @Test("rerun field encodes")
    func rerunField() throws {
        let output = AlfredOutput(items: [], rerun: 0.5)
        let json = try encodeJSON(output)
        #expect(json["rerun"] as? Double == 0.5)
    }

    @Test("Top-level variables encode")
    func outputVariables() throws {
        let output = AlfredOutput(items: [], variables: ["workflow_var": "value"])
        let json = try encodeJSON(output)
        let vars = json["variables"] as? [String: String]
        #expect(vars?["workflow_var"] == "value")
    }

    @Test("Icon path encodes")
    func iconEncoding() throws {
        var item = AlfredItem(title: "With Icon")
        item.icon = AlfredIcon(path: "icons/login.png")
        let json = try encodeJSON(AlfredOutput(items: [item]))
        let items = json["items"] as? [[String: Any]]
        let firstItem = items?.first
        let icon = firstItem?["icon"] as? [String: Any]
        #expect(icon?["path"] as? String == "icons/login.png")
    }

    @Test("Text field encodes copy and largetype")
    func textEncoding() throws {
        var item = AlfredItem(title: "With Text")
        item.text = AlfredText(copy: "copy value", largetype: "large value")
        let json = try encodeJSON(AlfredOutput(items: [item]))
        let items = json["items"] as? [[String: Any]]
        let firstItem = items?.first
        let text = firstItem?["text"] as? [String: Any]
        #expect(text?["copy"] as? String == "copy value")
        #expect(text?["largetype"] as? String == "large value")
    }

    @Test("error() helper produces correct item")
    func errorHelper() {
        let output = AlfredOutput.error("Something went wrong")
        #expect(output.items.count == 1)
        #expect(output.items.first?.title == "Error")
        #expect(output.items.first?.subtitle == "Something went wrong")
        #expect(output.items.first?.valid == false)
    }

    @Test("loading() helper sets rerun")
    func loadingHelper() {
        let output = AlfredOutput.loading()
        #expect(output.items.count == 1)
        #expect(output.rerun == 0.5)
    }

    @Test("single() helper produces one item")
    func singleHelper() {
        let item = AlfredItem(title: "Single Item")
        let output = AlfredOutput.single(item)
        #expect(output.items.count == 1)
        #expect(output.items.first?.title == "Single Item")
    }
}
