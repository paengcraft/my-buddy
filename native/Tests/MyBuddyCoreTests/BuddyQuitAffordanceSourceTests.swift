import XCTest

final class BuddyQuitAffordanceSourceTests: XCTestCase {
    func testSettingsPanelProvidesExplicitQuitButton() throws {
        let source = try String(
            contentsOfFile: "Sources/MyBuddyApp/BuddyViews.swift",
            encoding: .utf8
        )

        XCTAssertTrue(source.contains("Button(\"Quit\")"))
        XCTAssertTrue(source.contains("NSApp.terminate(nil)"))
    }

    func testApplicationProvidesCommandQQuitMenuItem() throws {
        let source = try String(
            contentsOfFile: "Sources/MyBuddyApp/main.swift",
            encoding: .utf8
        )

        XCTAssertTrue(source.contains("keyEquivalent: \"q\""))
        XCTAssertTrue(source.contains("#selector(NSApplication.terminate(_:))"))
    }
}
