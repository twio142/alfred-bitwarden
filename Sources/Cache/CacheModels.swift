import Foundation

struct VaultCache: Codable {
    var schemaVersion: Int
    var lastSyncedAt: Date
    var items: [CachedItem]
    var folders: [CachedFolder]
    var collections: [CachedCollection]
    var organizations: [CachedOrganization]
}

struct CachedItem: Codable {
    var id: String
    var name: String
    var type: ItemType
    var folderId: String?
    var organizationId: String?
    var collectionIds: [String]
    var favorite: Bool
    var login: CachedLoginData?
    var card: CachedCardData?
    var identity: BWIdentityData?
    var notes: String?
    var fields: [CachedCustomField]?
    var hasAttachments: Bool
    var hasTOTP: Bool
    var revisionDate: String?
}

struct CachedLoginData: Codable {
    var username: String?
    var uris: [BWLoginUri]?
}

struct CachedCardData: Codable {
    var cardholderName: String?
    var brand: String?
    var expMonth: String?
    var expYear: String?
}

struct CachedCustomField: Codable {
    var name: String?
    var value: String?
    var type: CustomFieldType
}

struct CachedFolder: Codable {
    var id: String
    var name: String
}

struct CachedCollection: Codable {
    var id: String
    var name: String
    var organizationId: String?
}

struct CachedOrganization: Codable {
    var id: String
    var name: String
}
