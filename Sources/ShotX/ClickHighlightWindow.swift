import Cocoa
import QuartzCore

/// Transparent fullscreen overlay that draws a colored ripple where the user
/// clicks. Used during screen recording so the video shows where clicks land.
/// The window is intentionally NOT excluded from ScreenCaptureKit — it's
/// passed as an `exceptingWindows` entry in `SCContentFilter` so it appears
/// in the captured frames.
final class ClickHighlightWindow {
    private var window: NSWindow?
    private var view: ClickHighlightView?
    private var eventMonitor: Any?

    func show() {
        guard let screen = NSScreen.main else { return }

        let w = NSWindow(
            contentRect: screen.frame,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        w.isOpaque = false
        w.backgroundColor = .clear
        w.hasShadow = false
        w.level = .screenSaver
        w.ignoresMouseEvents = true
        w.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]

        let v = ClickHighlightView(frame: NSRect(origin: .zero, size: screen.frame.size))
        w.contentView = v
        w.orderFrontRegardless()

        window = w
        view = v

        eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            let p = NSEvent.mouseLocation
            self?.view?.addRipple(atGlobal: p)
        }
    }

    func dismiss() {
        if let m = eventMonitor { NSEvent.removeMonitor(m) }
        eventMonitor = nil
        window?.orderOut(nil)
        window = nil
        view = nil
    }

    /// The window's CGWindowID, used to include this overlay in SCStream
    /// capture via `exceptingWindows`.
    var cgWindowID: CGWindowID? {
        guard let num = window?.windowNumber else { return nil }
        return CGWindowID(num)
    }
}

final class ClickHighlightView: NSView {
    private struct Ripple {
        let point: NSPoint
        let startTime: CFTimeInterval
    }

    private var ripples: [Ripple] = []
    private var refreshTimer: Timer?

    private let rippleDuration: CFTimeInterval = 0.55
    private let maxRadius: CGFloat = 42
    private let color = NSColor.systemYellow

    override init(frame: NSRect) {
        super.init(frame: frame)
        wantsLayer = true
    }

    required init?(coder: NSCoder) { fatalError() }

    override var isFlipped: Bool { false }

    func addRipple(atGlobal point: NSPoint) {
        guard let win = window else { return }
        // Global screen coords → view-local (window covers screen, so offset by frame origin)
        let local = NSPoint(
            x: point.x - win.frame.origin.x,
            y: point.y - win.frame.origin.y
        )
        ripples.append(Ripple(point: local, startTime: CACurrentMediaTime()))
        startRefreshIfNeeded()
        needsDisplay = true
    }

    private func startRefreshIfNeeded() {
        guard refreshTimer == nil else { return }
        let t = Timer(timeInterval: 1.0 / 60.0, repeats: true) { [weak self] _ in
            self?.tick()
        }
        RunLoop.main.add(t, forMode: .common)
        refreshTimer = t
    }

    private func tick() {
        let now = CACurrentMediaTime()
        ripples.removeAll { now - $0.startTime > rippleDuration }
        if ripples.isEmpty {
            refreshTimer?.invalidate()
            refreshTimer = nil
        }
        needsDisplay = true
    }

    override func draw(_ dirtyRect: NSRect) {
        let now = CACurrentMediaTime()
        for ripple in ripples {
            let age = now - ripple.startTime
            guard age >= 0, age < rippleDuration else { continue }
            let t = CGFloat(age / rippleDuration)

            // Expanding outer ring
            let radius = t * maxRadius
            let alpha = CGFloat(1.0 - t)
            let ringRect = NSRect(
                x: ripple.point.x - radius,
                y: ripple.point.y - radius,
                width: radius * 2,
                height: radius * 2
            )
            let ring = NSBezierPath(ovalIn: ringRect)
            ring.lineWidth = 3
            color.withAlphaComponent(alpha).setStroke()
            ring.stroke()

            // Softer inner fill (shrinks and fades)
            let innerR = (1.0 - t) * 10
            let innerAlpha = alpha * 0.5
            let innerRect = NSRect(
                x: ripple.point.x - innerR,
                y: ripple.point.y - innerR,
                width: innerR * 2,
                height: innerR * 2
            )
            color.withAlphaComponent(innerAlpha).setFill()
            NSBezierPath(ovalIn: innerRect).fill()
        }
    }

    deinit {
        refreshTimer?.invalidate()
    }
}
