import Foundation

public enum BuddyRelayPairingCode {
    public static let length = 8
    private static let allowedCharacterString = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"
    private static let allowedCharacters = Set(allowedCharacterString)

    public static func isValid(_ value: String) -> Bool {
        value.count == length && value.allSatisfy { allowedCharacters.contains($0) }
    }

    public static func randomCode<R: RandomNumberGenerator>(using generator: inout R) -> String {
        let characters = Array(allowedCharacterString)
        return String((0..<length).map { _ in
            characters.randomElement(using: &generator) ?? "A"
        })
    }
}

public struct BuddyRelayEndpoint {
    public let baseURL: URL

    public init(baseURL: URL) {
        self.baseURL = baseURL
    }

    public func roomURL(pairingCode: String) throws -> URL {
        guard BuddyRelayPairingCode.isValid(pairingCode) else {
            throw BuddyRelayEndpointError.invalidPairingCode
        }

        var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false)
        components?.scheme = "wss"
        components?.path = "/room/\(pairingCode)"
        components?.query = nil

        guard let url = components?.url else {
            throw BuddyRelayEndpointError.invalidBaseURL
        }

        return url
    }

    public func healthURL() throws -> URL {
        var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false)
        components?.scheme = "https"
        components?.path = "/health"
        components?.query = nil

        guard let url = components?.url else {
            throw BuddyRelayEndpointError.invalidBaseURL
        }

        return url
    }
}

public enum BuddyRelayEndpointError: Error, Equatable {
    case invalidPairingCode
    case invalidBaseURL
}
