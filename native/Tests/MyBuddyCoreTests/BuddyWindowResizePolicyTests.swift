import CoreGraphics
import XCTest
@testable import MyBuddyCore

final class BuddyWindowResizePolicyTests: XCTestCase {
    func testKeepsCharacterAnchorFixedWhenChatOpensBelowCharacter() {
        let origin = BuddyWindowResizePolicy.contentOrigin(
            currentContentFrame: CGRect(x: 500, y: 300, width: 300, height: 240),
            newContentSize: CGSize(width: 300, height: 338),
            currentAnchorOffset: CGPoint(x: 150, y: 102),
            newAnchorOffset: CGPoint(x: 150, y: 200),
            visibleFrame: nil
        )

        XCTAssertEqual(origin.x, 500)
        XCTAssertEqual(origin.y, 202)
    }

    func testKeepsCharacterCenterFixedWhenStageWidthChanges() {
        let origin = BuddyWindowResizePolicy.contentOrigin(
            currentContentFrame: CGRect(x: 500, y: 300, width: 300, height: 240),
            newContentSize: CGSize(width: 340, height: 280),
            currentAnchorOffset: CGPoint(x: 150, y: 102),
            newAnchorOffset: CGPoint(x: 170, y: 122),
            visibleFrame: nil
        )

        XCTAssertEqual(origin.x, 480)
        XCTAssertEqual(origin.y, 280)
    }
}
