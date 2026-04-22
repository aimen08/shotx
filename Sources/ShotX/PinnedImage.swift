import Cocoa
import SwiftUI

final class PinnedImageController {
    static let shared = PinnedImageController()

    private var panels: [NSPanel] = []

    func pin(_ image: NSImage) {
        let raw = image.size
        let maxSide: CGFloat = 600
        let minSide: CGFloat = 120
        let scale: CGFloat = {
            let largest = max(raw.width, raw.height)
            if largest > maxSide { return maxSide / largest }
            if largest < minSide { return minSide / largest }
            return 1.0
        }()
        let frameSize = NSSize(width: raw.width * scale, height: raw.height * scale)

        let origin: NSPoint = {
            guard let screen = NSScreen.main else { return .zero }
            let mouse = NSEvent.mouseLocation
            let x = min(
                max(screen.visibleFrame.minX + 16, mouse.x - frameSize.width / 2),
                screen.visibleFrame.maxX - frameSize.width - 16
            )
            let y = min(
                max(screen.visibleFrame.minY + 16, mouse.y - frameSize.height / 2),
                screen.visibleFrame.maxY - frameSize.height - 16
            )
            return NSPoint(x: x, y: y)
        }()

        let panel = NSPanel(
            contentRect: NSRect(origin: origin, size: frameSize),
            styleMask: [.borderless, .nonactivatingPanel, .resizable],
            backing: .buffered,
            defer: false
        )
        panel.isFloatingPanel = true
        panel.level = .floating
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = false
        panel.isMovableByWindowBackground = true
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]

        let view = PinnedImageView(
            image: image,
            onCopy: { ImageSaver.copyToClipboard(image) },
            onSave: { ImageSaver.saveToDesktop(image) },
            onEdit: { [weak self, weak panel] in
                guard let panel = panel else { return }
                self?.close(panel: panel)
                if let delegate = NSApp.delegate as? AppDelegate {
                    delegate.openAnnotator(with: image)
                }
            },
            onClose: { [weak self, weak panel] in
                guard let panel = panel else { return }
                self?.close(panel: panel)
            }
        )
        let hosting = NSHostingController(rootView: view)
        hosting.view.frame = NSRect(origin: .zero, size: frameSize)
        panel.contentViewController = hosting
        panel.orderFrontRegardless()
        panels.append(panel)
    }

    private func close(panel: NSPanel) {
        panel.orderOut(nil)
        panels.removeAll { $0 === panel }
    }

    func closeAll() {
        for p in panels { p.orderOut(nil) }
        panels.removeAll()
    }
}

private struct PinnedImageView: View {
    let image: NSImage
    let onCopy: () -> Void
    let onSave: () -> Void
    let onEdit: () -> Void
    let onClose: () -> Void
    @State private var hovering = false

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Image(nsImage: image)
                .resizable()
                .aspectRatio(contentMode: .fit)

            if hovering {
                HStack(spacing: 6) {
                    PinActionButton(icon: "pencil.tip", tooltip: "Edit", action: onEdit)
                    PinActionButton(icon: "doc.on.doc", tooltip: "Copy", action: onCopy)
                    PinActionButton(icon: "square.and.arrow.down", tooltip: "Save", action: onSave)
                    PinActionButton(icon: "xmark", tooltip: "Unpin", tint: .red, action: onClose)
                }
                .padding(8)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(Color.white.opacity(0.18), lineWidth: 0.5)
        )
        .shadow(color: .black.opacity(0.45), radius: 18, y: 6)
        .onHover { hovering = $0 }
        .animation(.easeOut(duration: 0.15), value: hovering)
    }
}

private struct PinActionButton: View {
    let icon: String
    let tooltip: String
    var tint: Color? = nil
    let action: () -> Void
    @State private var hovering = false

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 28, height: 28)
                .background(
                    Circle()
                        .fill(hovering ? (tint ?? Color.accentColor) : Color.black.opacity(0.62))
                )
                .overlay(
                    Circle()
                        .strokeBorder(Color.white.opacity(0.2), lineWidth: 0.5)
                )
                .shadow(color: .black.opacity(0.4), radius: 3, y: 1)
        }
        .buttonStyle(.plain)
        .help(tooltip)
        .onHover { hovering = $0 }
        .animation(.easeOut(duration: 0.1), value: hovering)
    }
}
