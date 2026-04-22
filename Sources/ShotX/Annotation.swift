import Cocoa

enum AnnotationTool: String, CaseIterable, Identifiable {
    case arrow, rectangle, text, step
    var id: String { rawValue }
    var symbolName: String {
        switch self {
        case .arrow: return "arrow.up.right"
        case .rectangle: return "rectangle"
        case .text: return "textformat"
        case .step: return "1.circle.fill"
        }
    }
    var label: String {
        switch self {
        case .arrow: return "Arrow"
        case .rectangle: return "Rectangle"
        case .text: return "Text"
        case .step: return "Step"
        }
    }
}

struct Annotation: Identifiable {
    enum Shape {
        case arrow(from: CGPoint, to: CGPoint)
        case rectangle(CGRect)
        case text(origin: CGPoint, string: String)
        case step(center: CGPoint, number: Int)
    }
    let id = UUID()
    var shape: Shape
    var color: NSColor
    var thickness: CGFloat
}

enum AnnotationRenderer {
    static func draw(_ ann: Annotation) {
        ann.color.setStroke()
        ann.color.setFill()
        switch ann.shape {
        case .arrow(let from, let to):
            drawArrow(from: from, to: to, thickness: ann.thickness, color: ann.color)
        case .rectangle(let r):
            let path = NSBezierPath(rect: r)
            path.lineWidth = ann.thickness
            path.stroke()
        case .text(let origin, let string):
            let font = NSFont.boldSystemFont(ofSize: 20)
            let attrs: [NSAttributedString.Key: Any] = [
                .font: font,
                .foregroundColor: ann.color,
                .strokeColor: NSColor.white,
                .strokeWidth: -3
            ]
            string.draw(at: origin, withAttributes: attrs)
        case .step(let center, let number):
            let radius: CGFloat = 16
            let rect = NSRect(
                x: center.x - radius, y: center.y - radius,
                width: radius * 2, height: radius * 2
            )
            ann.color.setFill()
            NSBezierPath(ovalIn: rect).fill()
            NSColor.white.setStroke()
            let outline = NSBezierPath(ovalIn: rect.insetBy(dx: 1, dy: 1))
            outline.lineWidth = 2
            outline.stroke()

            let text = "\(number)"
            let attrs: [NSAttributedString.Key: Any] = [
                .font: NSFont.boldSystemFont(ofSize: 16),
                .foregroundColor: NSColor.white
            ]
            let size = text.size(withAttributes: attrs)
            text.draw(
                at: NSPoint(x: center.x - size.width / 2, y: center.y - size.height / 2),
                withAttributes: attrs
            )
        }
    }

    private static func drawArrow(from: CGPoint, to: CGPoint, thickness: CGFloat, color: NSColor) {
        let dx = to.x - from.x
        let dy = to.y - from.y
        let length = hypot(dx, dy)
        guard length > 1 else { return }
        let angle = atan2(dy, dx)
        let headLength = max(14, thickness * 4)
        let headAngle: CGFloat = .pi / 7

        color.setStroke()
        color.setFill()

        let shaftEnd = CGPoint(
            x: to.x - cos(angle) * headLength * 0.7,
            y: to.y - sin(angle) * headLength * 0.7
        )
        let shaft = NSBezierPath()
        shaft.lineWidth = thickness
        shaft.lineCapStyle = .round
        shaft.move(to: from)
        shaft.line(to: shaftEnd)
        shaft.stroke()

        let head = NSBezierPath()
        head.move(to: to)
        head.line(to: CGPoint(
            x: to.x - headLength * cos(angle - headAngle),
            y: to.y - headLength * sin(angle - headAngle)
        ))
        head.line(to: CGPoint(
            x: to.x - headLength * cos(angle + headAngle),
            y: to.y - headLength * sin(angle + headAngle)
        ))
        head.close()
        head.fill()
    }
}

final class AnnotationCanvas: NSView {
    var image: NSImage? {
        didSet {
            if let img = image {
                setFrameSize(img.size)
            }
            needsDisplay = true
        }
    }
    var annotations: [Annotation] = [] { didSet { needsDisplay = true } }
    var currentTool: AnnotationTool = .arrow { didSet { resetCursorRects() } }
    var currentColor: NSColor = .systemRed
    var thickness: CGFloat = 3

    var onAnnotationsChanged: (([Annotation]) -> Void)?

    private var inProgress: Annotation?
    private var dragStart: NSPoint?
    private var nextStep: Int = 1

    override var isFlipped: Bool { false }
    override var acceptsFirstResponder: Bool { true }

    override func resetCursorRects() {
        discardCursorRects()
        let cursor: NSCursor
        switch currentTool {
        case .text: cursor = .iBeam
        default: cursor = .crosshair
        }
        addCursorRect(bounds, cursor: cursor)
    }

    override func mouseDown(with event: NSEvent) {
        let p = convert(event.locationInWindow, from: nil)
        dragStart = p

        switch currentTool {
        case .arrow:
            inProgress = Annotation(shape: .arrow(from: p, to: p), color: currentColor, thickness: thickness)
        case .rectangle:
            inProgress = Annotation(shape: .rectangle(CGRect(origin: p, size: .zero)), color: currentColor, thickness: thickness)
        case .step:
            let ann = Annotation(shape: .step(center: p, number: nextStep), color: currentColor, thickness: thickness)
            nextStep += 1
            annotations.append(ann)
            onAnnotationsChanged?(annotations)
            inProgress = nil
        case .text:
            inProgress = nil
            promptForText(at: p)
        }
        needsDisplay = true
    }

    override func mouseDragged(with event: NSEvent) {
        guard var ann = inProgress, let start = dragStart else { return }
        let p = convert(event.locationInWindow, from: nil)
        switch ann.shape {
        case .arrow:
            ann.shape = .arrow(from: start, to: p)
        case .rectangle:
            ann.shape = .rectangle(CGRect(
                x: min(start.x, p.x), y: min(start.y, p.y),
                width: abs(p.x - start.x), height: abs(p.y - start.y)
            ))
        default: break
        }
        inProgress = ann
        needsDisplay = true
    }

    override func mouseUp(with event: NSEvent) {
        defer {
            inProgress = nil
            dragStart = nil
            needsDisplay = true
        }
        guard let ann = inProgress else { return }
        switch ann.shape {
        case .arrow(let from, let to):
            if hypot(to.x - from.x, to.y - from.y) < 5 { return }
        case .rectangle(let r):
            if r.width < 5 || r.height < 5 { return }
        default: break
        }
        annotations.append(ann)
        onAnnotationsChanged?(annotations)
    }

    func undo() {
        guard !annotations.isEmpty else { return }
        let removed = annotations.removeLast()
        if case .step = removed.shape {
            nextStep = max(1, nextStep - 1)
        }
        onAnnotationsChanged?(annotations)
        needsDisplay = true
    }

    func resetSteps() { nextStep = 1 }

    private func promptForText(at point: NSPoint) {
        let alert = NSAlert()
        alert.messageText = "Add text"
        alert.informativeText = "Text will be placed where you clicked."
        alert.addButton(withTitle: "Add")
        alert.addButton(withTitle: "Cancel")
        let field = NSTextField(frame: NSRect(x: 0, y: 0, width: 280, height: 24))
        field.placeholderString = "Type here…"
        alert.accessoryView = field
        if let w = window {
            alert.beginSheetModal(for: w) { [weak self] response in
                guard response == .alertFirstButtonReturn,
                      !field.stringValue.isEmpty,
                      let self = self else { return }
                let ann = Annotation(
                    shape: .text(origin: point, string: field.stringValue),
                    color: self.currentColor,
                    thickness: self.thickness
                )
                self.annotations.append(ann)
                self.onAnnotationsChanged?(self.annotations)
                self.needsDisplay = true
            }
        }
    }

    override func draw(_ dirtyRect: NSRect) {
        NSColor.windowBackgroundColor.setFill()
        bounds.fill()

        image?.draw(in: bounds)

        for ann in annotations {
            AnnotationRenderer.draw(ann)
        }
        if let in_ = inProgress {
            AnnotationRenderer.draw(in_)
        }
    }

    func flattenedImage() -> NSImage? {
        guard let image = image,
              let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil)
        else { return nil }

        let pixelW = cgImage.width
        let pixelH = cgImage.height
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        guard let ctx = CGContext(
            data: nil,
            width: pixelW, height: pixelH,
            bitsPerComponent: 8, bytesPerRow: 0,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return nil }

        ctx.draw(cgImage, in: CGRect(x: 0, y: 0, width: pixelW, height: pixelH))

        let scaleX = CGFloat(pixelW) / image.size.width
        let scaleY = CGFloat(pixelH) / image.size.height
        ctx.scaleBy(x: scaleX, y: scaleY)

        let nsCtx = NSGraphicsContext(cgContext: ctx, flipped: false)
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = nsCtx
        for ann in annotations {
            AnnotationRenderer.draw(ann)
        }
        NSGraphicsContext.restoreGraphicsState()

        guard let output = ctx.makeImage() else { return nil }
        return NSImage(cgImage: output, size: image.size)
    }
}

final class AnnotationWindowController: NSObject, NSWindowDelegate {
    private var window: NSWindow?
    private var canvas: AnnotationCanvas?
    private var onClose: (() -> Void)?

    private let colors: [NSColor] = [
        .systemRed, .systemOrange, .systemYellow,
        .systemGreen, .systemBlue, .black, .white
    ]

    func open(image: NSImage, onClose: @escaping () -> Void) {
        self.onClose = onClose

        let canvas = AnnotationCanvas()
        canvas.image = image
        self.canvas = canvas

        let scroll = NSScrollView()
        scroll.hasVerticalScroller = true
        scroll.hasHorizontalScroller = true
        scroll.autohidesScrollers = true
        scroll.borderType = .noBorder
        scroll.backgroundColor = NSColor.windowBackgroundColor
        scroll.documentView = canvas

        let toolbar = buildToolbar()
        toolbar.translatesAutoresizingMaskIntoConstraints = false
        scroll.translatesAutoresizingMaskIntoConstraints = false

        let container = NSView()
        container.addSubview(toolbar)
        container.addSubview(scroll)
        NSLayoutConstraint.activate([
            toolbar.topAnchor.constraint(equalTo: container.topAnchor),
            toolbar.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            toolbar.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            toolbar.heightAnchor.constraint(equalToConstant: 50),
            scroll.topAnchor.constraint(equalTo: toolbar.bottomAnchor),
            scroll.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            scroll.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            scroll.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])

        let contentW = min(image.size.width + 40, 1200)
        let contentH = min(image.size.height + 110, 900)
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: contentW, height: contentH),
            styleMask: [.titled, .closable, .resizable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.title = "Annotate"
        window.contentView = container
        window.delegate = self
        window.isReleasedWhenClosed = false
        window.center()
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        self.window = window
    }

    private func buildToolbar() -> NSView {
        let bar = NSView()
        bar.wantsLayer = true
        bar.layer?.backgroundColor = NSColor.windowBackgroundColor.cgColor

        let divider = NSBox()
        divider.boxType = .separator
        divider.translatesAutoresizingMaskIntoConstraints = false
        bar.addSubview(divider)
        NSLayoutConstraint.activate([
            divider.leadingAnchor.constraint(equalTo: bar.leadingAnchor),
            divider.trailingAnchor.constraint(equalTo: bar.trailingAnchor),
            divider.bottomAnchor.constraint(equalTo: bar.bottomAnchor),
            divider.heightAnchor.constraint(equalToConstant: 1)
        ])

        var toolButtons: [NSButton] = []
        for tool in AnnotationTool.allCases {
            let symbol = NSImage(systemSymbolName: tool.symbolName, accessibilityDescription: tool.label)
            let button = NSButton(image: symbol ?? NSImage(), target: self, action: #selector(toolClicked(_:)))
            button.bezelStyle = .smallSquare
            button.setButtonType(.onOff)
            button.isBordered = true
            button.identifier = NSUserInterfaceItemIdentifier(tool.rawValue)
            button.state = (tool == .arrow) ? .on : .off
            button.toolTip = tool.label
            toolButtons.append(button)
        }

        var colorButtons: [NSButton] = []
        for (i, color) in colors.enumerated() {
            let button = NSButton(title: "", target: self, action: #selector(colorClicked(_:)))
            button.tag = i
            button.isBordered = false
            button.wantsLayer = true
            button.layer?.backgroundColor = color.cgColor
            button.layer?.cornerRadius = 10
            button.layer?.borderColor = NSColor.labelColor.cgColor
            button.layer?.borderWidth = (i == 0) ? 2 : 0
            button.widthAnchor.constraint(equalToConstant: 20).isActive = true
            button.heightAnchor.constraint(equalToConstant: 20).isActive = true
            colorButtons.append(button)
        }
        self.colorButtons = colorButtons
        self.toolButtons = toolButtons

        let sep1 = verticalSeparator()
        let sep2 = verticalSeparator()

        let undo = NSButton(title: "Undo", target: self, action: #selector(undoClicked))
        undo.bezelStyle = .rounded
        undo.keyEquivalent = "z"
        undo.keyEquivalentModifierMask = .command

        let cancel = NSButton(title: "Cancel", target: self, action: #selector(cancelClicked))
        cancel.bezelStyle = .rounded

        let saveDesktop = NSButton(title: "Save", target: self, action: #selector(saveDesktopClicked))
        saveDesktop.bezelStyle = .rounded

        let copyDone = NSButton(title: "Copy", target: self, action: #selector(copyClicked))
        copyDone.bezelStyle = .rounded
        copyDone.keyEquivalent = "\r"

        let spacer = NSView()
        spacer.setContentHuggingPriority(.defaultLow, for: .horizontal)

        let stack = NSStackView(views:
            toolButtons as [NSView]
            + [sep1]
            + (colorButtons as [NSView])
            + [sep2, undo, spacer, cancel, saveDesktop, copyDone]
        )
        stack.orientation = .horizontal
        stack.spacing = 8
        stack.alignment = .centerY
        stack.edgeInsets = NSEdgeInsets(top: 0, left: 12, bottom: 0, right: 12)
        stack.translatesAutoresizingMaskIntoConstraints = false
        bar.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: bar.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: bar.trailingAnchor),
            stack.topAnchor.constraint(equalTo: bar.topAnchor),
            stack.bottomAnchor.constraint(equalTo: divider.topAnchor)
        ])
        return bar
    }

    private func verticalSeparator() -> NSView {
        let box = NSBox()
        box.boxType = .separator
        box.widthAnchor.constraint(equalToConstant: 1).isActive = true
        box.heightAnchor.constraint(equalToConstant: 22).isActive = true
        return box
    }

    private var toolButtons: [NSButton] = []
    private var colorButtons: [NSButton] = []

    @objc private func toolClicked(_ sender: NSButton) {
        for b in toolButtons { b.state = (b === sender) ? .on : .off }
        if let id = sender.identifier?.rawValue,
           let tool = AnnotationTool(rawValue: id) {
            canvas?.currentTool = tool
        }
    }

    @objc private func colorClicked(_ sender: NSButton) {
        for (i, b) in colorButtons.enumerated() {
            b.layer?.borderWidth = (b === sender) ? 2 : 0
            b.layer?.borderColor = NSColor.labelColor.cgColor
            if b === sender, i < colors.count {
                canvas?.currentColor = colors[i]
            }
        }
    }

    @objc private func undoClicked() { canvas?.undo() }

    @objc private func cancelClicked() { window?.close() }

    @objc private func saveDesktopClicked() {
        guard let image = canvas?.flattenedImage() else { return }
        ImageSaver.saveToDesktop(image)
        HistoryStore.shared.add(image)
        window?.close()
    }

    @objc private func copyClicked() {
        guard let image = canvas?.flattenedImage() else { return }
        ImageSaver.copyToClipboard(image)
        HistoryStore.shared.add(image)
        window?.close()
    }

    func windowWillClose(_ notification: Notification) {
        onClose?()
    }
}
