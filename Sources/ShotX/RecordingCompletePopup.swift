import Cocoa
import AVFoundation
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
final class RecordingCompletePopupController {
    private var panel: NSPanel?
    private var dismissTimer: Timer?

    private static let popupSize = NSSize(width: 360, height: 132)

    func show(tempURL: URL, duration: TimeInterval, dimensions: CGSize) {
        dismiss()

        let thumbnail = VideoThumbnail.firstFrame(of: tempURL)
        let isGIF = tempURL.pathExtension.lowercased() == "gif"
        let view = RecordingCompleteView(
            thumbnail: thumbnail,
            duration: duration,
            dimensions: dimensions,
            isGIF: isGIF,
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
            onDismiss: { [weak self] in
                // File is in history, no need to auto-save.
                self?.dismiss()
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

        if let screen = NSScreen.main {
            let margin: CGFloat = 24
            let frame = NSRect(
                x: screen.visibleFrame.minX + margin,
                y: screen.visibleFrame.minY + margin,
                width: Self.popupSize.width,
                height: Self.popupSize.height
            )
            panel.setFrame(frame, display: true)
        }
        panel.orderFrontRegardless()
        self.panel = panel

        // Auto-dismiss after 15s. The recording is in history, so nothing is lost.
        dismissTimer = Timer.scheduledTimer(withTimeInterval: 15, repeats: false) { [weak self] _ in
            MainActor.assumeIsolated {
                self?.dismiss()
            }
        }
    }

    func dismiss() {
        dismissTimer?.invalidate()
        dismissTimer = nil
        panel?.orderOut(nil)
        panel = nil
    }

    // MARK: - Actions

    @discardableResult
    private func saveToDesktop(tempURL: URL, revealInFinder: Bool) -> URL? {
        let dest = Self.desktopDestination(extension: tempURL.pathExtension.lowercased())
        do {
            guard FileManager.default.fileExists(atPath: tempURL.path) else { return nil }
            // Copy (not move) so the history copy survives.
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
    let thumbnail: NSImage?
    let duration: TimeInterval
    let dimensions: CGSize
    let isGIF: Bool
    let onPlay: () -> Void
    let onSave: () -> Void
    let onCopy: () -> Void
    let onDismiss: () -> Void

    @State private var appeared = false
    @State private var thumbHovering = false

    var body: some View {
        HStack(spacing: 14) {
            thumbnailButton
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 5) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(.green)
                    Text(isGIF ? "GIF ready" : "Recording ready")
                        .font(.system(size: 13, weight: .semibold))
                }
                Text("\(formatDuration(duration)) · \(Int(dimensions.width)) × \(Int(dimensions.height))")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)

                Spacer(minLength: 4)

                HStack(spacing: 6) {
                    ActionChip(icon: "square.and.arrow.down", label: "Save", prominent: false, action: onSave)
                    ActionChip(icon: "doc.on.doc", label: "Copy", prominent: true, action: onCopy)
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
            .help("Dismiss (saves to Desktop silently)")
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
            withAnimation(.spring(response: 0.4, dampingFraction: 0.78)) {
                appeared = true
            }
        }
    }

    private var thumbnailButton: some View {
        Button(action: onPlay) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(
                        LinearGradient(
                            colors: [Color.white.opacity(0.1), Color.black.opacity(0.18)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                if let thumbnail = thumbnail {
                    Image(nsImage: thumbnail)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .padding(4)
                }
                if thumbHovering {
                    Color.black.opacity(0.28)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                Image(systemName: "play.circle.fill")
                    .font(.system(size: thumbHovering ? 32 : 26, weight: .semibold))
                    .foregroundStyle(.white.opacity(thumbHovering ? 1.0 : 0.88))
                    .shadow(color: .black.opacity(0.5), radius: 3, y: 1)
            }
            .frame(width: 96, height: 96)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .strokeBorder(Color.white.opacity(thumbHovering ? 0.4 : 0.18), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.25), radius: 6, y: 2)
        }
        .buttonStyle(.plain)
        .onHover { thumbHovering = $0 }
        .animation(.easeOut(duration: 0.15), value: thumbHovering)
        .help(isGIF ? "Open GIF" : "Play recording")
    }

    private func formatDuration(_ t: TimeInterval) -> String {
        let totalSeconds = Int(t)
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        if minutes >= 60 {
            let hours = minutes / 60
            return String(format: "%d:%02d:%02d", hours, minutes % 60, seconds)
        }
        return String(format: "%d:%02d", minutes, seconds)
    }
}

private struct ActionChip: View {
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
