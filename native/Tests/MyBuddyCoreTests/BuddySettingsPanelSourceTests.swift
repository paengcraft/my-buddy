import XCTest

final class BuddySettingsPanelSourceTests: XCTestCase {
    func testSettingsPanelUsesHostFirstConnectionLabels() throws {
        let source = try String(
            contentsOfFile: "Sources/MyBuddyApp/BuddyViews.swift",
            encoding: .utf8
        )

        XCTAssertTrue(source.contains("\"친구 연결\""))
        XCTAssertTrue(source.contains("Button(\"호스트 시작\")"))
        XCTAssertTrue(source.contains("Text(\"초대 코드\")"))
        XCTAssertTrue(source.contains("\"상대 코드로 참여\""))
        XCTAssertTrue(source.contains("Button(\"참여\")"))
        XCTAssertFalse(source.contains("Button(\"Join\")"))
        XCTAssertFalse(source.contains("TextField(\"Code\""))
    }

    func testSettingsPanelUsesRelayAwareTopStatus() throws {
        let viewsSource = try String(
            contentsOfFile: "Sources/MyBuddyApp/BuddyViews.swift",
            encoding: .utf8
        )
        let stateSource = try String(
            contentsOfFile: "Sources/MyBuddyApp/BuddyAppState.swift",
            encoding: .utf8
        )

        XCTAssertTrue(viewsSource.contains("state.settingsConnectionLabel"))
        XCTAssertFalse(viewsSource.contains("Text(state.connectionLabel)"))
        XCTAssertTrue(stateSource.contains("var settingsConnectionLabel: String"))
        XCTAssertTrue(stateSource.contains("\"상대 기다리는 중\""))
        XCTAssertTrue(stateSource.contains("\"상대 연결됨\""))
    }
}
