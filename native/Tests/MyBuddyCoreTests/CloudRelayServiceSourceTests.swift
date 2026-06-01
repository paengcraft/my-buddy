import XCTest

final class CloudRelayServiceSourceTests: XCTestCase {
    func testRelayHelloIsSentOnlyAfterServerReadyMessage() throws {
        let source = try String(
            contentsOfFile: "Sources/MyBuddyApp/CloudRelayService.swift",
            encoding: .utf8
        )

        let connectBody = try XCTUnwrap(
            source.slice(from: "func connect(pairingCode: String)", to: "func disconnect()")
        )
        XCTAssertFalse(
            connectBody.contains("sendHello()"),
            "Sending hello before the WebSocket is ready can fail locally and leave the relay without client metadata."
        )

        let readyCase = try XCTUnwrap(
            source.slice(from: "case \"ready\":", to: "case \"pong\":")
        )
        XCTAssertTrue(
            readyCase.contains("sendHello()"),
            "The relay should send hello after the server confirms the WebSocket is ready."
        )
    }

    func testStaleWebSocketCallbacksCannotDisconnectCurrentRelaySession() throws {
        let source = try String(
            contentsOfFile: "Sources/MyBuddyApp/CloudRelayService.swift",
            encoding: .utf8
        )

        XCTAssertTrue(
            source.contains("private var connectionGeneration = 0"),
            "Relay sessions need a generation marker so callbacks from a cancelled WebSocket cannot mutate the new session."
        )

        let connectBody = try XCTUnwrap(
            source.slice(from: "func connect(pairingCode: String)", to: "func disconnect()")
        )
        XCTAssertTrue(
            connectBody.contains("connectionGeneration += 1"),
            "Starting a relay connection should invalidate callbacks from earlier WebSocket tasks."
        )
        XCTAssertTrue(
            connectBody.contains("receiveNext(connectionGeneration: connectionGeneration)"),
            "Receive callbacks should be tied to the generation that started them."
        )

        let receiveBody = try XCTUnwrap(
            source.slice(from: "private func receiveNext", to: "private func handle(")
        )
        XCTAssertTrue(
            receiveBody.contains("connectionGeneration == self.connectionGeneration"),
            "Stale receive callbacks should return before handling messages or disconnect errors."
        )
        XCTAssertTrue(
            receiveBody.contains("handleDisconnect(") &&
                receiveBody.contains("errorDescription: error.localizedDescription") &&
                receiveBody.contains("connectionGeneration: connectionGeneration"),
            "Disconnect handling should verify that the failure belongs to the active relay session."
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
