@testable import bw_alfred
import Foundation
import Testing

struct Base32Tests {
    @Test("Decode standard vector")
    func standardVector() {
        // "Hello" in Base32 = JBSWY3DP
        let decoded = Base32.decode("JBSWY3DP")
        #expect(decoded == Data("Hello".utf8))
    }

    @Test("Case insensitive decoding")
    func caseInsensitive() {
        let upper = Base32.decode("JBSWY3DP")
        let lower = Base32.decode("jbswy3dp")
        #expect(upper != nil)
        #expect(upper == lower)
    }

    @Test("Padding variants produce same result")
    func paddingVariants() {
        let withPadding = Base32.decode("JBSWY3DP========")
        let withoutPadding = Base32.decode("JBSWY3DP")
        #expect(withPadding == withoutPadding)
    }

    @Test("Strips spaces before decoding")
    func stripsSpaces() {
        let withSpaces = Base32.decode("JBSW Y3DP")
        let withoutSpaces = Base32.decode("JBSWY3DP")
        #expect(withSpaces == withoutSpaces)
    }

    @Test("Empty string returns empty data")
    func emptyString() {
        let result = Base32.decode("")
        #expect(result != nil)
        #expect(result == Data())
    }

    @Test("Invalid characters return nil")
    func invalidChars() {
        #expect(Base32.decode("!@#$%^&*") == nil)
        #expect(Base32.decode("0INVALID") == nil)
        #expect(Base32.decode("ABCD1EFG") == nil) // '1' is not valid Base32
    }

    @Test("Known TOTP secret decodes correctly")
    func knownTOTPSecret() {
        let decoded = Base32.decode("JBSWY3DPEHPK3PXP")
        #expect(decoded != nil)
        #expect(decoded?.count == 10)
    }
}
