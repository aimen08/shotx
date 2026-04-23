import Cocoa

final class SelectionView: NSView {
    var onSelect: ((CGRect) -> Void)?
    var onCancel: (() -> Void)?

    private var startPoint: NSPoint?
    private var currentRect: NSRect = .zero
    private var trackingArea: NSTrackingArea?

    override var acceptsFirstResponder: Bool { true }
    override var isFlipped: Bool { false }

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        if let t = trackingArea { removeTrackingArea(t) }
        // .activeAlways + .cursorUpdate so the crosshair is applied regardless
        // of key-window state, which can be flaky for .accessory apps.
        let t = NSTrackingArea(
            rect: bounds,
            options: [.activeAlways, .inVisibleRect, .mouseMoved, .cursorUpdate],
            owner: self,
            userInfo: nil
        )
        addTrackingArea(t)
        trackingArea = t
    }

    override func cursorUpdate(with event: NSEvent) {
        NSCursor.crosshair.set()
    }

    override func mouseMoved(with event: NSEvent) {
        NSCursor.crosshair.set()
    }

    override func mouseDown(with event: NSEvent) {
        startPoint = convert(event.locationInWindow, from: nil)
        currentRect = .zero
        needsDisplay = true
    }

    override func mouseDragged(with event: NSEvent) {
        guard let start = startPoint else { return }
        let p = convert(event.locationInWindow, from: nil)
        currentRect = NSRect(
            x: min(start.x, p.x),
            y: min(start.y, p.y),
            width: abs(p.x - start.x),
            height: abs(p.y - start.y)
        )
        needsDisplay = true
    }

    override func mouseUp(with event: NSEvent) {
        defer {
            startPoint = nil
            currentRect = .zero
            needsDisplay = true
        }
        if currentRect.width < 3 || currentRect.height < 3 {
            onCancel?()
            return
        }
        onSelect?(currentRect)
    }

    override func keyDown(with event: NSEvent) {
        if event.keyCode == 53 { // Escape
            onCancel?()
        } else {
            super.keyDown(with: event)
        }
    }

    override func draw(_ dirtyRect: NSRect) {
        // Dim the whole screen.
        NSColor.black.withAlphaComponent(0.35).setFill()
        bounds.fill()

        guard currentRect.width > 0 && currentRect.height > 0 else { return }

        // Punch a clear hole for the selection.
        NSColor.clear.setFill()
        currentRect.fill(using: .copy)

        // Selection border.
        NSColor.white.setStroke()
        let path = NSBezierPath(rect: currentRect.insetBy(dx: 0.5, dy: 0.5))
        path.lineWidth = 1
        path.stroke()

        // Dimensions label.
        let label = "\(Int(currentRect.width)) × \(Int(currentRect.height))"
        let attrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 11, weight: .medium),
            .foregroundColor: NSColor.white
        ]
        let size = label.size(withAttributes: attrs)
        let padding: CGFloat = 4
        var labelOrigin = NSPoint(
            x: currentRect.maxX - size.width - padding * 2,
            y: currentRect.minY - size.height - padding * 2 - 2
        )
        if labelOrigin.y < 0 {
            labelOrigin.y = currentRect.maxY + 2
        }
        let bg = NSRect(
            x: labelOrigin.x,
            y: labelOrigin.y,
            width: size.width + padding * 2,
            height: size.height + padding * 2
        )
        NSColor.black.withAlphaComponent(0.7).setFill()
        NSBezierPath(roundedRect: bg, xRadius: 3, yRadius: 3).fill()
        label.draw(
            at: NSPoint(x: labelOrigin.x + padding, y: labelOrigin.y + padding),
            withAttributes: attrs
        )
    }
}
