import Foundation

public enum BuddyRelayReconnectPolicy {
    public static let maximumDelay: TimeInterval = 10

    public static func delay(forAttempt attempt: Int) -> TimeInterval {
        let boundedAttempt = max(0, min(attempt, 4))
        let delay = pow(2, Double(boundedAttempt))
        return min(maximumDelay, delay)
    }
}
