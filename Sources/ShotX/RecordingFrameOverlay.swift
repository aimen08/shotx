import Cocoa

final class RecordingFrameOverlay {
    private var window: NSWindow?
    private var view: RecordingFrameView?

    func show(rect: NSRect, recording: Bool) {
        if window == nil {
            let win = NSWindow(
                contentRect: rect,
                styleMask: [.borderless],
                backing: .buffered,
                defer: false
            )
            win.isOpaque = false
            win.backgroundColor = .clear
            win.hasShadow = false
            win.level = .floating
            win.ignoresMouseEvents = true
            win.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]

            let v = RecordingFrameView(frame: NSRect(origin: .zero, size: rect.size))
            win.contentView = v
            window = win
            view = v
        }

        window?.setFrame(rect, display: true)
        view?.frame = NSRect(origin: .zero, size: rect.size)
        view?.recording = recording
        view?.needsDisplay = true
        window?.orderFrontRegardless()
    }

    func setRecording(_ recording: Bool) {
        view?.recording = recording
        view?.needsDisplay = true
    }

    func dismiss() {
        window?.orderOut(nil)
        window = nil
        view = nil
    }
}

final class RecordingFrameView: NSView {
    var recording = false

    override var isFlipped: Bool { false }

    override func draw(_ dirtyRect: NSRect) {
        let color: NSColor = recording ? .systemRed : .controlAccentColor
        let lineWidth: CGFloat = 3
        let inset = lineWidth / 2
        let path = NSBezierPath(rect: bounds.insetBy(dx: inset, dy: inset))
        path.lineWidth = lineWidth

        NSGraphicsContext.saveGraphicsState()
        let shadow = NSShadow()
        shadow.shadowColor = color.withAlphaComponent(0.7)
        shadow.shadowBlurRadius = 6
        shadow.shadowOffset = .zero
        shadow.set()
        color.setStroke()
        path.stroke()
        NSGraphicsContext.restoreGraphicsState()

        // Corner accents for a viewfinder feel.
        let cornerLen: CGFloat = 14
        let cornerWidth: CGFloat = 5
        color.setStroke()
        let corners = NSBezierPath()
        corners.lineWidth = cornerWidth
        corners.lineCapStyle = .round

        let edge = inset + cornerWidth / 2

        // Top-left
        corners.move(to: NSPoint(x: edge, y: bounds.maxY - edge))
        corners.line(to: NSPoint(x: edge + cornerLen, y: bounds.maxY - edge))
        corners.move(to: NSPoint(x: edge, y: bounds.maxY - edge))
        corners.line(to: NSPoint(x: edge, y: bounds.maxY - edge - cornerLen))
        // Top-right
        corners.move(to: NSPoint(x: bounds.maxX - edge, y: bounds.maxY - edge))
        corners.line(to: NSPoint(x: bounds.maxX - edge - cornerLen, y: bounds.maxY - edge))
        corners.move(to: NSPoint(x: bounds.maxX - edge, y: bounds.maxY - edge))
        corners.line(to: NSPoint(x: bounds.maxX - edge, y: bounds.maxY - edge - cornerLen))
        // Bottom-left
        corners.move(to: NSPoint(x: edge, y: edge))
        corners.line(to: NSPoint(x: edge + cornerLen, y: edge))
        corners.move(to: NSPoint(x: edge, y: edge))
        corners.line(to: NSPoint(x: edge, y: edge + cornerLen))
        // Bottom-right
        corners.move(to: NSPoint(x: bounds.maxX - edge, y: edge))
        corners.line(to: NSPoint(x: bounds.maxX - edge - cornerLen, y: edge))
        corners.move(to: NSPoint(x: bounds.maxX - edge, y: edge))
        corners.line(to: NSPoint(x: bounds.maxX - edge, y: edge + cornerLen))

        corners.stroke()
    }
}
