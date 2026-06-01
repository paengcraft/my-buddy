import XCTest
@testable import MyBuddyCore

final class BuddyChatMessagePolicyTests: XCTestCase {
    func testPreparesTrimmedMessageWithinLimit() {
        XCTAssertEqual(
            BuddyChatMessagePolicy.preparedText("  hello  "),
            "hello"
        )
    }

    func testRejectsEmptyAndOversizedMessages() {
        XCTAssertNil(BuddyChatMessagePolicy.preparedText("   "))
        XCTAssertNil(BuddyChatMessagePolicy.preparedText(String(repeating: "x", count: 281)))
    }
}
