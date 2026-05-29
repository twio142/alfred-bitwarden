import Foundation
import CryptoKit

struct TOTPGenerator {
    static func generate(secret: Data, digits: Int = 6, period: Int = 30) -> String? {
        let counter = UInt64(Date().timeIntervalSince1970) / UInt64(period)
        return generate(secret: secret, counter: counter, digits: digits)
    }

    static func generate(secret: Data, counter: UInt64, digits: Int = 6) -> String? {
        // Convert counter to big-endian bytes
        var bigEndian = counter.bigEndian
        let counterData = Data(bytes: &bigEndian, count: MemoryLayout<UInt64>.size)

        // HMAC-SHA1
        let key = SymmetricKey(data: secret)
        let hmac = HMAC<Insecure.SHA1>.authenticationCode(for: counterData, using: key)
        let digest = Data(hmac)

        // Dynamic truncation
        let offset = Int(digest[digest.count - 1] & 0x0F)
        guard offset + 4 <= digest.count else { return nil }

        let truncated =
            (UInt32(digest[offset]) & 0x7F) << 24 |
            UInt32(digest[offset + 1]) << 16 |
            UInt32(digest[offset + 2]) << 8 |
            UInt32(digest[offset + 3])

        let modulo = UInt32(pow(10.0, Double(digits)))
        let code = truncated % modulo

        return String(format: "%0\(digits)d", code)
    }

    static func generate(base32Secret: String, digits: Int = 6, period: Int = 30) -> String? {
        guard let secretData = Base32.decode(base32Secret) else { return nil }
        return generate(secret: secretData, digits: digits, period: period)
    }
}
