import AppKit
import Foundation
import MyBuddyCore

enum BuddyAssets {
    static func idleImage() -> NSImage {
        image(named: "character_idle", extension: "png") ?? placeholderImage()
    }

    static func animationFramesById() -> [String: [NSImage]] {
        Dictionary(
            uniqueKeysWithValues: BuddyAnimationPlan.reactionAnimations.map { animation in
                (animation.id, animationFrames(for: animation))
            }
        )
    }

    private static func animationFrames(for animation: BuddyReactionAnimation) -> [NSImage] {
        let frames = animation.frameIndices.compactMap { index in
            image(named: String(format: "Frames/frame_%03d", index), extension: "png")
        }
        return frames.isEmpty ? [idleImage()] : frames
    }

    private static func image(named name: String, extension fileExtension: String) -> NSImage? {
        let fallbackName = (name as NSString).lastPathComponent
        let resourceNames = fallbackName == name ? [name] : [name, fallbackName]

        for resourceName in resourceNames {
            guard let url = Bundle.module.url(
                forResource: resourceName,
                withExtension: fileExtension
            ),
                let image = NSImage(contentsOf: url)
            else {
                continue
            }

            image.isTemplate = false
            return image
        }

        assertionFailure("Missing bundled image: \(name).\(fileExtension)")
        return nil
    }

    private static func placeholderImage() -> NSImage {
        NSImage(size: NSSize(width: 360, height: 360))
    }
}
