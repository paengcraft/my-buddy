import XCTest

final class BuddyChatComposerStyleSourceTests: XCTestCase {
    func testChatComposerUsesCompactRoundedRectangleInsteadOfCapsule() throws {
        let source = try String(
            contentsOfFile: "Sources/MyBuddyApp/BuddyViews.swift",
            encoding: .utf8
        )

        XCTAssertFalse(source.contains(".background(.regularMaterial, in: Capsule())"))
        XCTAssertTrue(source.contains("RoundedRectangle(cornerRadius: 16"))
    }
}
