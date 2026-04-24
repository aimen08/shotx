import Cocoa
import Combine
import SwiftUI

@MainActor
final class PostCapturePopupState: ObservableObject {
    @Published var minimized = false
}

@MainActor
final class PostCapturePopupController {
    private var panel: NSPanel?
    private var dismissTimer: Timer?
    private var cancellables = Set<AnyCancellable>()
    let state = PostCapturePopupState()

    private static let popupSize = NSSize(width: 250, height: 160)
    private static let minimizedSize = NSSize(width: 250, height: 26)
    private static let autoDismissAfter: TimeInterval = 6.0
    private static let edgeMargin: CGFloat = 20

    func show(image: NSImage, fileURL: URL?, onEdit: @escaping () -> Void) {
        // Reset state for fresh popup
        state.minimized = false
        cancellables.removeAll()

        let view = PostCapturePopupView(
            image: image,
            fileURL: fileURL,
            state: state,
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
            onPin: { [weak self] in
                PinnedImageController.shared.pin(image)
                self?.dismiss()
            },
            onReveal: { [weak self] in
                if let url = fileURL {
                    NSWorkspace.shared.activateFileViewerSelecting([url])
                }
                self?.dismiss()
            },
            onDismiss: { [weak self] in self?.dismiss() },
            onHoverChanged: { [weak self] hovering in
                if hovering {
                    self?.cancelAutoDismiss()
                } else {
                    self?.scheduleAutoDismiss()
                }
            }
        )

        let hosting = NSHostingController(rootView: view)
        hosting.view.frame = NSRect(origin: .zero, size: Self.popupSize)

        let panel = NSPanel(
            contentRect: NSRect(origin: .zero, size: Self.popupSize),
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
            let frame = NSRect(
                x: screen.visibleFrame.minX + Self.edgeMargin,
                y: screen.visibleFrame.minY + Self.edgeMargin,
                width: Self.popupSize.width,
                height: Self.popupSize.height
            )
            panel.setFrame(frame, display: true)
        }
        panel.orderFrontRegardless()
        self.panel = panel

        // Resize the panel when the popup minimizes / expands
        state.$minimized
            .dropFirst()
            .sink { [weak self] minimized in
                self?.updatePanelSize(minimized: minimized)
            }
            .store(in: &cancellables)

        scheduleAutoDismiss()
    }

    private func updatePanelSize(minimized: Bool) {
        guard let panel = panel, let screen = NSScreen.main else { return }
        let size = minimized ? Self.minimizedSize : Self.popupSize
        let frame = NSRect(
            x: screen.visibleFrame.minX + Self.edgeMargin,
            y: screen.visibleFrame.minY + Self.edgeMargin,
            width: size.width,
            height: size.height
        )
        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = 0.28
            ctx.allowsImplicitAnimation = true
            panel.animator().setFrame(frame, display: true)
        }
    }

    func dismiss() {
        cancelAutoDismiss()
        cancellables.removeAll()
        panel?.orderOut(nil)
        panel = nil
    }

    private func scheduleAutoDismiss() {
        cancelAutoDismiss()
        dismissTimer = Timer.scheduledTimer(withTimeInterval: Self.autoDismissAfter, repeats: false) { [weak self] _ in
            MainActor.assumeIsolated { self?.dismiss() }
        }
    }

    private func cancelAutoDismiss() {
        dismissTimer?.invalidate()
        dismissTimer = nil
    }
}

struct PostCapturePopupView: View {
    let image: NSImage
    let fileURL: URL?
    @ObservedObject var state: PostCapturePopupState
    let onSave: () -> Void
    let onEdit: () -> Void
    let onCopy: () -> Void
    let onPin: () -> Void
    let onReveal: () -> Void
    let onDismiss: () -> Void
    let onHoverChanged: (Bool) -> Void

    @State private var appeared = false
    @State private var hovering = false
    @State private var dragY: CGFloat = 0

    var body: some View {
        Group {
            if state.minimized {
                minimizedView
            } else {
                expandedView
            }
        }
        .animation(.spring(response: 0.32, dampingFraction: 0.78), value: state.minimized)
        .scaleEffect(appeared ? 1 : 0.92)
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 14)
        .onAppear {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.78)) {
                appeared = true
            }
        }
    }

    // MARK: - Expanded

    private var expandedView: some View {
        ZStack {
            // Image area — supports drag-out to other apps + double-click to edit
            ZStack {
                Color.black.opacity(0.4)
                Image(nsImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .blur(radius: hovering ? 14 : 0)
            }
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .onDrag { exportProvider() }
            .onTapGesture(count: 2) { onEdit() }

            if hovering {
                Color.black.opacity(0.32)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .transition(.opacity)
                    .allowsHitTesting(false)
            }

            // Top strip — visible handle + minimize drag gesture
            VStack {
                ZStack {
                    Color.clear
                    Capsule()
                        .fill(Color.white.opacity(hovering ? 0.7 : 0.55))
                        .frame(width: 36, height: 4)
                        .shadow(color: .black.opacity(0.5), radius: 2, y: 1)
                }
                .frame(height: 22)
                .contentShape(Rectangle())
                .gesture(minimizeDragGesture)
                Spacer()
            }

            if hovering {
                hoverControls.transition(.opacity)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(Color.white.opacity(0.1), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.32), radius: 18, y: 6)
        .offset(y: dragY)
        .onHover { value in
            hovering = value
            onHoverChanged(value)
        }
        .animation(.easeOut(duration: 0.18), value: hovering)
    }

    private func exportProvider() -> NSItemProvider {
        if let url = fileURL, FileManager.default.fileExists(atPath: url.path),
           let provider = NSItemProvider(contentsOf: url) {
            return provider
        }
        // Fallback: register PNG data directly
        let provider = NSItemProvider()
        if let tiff = image.tiffRepresentation,
           let bitmap = NSBitmapImageRep(data: tiff),
           let png = bitmap.representation(using: .png, properties: [:]) {
            provider.registerDataRepresentation(forTypeIdentifier: "public.png", visibility: .all) { completion in
                completion(png, nil)
                return nil
            }
        }
        return provider
    }

    private var hoverControls: some View {
        ZStack {
            // Center: Copy / Save
            VStack(spacing: 7) {
                centerButton(label: "Copy", action: onCopy)
                centerButton(label: "Save", action: onSave)
            }

            // Corners
            VStack {
                HStack {
                    cornerButton(icon: "xmark", action: onDismiss)
                    Spacer()
                    cornerButton(icon: "pin.fill", action: onPin)
                }
                Spacer()
                HStack {
                    EditCornerButton(action: onEdit)
                    Spacer()
                    cornerButton(icon: "folder.fill", action: onReveal)
                }
            }
            .padding(8)
        }
    }

    private func cornerButton(icon: String, action: @escaping () -> Void) -> some View {
        CornerButton(icon: icon, action: action)
    }

    private func centerButton(label: String, action: @escaping () -> Void) -> some View {
        CenterButton(label: label, action: action)
    }

    // MARK: - Minimized

    private var minimizedView: some View {
        Button {
            state.minimized = false
        } label: {
            ZStack {
                Capsule()
                    .fill(Color.white.opacity(0.65))
                    .frame(width: 48, height: 4)
                    .shadow(color: .black.opacity(0.5), radius: 2, y: 1)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 13))
            .overlay(
                RoundedRectangle(cornerRadius: 13)
                    .strokeBorder(Color.white.opacity(0.12), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.32), radius: 14, y: 4)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .help("Tap to expand")
    }

    // MARK: - Minimize-by-drag (handle area only)

    private var minimizeDragGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                dragY = max(0, value.translation.height)
            }
            .onEnded { value in
                if value.translation.height > 24 {
                    dragY = 0
                    state.minimized = true
                } else {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.72)) {
                        dragY = 0
                    }
                }
            }
    }
}

// MARK: - Buttons

private struct CornerButton: View {
    let icon: String
    let action: () -> Void
    @State private var hovering = false

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 26, height: 26)
                .background(
                    Circle()
                        .fill(hovering ? Color.white.opacity(0.32) : Color.black.opacity(0.55))
                )
                .overlay(
                    Circle()
                        .strokeBorder(Color.white.opacity(0.18), lineWidth: 0.5)
                )
                .shadow(color: .black.opacity(0.4), radius: 3, y: 1)
        }
        .buttonStyle(.plain)
        .onHover { hovering = $0 }
        .animation(.easeOut(duration: 0.12), value: hovering)
    }
}

private struct EditCornerButton: View {
    let action: () -> Void
    @State private var hovering = false

    var body: some View {
        Button(action: action) {
            Image(systemName: "square.and.pencil")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 26, height: 26)
                .background(
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.accentColor,
                                    Color.accentColor.opacity(hovering ? 0.95 : 0.78)
                                ],
                                startPoint: .top, endPoint: .bottom
                            )
                        )
                )
                .overlay(
                    Circle()
                        .strokeBorder(Color.white.opacity(0.35), lineWidth: 0.8)
                )
                .shadow(color: Color.accentColor.opacity(0.55), radius: 5, y: 1)
                .scaleEffect(hovering ? 1.1 : 1.0)
        }
        .buttonStyle(.plain)
        .onHover { hovering = $0 }
        .help("Edit")
        .animation(.spring(response: 0.28, dampingFraction: 0.7), value: hovering)
    }
}

private struct CenterButton: View {
    let label: String
    let action: () -> Void
    @State private var hovering = false

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 12.5, weight: .semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 7)
                .background(
                    Capsule()
                        .fill(hovering ? Color.white.opacity(0.32) : Color.white.opacity(0.18))
                )
                .overlay(
                    Capsule()
                        .strokeBorder(Color.white.opacity(0.2), lineWidth: 0.5)
                )
                .shadow(color: .black.opacity(0.4), radius: 4, y: 1)
        }
        .buttonStyle(.plain)
        .onHover { hovering = $0 }
        .animation(.easeOut(duration: 0.12), value: hovering)
    }
}

