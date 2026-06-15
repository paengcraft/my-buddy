import XCTest
@testable import MyBuddyCore

final class BuddyGeometryTests: XCTestCase {
    func testClampsCharacterSize() {
        XCTAssertEqual(
            BuddyGeometry.clampedCharacterSize(20),
            BuddyGeometry.minimumCharacterSize
        )
        XCTAssertEqual(
            BuddyGeometry.clampedCharacterSize(999),
            BuddyGeometry.maximumCharacterSize
        )
    }

    func testStageExpandsForChatAndSettings() {
        let idle = BuddyGeometry.stageSize(
            characterSize: 176,
            chatOpen: false,
            settingsOpen: false
        )
        let chat = BuddyGeometry.stageSize(
            characterSize: 176,
            chatOpen: true,
            settingsOpen: false
        )
        let settings = BuddyGeometry.stageSize(
            characterSize: 176,
            chatOpen: true,
            settingsOpen: true
        )

        XCTAssertGreaterThan(chat.height, idle.height)
        XCTAssertGreaterThan(settings.height, chat.height)
        XCTAssertEqual(settings.width, BuddyGeometry.minimumStageWidth)
    }

    func testStageExpandsForCornerTodoBoardWithoutMovingCharacterAnchor() {
        let idleAnchor = BuddyGeometry.characterAnchorOffset(
            characterSize: 176,
            chatOpen: false,
            settingsOpen: false,
            todoBoardOpen: false
        )
        let todoSize = BuddyGeometry.stageSize(
            characterSize: 176,
            chatOpen: false,
            settingsOpen: false,
            todoBoardOpen: true
        )
        let todoAnchor = BuddyGeometry.characterAnchorOffset(
            characterSize: 176,
            chatOpen: false,
            settingsOpen: false,
            todoBoardOpen: true
        )

        XCTAssertGreaterThanOrEqual(todoSize.width, BuddyGeometry.todoBoardWidth + 36)
        XCTAssertGreaterThan(todoSize.height, 176 + BuddyGeometry.idleVerticalPadding)
        XCTAssertEqual(todoAnchor.y, idleAnchor.y)
    }

    func testCharacterAnchorMovesOnlyForBottomOverlays() {
        let idleAnchor = BuddyGeometry.characterAnchorOffset(
            characterSize: 176,
            chatOpen: false,
            settingsOpen: false
        )
        let chatAnchor = BuddyGeometry.characterAnchorOffset(
            characterSize: 176,
            chatOpen: true,
            settingsOpen: false
        )
        let settingsAnchor = BuddyGeometry.characterAnchorOffset(
            characterSize: 176,
            chatOpen: false,
            settingsOpen: true
        )

        XCTAssertEqual(chatAnchor.y - idleAnchor.y, BuddyGeometry.chatHeight)
        XCTAssertEqual(settingsAnchor.y, idleAnchor.y)
    }

    func testReactionFramesSkipBackFacingIntro() {
        XCTAssertEqual(BuddyAnimationPlan.reactionFrameIndices.first, 6)
        XCTAssertEqual(BuddyAnimationPlan.reactionFrameIndices.last, 22)
        XCTAssertEqual(BuddyAnimationPlan.reactionFrameIndices.count, 17)
    }

    func testDefinesMultipleValidReactionAnimations() {
        XCTAssertGreaterThanOrEqual(BuddyAnimationPlan.reactionAnimations.count, 8)

        let animationIds = Set(BuddyAnimationPlan.reactionAnimations.map(\.id))
        XCTAssertEqual(animationIds.count, BuddyAnimationPlan.reactionAnimations.count)

        for animation in BuddyAnimationPlan.reactionAnimations {
            XCTAssertFalse(animation.id.isEmpty)
            XCTAssertFalse(animation.frameIndices.isEmpty)
            XCTAssertGreaterThan(animation.frameDuration, 0)

            for frameIndex in animation.frameIndices {
                XCTAssertGreaterThanOrEqual(frameIndex, 0)
                XCTAssertLessThan(frameIndex, BuddyAnimationPlan.sourceFrameCount)
            }
        }
    }

    func testFindsReactionAnimationById() {
        let animation = BuddyAnimationPlan.reactionAnimation(id: "quick-pop")

        XCTAssertEqual(animation?.id, "quick-pop")
        XCTAssertNil(BuddyAnimationPlan.reactionAnimation(id: "missing"))
    }

    func testIncludesSpinReactionAnimationsFromOriginalIntroFrames() {
        XCTAssertEqual(
            BuddyAnimationPlan.reactionAnimation(id: "spin-in")?.frameIndices,
            Array(0...6)
        )
        XCTAssertEqual(
            BuddyAnimationPlan.reactionAnimation(id: "spin-pop")?.frameIndices.prefix(7),
            Array(0...6)[...]
        )
        XCTAssertTrue(
            BuddyAnimationPlan.reactionAnimations.contains { animation in
                animation.frameIndices.contains(0)
            }
        )
    }
}
