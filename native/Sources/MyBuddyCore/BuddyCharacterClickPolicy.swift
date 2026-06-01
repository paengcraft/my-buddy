public enum BuddyCharacterClickAction: Equatable {
    case react
    case openChat
}

public struct BuddyCharacterClickPolicy {
    public static func action(forClickCount clickCount: Int) -> BuddyCharacterClickAction {
        if clickCount >= 2 {
            return .openChat
        }

        return .react
    }
}
