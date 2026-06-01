import AppKit
import SwiftUI
import MyBuddyCore

final class BuddyPanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}

final class BuddyWindowController {
    private let state: BuddyAppState
    private let panel: BuddyPanel
    private var currentCharacterAnchorOffset: CGPoint

    init(state: BuddyAppState) {
        self.state = state
        let size = state.stageSize
        let initialFrame = Self.initialFrame(for: size)
        currentCharacterAnchorOffset = state.characterAnchorOffset

        panel = BuddyPanel(
            contentRect: initialFrame,
            styleMask: [.borderless, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )

        configurePanel()
        let hostingView = NSHostingView(rootView: BuddyRootView(state: state))
        hostingView.frame = NSRect(origin: .zero, size: size)
        hostingView.autoresizingMask = [.width, .height]
        panel.contentView = hostingView
        panel.setContentSize(size)
        state.onStageSizeChange = { [weak self] newSize in
            guard let self else { return }
            self.resizeWindow(to: newSize, characterAnchorOffset: self.state.characterAnchorOffset)
        }
    }

    func show() {
        panel.centerOnVisibleScreenIfNeeded()
        NSApp.activate(ignoringOtherApps: true)
        panel.makeKeyAndOrderFront(nil)
        panel.orderFrontRegardless()
    }

    private func configurePanel() {
        panel.title = "My Buddy"
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = BuddyWindowPresentation.usesSystemWindowShadow
        panel.level = .statusBar
        panel.hidesOnDeactivate = false
        panel.isReleasedWhenClosed = false
        panel.isMovableByWindowBackground = true
        panel.collectionBehavior = [
            .canJoinAllSpaces,
            .fullScreenAuxiliary,
            .ignoresCycle
        ]
        panel.setFrameAutosaveName("MyBuddyWindowFrame")
    }

    private func resizeWindow(to size: CGSize, characterAnchorOffset: CGPoint) {
        let currentContentFrame = panel.contentRect(forFrameRect: panel.frame)
        let visibleFrame = panel.screen?.visibleFrame ?? NSScreen.main?.visibleFrame
        let origin = BuddyWindowResizePolicy.contentOrigin(
            currentContentFrame: currentContentFrame,
            newContentSize: size,
            currentAnchorOffset: currentCharacterAnchorOffset,
            newAnchorOffset: characterAnchorOffset,
            visibleFrame: visibleFrame
        )

        let newContentFrame = NSRect(
            x: origin.x,
            y: origin.y,
            width: size.width,
            height: size.height
        )
        let newFrame = panel.frameRect(forContentRect: newContentFrame)
        panel.setFrame(newFrame, display: true, animate: false)
        currentCharacterAnchorOffset = characterAnchorOffset
    }

    private static func initialFrame(for size: CGSize) -> NSRect {
        let screenFrame = NSScreen.main?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1440, height: 900)
        return NSRect(
            x: screenFrame.maxX - size.width - 80,
            y: screenFrame.minY + 80,
            width: size.width,
            height: size.height
        )
    }
}

private extension NSWindow {
    func centerOnVisibleScreenIfNeeded() {
        guard let visibleFrame = screen?.visibleFrame ?? NSScreen.main?.visibleFrame else {
            return
        }

        if visibleFrame.intersects(frame) {
            return
        }

        setFrameOrigin(
            NSPoint(
                x: visibleFrame.midX - frame.width / 2,
                y: visibleFrame.midY - frame.height / 2
            )
        )
    }
}
