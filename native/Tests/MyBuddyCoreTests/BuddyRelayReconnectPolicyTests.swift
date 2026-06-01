import XCTest
@testable import MyBuddyCore

final class BuddyRelayReconnectPolicyTests: XCTestCase {
    func testReconnectDelayUsesCappedExponentialBackoff() {
        XCTAssertEqual(BuddyRelayReconnectPolicy.delay(forAttempt: 0), 1)
        XCTAssertEqual(BuddyRelayReconnectPolicy.delay(forAttempt: 1), 2)
        XCTAssertEqual(BuddyRelayReconnectPolicy.delay(forAttempt: 2), 4)
        XCTAssertEqual(BuddyRelayReconnectPolicy.delay(forAttempt: 3), 8)
        XCTAssertEqual(BuddyRelayReconnectPolicy.delay(forAttempt: 4), 10)
        XCTAssertEqual(BuddyRelayReconnectPolicy.delay(forAttempt: 99), 10)
    }
}
