import AVFoundation
import AppKit

// Borderless circular floating panel that hosts a live front-camera preview.
// Lives in screen coordinates so its CGWindowID can be passed to ScreenRecorder
// as an exception, baking the webcam circle into the captured MP4.
//
// We render frames manually through AVCaptureVideoDataOutput → CIImage →
// NSImageView (with a center-square crop for aspect-fill) instead of using
// AVCaptureVideoPreviewLayer. The preview layer is Metal-backed: it escapes
// the parent layer's circular mask AND doesn't show up in ScreenCaptureKit
// recordings. Rendering into a normal CALayer.contents fixes both.
//
// During preview the panel is draggable from anywhere on its body, and a
// small handle in the bottom-right corner resizes the circle. While recording
// is in progress the panel is frozen.
@MainActor
final class WebcamWindow {
    private let panel: NSPanel
    private let container: NSView
    private let imageView: NSImageView
    private let resizeHandle: ResizeHandleView
    private let session: AVCaptureSession
    private let frameDelegate: WebcamFrameDelegate
    private let bufferQueue = DispatchQueue(label: "shotx.webcam.frames", qos: .userInteractive)

    private static let minDiameter: CGFloat = 100
    private static let maxDiameter: CGFloat = 420
    private static let initialMargin: CGFloat = 18

    var cgWindowID: CGWindowID? {
        guard panel.windowNumber > 0 else { return nil }
        return CGWindowID(panel.windowNumber)
    }

    /// Returns nil if no camera is available or input/output creation fails.
    init?(in rect: NSRect) {
        guard let device = WebcamWindow.frontCamera() else { return nil }
        guard let input = try? AVCaptureDeviceInput(device: device) else { return nil }

        let session = AVCaptureSession()
        session.beginConfiguration()
        session.sessionPreset = .medium
        if session.canAddInput(input) { session.addInput(input) }

        let output = AVCaptureVideoDataOutput()
        output.videoSettings = [
            kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA)
        ]
        output.alwaysDiscardsLateVideoFrames = true
        guard session.canAddOutput(output) else {
            session.commitConfiguration()
            return nil
        }
        session.addOutput(output)
        session.commitConfiguration()
        self.session = session

        let initialDiameter = WebcamWindow.initialDiameter(for: rect)
        let frame = NSRect(
            x: rect.minX + Self.initialMargin,
            y: rect.minY + Self.initialMargin,
            width: initialDiameter,
            height: initialDiameter
        )

        let panel = NSPanel(
            contentRect: frame,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = false
        panel.level = .screenSaver
        panel.isMovableByWindowBackground = true
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        self.panel = panel

        let container = NSView(frame: NSRect(origin: .zero, size: frame.size))
        container.autoresizesSubviews = true
        container.wantsLayer = true

        let imageView = DraggableImageView(frame: container.bounds)
        imageView.autoresizingMask = [.width, .height]
        imageView.imageScaling = .scaleAxesIndependently
        imageView.imageAlignment = .alignCenter
        imageView.wantsLayer = true
        imageView.layer?.cornerRadius = initialDiameter / 2
        imageView.layer?.masksToBounds = true
        imageView.layer?.borderColor = NSColor.white.withAlphaComponent(0.85).cgColor
        imageView.layer?.borderWidth = 3
        imageView.layer?.backgroundColor = NSColor.black.cgColor
        container.addSubview(imageView)
        self.imageView = imageView

        let handleSize: CGFloat = 26
        let handle = ResizeHandleView(frame: NSRect(
            x: container.bounds.width - handleSize,
            y: 0,
            width: handleSize,
            height: handleSize
        ))
        handle.autoresizingMask = [.minXMargin, .maxYMargin]
        container.addSubview(handle)
        self.resizeHandle = handle

        panel.contentView = container
        self.container = container

        self.frameDelegate = WebcamFrameDelegate(target: imageView)
        output.setSampleBufferDelegate(frameDelegate, queue: bufferQueue)

        // When the handle resizes the panel, update the circle's cornerRadius
        // to keep it perfectly round at the new diameter.
        handle.onSizeChange = { [weak imageView] newSize in
            imageView?.layer?.cornerRadius = newSize / 2
        }
    }

    func show() {
        panel.orderFrontRegardless()
        let session = self.session
        DispatchQueue.global(qos: .userInitiated).async {
            session.startRunning()
        }
    }

    func dismiss() {
        let session = self.session
        DispatchQueue.global(qos: .userInitiated).async {
            session.stopRunning()
        }
        panel.orderOut(nil)
    }

    /// Disable user interaction (drag/resize) once recording starts so the
    /// circle sits stable in the frame and clicks pass through to the app
    /// being recorded.
    func setInteractive(_ interactive: Bool) {
        panel.isMovableByWindowBackground = interactive
        panel.ignoresMouseEvents = !interactive
        resizeHandle.isHidden = !interactive
    }

    // MARK: - Helpers

    private static func frontCamera() -> AVCaptureDevice? {
        if let front = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) {
            return front
        }
        return AVCaptureDevice.default(for: .video)
    }

    private static func initialDiameter(for rect: NSRect) -> CGFloat {
        let suggested = min(rect.width, rect.height) * 0.16
        return max(minDiameter, min(maxDiameter, suggested))
    }

    static func authorizationStatus() -> AVAuthorizationStatus {
        AVCaptureDevice.authorizationStatus(for: .video)
    }

    static func requestAccess() async -> Bool {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized: return true
        case .denied, .restricted: return false
        case .notDetermined: return await AVCaptureDevice.requestAccess(for: .video)
        @unknown default: return false
        }
    }
}

// MARK: - Subviews

/// NSImageView whose mouse-down moves its window — lets the user grab the
/// circle anywhere to drag it.
private final class DraggableImageView: NSImageView {
    override var mouseDownCanMoveWindow: Bool { true }
}

/// Small bottom-right handle. Captures its own drag to resize the window
/// (anchored at the top-left, kept square) instead of moving it.
private final class ResizeHandleView: NSView {
    var onSizeChange: ((CGFloat) -> Void)?

    private var initialFrame: NSRect = .zero
    private var initialMouse: NSPoint = .zero

    override var mouseDownCanMoveWindow: Bool { false }

    override func draw(_ dirtyRect: NSRect) {
        let path = NSBezierPath()
        let inset: CGFloat = 6
        // Three diagonal "grip" lines suggesting resizability
        for offset: CGFloat in [0, 5, 10] {
            path.move(to: NSPoint(x: bounds.maxX - inset - offset, y: bounds.minY + inset))
            path.line(to: NSPoint(x: bounds.maxX - inset, y: bounds.minY + inset + offset))
        }
        path.lineWidth = 1.6
        path.lineCapStyle = .round
        NSColor.white.withAlphaComponent(0.85).setStroke()
        path.stroke()
    }

    override func resetCursorRects() {
        addCursorRect(bounds, cursor: NSCursor(image: NSImage(systemSymbolName: "arrow.up.left.and.arrow.down.right", accessibilityDescription: nil) ?? NSImage(), hotSpot: NSPoint(x: 8, y: 8)))
    }

    override func mouseDown(with event: NSEvent) {
        guard let win = window else { return }
        initialFrame = win.frame
        initialMouse = NSEvent.mouseLocation
    }

    override func mouseDragged(with event: NSEvent) {
        guard let win = window else { return }
        let current = NSEvent.mouseLocation
        let dx = current.x - initialMouse.x
        // Screen coords are y-up; dragging the cursor "down" decreases y, so
        // invert to get an intuitive "drag down → grow taller" delta.
        let dy = -(current.y - initialMouse.y)
        let delta = max(dx, dy)
        let newSize = max(100, min(420, initialFrame.width + delta))
        // Anchor top-left so the handle stays under the cursor as we grow.
        let topY = initialFrame.maxY
        let leftX = initialFrame.minX
        let newFrame = NSRect(x: leftX, y: topY - newSize, width: newSize, height: newSize)
        win.setFrame(newFrame, display: true)
        onSizeChange?(newSize)
    }
}

// MARK: - Frame delegate

/// Receives raw camera frames off-main, mirrors them horizontally, crops to
/// a center square so the circle fills cleanly with no letterboxing, then
/// hands the result to the NSImageView on the main queue.
private final class WebcamFrameDelegate: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    private let context = CIContext()
    private weak var target: NSImageView?

    init(target: NSImageView) {
        self.target = target
    }

    func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        let oriented = CIImage(cvPixelBuffer: pixelBuffer).oriented(.upMirrored)
        let extent = oriented.extent
        let side = min(extent.width, extent.height)
        let crop = CGRect(
            x: extent.midX - side / 2,
            y: extent.midY - side / 2,
            width: side,
            height: side
        )
        guard let cg = context.createCGImage(oriented, from: crop) else { return }
        let nsImage = NSImage(cgImage: cg, size: NSSize(width: cg.width, height: cg.height))
        DispatchQueue.main.async { [weak self] in
            MainActor.assumeIsolated {
                self?.target?.image = nsImage
            }
        }
    }
}
