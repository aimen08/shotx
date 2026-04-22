import Cocoa
import SwiftUI

final class PostCapturePopupController {
    private var panel: NSPanel?
    private var dismissTimer: Timer?

    private static let popupSize = NSSize(width: 340, height: 128)

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
        let size = Self.popupSize
        hosting.view.frame = NSRect(origin: .zero, size: size)

        let panel = NSPanel(
            contentRect: NSRect(origin: .zero, size: size),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.isFloatingPanel = true
        panel.level = .statusBar
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = false
        panel.contentViewController = hosting
        panel.collectionBehavior = [.canJoinAllSpaces, .transient, .fullScreenAuxiliary]
        panel.becomesKeyOnlyIfNeeded = true

        if let screen = NSScreen.main {
            let margin: CGFloat = 24
            let frame = NSRect(
                x: screen.visibleFrame.minX + margin,
                y: screen.visibleFrame.minY + margin,
                width: size.width, height: size.height
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

    @State private var appeared = false

    var body: some View {
        HStack(spacing: 14) {
            thumbnail
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 5) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(.green)
                    Text("Copied to clipboard")
                        .font(.system(size: 13, weight: .semibold))
                }
                Text("\(Int(image.size.width)) × \(Int(image.size.height))")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)

                Spacer(minLength: 4)

                HStack(spacing: 6) {
                    PopupActionButton(icon: "square.and.arrow.down", label: "Save", prominent: false, action: onSave)
                    PopupActionButton(icon: "pencil.tip", label: "Edit", prominent: true, action: onEdit)
                }
            }

            Spacer(minLength: 0)

            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(.secondary)
                    .frame(width: 20, height: 20)
                    .background(Color.primary.opacity(0.08))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            .help("Dismiss")
        }
        .padding(14)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(Color.white.opacity(0.1), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.32), radius: 22, y: 8)
        .scaleEffect(appeared ? 1 : 0.92)
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 14)
        .onAppear {
            withAnimation(.spring(response: 0.42, dampingFraction: 0.78)) {
                appeared = true
            }
        }
    }

    private var thumbnail: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.12),
                            Color.black.opacity(0.18)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            Image(nsImage: image)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .padding(5)
        }
        .frame(width: 96, height: 96)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .strokeBorder(Color.white.opacity(0.18), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.25), radius: 6, y: 2)
    }
}

private struct PopupActionButton: View {
    let icon: String
    let label: String
    let prominent: Bool
    let action: () -> Void
    @State private var hovering = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 10, weight: .bold))
                Text(label)
                    .font(.system(size: 11.5, weight: .semibold))
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .foregroundStyle(prominent ? Color.white : Color.primary)
            .background(
                RoundedRectangle(cornerRadius: 7)
                    .fill(
                        prominent
                            ? Color.accentColor
                            : Color.primary.opacity(hovering ? 0.12 : 0.08)
                    )
            )
        }
        .buttonStyle(.plain)
        .onHover { hovering = $0 }
        .animation(.easeOut(duration: 0.12), value: hovering)
    }
}
