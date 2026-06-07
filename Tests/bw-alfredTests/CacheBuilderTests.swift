@testable import bw_alfred
import Foundation
import Testing

struct CacheBuilderTests {
    func makeLoginItem(
        id: String = "test-id",
        password: String? = "secret",
        totp: String? = "JBSWY3DP",
        fields: [BWCustomField]? = nil
    ) -> BWItem {
        BWItem(
            id: id,
            name: "Test Login",
            type: .login,
            folderId: nil,
            organizationId: nil,
            collectionIds: [],
            favorite: false,
            login: BWLoginData(username: "user@example.com", password: password, totp: totp, uris: nil),
            card: nil,
            identity: nil,
            secureNote: nil,
            notes: nil,
            fields: fields,
            attachments: nil,
            revisionDate: "2024-01-01T00:00:00Z"
        )
    }

    @Test("Username retained in cache")
    func usernameRetained() {
        let item = makeLoginItem(password: "super-secret", totp: nil)
        let cached = CacheBuilder.build(from: item)
        #expect(cached.login?.username == "user@example.com")
    }

    @Test("hasTOTP set when native TOTP present")
    func hasTOTPNative() {
        let item = makeLoginItem(totp: "JBSWY3DPEHPK3PXP")
        let cached = CacheBuilder.build(from: item)
        #expect(cached.hasTOTP == true)
    }

    @Test("hasTOTP false when no TOTP")
    func hasTOTPFalse() {
        let item = makeLoginItem(totp: nil)
        let cached = CacheBuilder.build(from: item)
        #expect(cached.hasTOTP == false)
    }

    @Test("hasTOTP set for hidden field named 'totp'")
    func hasTOTPHiddenField() {
        let fields = [BWCustomField(name: "totp", value: "JBSWY3DP", type: .hidden)]
        let item = makeLoginItem(totp: nil, fields: fields)
        let cached = CacheBuilder.build(from: item)
        #expect(cached.hasTOTP == true)
    }

    @Test("hasTOTP field name check is case-insensitive")
    func hasTOTPCaseInsensitive() {
        let fields = [BWCustomField(name: "TOTP", value: "JBSWY3DP", type: .hidden)]
        let item = makeLoginItem(totp: nil, fields: fields)
        let cached = CacheBuilder.build(from: item)
        #expect(cached.hasTOTP == true)
    }

    @Test("Hidden field value stripped")
    func hiddenFieldStripped() {
        let fields = [BWCustomField(name: "secret", value: "hidden-value", type: .hidden)]
        let item = makeLoginItem(totp: nil, fields: fields)
        let cached = CacheBuilder.build(from: item)
        #expect(cached.fields?.first?.value == nil)
        #expect(cached.fields?.first?.type == .hidden)
        #expect(cached.fields?.first?.name == "secret")
    }

    @Test("Text field value retained")
    func textFieldRetained() {
        let fields = [BWCustomField(name: "website", value: "example.com", type: .text)]
        let item = makeLoginItem(totp: nil, fields: fields)
        let cached = CacheBuilder.build(from: item)
        #expect(cached.fields?.first?.value == "example.com")
    }

    @Test("Card safe fields retained, sensitive stripped by type definition")
    func cardFieldsRetained() {
        let item = BWItem(
            id: "card-id", name: "My Card", type: .card,
            folderId: nil, organizationId: nil, collectionIds: [],
            favorite: false, login: nil,
            card: BWCardData(cardholderName: "John", brand: "Visa", number: "4111111111111111", code: "123", expMonth: "12", expYear: "2025"),
            identity: nil, secureNote: nil, notes: nil, fields: nil, attachments: nil,
            revisionDate: "2024-01-01T00:00:00Z"
        )
        let cached = CacheBuilder.build(from: item)
        #expect(cached.card?.cardholderName == "John")
        #expect(cached.card?.brand == "Visa")
        #expect(cached.card?.expMonth == "12")
        #expect(cached.card?.expYear == "2025")
    }

    @Test("hasAttachments true when attachments exist")
    func hasAttachmentsTrue() {
        var item = makeLoginItem()
        item.attachments = [BWAttachment(id: "att1", fileName: "file.pdf", size: "1024", sizeName: "1 KB", url: nil)]
        let cached = CacheBuilder.build(from: item)
        #expect(cached.hasAttachments == true)
    }

    @Test("hasAttachments false when attachments empty")
    func hasAttachmentsFalse() {
        var item = makeLoginItem()
        item.attachments = []
        let cached = CacheBuilder.build(from: item)
        #expect(cached.hasAttachments == false)
    }
}
