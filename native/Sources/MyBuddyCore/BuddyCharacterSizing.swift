import CoreGraphics

public struct BuddyCharacterSizePreset: Equatable, Identifiable {
    public let id: String
    public let label: String
    public let size: CGFloat

    public init(id: String, label: String, size: CGFloat) {
        self.id = id
        self.label = label
        self.size = size
    }
}

public enum BuddyCharacterSizing {
    public static let stepSize: CGFloat = 16

    public static let presets: [BuddyCharacterSizePreset] = [
        BuddyCharacterSizePreset(id: "extraSmall", label: "XS", size: 104),
        BuddyCharacterSizePreset(id: "small", label: "S", size: 136),
        BuddyCharacterSizePreset(id: "medium", label: "M", size: BuddyGeometry.defaultCharacterSize),
        BuddyCharacterSizePreset(id: "large", label: "L", size: 224),
        BuddyCharacterSizePreset(id: "extraLarge", label: "XL", size: 264)
    ]

    public static func adjustedSize(from size: CGFloat, stepCount: Int) -> CGFloat {
        BuddyGeometry.clampedCharacterSize(size + CGFloat(stepCount) * stepSize)
    }

    public static func preset(id: String) -> BuddyCharacterSizePreset? {
        presets.first { $0.id == id }
    }

    public static func presetId(exactlyMatchingSize size: CGFloat) -> String? {
        presets.first { $0.size == size }?.id
    }
}
