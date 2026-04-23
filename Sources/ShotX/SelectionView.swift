import Cocoa

final class SelectionView: NSView {
    var onSelect: ((CGRect) -> Void)?
    var onCancel: (() -> Void)?

    private var startPoint: NSPoint?
    private var currentRect: NSRect = .zero
    private var mousePosition: NSPoint?
    private var trackingArea: NSTrackingArea?

    override var acceptsFirstResponder: Bool { true }
    override var isFlipped: Bool { false }

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        if let t = trackingArea { removeTrackingArea(t) }
        let t = NSTrackingArea(
            rect: bounds,
            options: [.activeAlways, .inVisibleRect, .mouseMoved, .mouseEnteredAndExited],
            owner: self,
            userInfo: nil
        )
        addTrackingArea(t)
        trackingArea = t
    }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        guard let win = window else { return }
        // Seed the mouse position from the current cursor location so the
        // crosshair is visible on the very first frame, before any mouseMoved.
        let global = NSEvent.mouseLocation
        mousePosition = NSPoint(
            x: global.x - win.frame.origin.x,
            y: global.y - win.frame.origin.y
        )
        needsDisplay = true
    }

    // MARK: - Mouse tracking (for crosshair position)

    override func mouseMoved(with event: NSEvent) {
        mousePosition = convert(event.locationInWindow, from: nil)
        needsDisplay = true
    }

    override func mouseEntered(with event: NSEvent) {
        mousePosition = convert(event.locationInWindow, from: nil)
        needsDisplay = true
    }

    // MARK: - Selection

    override func mouseDown(with event: NSEvent) {
        let p = convert(event.locationInWindow, from: nil)
        startPoint = p
        mousePosition = p
        currentRect = .zero
        needsDisplay = true
    }

    override func mouseDragged(with event: NSEvent) {
        guard let start = startPoint else { return }
        let p = convert(event.locationInWindow, from: nil)
        mousePosition = p
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

    // MARK: - Drawing

    override func draw(_ dirtyRect: NSRect) {
        // Dim the whole screen
        NSColor.black.withAlphaComponent(0.35).setFill()
        bounds.fill()

        // Punch out the selection area so the live screen shows through
        if currentRect.width > 0, currentRect.height > 0 {
            NSColor.clear.setFill()
            currentRect.fill(using: .copy)

            // White border around the selection
            NSColor.white.setStroke()
            let border = NSBezierPath(rect: currentRect.insetBy(dx: 0.5, dy: 0.5))
            border.lineWidth = 1
            border.stroke()

            drawDimensions(for: currentRect)
        }

        // Draw our own crosshair cursor wherever the mouse is
        if let pos = mousePosition {
            drawCrosshair(at: pos)
        }
    }

    private func drawCrosshair(at p: NSPoint) {
        // Two thin white lines meeting at the cursor, with a small gap at
        // the centre so the tip is clearly visible. Soft shadow for contrast
        // against any background.
        let arm: CGFloat = 11
        let gap: CGFloat = 3
        let lineWidth: CGFloat = 1

        NSGraphicsContext.saveGraphicsState()
        let shadow = NSShadow()
        shadow.shadowColor = NSColor.black.withAlphaComponent(0.55)
        shadow.shadowBlurRadius = 2
        shadow.shadowOffset = .zero
        shadow.set()

        NSColor.white.setStroke()
        let path = NSBezierPath()
        path.lineWidth = lineWidth

        // Up
        path.move(to: NSPoint(x: p.x, y: p.y + gap))
        path.line(to: NSPoint(x: p.x, y: p.y + arm))
        // Down
        path.move(to: NSPoint(x: p.x, y: p.y - gap))
        path.line(to: NSPoint(x: p.x, y: p.y - arm))
        // Left
        path.move(to: NSPoint(x: p.x - gap, y: p.y))
        path.line(to: NSPoint(x: p.x - arm, y: p.y))
        // Right
        path.move(to: NSPoint(x: p.x + gap, y: p.y))
        path.line(to: NSPoint(x: p.x + arm, y: p.y))

        path.stroke()
        NSGraphicsContext.restoreGraphicsState()
    }

    private func drawDimensions(for rect: NSRect) {
        let label = "\(Int(rect.width)) × \(Int(rect.height))"
        let attrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 11, weight: .medium),
            .foregroundColor: NSColor.white
        ]
        let size = label.size(withAttributes: attrs)
        let padding: CGFloat = 4
        var origin = NSPoint(
            x: rect.maxX - size.width - padding * 2,
            y: rect.minY - size.height - padding * 2 - 2
        )
        if origin.y < 0 {
            origin.y = rect.maxY + 2
        }
        let bg = NSRect(
            x: origin.x,
            y: origin.y,
            width: size.width + padding * 2,
            height: size.height + padding * 2
        )
        NSColor.black.withAlphaComponent(0.7).setFill()
        NSBezierPath(roundedRect: bg, xRadius: 3, yRadius: 3).fill()
        label.draw(
            at: NSPoint(x: origin.x + padding, y: origin.y + padding),
            withAttributes: attrs
        )
    }
}
