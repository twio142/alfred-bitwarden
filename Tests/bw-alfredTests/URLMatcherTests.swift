@testable import bw_alfred
import Foundation
import Testing

struct URLMatcherTests {
    @Test("Simple domains extract correctly")
    func simpleDomains() {
        #expect(URLMatcher.etld1(from: "https://example.com") == "example.com")
        #expect(URLMatcher.etld1(from: "https://www.example.com") == "example.com")
        #expect(URLMatcher.etld1(from: "https://sub.example.com") == "example.com")
        #expect(URLMatcher.etld1(from: "http://example.org") == "example.org")
    }

    @Test("Compound suffixes handled")
    func compoundSuffixes() {
        #expect(URLMatcher.etld1(from: "https://example.co.uk") == "example.co.uk")
        #expect(URLMatcher.etld1(from: "https://www.example.co.uk") == "example.co.uk")
        #expect(URLMatcher.etld1(from: "https://bbc.co.uk") == "bbc.co.uk")
        #expect(URLMatcher.etld1(from: "https://example.com.au") == "example.com.au")
        #expect(URLMatcher.etld1(from: "https://example.co.jp") == "example.co.jp")
    }

    @Test("IP addresses return nil")
    func ipAddresses() {
        #expect(URLMatcher.etld1(from: "https://192.168.1.1") == nil)
        #expect(URLMatcher.etld1(from: "http://10.0.0.1/path") == nil)
        #expect(URLMatcher.etld1(from: "https://8.8.8.8") == nil)
    }

    @Test("localhost returns nil")
    func localhost() {
        #expect(URLMatcher.etld1(from: "http://localhost") == nil)
        #expect(URLMatcher.etld1(from: "http://localhost:8080") == nil)
    }

    @Test("file:// scheme returns nil")
    func fileScheme() {
        #expect(URLMatcher.etld1(from: "file:///Users/test/file.html") == nil)
    }

    @Test("Non-HTTP schemes return nil")
    func nonHTTPSchemes() {
        #expect(URLMatcher.etld1(from: "ftp://example.com") == nil)
        #expect(URLMatcher.etld1(from: "ssh://example.com") == nil)
    }

    @Test("Invalid URLs return nil")
    func invalidURLs() {
        #expect(URLMatcher.etld1(from: "not-a-url") == nil)
        #expect(URLMatcher.etld1(from: "") == nil)
    }

    @Test("Single-label host returns nil")
    func singleLabelHost() {
        #expect(URLMatcher.etld1(from: "http://intranet") == nil)
    }

    @Test("Common domains extract correctly")
    func commonDomains() {
        #expect(URLMatcher.etld1(from: "https://github.com/user/repo") == "github.com")
        #expect(URLMatcher.etld1(from: "https://accounts.google.com") == "google.com")
        #expect(URLMatcher.etld1(from: "https://mail.yahoo.com") == "yahoo.com")
    }

    @Test("www. prefix stripped before comparison")
    func wwwStripping() {
        let withWWW = URLMatcher.etld1(from: "https://www.github.com")
        let withoutWWW = URLMatcher.etld1(from: "https://github.com")
        #expect(withWWW == withoutWWW)
    }
}
