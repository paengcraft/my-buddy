import XCTest
@testable import MyBuddyCore

final class BuddyWindowPresentationTests: XCTestCase {
    func testTransparentOverlayDisablesSystemWindowShadow() {
        XCTAssertFalse(BuddyWindowPresentation.usesSystemWindowShadow)
    }
}
