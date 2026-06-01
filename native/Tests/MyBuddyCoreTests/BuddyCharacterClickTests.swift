import XCTest
@testable import MyBuddyCore

final class BuddyCharacterClickTests: XCTestCase {
    func testSingleClickOnlyReacts() {
        XCTAssertEqual(
            BuddyCharacterClickPolicy.action(forClickCount: 1),
            .react
        )
    }

    func testDoubleClickOpensChat() {
        XCTAssertEqual(
            BuddyCharacterClickPolicy.action(forClickCount: 2),
            .openChat
        )
    }
}
