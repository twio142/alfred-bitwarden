@testable import bw_alfred
import Testing

struct NavStackTests {
    @Test func pushOntoEmpty() {
        #expect(NavStack.push("search", onto: "") == "search")
    }

    @Test func pushOntoExisting() {
        #expect(NavStack.push("more", onto: "search") == "more|search")
    }

    @Test func popSingle() {
        let (cmd, rem) = NavStack.pop(from: "search")
        #expect(cmd == "search")
        #expect(rem == "")
    }

    @Test func popMultiple() {
        let (cmd, rem) = NavStack.pop(from: "more|search")
        #expect(cmd == "more")
        #expect(rem == "search")
    }

    @Test func popEmpty() {
        let (cmd, rem) = NavStack.pop(from: "")
        #expect(cmd == nil)
        #expect(rem == "")
    }
}
