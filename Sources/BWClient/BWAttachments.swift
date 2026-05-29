import Foundation

struct BWAttachments {
    static func download(attachmentId: String, itemId: String) throws -> Data {
        let path = "/object/attachment/\(attachmentId)?itemid=\(itemId)"
        return try BWClient.shared.get(path)
    }
}
