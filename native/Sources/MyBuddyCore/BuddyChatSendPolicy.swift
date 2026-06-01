public struct BuddyChatSendPresentation: Equatable {
    public let keepsComposerOpen: Bool
    public let showsLocalSpeechBubble: Bool
}

public enum BuddyChatSendPolicy {
    public static let localSentMessagePresentation = BuddyChatSendPresentation(
        keepsComposerOpen: true,
        showsLocalSpeechBubble: false
    )
}
