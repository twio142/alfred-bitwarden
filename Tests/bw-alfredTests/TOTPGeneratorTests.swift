@testable import bw_alfred
import Foundation
import Testing

struct TOTPGeneratorTests {
    let rfcSecret = Data("12345678901234567890".utf8)

    @Test("RFC 6238 Appendix B SHA-1 test vectors")
    func rfcVectors() {
        let cases: [(unix: UInt64, expected: String)] = [
            (59, "94287082"),
            (1_111_111_109, "07081804"),
            (1_111_111_111, "14050471"),
            (1_234_567_890, "89005924"),
            (2_000_000_000, "69279037"),
            (20_000_000_000, "65353130"),
        ]
        for (unix, expected) in cases {
            let counter = unix / 30
            let code = TOTPGenerator.generate(secret: rfcSecret, counter: counter, digits: 8)
            #expect(code == expected, "Failed for unix=\(unix)")
        }
    }

    @Test("6-digit code from known secret")
    func sixDigitGeneration() throws {
        let secret = try #require(Base32.decode("JBSWY3DPEHPK3PXP"))
        let code = TOTPGenerator.generate(secret: secret)
        #expect(code != nil)
        #expect(code?.count == 6)
        #expect(code?.allSatisfy { $0.isNumber } == true)
    }

    @Test("Generate from Base32 string")
    func fromBase32String() {
        let code = TOTPGenerator.generate(base32Secret: "JBSWY3DPEHPK3PXP")
        #expect(code != nil)
        #expect(code?.count == 6)
    }

    @Test("Invalid Base32 returns nil")
    func invalidBase32() {
        let code = TOTPGenerator.generate(base32Secret: "!invalid!")
        #expect(code == nil)
    }
}
