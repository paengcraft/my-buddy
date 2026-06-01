import Foundation

public struct BuddyReactionAnimation: Equatable, Identifiable {
    public let id: String
    public let frameIndices: [Int]
    public let frameDuration: TimeInterval

    public init(id: String, frameIndices: [Int], frameDuration: TimeInterval) {
        self.id = id
        self.frameIndices = frameIndices
        self.frameDuration = frameDuration
    }
}

public enum BuddyAnimationPlan {
    public static let sourceFrameCount = 23
    public static let reactionStartFrame = 6
    public static let frameDuration: TimeInterval = 0.075
    public static let reactionAnimations: [BuddyReactionAnimation] = [
        BuddyReactionAnimation(
            id: "spin-in",
            frameIndices: Array(0...6),
            frameDuration: 0.075
        ),
        BuddyReactionAnimation(
            id: "spin-pop",
            frameIndices: Array(0...6) + [8, 10, 12],
            frameDuration: 0.07
        ),
        BuddyReactionAnimation(
            id: "turn-and-wave",
            frameIndices: Array(1...6) + [9, 10, 11],
            frameDuration: 0.07
        ),
        BuddyReactionAnimation(
            id: "full-spin-hop",
            frameIndices: Array(0...14),
            frameDuration: 0.072
        ),
        BuddyReactionAnimation(
            id: "full-hop",
            frameIndices: reactionFrameIndices,
            frameDuration: frameDuration
        ),
        BuddyReactionAnimation(
            id: "quick-pop",
            frameIndices: Array(6...14),
            frameDuration: 0.065
        ),
        BuddyReactionAnimation(
            id: "settle-bounce",
            frameIndices: Array(12...22),
            frameDuration: 0.07
        ),
        BuddyReactionAnimation(
            id: "double-bob",
            frameIndices: [6, 8, 10, 12, 10, 12, 14, 16, 18, 20, 22],
            frameDuration: 0.06
        )
    ]

    public static var reactionFrameIndices: [Int] {
        Array(reactionStartFrame..<sourceFrameCount)
    }

    public static var defaultReactionAnimation: BuddyReactionAnimation {
        reactionAnimations.first ?? BuddyReactionAnimation(
            id: "default",
            frameIndices: reactionFrameIndices,
            frameDuration: frameDuration
        )
    }

    public static func reactionAnimation(id: String?) -> BuddyReactionAnimation? {
        guard let id else { return nil }
        return reactionAnimations.first { $0.id == id }
    }

    public static func randomReactionAnimation<R: RandomNumberGenerator>(
        using generator: inout R
    ) -> BuddyReactionAnimation {
        reactionAnimations.randomElement(using: &generator) ?? defaultReactionAnimation
    }
}
