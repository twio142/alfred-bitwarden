import Foundation

enum Base32 {
    private static let alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZ234567"
    private static let decodeMap: [Character: UInt8] = {
        var map = [Character: UInt8]()
        for (i, c) in alphabet.enumerated() {
            map[c] = UInt8(i)
        }
        return map
    }()

    static func decode(_ string: String) -> Data? {
        // Normalize: uppercase, strip spaces, strip padding
        let clean = string
            .uppercased()
            .replacingOccurrences(of: " ", with: "")
            .trimmingCharacters(in: CharacterSet(charactersIn: "="))

        guard !clean.isEmpty else { return Data() }

        // Validate characters
        guard clean.allSatisfy({ decodeMap[$0] != nil }) else { return nil }

        var buffer: UInt64 = 0
        var bitsLeft = 0
        var output = Data()

        for char in clean {
            guard let value = decodeMap[char] else { return nil }
            buffer = (buffer << 5) | UInt64(value)
            bitsLeft += 5
            if bitsLeft >= 8 {
                bitsLeft -= 8
                output.append(UInt8((buffer >> bitsLeft) & 0xFF))
            }
        }

        return output
    }
}
