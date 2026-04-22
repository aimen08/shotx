import Cocoa
import Combine
import SwiftUI

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
        case text(origin: CGPoint, string: String, fontSize: CGFloat)
        case step(center: CGPoint, number: Int)
    }
    let id = UUID()
    var shape: Shape
    var color: NSColor
    var thickness: CGFloat
}

enum AnnotationRenderer {
    static func draw(_ ann: Annotation) {
        switch ann.shape {
        case .arrow(let from, let to):
            drawArrow(from: from, to: to, thickness: ann.thickness, color: ann.color)
        case .rectangle(let r):
            drawRectangle(r, thickness: ann.thickness, color: ann.color)
        case .text(let origin, let string, let fontSize):
            drawText(string, at: origin, fontSize: fontSize, color: ann.color)
        case .step(let center, let number):
            drawStep(at: center, number: number, color: ann.color)
        }
    }

    private static func drawArrow(from: CGPoint, to: CGPoint, thickness: CGFloat, color: NSColor) {
        let dx = to.x - from.x
        let dy = to.y - from.y
        let length = hypot(dx, dy)
        guard length > 4 else { return }

        let angle = atan2(dy, dx)
        let shaftWidth = max(4, thickness * 1.6)
        let headLength = max(18, thickness * 5)
        let headWidth = max(22, thickness * 6)

        let effectiveHeadLength = min(headLength, length * 0.65)
        let headRatio = effectiveHeadLength / headLength
        let effectiveHeadWidth = headWidth * headRatio

        let shaftEnd = CGPoint(
            x: to.x - cos(angle) * effectiveHeadLength,
            y: to.y - sin(angle) * effectiveHeadLength
        )
        let px = -sin(angle)
        let py = cos(angle)

        let path = NSBezierPath()
        path.move(to: CGPoint(x: from.x + px * shaftWidth / 2, y: from.y + py * shaftWidth / 2))
        path.line(to: CGPoint(x: shaftEnd.x + px * shaftWidth / 2, y: shaftEnd.y + py * shaftWidth / 2))
        path.line(to: CGPoint(x: shaftEnd.x + px * effectiveHeadWidth / 2, y: shaftEnd.y + py * effectiveHeadWidth / 2))
        path.line(to: to)
        path.line(to: CGPoint(x: shaftEnd.x - px * effectiveHeadWidth / 2, y: shaftEnd.y - py * effectiveHeadWidth / 2))
        path.line(to: CGPoint(x: shaftEnd.x - px * shaftWidth / 2, y: shaftEnd.y - py * shaftWidth / 2))
        path.line(to: CGPoint(x: from.x - px * shaftWidth / 2, y: from.y - py * shaftWidth / 2))
        path.close()

        NSGraphicsContext.saveGraphicsState()
        let shadow = NSShadow()
        shadow.shadowColor = NSColor.black.withAlphaComponent(0.35)
        shadow.shadowBlurRadius = 4
        shadow.shadowOffset = NSSize(width: 0, height: -1)
        shadow.set()
        color.setFill()
        path.fill()
        NSGraphicsContext.restoreGraphicsState()
    }

    private static func drawRectangle(_ rect: CGRect, thickness: CGFloat, color: NSColor) {
        let path = NSBezierPath(roundedRect: rect, xRadius: 3, yRadius: 3)
        path.lineWidth = max(3, thickness)
        path.lineJoinStyle = .round

        NSGraphicsContext.saveGraphicsState()
        let shadow = NSShadow()
        shadow.shadowColor = NSColor.black.withAlphaComponent(0.25)
        shadow.shadowBlurRadius = 3
        shadow.shadowOffset = NSSize(width: 0, height: -1)
        shadow.set()
        color.setStroke()
        path.stroke()
        NSGraphicsContext.restoreGraphicsState()
    }

    private static func drawText(_ string: String, at origin: CGPoint, fontSize: CGFloat, color: NSColor) {
        let font = NSFont.systemFont(ofSize: fontSize, weight: .bold)
        let attrs: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: color,
            .strokeColor: NSColor.white,
            .strokeWidth: -3
        ]

        NSGraphicsContext.saveGraphicsState()
        let shadow = NSShadow()
        shadow.shadowColor = NSColor.black.withAlphaComponent(0.35)
        shadow.shadowBlurRadius = 3
        shadow.shadowOffset = NSSize(width: 0, height: -1)
        shadow.set()
        string.draw(at: origin, withAttributes: attrs)
        NSGraphicsContext.restoreGraphicsState()
    }

    private static func drawStep(at center: CGPoint, number: Int, color: NSColor) {
        let radius: CGFloat = 18
        let rect = NSRect(
            x: center.x - radius, y: center.y - radius,
            width: radius * 2, height: radius * 2
        )

        NSGraphicsContext.saveGraphicsState()
        let shadow = NSShadow()
        shadow.shadowColor = NSColor.black.withAlphaComponent(0.35)
        shadow.shadowBlurRadius = 4
        shadow.shadowOffset = NSSize(width: 0, height: -2)
        shadow.set()
        color.setFill()
        NSBezierPath(ovalIn: rect).fill()
        NSGraphicsContext.restoreGraphicsState()

        NSColor.white.setStroke()
        let outline = NSBezierPath(ovalIn: rect.insetBy(dx: 2, dy: 2))
        outline.lineWidth = 2
        outline.stroke()

        let text = "\(number)"
        let attrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 16, weight: .heavy),
            .foregroundColor: NSColor.white
        ]
        let size = text.size(withAttributes: attrs)
        text.draw(
            at: NSPoint(x: center.x - size.width / 2, y: center.y - size.height / 2),
            withAttributes: attrs
        )
    }
}

final class AnnotationState: ObservableObject {
    @Published var tool: AnnotationTool = .arrow
    @Published var colorIndex: Int = 0

    static let palette: [NSColor] = [
        .systemRed, NSColor(srgbRed: 1.0, green: 0.5, blue: 0.1, alpha: 1),
        .systemYellow, NSColor(srgbRed: 0.2, green: 0.8, blue: 0.4, alpha: 1),
        .systemBlue, NSColor(srgbRed: 0.6, green: 0.3, blue: 0.9, alpha: 1),
        NSColor(white: 0.1, alpha: 1), .white
    ]

    var color: NSColor { AnnotationState.palette[colorIndex] }
}

final class InlineTextEditor: NSView, NSTextFieldDelegate {
    var onCommit: ((String, CGPoint, CGFloat) -> Void)?
    var onCancel: (() -> Void)?

    private let textField = NSTextField()
    private let dragBar = NSView()
    private let resizeHandle = NSView()

    private let handleHeight: CGFloat = 10
    private let padding: CGFloat = 6
    private let cornerSize: CGFloat = 12

    private var currentFontSize: CGFloat
    private let fontSizeMin: CGFloat = 10
    private let fontSizeMax: CGFloat = 120

    private var dragMode: DragMode = .none
    private var dragStart: NSPoint = .zero
    private var initialFrame: NSRect = .zero
    private var initialFontSize: CGFloat = 0

    private var committed = false

    enum DragMode { case none, move, resize }

    init(origin: NSPoint, color: NSColor, fontSize: CGFloat) {
        self.currentFontSize = fontSize
        let initialSize = NSSize(width: 140, height: 50)
        super.init(frame: NSRect(
            x: origin.x - padding,
            y: origin.y - padding,
            width: initialSize.width,
            height: initialSize.height
        ))
        wantsLayer = true
        layer?.cornerRadius = 4
        layer?.borderColor = NSColor.controlAccentColor.cgColor
        layer?.borderWidth = 1.5
        layer?.backgroundColor = NSColor.black.withAlphaComponent(0.05).cgColor

        dragBar.wantsLayer = true
        dragBar.layer?.backgroundColor = NSColor.controlAccentColor.withAlphaComponent(0.85).cgColor
        dragBar.layer?.cornerRadius = 2
        addSubview(dragBar)

        textField.isBezeled = false
        textField.drawsBackground = false
        textField.focusRingType = .none
        textField.font = NSFont.systemFont(ofSize: currentFontSize, weight: .bold)
        textField.textColor = color
        textField.placeholderString = "Text"
        textField.delegate = self
        textField.cell?.wraps = false
        textField.cell?.isScrollable = true
        addSubview(textField)

        resizeHandle.wantsLayer = true
        resizeHandle.layer?.backgroundColor = NSColor.controlAccentColor.cgColor
        resizeHandle.layer?.cornerRadius = cornerSize / 2
        resizeHandle.layer?.borderColor = NSColor.white.cgColor
        resizeHandle.layer?.borderWidth = 1.5
        addSubview(resizeHandle)

        layoutSubviews()
    }

    required init?(coder: NSCoder) { fatalError() }

    override func layout() {
        super.layout()
        layoutSubviews()
    }

    private func layoutSubviews() {
        let barY = bounds.height - handleHeight
        dragBar.frame = NSRect(x: padding, y: barY + 2, width: bounds.width - padding * 2, height: 4)
        textField.frame = NSRect(
            x: padding,
            y: padding,
            width: bounds.width - padding * 2,
            height: bounds.height - handleHeight - padding
        )
        resizeHandle.frame = NSRect(
            x: bounds.width - cornerSize - 2,
            y: 2,
            width: cornerSize,
            height: cornerSize
        )
    }

    override var isFlipped: Bool { false }
    override var acceptsFirstResponder: Bool { false }

    override func resetCursorRects() {
        discardCursorRects()
        addCursorRect(dragBar.frame, cursor: .openHand)
        addCursorRect(resizeHandle.frame, cursor: .crosshair)
    }

    func beginEditing() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self, let window = self.window else { return }
            window.makeFirstResponder(self.textField)
        }
    }

    override func mouseDown(with event: NSEvent) {
        let local = convert(event.locationInWindow, from: nil)
        dragStart = superview?.convert(event.locationInWindow, from: nil) ?? .zero
        initialFrame = frame
        initialFontSize = currentFontSize

        if resizeHandle.frame.insetBy(dx: -4, dy: -4).contains(local) {
            dragMode = .resize
        } else if dragBar.frame.insetBy(dx: -2, dy: -6).contains(local) {
            dragMode = .move
            NSCursor.closedHand.push()
        } else {
            dragMode = .none
            window?.makeFirstResponder(textField)
        }
    }

    override func mouseDragged(with event: NSEvent) {
        guard let superview = superview else { return }
        let current = superview.convert(event.locationInWindow, from: nil)
        let dx = current.x - dragStart.x
        let dy = current.y - dragStart.y

        switch dragMode {
        case .move:
            frame.origin.x = initialFrame.origin.x + dx
            frame.origin.y = initialFrame.origin.y + dy
        case .resize:
            let delta = (dx + dy) * 0.3
            currentFontSize = max(fontSizeMin, min(fontSizeMax, initialFontSize + delta))
            textField.font = NSFont.systemFont(ofSize: currentFontSize, weight: .bold)
            autoSize(preserveOrigin: true)
        case .none:
            break
        }
    }

    override func mouseUp(with event: NSEvent) {
        if dragMode == .move { NSCursor.pop() }
        dragMode = .none
    }

    private func autoSize(preserveOrigin: Bool = true) {
        let text = textField.stringValue.isEmpty ? "Text" : textField.stringValue
        let attrs: [NSAttributedString.Key: Any] = [.font: textField.font as Any]
        let size = text.size(withAttributes: attrs)
        let newW = max(size.width + padding * 2 + 16, 80)
        let newH = max(size.height + handleHeight + padding + 4, 40)
        let originalOrigin = frame.origin
        frame = NSRect(x: originalOrigin.x, y: originalOrigin.y, width: newW, height: newH)
    }

    // MARK: - NSTextFieldDelegate

    func controlTextDidChange(_ obj: Notification) {
        autoSize()
    }

    func control(_ control: NSControl, textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
        if commandSelector == #selector(NSResponder.cancelOperation(_:)) {
            cancel()
            return true
        }
        if commandSelector == #selector(NSResponder.insertNewline(_:)) {
            commit()
            return true
        }
        return false
    }

    func commit() {
        guard !committed else { return }
        committed = true
        let text = textField.stringValue
        if text.isEmpty {
            onCancel?()
        } else {
            // Bottom-left of the text area (matches where we render the annotation).
            let origin = NSPoint(
                x: frame.origin.x + padding + 2,
                y: frame.origin.y + padding
            )
            onCommit?(text, origin, currentFontSize)
        }
    }

    func cancel() {
        guard !committed else { return }
        committed = true
        onCancel?()
    }

    func updateColor(_ color: NSColor) {
        textField.textColor = color
    }
}

final class AnnotationCanvas: NSView {
    var image: NSImage? {
        didSet {
            if let img = image { setFrameSize(img.size) }
            needsDisplay = true
        }
    }
    var annotations: [Annotation] = [] { didSet { needsDisplay = true } }
    var currentTool: AnnotationTool = .arrow { didSet { resetCursorRects() } }
    var currentColor: NSColor = .systemRed {
        didSet { activeTextEditor?.updateColor(currentColor) }
    }
    var thickness: CGFloat = 5

    var onAnnotationsChanged: (([Annotation]) -> Void)?

    private var inProgress: Annotation?
    private var dragStart: NSPoint?
    private var nextStep: Int = 1
    private var activeTextEditor: InlineTextEditor?

    override var isFlipped: Bool { false }
    override var acceptsFirstResponder: Bool { true }

    override func resetCursorRects() {
        discardCursorRects()
        let cursor: NSCursor = (currentTool == .text) ? .iBeam : .crosshair
        addCursorRect(bounds, cursor: cursor)
    }

    override func mouseDown(with event: NSEvent) {
        // If an editor is open, clicking outside commits it and swallows the click.
        if let editor = activeTextEditor {
            let p = convert(event.locationInWindow, from: nil)
            if !editor.frame.contains(p) {
                editor.commit()
                return
            }
        }

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
            startTextEditor(at: p)
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

    func commitActiveTextEditor() {
        activeTextEditor?.commit()
    }

    private func startTextEditor(at point: NSPoint) {
        activeTextEditor?.commit()
        let editor = InlineTextEditor(origin: point, color: currentColor, fontSize: 24)
        editor.onCommit = { [weak self] text, origin, fontSize in
            guard let self = self else { return }
            let ann = Annotation(
                shape: .text(origin: origin, string: text, fontSize: fontSize),
                color: self.currentColor,
                thickness: self.thickness
            )
            self.annotations.append(ann)
            self.onAnnotationsChanged?(self.annotations)
            self.activeTextEditor?.removeFromSuperview()
            self.activeTextEditor = nil
            self.needsDisplay = true
        }
        editor.onCancel = { [weak self] in
            self?.activeTextEditor?.removeFromSuperview()
            self?.activeTextEditor = nil
            self?.needsDisplay = true
        }
        addSubview(editor)
        activeTextEditor = editor
        editor.beginEditing()
    }

    override func draw(_ dirtyRect: NSRect) {
        NSColor.windowBackgroundColor.setFill()
        bounds.fill()
        image?.draw(in: bounds)
        for ann in annotations { AnnotationRenderer.draw(ann) }
        if let in_ = inProgress { AnnotationRenderer.draw(in_) }
    }

    func flattenedImage() -> NSImage? {
        commitActiveTextEditor()

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
        for ann in annotations { AnnotationRenderer.draw(ann) }
        NSGraphicsContext.restoreGraphicsState()

        guard let output = ctx.makeImage() else { return nil }
        return NSImage(cgImage: output, size: image.size)
    }
}

struct AnnotationToolbar: View {
    @ObservedObject var state: AnnotationState
    let onUndo: () -> Void
    let onCancel: () -> Void
    let onSave: () -> Void
    let onCopy: () -> Void

    var body: some View {
        HStack(spacing: 14) {
            toolGroup
            colorGroup
            Spacer(minLength: 8)
            undoButton
            Divider().frame(height: 20)
            Button("Cancel", action: onCancel)
                .buttonStyle(SlickButtonStyle(prominent: false))
                .fixedSize()
            Button(action: onSave) {
                Label("Save", systemImage: "square.and.arrow.down")
                    .lineLimit(1)
            }
            .buttonStyle(SlickButtonStyle(prominent: false))
            .fixedSize()
            Button(action: onCopy) {
                Label("Copy", systemImage: "doc.on.doc")
                    .lineLimit(1)
            }
            .buttonStyle(SlickButtonStyle(prominent: true))
            .fixedSize()
            .keyboardShortcut(.defaultAction)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity)
        .background(.ultraThinMaterial)
        .overlay(alignment: .bottom) {
            Divider()
        }
    }

    private var toolGroup: some View {
        HStack(spacing: 3) {
            ForEach(AnnotationTool.allCases) { tool in
                ToolChip(
                    systemName: tool.symbolName,
                    isSelected: state.tool == tool,
                    tooltip: tool.label
                ) {
                    state.tool = tool
                }
            }
        }
        .padding(4)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.primary.opacity(0.06))
        )
        .fixedSize()
    }

    private var colorGroup: some View {
        HStack(spacing: 7) {
            ForEach(AnnotationState.palette.indices, id: \.self) { idx in
                ColorDot(
                    color: Color(nsColor: AnnotationState.palette[idx]),
                    isSelected: state.colorIndex == idx
                ) {
                    state.colorIndex = idx
                }
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.primary.opacity(0.06))
        )
        .fixedSize()
    }

    private var undoButton: some View {
        Button(action: onUndo) {
            Image(systemName: "arrow.uturn.backward")
                .font(.system(size: 13, weight: .semibold))
                .frame(width: 30, height: 26)
        }
        .buttonStyle(SlickButtonStyle(prominent: false))
        .keyboardShortcut("z", modifiers: .command)
        .help("Undo (⌘Z)")
        .fixedSize()
    }
}

private struct ToolChip: View {
    let systemName: String
    let isSelected: Bool
    let tooltip: String
    let action: () -> Void
    @State private var hovering = false

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 14, weight: .semibold))
                .frame(width: 34, height: 28)
                .foregroundStyle(isSelected ? Color.white : Color.primary.opacity(0.85))
                .background(
                    RoundedRectangle(cornerRadius: 7)
                        .fill(isSelected ? Color.accentColor : (hovering ? Color.primary.opacity(0.08) : .clear))
                )
        }
        .buttonStyle(.plain)
        .onHover { hovering = $0 }
        .help(tooltip)
        .animation(.easeOut(duration: 0.12), value: isSelected)
    }
}

private struct ColorDot: View {
    let color: Color
    let isSelected: Bool
    let action: () -> Void
    @State private var hovering = false

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .strokeBorder(Color.accentColor, lineWidth: isSelected ? 2.5 : 0)
                    .frame(width: 24, height: 24)
                Circle()
                    .fill(color)
                    .frame(width: isSelected ? 16 : 18, height: isSelected ? 16 : 18)
                    .overlay(
                        Circle()
                            .strokeBorder(Color.primary.opacity(0.15), lineWidth: 0.5)
                    )
                    .scaleEffect(hovering && !isSelected ? 1.1 : 1.0)
            }
        }
        .buttonStyle(.plain)
        .onHover { hovering = $0 }
        .animation(.spring(response: 0.25, dampingFraction: 0.7), value: isSelected)
        .animation(.easeOut(duration: 0.12), value: hovering)
    }
}

struct SlickButtonStyle: ButtonStyle {
    let prominent: Bool
    @State private var hovering = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 12.5, weight: .semibold))
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .foregroundStyle(prominent ? Color.white : Color.primary)
            .background(
                RoundedRectangle(cornerRadius: 7)
                    .fill(
                        prominent
                            ? Color.accentColor.opacity(configuration.isPressed ? 0.8 : 1.0)
                            : Color.primary.opacity(configuration.isPressed ? 0.15 : (hovering ? 0.1 : 0.06))
                    )
            )
            .onHover { hovering = $0 }
            .animation(.easeOut(duration: 0.12), value: hovering)
    }
}

final class CenteringClipView: NSClipView {
    override func constrainBoundsRect(_ proposedBounds: NSRect) -> NSRect {
        var rect = super.constrainBoundsRect(proposedBounds)
        guard let docView = documentView else { return rect }
        if rect.width > docView.frame.width {
            rect.origin.x = (docView.frame.width - rect.width) / 2
        }
        if rect.height > docView.frame.height {
            rect.origin.y = (docView.frame.height - rect.height) / 2
        }
        return rect
    }
}

final class AnnotationWindowController: NSObject, NSWindowDelegate {
    private var window: NSWindow?
    private var canvas: AnnotationCanvas?
    private var onClose: (() -> Void)?

    private let state = AnnotationState()
    private var cancellables = Set<AnyCancellable>()

    func open(image: NSImage, onClose: @escaping () -> Void) {
        self.onClose = onClose

        let canvas = AnnotationCanvas()
        canvas.image = image
        canvas.currentTool = state.tool
        canvas.currentColor = state.color
        self.canvas = canvas

        state.$tool
            .sink { [weak canvas] in canvas?.currentTool = $0 }
            .store(in: &cancellables)
        state.$colorIndex
            .sink { [weak canvas] idx in
                canvas?.currentColor = AnnotationState.palette[idx]
            }
            .store(in: &cancellables)

        let scroll = NSScrollView()
        scroll.hasVerticalScroller = true
        scroll.hasHorizontalScroller = true
        scroll.autohidesScrollers = true
        scroll.borderType = .noBorder
        scroll.drawsBackground = true
        scroll.backgroundColor = NSColor(white: 0.11, alpha: 1)

        let centering = CenteringClipView(frame: scroll.contentView.bounds)
        centering.drawsBackground = true
        centering.backgroundColor = NSColor(white: 0.11, alpha: 1)
        scroll.contentView = centering

        scroll.documentView = canvas
        scroll.translatesAutoresizingMaskIntoConstraints = false

        let toolbarView = AnnotationToolbar(
            state: state,
            onUndo: { [weak self] in self?.canvas?.undo() },
            onCancel: { [weak self] in self?.window?.close() },
            onSave: { [weak self] in self?.saveToDesktop() },
            onCopy: { [weak self] in self?.copyToClipboard() }
        )
        let hosting = NSHostingView(rootView: toolbarView)
        hosting.translatesAutoresizingMaskIntoConstraints = false

        let container = NSView()
        container.addSubview(hosting)
        container.addSubview(scroll)
        NSLayoutConstraint.activate([
            hosting.topAnchor.constraint(equalTo: container.topAnchor),
            hosting.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            hosting.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            scroll.topAnchor.constraint(equalTo: hosting.bottomAnchor),
            scroll.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            scroll.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            scroll.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])

        let horizontalPadding: CGFloat = 200
        let verticalPadding: CGFloat = 220
        let contentW = min(max(image.size.width + horizontalPadding, 920), 1400)
        let contentH = min(max(image.size.height + verticalPadding, 560), 960)
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: contentW, height: contentH),
            styleMask: [.titled, .closable, .resizable, .miniaturizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        window.title = "Annotate"
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        window.contentMinSize = NSSize(width: 880, height: 400)
        window.contentView = container
        window.delegate = self
        window.isReleasedWhenClosed = false
        window.center()
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        self.window = window
    }

    private func saveToDesktop() {
        guard let image = canvas?.flattenedImage() else { return }
        ImageSaver.saveToDesktop(image)
        HistoryStore.shared.add(image)
        window?.close()
    }

    private func copyToClipboard() {
        guard let image = canvas?.flattenedImage() else { return }
        ImageSaver.copyToClipboard(image)
        HistoryStore.shared.add(image)
        window?.close()
    }

    func windowWillClose(_ notification: Notification) {
        onClose?()
    }
}
