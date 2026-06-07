import Foundation

enum CacheBuilder {
    static func build(from item: BWItem) -> CachedItem {
        let hasTOTP = item.login?.totp != nil ||
            item.fields?.contains { field in
                field.name?.lowercased() == "totp" && field.type == .hidden
            } == true

        let cachedLogin = item.login.map { login in
            CachedLoginData(username: login.username, uris: login.uris)
        }

        let cachedCard = item.card.map { card in
            CachedCardData(
                cardholderName: card.cardholderName,
                brand: card.brand,
                expMonth: card.expMonth,
                expYear: card.expYear
            )
        }

        let cachedFields = item.fields?.map { field in
            CachedCustomField(
                name: field.name,
                value: field.type == .hidden ? nil : field.value,
                type: field.type
            )
        }

        return CachedItem(
            id: item.id,
            name: item.name,
            type: item.type,
            folderId: item.folderId,
            organizationId: item.organizationId,
            collectionIds: item.collectionIds,
            favorite: item.favorite,
            login: cachedLogin,
            card: cachedCard,
            identity: item.identity,
            notes: item.notes,
            fields: cachedFields,
            hasAttachments: item.attachments?.isEmpty == false,
            hasTOTP: hasTOTP,
            revisionDate: item.revisionDate
        )
    }
}
