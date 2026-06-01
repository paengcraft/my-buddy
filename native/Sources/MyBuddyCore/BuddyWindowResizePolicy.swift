import CoreGraphics

public enum BuddyWindowResizePolicy {
    public static func contentOrigin(
        currentContentFrame: CGRect,
        newContentSize: CGSize,
        currentAnchorOffset: CGPoint,
        newAnchorOffset: CGPoint,
        visibleFrame: CGRect?
    ) -> CGPoint {
        var origin = CGPoint(
            x: currentContentFrame.minX + currentAnchorOffset.x - newAnchorOffset.x,
            y: currentContentFrame.minY + currentAnchorOffset.y - newAnchorOffset.y
        )

        if let visibleFrame {
            origin.x = min(max(origin.x, visibleFrame.minX), visibleFrame.maxX - newContentSize.width)
            origin.y = min(max(origin.y, visibleFrame.minY), visibleFrame.maxY - newContentSize.height)
        }

        return origin
    }
}
