import Cocoa
import AVFoundation
import Combine
import SwiftUI

enum VideoThumbnail {
    static func firstFrame(of url: URL) -> NSImage? {
        if url.pathExtension.lowercased() == "gif" {
            return NSImage(contentsOf: url)
        }
        let asset = AVURLAsset(url: url)
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        generator.requestedTimeToleranceBefore = .zero
        generator.requestedTimeToleranceAfter = .zero
        let time = CMTime(seconds: 0.1, preferredTimescale: 600)
        guard let cg = try? generator.copyCGImage(at: time, actualTime: nil) else { return nil }
        return NSImage(cgImage: cg, size: NSSize(width: cg.width, height: cg.height))
    }
}

@MainActor
final class RecordingCompletePopupState: ObservableObject {
    @Published var minimized = false
}

@MainActor
final class RecordingCompletePopupController {
    private var panel: NSPanel?
    private var dismissTimer: Timer?
    private var cancellables = Set<AnyCancellable>()
    let state = RecordingCompletePopupState()

    private static let popupSize = NSSize(width: 250, height: 160)
    private static let minimizedSize = NSSize(width: 250, height: 26)
    private static let autoDismissAfter: TimeInterval = 10.0
    private static let edgeMargin: CGFloat = 20

    func show(tempURL: URL, duration: TimeInterval, dimensions: CGSize) {
        // Reset state for a fresh popup
        state.minimized = false
        cancellables.removeAll()

        let thumbnail = VideoThumbnail.firstFrame(of: tempURL)
        let isGIF = tempURL.pathExtension.lowercased() == "gif"

        let view = RecordingCompleteView(
            fileURL: tempURL,
            thumbnail: thumbnail,
            duration: duration,
            dimensions: dimensions,
            isGIF: isGIF,
            state: state,
            onPlay: {
                NSWorkspace.shared.open(tempURL)
            },
            onSave: { [weak self] in
                guard let self = self else { return }
                self.saveToDesktop(tempURL: tempURL, revealInFinder: true)
                self.dismiss()
            },
            onCopy: { [weak self] in
                guard let self = self else { return }
                self.copyAndSave(tempURL: tempURL)
                self.dismiss()
            },
            onReveal: { [weak self] in
                NSWorkspace.shared.activateFileViewerSelecting([tempURL])
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

    // MARK: - Actions

    @discardableResult
    private func saveToDesktop(tempURL: URL, revealInFinder: Bool) -> URL? {
        let dest = Self.desktopDestination(extension: tempURL.pathExtension.lowercased())
        do {
            guard FileManager.default.fileExists(atPath: tempURL.path) else { return nil }
            try FileManager.default.copyItem(at: tempURL, to: dest)
            if revealInFinder {
                ToastController.shared.show(
                    message: "Recording saved to Desktop",
                    icon: "checkmark.circle.fill",
                    tint: .systemGreen
                )
                NSWorkspace.shared.activateFileViewerSelecting([dest])
            }
            return dest
        } catch {
            ToastController.shared.show(
                message: "Couldn't save recording: \(error.localizedDescription)",
                icon: "exclamationmark.triangle.fill",
                tint: .systemRed
            )
            return nil
        }
    }

    private func copyAndSave(tempURL: URL) {
        guard let dest = saveToDesktop(tempURL: tempURL, revealInFinder: false) else { return }
        let pb = NSPasteboard.general
        pb.clearContents()
        pb.writeObjects([dest as NSURL])
        ToastController.shared.show(
            message: "Recording copied to clipboard",
            icon: "doc.on.doc.fill",
            tint: .systemBlue
        )
    }

    private static func desktopDestination(extension ext: String) -> URL {
        let desktop = FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask).first!
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd 'at' HH.mm.ss"
        let safeExt = ext.isEmpty ? "mp4" : ext
        return desktop.appendingPathComponent("ShotX Recording \(formatter.string(from: Date())).\(safeExt)")
    }
}

// MARK: - View

private struct RecordingCompleteView: View {
    let fileURL: URL
    let thumbnail: NSImage?
    let duration: TimeInterval
    let dimensions: CGSize
    let isGIF: Bool
    @ObservedObject var state: RecordingCompletePopupState
    let onPlay: () -> Void
    let onSave: () -> Void
    let onCopy: () -> Void
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

    // MARK: Expanded

    private var expandedView: some View {
        ZStack {
            thumbnailBackground
                .onDrag { exportProvider() }

            if hovering {
                Color.black.opacity(0.34)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .transition(.opacity)
                    .allowsHitTesting(false)
            } else {
                // Default state: centered play-circle icon (YouTube-style preview)
                Image(systemName: "play.circle.fill")
                    .font(.system(size: 42, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.95))
                    .shadow(color: .black.opacity(0.55), radius: 5, y: 2)
                    .allowsHitTesting(false)
                    .transition(.opacity)

                // Duration / GIF badge in top-right
                VStack {
                    HStack {
                        Spacer()
                        durationBadge
                    }
                    Spacer()
                }
                .padding(8)
                .allowsHitTesting(false)
            }

            // Drag handle at the top
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

    private var thumbnailBackground: some View {
        ZStack {
            Color.black.opacity(0.4)
            if let thumbnail = thumbnail {
                Image(nsImage: thumbnail)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .blur(radius: hovering ? 14 : 0)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private var durationBadge: some View {
        Text(isGIF ? "GIF" : formatDuration(duration))
            .font(.system(size: 10, weight: .heavy, design: .rounded))
            .monospacedDigit()
            .foregroundStyle(.white)
            .padding(.horizontal, 6)
            .padding(.vertical, 2.5)
            .background(
                Capsule().fill(Color.black.opacity(0.7))
            )
            .shadow(color: .black.opacity(0.4), radius: 2, y: 1)
    }

    private var hoverControls: some View {
        ZStack {
            // Center: Copy / Save
            VStack(spacing: 7) {
                CenterButton(label: "Copy", action: onCopy)
                CenterButton(label: "Save", action: onSave)
            }

            // Corners
            VStack {
                HStack {
                    CornerButton(icon: "xmark", action: onDismiss)
                    Spacer()
                }
                Spacer()
                HStack {
                    PlayCornerButton(action: onPlay)
                    Spacer()
                    CornerButton(icon: "folder.fill", action: onReveal)
                }
            }
            .padding(8)
        }
    }

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

    private func exportProvider() -> NSItemProvider {
        if FileManager.default.fileExists(atPath: fileURL.path),
           let provider = NSItemProvider(contentsOf: fileURL) {
            return provider
        }
        return NSItemProvider()
    }

    private func formatDuration(_ t: TimeInterval) -> String {
        let total = Int(t)
        let h = total / 3600
        let m = (total / 60) % 60
        let s = total % 60
        if h > 0 { return String(format: "%d:%02d:%02d", h, m, s) }
        return String(format: "%d:%02d", m, s)
    }

    // MARK: Minimized

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

private struct PlayCornerButton: View {
    let action: () -> Void
    @State private var hovering = false

    var body: some View {
        Button(action: action) {
            Image(systemName: "play.fill")
                .font(.system(size: 10, weight: .black))
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
        .help("Play")
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
