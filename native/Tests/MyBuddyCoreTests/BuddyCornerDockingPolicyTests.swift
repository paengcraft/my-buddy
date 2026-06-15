import CoreGraphics
import XCTest
@testable import MyBuddyCore

final class BuddyCornerDockingPolicyTests: XCTestCase {
    private let visibleFrame = CGRect(x: 0, y: 0, width: 1440, height: 900)

    func testDetectsTopLeftDockingWhenWindowIsNearTopLeftCorner() {
        let corner = BuddyCornerDockingPolicy.dockedCorner(
            windowFrame: CGRect(x: 16, y: 760, width: 180, height: 120),
            visibleFrame: visibleFrame
        )

        XCTAssertEqual(corner, .topLeft)
    }

    func testDetectsBottomRightDockingWhenWindowIsNearBottomRightCorner() {
        let corner = BuddyCornerDockingPolicy.dockedCorner(
            windowFrame: CGRect(x: 1260, y: 20, width: 170, height: 120),
            visibleFrame: visibleFrame
        )

        XCTAssertEqual(corner, .bottomRight)
    }

    func testDoesNotDockWhenWindowIsAwayFromCorners() {
        let corner = BuddyCornerDockingPolicy.dockedCorner(
            windowFrame: CGRect(x: 500, y: 320, width: 180, height: 120),
            visibleFrame: visibleFrame
        )

        XCTAssertNil(corner)
    }
}
