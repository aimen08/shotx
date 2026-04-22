import Cocoa
import SwiftUI

final class PostCapturePopupController {
    private var panel: NSPanel?
    private var dismissTimer: Timer?

    func show(image: NSImage, onEdit: @escaping () -> Void) {
        let view = PostCapturePopupView(
            image: image,
            onSave: { [weak self] in
                ImageSaver.saveToDesktop(image)
                self?.dismiss()
            },
            onEdit: { [weak self] in
                self?.dismiss()
                onEdit()
            },
            onCopy: { [weak self] in
                ImageSaver.copyToClipboard(image)
                self?.dismiss()
            },
            onDismiss: { [weak self] in self?.dismiss() }
        )

        let hosting = NSHostingController(rootView: view)
        hosting.view.frame = NSRect(x: 0, y: 0, width: 300, height: 110)

        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 300, height: 110),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.isFloatingPanel = true
        panel.level = .statusBar
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = true
        panel.contentViewController = hosting
        panel.collectionBehavior = [.canJoinAllSpaces, .transient, .fullScreenAuxiliary]
        panel.becomesKeyOnlyIfNeeded = true

        if let screen = NSScreen.main {
            let margin: CGFloat = 24
            let frame = NSRect(
                x: screen.visibleFrame.minX + margin,
                y: screen.visibleFrame.minY + margin,
                width: 300,
                height: 110
            )
            panel.setFrame(frame, display: true)
        }
        panel.orderFrontRegardless()
        self.panel = panel

        dismissTimer?.invalidate()
        dismissTimer = Timer.scheduledTimer(withTimeInterval: 6.0, repeats: false) { [weak self] _ in
            self?.dismiss()
        }
    }

    func dismiss() {
        dismissTimer?.invalidate()
        dismissTimer = nil
        panel?.orderOut(nil)
        panel = nil
    }
}

struct PostCapturePopupView: View {
    let image: NSImage
    let onSave: () -> Void
    let onEdit: () -> Void
    let onCopy: () -> Void
    let onDismiss: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(nsImage: image)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 80, height: 80)
                .background(Color.black.opacity(0.2))
                .clipShape(RoundedRectangle(cornerRadius: 6))

            VStack(alignment: .leading, spacing: 6) {
                Text("Copied to clipboard")
                    .font(.subheadline).fontWeight(.semibold)
                Text("\(Int(image.size.width)) × \(Int(image.size.height))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                HStack(spacing: 6) {
                    Button(action: onSave) {
                        Label("Save", systemImage: "square.and.arrow.down")
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)

                    Button(action: onEdit) {
                        Label("Edit", systemImage: "pencil.tip")
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                }
            }

            Spacer(minLength: 0)

            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.secondary)
                    .frame(width: 18, height: 18)
                    .background(Color.secondary.opacity(0.15))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
        }
        .padding(12)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(Color.white.opacity(0.1))
        )
    }
}
