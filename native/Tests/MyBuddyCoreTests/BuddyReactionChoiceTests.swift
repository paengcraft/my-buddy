import XCTest
@testable import MyBuddyCore

final class BuddyReactionChoiceTests: XCTestCase {
    func testReactionChoicesMapToKnownAnimations() {
        XCTAssertGreaterThanOrEqual(BuddyReactionChoice.quickChoices.count, 4)

        for choice in BuddyReactionChoice.quickChoices {
            XCTAssertFalse(choice.label.isEmpty)
            XCTAssertNotNil(BuddyAnimationPlan.reactionAnimation(id: choice.animationId))
        }
    }
}
