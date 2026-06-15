import CoreGraphics

public enum BuddyDockedCorner: String, Equatable, Codable {
    case topLeft
    case topRight
    case bottomLeft
    case bottomRight
}

public enum BuddyCornerDockingPolicy {
    public static let defaultThreshold: CGFloat = 64

    public static func dockedCorner(
        windowFrame: CGRect,
        visibleFrame: CGRect,
        threshold: CGFloat = defaultThreshold
    ) -> BuddyDockedCorner? {
        let nearLeft = abs(windowFrame.minX - visibleFrame.minX) <= threshold
        let nearRight = abs(visibleFrame.maxX - windowFrame.maxX) <= threshold
        let nearBottom = abs(windowFrame.minY - visibleFrame.minY) <= threshold
        let nearTop = abs(visibleFrame.maxY - windowFrame.maxY) <= threshold

        switch (nearLeft, nearRight, nearBottom, nearTop) {
        case (true, false, false, true):
            return .topLeft
        case (false, true, false, true):
            return .topRight
        case (true, false, true, false):
            return .bottomLeft
        case (false, true, true, false):
            return .bottomRight
        default:
            return nil
        }
    }
}
