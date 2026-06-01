public struct BuddyReactionChoice: Equatable, Identifiable {
    public let id: String
    public let label: String
    public let systemImageName: String
    public let animationId: String

    public init(id: String, label: String, systemImageName: String, animationId: String) {
        self.id = id
        self.label = label
        self.systemImageName = systemImageName
        self.animationId = animationId
    }

    public static let quickChoices: [BuddyReactionChoice] = [
        BuddyReactionChoice(
            id: "wave",
            label: "Wave",
            systemImageName: "hand.wave",
            animationId: "turn-and-wave"
        ),
        BuddyReactionChoice(
            id: "pop",
            label: "Pop",
            systemImageName: "sparkles",
            animationId: "quick-pop"
        ),
        BuddyReactionChoice(
            id: "spin",
            label: "Spin",
            systemImageName: "arrow.2.circlepath",
            animationId: "spin-pop"
        ),
        BuddyReactionChoice(
            id: "bounce",
            label: "Bounce",
            systemImageName: "arrow.up.and.down",
            animationId: "double-bob"
        )
    ]
}
