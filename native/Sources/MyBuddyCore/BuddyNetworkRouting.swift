import Foundation

public enum BuddyNetworkRouting {
    public static let broadcastAddress = "255.255.255.255"

    public static func destinationAddresses(knownPeerAddresses: [String]) -> [String] {
        var seenAddresses = Set<String>()
        var destinations: [String] = []

        for address in [broadcastAddress] + knownPeerAddresses {
            let normalizedAddress = address.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !normalizedAddress.isEmpty else { continue }
            guard seenAddresses.insert(normalizedAddress).inserted else { continue }

            destinations.append(normalizedAddress)
        }

        return destinations
    }
}
