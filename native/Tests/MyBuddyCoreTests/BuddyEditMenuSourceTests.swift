import XCTest

final class BuddyEditMenuSourceTests: XCTestCase {
    func testApplicationProvidesStandardEditMenuForTextInputShortcuts() throws {
        let source = try String(
            contentsOfFile: "Sources/MyBuddyApp/main.swift",
            encoding: .utf8
        )

        XCTAssertTrue(source.contains("title: \"Edit\""))
        XCTAssertTrue(source.contains("#selector(NSText.cut(_:))"))
        XCTAssertTrue(source.contains("#selector(NSText.copy(_:))"))
        XCTAssertTrue(source.contains("#selector(NSText.paste(_:))"))
        XCTAssertTrue(source.contains("#selector(NSText.selectAll(_:))"))
    }
}
