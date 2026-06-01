import XCTest
@testable import MyBuddyCore

final class BuddyNetworkRoutingTests: XCTestCase {
    func testDestinationsIncludeBroadcastAndKnownPeers() {
        let destinations = BuddyNetworkRouting.destinationAddresses(
            knownPeerAddresses: [
                "192.168.0.12",
                "192.168.0.12",
                "192.168.0.13"
            ]
        )

        XCTAssertEqual(
            destinations,
            [
                "255.255.255.255",
                "192.168.0.12",
                "192.168.0.13"
            ]
        )
    }
}
