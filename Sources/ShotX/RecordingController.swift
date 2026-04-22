import Cocoa
import SwiftUI

@MainActor
final class RecordingController {
    static let shared = RecordingController()

    private var overlayController: OverlayController?
    private var optionsPanel: NSPanel?
    private var optionsOutsideMonitor: Any?

    private var stopPanel: NSPanel?
    private var stopState = RecordingStopState()
    private var elapsedTimer: Timer?
    private var startDate: Date?

    private var recorder: AnyObject?
    private var completePopup = RecordingCompletePopupController()
    private var frameOverlay = RecordingFrameOverlay()

    private var currentRect: CGRect?

    private enum RecordingMode { case video, gif }
    private var pendingMode: RecordingMode = .video

    private(set) var isRecording = false

    // MARK: - Flow

    func startRecordingFlow() {
        guard !isRecording, overlayController == nil, optionsPanel == nil else { return }

        let overlay = OverlayController()
        overlayController = overlay
        overlay.begin { [weak self] _, rect, screen in
            self?.overlayController = nil
            guard let rect = rect, let screen = screen else { return }
            self?.currentRect = rect
            self?.frameOverlay.show(rect: rect, recording: false)
            self?.showOptions(rect: rect, screen: screen)
        }
    }

    // MARK: - Options panel

    private func showOptions(rect: CGRect, screen: NSScreen) {
        let view = RecordingOptionsView(
            dimensions: rect.size,
            onRecordVideo: { [weak self] options in
                self?.pendingMode = .video
                self?.tearDownOptionsPanel()
                self?.frameOverlay.setRecording(true)
                self?.beginRecording(rect: rect, screen: screen, options: options)
            },
            onRecordGIF: { [weak self] options in
                self?.pendingMode = .gif
                self?.tearDownOptionsPanel()
                self?.frameOverlay.setRecording(true)
                self?.beginRecording(rect: rect, screen: screen, options: options)
            },
            onCancel: { [weak self] in self?.cancelOptions() }
        )

        let hosting = NSHostingController(rootView: view)
        hosting.view.layer?.backgroundColor = NSColor.clear.cgColor

        let size = NSSize(width: 380, height: 170)
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

        let origin = Self.positionBottomCenter(size: size, screen: screen)
        panel.setFrame(NSRect(origin: origin, size: size), display: true)
        panel.orderFrontRegardless()
        optionsPanel = panel

        optionsOutsideMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            self?.handleOutsideClick(at: NSEvent.mouseLocation)
        }
    }

    private func handleOutsideClick(at point: NSPoint) {
        // Don't dismiss if user is interacting with the recording region.
        if let rect = currentRect, rect.contains(point) {
            return
        }
        cancelOptions()
    }

    private func cancelOptions() {
        tearDownOptionsPanel()
        frameOverlay.dismiss()
        currentRect = nil
    }

    private func tearDownOptionsPanel() {
        if let monitor = optionsOutsideMonitor {
            NSEvent.removeMonitor(monitor)
            optionsOutsideMonitor = nil
        }
        optionsPanel?.orderOut(nil)
        optionsPanel = nil
    }

    // MARK: - Recording

    private func beginRecording(rect: CGRect, screen: NSScreen, options: RecordingOptions) {
        guard #available(macOS 13.0, *) else {
            ToastController.shared.show(
                message: "Screen recording requires macOS 13 or later",
                icon: "exclamationmark.triangle.fill",
                tint: .systemOrange
            )
            return
        }

        let url = Self.temporaryMP4URL()
        let recorder = ScreenRecorder(outputURL: url)
        self.recorder = recorder
        recorder.onError = { [weak self] error in
            DispatchQueue.main.async {
                self?.failRecording(error: error)
            }
        }

        Task { [weak self] in
            do {
                try await recorder.start(rect: rect, screen: screen, showsCursor: options.showCursor)
                guard let self = self else { return }
                self.isRecording = true
                self.startDate = Date()
                self.showStopPill()
            } catch {
                guard let self = self else { return }
                self.recorder = nil
                self.failRecording(error: error)
            }
        }
    }

    func stopRecording() {
        guard isRecording, #available(macOS 13.0, *), let recorder = recorder as? ScreenRecorder else { return }
        isRecording = false

        let duration = startDate.map { Date().timeIntervalSince($0) } ?? 0
        let dimensions = currentRect?.size ?? .zero

        Task { [weak self] in
            let maybeURL = await recorder.stop()
            guard let self = self else { return }
            self.recorder = nil
            self.dismissStopPill()
            self.frameOverlay.dismiss()
            self.currentRect = nil
            self.handleFinished(tempURL: maybeURL, duration: duration, dimensions: dimensions)
        }
    }

    private func failRecording(error: Error) {
        isRecording = false
        dismissStopPill()
        frameOverlay.dismiss()
        currentRect = nil
        recorder = nil
        ToastController.shared.show(
            message: (error as? LocalizedError)?.errorDescription ?? error.localizedDescription,
            icon: "exclamationmark.triangle.fill",
            tint: .systemRed
        )
    }

    private func handleFinished(tempURL: URL?, duration: TimeInterval, dimensions: CGSize) {
        guard let tempURL = tempURL else {
            ToastController.shared.show(
                message: "Recording didn't finish cleanly",
                icon: "exclamationmark.triangle.fill",
                tint: .systemOrange
            )
            return
        }
        if pendingMode == .gif {
            convertAndPresentGIF(videoURL: tempURL, duration: duration, dimensions: dimensions)
        } else {
            let url = HistoryStore.shared.add(videoAt: tempURL, duration: duration, dimensions: dimensions)
                .map { HistoryStore.shared.fileURL(for: $0) } ?? tempURL
            completePopup.show(tempURL: url, duration: duration, dimensions: dimensions)
        }
    }

    private func convertAndPresentGIF(videoURL: URL, duration: TimeInterval, dimensions: CGSize) {
        ToastController.shared.show(
            message: "Converting to GIF…",
            icon: "circle.dashed",
            tint: .systemBlue,
            duration: 120
        )

        let gifURL = videoURL.deletingPathExtension().appendingPathExtension("gif")

        Task { [weak self] in
            do {
                try await GIFConverter.convert(
                    videoURL: videoURL,
                    outputURL: gifURL,
                    fps: 12,
                    maxDimension: 720
                )
                try? FileManager.default.removeItem(at: videoURL)
                guard let self = self else { return }
                ToastController.shared.dismiss()
                let url = HistoryStore.shared.add(gifAt: gifURL, duration: duration, dimensions: dimensions)
                    .map { HistoryStore.shared.fileURL(for: $0) } ?? gifURL
                self.completePopup.show(tempURL: url, duration: duration, dimensions: dimensions)
            } catch {
                ToastController.shared.dismiss()
                ToastController.shared.show(
                    message: (error as? LocalizedError)?.errorDescription ?? error.localizedDescription,
                    icon: "exclamationmark.triangle.fill",
                    tint: .systemRed
                )
            }
        }
    }

    // MARK: - Stop pill

    private func showStopPill() {
        dismissStopPill()

        stopState = RecordingStopState()
        let view = RecordingStopView(state: stopState, onStop: { [weak self] in
            self?.stopRecording()
        })
        let hosting = NSHostingController(rootView: view)
        let size = NSSize(width: 240, height: 46)
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
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]

        if let screen = NSScreen.main {
            let vf = screen.visibleFrame
            let frame = NSRect(
                x: vf.midX - size.width / 2,
                y: vf.maxY - size.height - 10,
                width: size.width,
                height: size.height
            )
            panel.setFrame(frame, display: true)
        }
        panel.orderFrontRegardless()
        stopPanel = panel

        startDate = Date()
        elapsedTimer?.invalidate()
        elapsedTimer = Timer.scheduledTimer(withTimeInterval: 0.25, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated {
                guard let self = self, let start = self.startDate else { return }
                self.stopState.elapsed = Date().timeIntervalSince(start)
            }
        }
    }

    private func dismissStopPill() {
        elapsedTimer?.invalidate()
        elapsedTimer = nil
        startDate = nil
        stopPanel?.orderOut(nil)
        stopPanel = nil
    }

    // MARK: - Helpers

    private static func temporaryMP4URL() -> URL {
        let dir = FileManager.default.temporaryDirectory
        return dir.appendingPathComponent("shotx-\(UUID().uuidString).mp4")
    }

    private static func positionBottomCenter(size: NSSize, screen: NSScreen) -> NSPoint {
        let vf = screen.visibleFrame
        let liftAboveBottom: CGFloat = 80
        let x = vf.midX - size.width / 2
        let y = vf.minY + liftAboveBottom
        return NSPoint(x: x, y: y)
    }
}
