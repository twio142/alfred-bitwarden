@testable import bw_alfred
import Foundation
import Testing

struct BWModelsTests {
    @Test("Decode BWItem with login data")
    func decodeLoginItem() throws {
        let json = """
        {
            "id": "item-123",
            "name": "My Website",
            "type": 1,
            "favorite": true,
            "collectionIds": [],
            "login": {
                "username": "user1",
                "password": "password1",
                "totp": "JBSWY3DP",
                "uris": [
                    { "uri": "https://example.com", "match": 0 }
                ]
            },
            "revisionDate": "2024-01-01T12:00:00Z"
        }
        """.data(using: .utf8)!

        let item = try JSONDecoder().decode(BWItem.self, from: json)
        #expect(item.id == "item-123")
        #expect(item.name == "My Website")
        #expect(item.type == .login)
        #expect(item.favorite == true)
        #expect(item.login?.username == "user1")
        #expect(item.login?.password == "password1")
        #expect(item.login?.totp == "JBSWY3DP")
        #expect(item.login?.uris?.first?.uri == "https://example.com")
        #expect(item.login?.uris?.first?.match == .domain)
    }

    @Test("Decode BWItem with card data")
    func decodeCardItem() throws {
        let json = """
        {
            "id": "card-123",
            "name": "My Visa",
            "type": 3,
            "favorite": false,
            "collectionIds": [],
            "card": {
                "cardholderName": "John Doe",
                "brand": "Visa",
                "number": "4111111111111111",
                "expMonth": "12",
                "expYear": "2025"
            }
        }
        """.data(using: .utf8)!

        let item = try JSONDecoder().decode(BWItem.self, from: json)
        #expect(item.id == "card-123")
        #expect(item.type == .card)
        #expect(item.card?.cardholderName == "John Doe")
        #expect(item.card?.brand == "Visa")
        #expect(item.card?.number == "4111111111111111")
    }

    @Test("Decode BWItem with custom fields")
    func decodeCustomFields() throws {
        let json = """
        {
            "id": "item-fields",
            "name": "Item with Fields",
            "type": 2,
            "favorite": false,
            "collectionIds": [],
            "fields": [
                { "name": "PIN", "value": "1234", "type": 1 },
                { "name": "Note", "value": "Some note", "type": 0 }
            ]
        }
        """.data(using: .utf8)!

        let item = try JSONDecoder().decode(BWItem.self, from: json)
        #expect(item.fields?.count == 2)
        #expect(item.fields?[0].name == "PIN")
        #expect(item.fields?[0].type == .hidden)
        #expect(item.fields?[1].name == "Note")
        #expect(item.fields?[1].type == .text)
    }

    @Test("Decode BWItem with attachments")
    func decodeAttachments() throws {
        let json = """
        {
            "id": "item-att",
            "name": "Item with Attachment",
            "type": 2,
            "favorite": false,
            "collectionIds": [],
            "attachments": [
                { "id": "att-1", "fileName": "secret.pdf", "size": "1024", "sizeName": "1 KB" }
            ]
        }
        """.data(using: .utf8)!

        let item = try JSONDecoder().decode(BWItem.self, from: json)
        #expect(item.attachments?.count == 1)
        #expect(item.attachments?.first?.id == "att-1")
        #expect(item.attachments?.first?.fileName == "secret.pdf")
    }
}
