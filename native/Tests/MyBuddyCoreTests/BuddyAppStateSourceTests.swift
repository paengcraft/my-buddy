import XCTest

final class BuddyAppStateSourceTests: XCTestCase {
    func testCharacterSizeObserverDoesNotAssignToPublishedPropertyItself() throws {
        let source = try String(
            contentsOfFile: "Sources/MyBuddyApp/BuddyAppState.swift",
            encoding: .utf8
        )

        XCTAssertFalse(
            source.contains("characterSize = BuddyGeometry.clampedCharacterSize(characterSize)"),
            "Assigning characterSize inside its own didSet recursively re-enters the Published setter."
        )
    }

    func testRelayConnectedStatusClearsPreviousNetworkError() throws {
        let source = try String(
            contentsOfFile: "Sources/MyBuddyApp/BuddyAppState.swift",
            encoding: .utf8
        )

        let statusHandler = try XCTUnwrap(
            source.slice(
                from: "cloudRelayService?.onStatusChange =",
                to: "cloudRelayService?.onError ="
            )
        )

        XCTAssertTrue(
            statusHandler.contains("status == \"Relay connected\""),
            "A successful relay reconnect should be handled explicitly instead of leaving stale error state."
        )
        XCTAssertTrue(
            statusHandler.contains("networkError = nil"),
            "Diagnostics should not keep an old relay socket error after the relay reports it is connected."
        )
    }
}

private extension String {
    func slice(from start: String, to end: String) -> String? {
        guard let startRange = range(of: start),
              let endRange = range(of: end, range: startRange.upperBound..<endIndex)
        else {
            return nil
        }

        return String(self[startRange.upperBound..<endRange.lowerBound])
    }
}
