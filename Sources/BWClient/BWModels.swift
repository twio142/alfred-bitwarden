import Foundation

enum ItemType: Int, Codable {
    case login = 1
    case secureNote = 2
    case card = 3
    case identity = 4
}

enum URIMatchType: Int, Codable {
    case domain = 0
    case host = 1
    case startsWith = 2
    case exact = 3
    case regex = 4
    case never = 5
}

enum CustomFieldType: Int, Codable {
    case text = 0
    case hidden = 1
    case boolean = 2
    case linked = 3
}

enum VaultStatus: String, Codable {
    case unauthenticated
    case locked
    case unlocked
}

struct BWItem: Codable {
    var id: String
    var name: String
    var type: ItemType
    var folderId: String?
    var organizationId: String?
    var collectionIds: [String]
    var favorite: Bool
    var login: BWLoginData?
    var card: BWCardData?
    var identity: BWIdentityData?
    var secureNote: BWSecureNoteData?
    var notes: String?
    var fields: [BWCustomField]?
    var attachments: [BWAttachment]?
    var revisionDate: String?
}

struct BWLoginData: Codable {
    var username: String?
    var password: String?
    var totp: String?
    var uris: [BWLoginUri]?
}

struct BWLoginUri: Codable {
    var uri: String?
    var match: URIMatchType?
}

struct BWCardData: Codable {
    var cardholderName: String?
    var brand: String?
    var number: String?
    var code: String?
    var expMonth: String?
    var expYear: String?
}

struct BWIdentityData: Codable {
    var title: String?
    var firstName: String?
    var middleName: String?
    var lastName: String?
    var address1: String?
    var address2: String?
    var address3: String?
    var city: String?
    var state: String?
    var postalCode: String?
    var country: String?
    var company: String?
    var email: String?
    var phone: String?
    var ssn: String?
    var username: String?
    var passportNumber: String?
    var licenseNumber: String?
}

struct BWCustomField: Codable {
    var name: String?
    var value: String?
    var type: CustomFieldType
}

struct BWAttachment: Codable {
    var id: String
    var fileName: String?
    var size: String?
    var sizeName: String?
    var url: String?
}

struct BWSecureNoteData: Codable {
    var type: Int?
}
