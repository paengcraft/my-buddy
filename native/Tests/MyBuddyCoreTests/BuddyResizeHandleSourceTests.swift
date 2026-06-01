import XCTest

final class BuddyResizeHandleSourceTests: XCTestCase {
    func testSettingsPanelDoesNotShowLegacyBlueResizeHandle() throws {
        let source = try String(
            contentsOfFile: "Sources/MyBuddyApp/BuddyViews.swift",
            encoding: .utf8
        )

        XCTAssertFalse(source.contains("ResizeHandle"))
        XCTAssertFalse(source.contains(".fill(Color.blue)"))
    }

    func testAppStateDoesNotKeepLegacyDragResizeEntryPoint() throws {
        let source = try String(
            contentsOfFile: "Sources/MyBuddyApp/BuddyAppState.swift",
            encoding: .utf8
        )

        XCTAssertFalse(source.contains("resizeCharacter(by"))
    }
}
