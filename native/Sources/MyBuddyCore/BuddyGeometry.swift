import CoreGraphics

public enum BuddyGeometry {
    public static let minimumCharacterSize: CGFloat = 88
    public static let maximumCharacterSize: CGFloat = 280
    public static let defaultCharacterSize: CGFloat = 176
    public static let minimumStageWidth: CGFloat = 300
    public static let idleVerticalPadding: CGFloat = 64
    public static let chatHeight: CGFloat = 98
    public static let settingsHeight: CGFloat = 390
    public static let contentVerticalPadding: CGFloat = 14

    public static func clampedCharacterSize(_ size: CGFloat) -> CGFloat {
        min(max(size, minimumCharacterSize), maximumCharacterSize)
    }

    public static func stageSize(
        characterSize rawCharacterSize: CGFloat,
        chatOpen: Bool,
        settingsOpen: Bool
    ) -> CGSize {
        let characterSize = clampedCharacterSize(rawCharacterSize)
        let width = max(minimumStageWidth, characterSize + 72)
        let overlayHeight: CGFloat

        if settingsOpen {
            overlayHeight = settingsHeight
        } else if chatOpen {
            overlayHeight = chatHeight
        } else {
            overlayHeight = 0
        }

        return CGSize(
            width: width,
            height: characterSize + idleVerticalPadding + overlayHeight
        )
    }

    public static func bottomOverlayHeight(chatOpen: Bool, settingsOpen: Bool) -> CGFloat {
        settingsOpen ? 0 : (chatOpen ? chatHeight : 0)
    }

    public static func characterAnchorOffset(
        characterSize rawCharacterSize: CGFloat,
        chatOpen: Bool,
        settingsOpen: Bool
    ) -> CGPoint {
        let characterSize = clampedCharacterSize(rawCharacterSize)
        let stageSize = stageSize(
            characterSize: characterSize,
            chatOpen: chatOpen,
            settingsOpen: settingsOpen
        )

        return CGPoint(
            x: stageSize.width / 2,
            y: contentVerticalPadding
                + bottomOverlayHeight(chatOpen: chatOpen, settingsOpen: settingsOpen)
                + characterSize / 2
        )
    }
}
