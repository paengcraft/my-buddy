import XCTest
@testable import MyBuddyCore

final class BuddyChatSendPolicyTests: XCTestCase {
    func testLocalSentMessageKeepsComposerOpenWithoutLocalSpeechBubble() {
        let presentation = BuddyChatSendPolicy.localSentMessagePresentation

        XCTAssertTrue(presentation.keepsComposerOpen)
        XCTAssertFalse(presentation.showsLocalSpeechBubble)
    }
}
