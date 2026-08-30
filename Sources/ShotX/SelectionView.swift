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

    // MARK: - Redraw bookkeeping
    //
    // This view is the size of a whole display, so `needsDisplay = true` on every
    // mouse event repaints the full dim layer, the selection and the crosshair —
    // several megapixels of drawing per mouse move, which is what made dragging a
    // selection feel heavy on large screens. Every event below invalidates only
    // the pixels that actually changed.

    /// Bounding box of the crosshair including its arms and drop shadow.
    private func crosshairDirtyRect(at p: NSPoint) -> NSRect {
        let reach: CGFloat = 11 + 5 // arm length + shadow blur + line width
        return NSRect(x: p.x - reach, y: p.y - reach, width: reach * 2, height: reach * 2)
    }

    private func moveCrosshair(to p: NSPoint) {
        if let old = mousePosition {
            if old == p { return }
            setNeedsDisplay(crosshairDirtyRect(at: old))
        }
        mousePosition = p
        setNeedsDisplay(crosshairDirtyRect(at: p))
    }

    /// Invalidates the bands between the old and new selection: the shared
    /// interior is identical in both frames, so only the edges that moved (and
    /// the dimension label, which rides along) need repainting.
    private func invalidateSelection(from old: NSRect, to new: NSRect) {
        let outset: CGFloat = 2 // border stroke + antialiasing

        // The white border of the old rect can sit well inside the union of the
        // two, where the band arithmetic below wouldn't touch it — repaint both
        // outlines explicitly or the previous frame's edges stay on screen.
        if !old.isEmpty {
            invalidateEdges(of: old, outset: outset)
            setNeedsDisplay(dimensionsDirtyRect(for: old))
        }
        if !new.isEmpty {
            invalidateEdges(of: new, outset: outset)
            setNeedsDisplay(dimensionsDirtyRect(for: new))
        }

        let a = old.isEmpty ? NSRect.zero : old.insetBy(dx: -outset, dy: -outset)
        let b = new.isEmpty ? NSRect.zero : new.insetBy(dx: -outset, dy: -outset)

        guard !a.isEmpty, !b.isEmpty, a.intersects(b) else {
            if !a.isEmpty { setNeedsDisplay(a) }
            if !b.isEmpty { setNeedsDisplay(b) }
            return
        }

        let union = a.union(b)
        let inter = a.intersection(b)
        setNeedsDisplay(NSRect(x: union.minX, y: union.minY,
                               width: union.width, height: inter.minY - union.minY))
        setNeedsDisplay(NSRect(x: union.minX, y: inter.maxY,
                               width: union.width, height: union.maxY - inter.maxY))
        setNeedsDisplay(NSRect(x: union.minX, y: inter.minY,
                               width: inter.minX - union.minX, height: inter.height))
        setNeedsDisplay(NSRect(x: inter.maxX, y: inter.minY,
                               width: union.maxX - inter.maxX, height: inter.height))
    }

    /// The four thin strips the selection outline is drawn into.
    private func invalidateEdges(of rect: NSRect, outset: CGFloat) {
        let thickness = outset * 2
        let r = rect.insetBy(dx: -outset, dy: -outset)
        setNeedsDisplay(NSRect(x: r.minX, y: r.minY, width: r.width, height: thickness))
        setNeedsDisplay(NSRect(x: r.minX, y: r.maxY - thickness, width: r.width, height: thickness))
        setNeedsDisplay(NSRect(x: r.minX, y: r.minY, width: thickness, height: r.height))
        setNeedsDisplay(NSRect(x: r.maxX - thickness, y: r.minY, width: thickness, height: r.height))
    }

    /// Generous box around wherever the "W × H" label can land for a selection.
    private func dimensionsDirtyRect(for rect: NSRect) -> NSRect {
        let w: CGFloat = 140
        let h: CGFloat = 28
        return NSRect(x: rect.maxX - w, y: rect.minY - h - 4, width: w, height: rect.height + h * 2 + 8)
            .intersection(bounds)
    }

    // MARK: - Mouse tracking (for crosshair position)

    override func mouseMoved(with event: NSEvent) {
        moveCrosshair(to: convert(event.locationInWindow, from: nil))
    }

    override func mouseEntered(with event: NSEvent) {
        moveCrosshair(to: convert(event.locationInWindow, from: nil))
    }

    // MARK: - Selection

    override func mouseDown(with event: NSEvent) {
        let p = convert(event.locationInWindow, from: nil)
        startPoint = p
        let previous = currentRect
        currentRect = .zero
        invalidateSelection(from: previous, to: .zero)
        moveCrosshair(to: p)
    }

    override func mouseDragged(with event: NSEvent) {
        guard let start = startPoint else { return }
        let p = convert(event.locationInWindow, from: nil)
        let previous = currentRect
        currentRect = NSRect(
            x: min(start.x, p.x),
            y: min(start.y, p.y),
            width: abs(p.x - start.x),
            height: abs(p.y - start.y)
        )
        invalidateSelection(from: previous, to: currentRect)
        moveCrosshair(to: p)
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
