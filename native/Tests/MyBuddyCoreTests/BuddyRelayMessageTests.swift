import XCTest
@testable import MyBuddyCore

final class BuddyRelayMessageTests: XCTestCase {
    func testAcceptsValidPairingCode() {
        XCTAssertTrue(BuddyRelayPairingCode.isValid("ABCD2345"))
    }

    func testRejectsInvalidPairingCode() {
        XCTAssertFalse(BuddyRelayPairingCode.isValid("ABCD1234"))
        XCTAssertFalse(BuddyRelayPairingCode.isValid("abcd2345"))
        XCTAssertFalse(BuddyRelayPairingCode.isValid("ABCD234"))
        XCTAssertFalse(BuddyRelayPairingCode.isValid("ABCD23456"))
    }

    func testGeneratesEightCharacterPairingCode() {
        var generator = FixedRandomNumberGenerator(values: [0, 1, 2, 3, 4, 5, 6, 7])

        let code = BuddyRelayPairingCode.randomCode(using: &generator)

        XCTAssertEqual(code.count, 8)
        XCTAssertTrue(BuddyRelayPairingCode.isValid(code))
    }

    func testBuildsRoomURL() throws {
        let url = try BuddyRelayEndpoint(
            baseURL: URL(string: "https://buddy-relay.example.workers.dev")!
        ).roomURL(pairingCode: "ABCD2345")

        XCTAssertEqual(url.absoluteString, "wss://buddy-relay.example.workers.dev/room/ABCD2345")
    }

    func testBuildsHealthURL() throws {
        let url = try BuddyRelayEndpoint(
            baseURL: URL(string: "https://buddy-relay.example.workers.dev/old/path?x=1")!
        ).healthURL()

        XCTAssertEqual(url.absoluteString, "https://buddy-relay.example.workers.dev/health")
    }
}

private struct FixedRandomNumberGenerator: RandomNumberGenerator {
    var values: [UInt64]

    mutating func next() -> UInt64 {
        values.isEmpty ? 0 : values.removeFirst()
    }
}
