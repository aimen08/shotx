import Cocoa

struct CapturableWindow {
    let id: CGWindowID
    let cgRect: CGRect      // top-left origin (CG coords)
    let ownerName: String
}

final class WindowCaptureController {
    private var window: NSWindow?
    private var view: WindowSelectionView?
    private var completion: ((NSImage?) -> Void)?
    private var cursorPushed = false

    func begin(completion: @escaping (NSImage?) -> Void) {
        self.completion = completion
        guard let screen = NSScreen.main else { completion(nil); return }

        NSApp.activate(ignoringOtherApps: true)

        let windows = Self.enumerateWindows()
        let view = WindowSelectionView(
            windows: windows,
            onSelect: { [weak self] w in self?.capture(window: w) },
            onCancel: { [weak self] in self?.finish(with: nil) }
        )
        view.frame = NSRect(origin: .zero, size: screen.frame.size)
        self.view = view

        let window = NSWindow(
            contentRect: screen.frame,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        window.isOpaque = false
        window.backgroundColor = .clear
        window.hasShadow = false
        window.level = .screenSaver
        window.ignoresMouseEvents = false
        window.isMovable = false
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        window.setFrame(screen.frame, display: false)
        window.contentView = view
        window.makeKeyAndOrderFront(nil)
        window.makeFirstResponder(view)
        self.window = window

        NSCursor.pointingHand.push()
        cursorPushed = true
    }

    private func capture(window w: CapturableWindow) {
        tearDownOverlay()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { [weak self] in
            guard let cg = CGWindowListCreateImage(
                .null,
                .optionIncludingWindow,
                w.id,
                [.bestResolution]
            ) else {
                self?.completion?(nil)
                return
            }
            let size = NSSize(width: cg.width, height: cg.height)
            let image = NSImage(cgImage: cg, size: size)
            self?.completion?(image)
        }
    }

    private func finish(with image: NSImage?) {
        tearDownOverlay()
        completion?(image)
    }

    private func tearDownOverlay() {
        if cursorPushed {
            NSCursor.pop()
            cursorPushed = false
        }
        window?.orderOut(nil)
        window = nil
        view = nil
    }

    private static func enumerateWindows() -> [CapturableWindow] {
        let options: CGWindowListOption = [.optionOnScreenOnly, .excludeDesktopElements]
        let infos = (CGWindowListCopyWindowInfo(options, kCGNullWindowID) as? [[String: Any]]) ?? []
        let selfPID = NSRunningApplication.current.processIdentifier

        return infos.compactMap { info -> CapturableWindow? in
            guard let pid = info[kCGWindowOwnerPID as String] as? pid_t,
                  pid != selfPID,
                  let layer = info[kCGWindowLayer as String] as? Int,
                  layer == 0,
                  let id = info[kCGWindowNumber as String] as? CGWindowID,
                  let boundsDict = info[kCGWindowBounds as String] as? [String: Any],
                  let x = boundsDict["X"] as? CGFloat,
                  let y = boundsDict["Y"] as? CGFloat,
                  let w = boundsDict["Width"] as? CGFloat,
                  let h = boundsDict["Height"] as? CGFloat,
                  w > 40, h > 40
            else { return nil }
            let owner = (info[kCGWindowOwnerName as String] as? String) ?? ""
            return CapturableWindow(
                id: id,
                cgRect: CGRect(x: x, y: y, width: w, height: h),
                ownerName: owner
            )
        }
    }
}

final class WindowSelectionView: NSView {
    var onSelect: ((CapturableWindow) -> Void)?
    var onCancel: (() -> Void)?

    private let windows: [CapturableWindow]
    private var hovered: CapturableWindow?
    private var trackingArea: NSTrackingArea?

    init(
        windows: [CapturableWindow],
        onSelect: @escaping (CapturableWindow) -> Void,
        onCancel: @escaping () -> Void
    ) {
        self.windows = windows
        self.onSelect = onSelect
        self.onCancel = onCancel
        super.init(frame: .zero)
    }

    required init?(coder: NSCoder) { fatalError() }

    override var isFlipped: Bool { false }
    override var acceptsFirstResponder: Bool { true }

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        if let ta = trackingArea { removeTrackingArea(ta) }
        let ta = NSTrackingArea(
            rect: bounds,
            options: [.activeAlways, .mouseMoved, .inVisibleRect],
            owner: self,
            userInfo: nil
        )
        addTrackingArea(ta)
        trackingArea = ta
    }

    override func mouseMoved(with event: NSEvent) {
        let p = convert(event.locationInWindow, from: nil)
        let newHovered = findWindow(at: p)
        if newHovered?.id != hovered?.id {
            hovered = newHovered
            needsDisplay = true
        }
    }

    override func mouseDown(with event: NSEvent) {
        if let hovered = hovered {
            onSelect?(hovered)
        } else {
            onCancel?()
        }
    }

    override func keyDown(with event: NSEvent) {
        if event.keyCode == 53 { onCancel?() }
    }

    override func draw(_ dirtyRect: NSRect) {
        NSColor.black.withAlphaComponent(0.28).setFill()
        bounds.fill()

        guard let hovered = hovered else { return }
        let rect = appKitRect(for: hovered)

        NSColor.clear.setFill()
        rect.fill(using: .copy)

        let stroke = NSBezierPath(roundedRect: rect.insetBy(dx: 1.5, dy: 1.5), xRadius: 6, yRadius: 6)
        stroke.lineWidth = 3
        NSColor.controlAccentColor.setStroke()
        stroke.stroke()

        // Label with app name
        let label = hovered.ownerName
        guard !label.isEmpty else { return }
        let attrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 13, weight: .semibold),
            .foregroundColor: NSColor.white
        ]
        let textSize = label.size(withAttributes: attrs)
        let padding: CGFloat = 8
        let bg = NSRect(
            x: rect.origin.x,
            y: rect.maxY + 8,
            width: textSize.width + padding * 2,
            height: textSize.height + padding
        )
        NSColor.controlAccentColor.setFill()
        NSBezierPath(roundedRect: bg, xRadius: 4, yRadius: 4).fill()
        label.draw(
            at: NSPoint(x: bg.origin.x + padding, y: bg.origin.y + padding / 2),
            withAttributes: attrs
        )
    }

    private func appKitRect(for w: CapturableWindow) -> NSRect {
        guard let primary = NSScreen.screens.first else { return .zero }
        return NSRect(
            x: w.cgRect.origin.x,
            y: primary.frame.height - w.cgRect.origin.y - w.cgRect.height,
            width: w.cgRect.width,
            height: w.cgRect.height
        )
    }

    private func findWindow(at point: NSPoint) -> CapturableWindow? {
        // Windows from CGWindowListCopyWindowInfo are ordered front-to-back.
        for w in windows {
            if appKitRect(for: w).contains(point) {
                return w
            }
        }
        return nil
    }
}
