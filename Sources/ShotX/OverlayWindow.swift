import Cocoa

final class OverlayWindow: NSWindow {
    private let selectionView: SelectionView
    private let targetScreen: NSScreen

    init(
        screen: NSScreen,
        onSelect: @escaping (CGRect, NSScreen) -> Void,
        onCancel: @escaping () -> Void
    ) {
        self.targetScreen = screen
        self.selectionView = SelectionView(frame: NSRect(origin: .zero, size: screen.frame.size))

        super.init(
            contentRect: screen.frame,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        setFrame(screen.frame, display: false)

        isOpaque = false
        backgroundColor = .clear
        hasShadow = false
        level = .screenSaver
        ignoresMouseEvents = false
        isMovable = false
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]

        selectionView.onSelect = { [weak self] rectInView in
            guard let self = self else { return }
            // Convert view-local AppKit coords → global AppKit coords (origin at primary screen bottom-left).
            let global = CGRect(
                x: self.targetScreen.frame.origin.x + rectInView.origin.x,
                y: self.targetScreen.frame.origin.y + rectInView.origin.y,
                width: rectInView.width,
                height: rectInView.height
            )
            onSelect(global, self.targetScreen)
        }
        selectionView.onCancel = onCancel
        contentView = selectionView

        makeFirstResponder(selectionView)
    }

    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}
