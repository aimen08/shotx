import Cocoa
import Carbon.HIToolbox
import SwiftUI

struct ShortcutRecorder: NSViewRepresentable {
    @Binding var shortcut: Shortcut

    func makeNSView(context: Context) -> ShortcutRecorderView {
        let v = ShortcutRecorderView()
        v.onCapture = { shortcut = $0 }
        return v
    }

    func updateNSView(_ nsView: ShortcutRecorderView, context: Context) {
        nsView.displayShortcut = shortcut
        nsView.needsDisplay = true
    }
}

final class ShortcutRecorderView: NSView {
    var onCapture: ((Shortcut) -> Void)?
    var displayShortcut: Shortcut = .default { didSet { needsDisplay = true } }

    private var isRecording = false {
        didSet {
            needsDisplay = true
            if isRecording { startMonitor() } else { stopMonitor() }
        }
    }
    private var monitor: Any?

    override var acceptsFirstResponder: Bool { true }
    override var isFlipped: Bool { true }
    override var intrinsicContentSize: NSSize { NSSize(width: 160, height: 26) }

    override func resetCursorRects() {
        discardCursorRects()
        addCursorRect(bounds, cursor: .pointingHand)
    }

    override func mouseDown(with event: NSEvent) {
        window?.makeFirstResponder(self)
        isRecording.toggle()
    }

    private func startMonitor() {
        monitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown, .flagsChanged]) { [weak self] event in
            guard let self = self, self.isRecording else { return event }
            if event.type == .keyDown {
                if event.keyCode == UInt16(kVK_Escape) {
                    self.isRecording = false
                    return nil
                }
                let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
                var carbonMods: UInt32 = 0
                if flags.contains(.command) { carbonMods |= UInt32(cmdKey) }
                if flags.contains(.option) { carbonMods |= UInt32(optionKey) }
                if flags.contains(.control) { carbonMods |= UInt32(controlKey) }
                if flags.contains(.shift) { carbonMods |= UInt32(shiftKey) }
                guard carbonMods != 0 else {
                    NSSound.beep()
                    return nil
                }
                let captured = Shortcut(keyCode: UInt32(event.keyCode), modifiers: carbonMods)
                self.displayShortcut = captured
                self.onCapture?(captured)
                self.isRecording = false
                return nil
            }
            return event
        }
    }

    private func stopMonitor() {
        if let m = monitor { NSEvent.removeMonitor(m); monitor = nil }
    }

    deinit { stopMonitor() }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        let path = NSBezierPath(roundedRect: bounds.insetBy(dx: 0.5, dy: 0.5), xRadius: 6, yRadius: 6)
        (isRecording ? NSColor.controlAccentColor.withAlphaComponent(0.15) : NSColor.textBackgroundColor).setFill()
        path.fill()
        (isRecording ? NSColor.controlAccentColor : NSColor.separatorColor).setStroke()
        path.lineWidth = 1
        path.stroke()

        let text = isRecording ? "Press shortcut…" : ShortcutFormatter.describe(displayShortcut)
        let attrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 13, weight: .medium),
            .foregroundColor: isRecording ? NSColor.controlAccentColor : NSColor.labelColor
        ]
        let size = text.size(withAttributes: attrs)
        let origin = NSPoint(x: (bounds.width - size.width) / 2,
                             y: (bounds.height - size.height) / 2)
        text.draw(at: origin, withAttributes: attrs)
    }
}
