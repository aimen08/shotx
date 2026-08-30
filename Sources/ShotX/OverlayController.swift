import Cocoa

final class OverlayController {
    private var windows: [OverlayWindow] = []
    private var completion: ((NSImage?, CGRect?, NSScreen?) -> Void)?
    private var finished = false
    private var cursorHidden = false

    func begin(completion: @escaping (NSImage?, CGRect?, NSScreen?) -> Void) {
        self.completion = completion

        // Hide the system cursor. SelectionView draws a custom crosshair in
        // its own view, so we don't need macOS's cursor machinery at all —
        // which removes every source of cursor-update timing variance.
        NSCursor.hide()
        cursorHidden = true

        for screen in NSScreen.screens {
            let window = OverlayWindow(
                screen: screen,
                onSelect: { [weak self] rectInScreen, screen in
                    self?.finish(with: rectInScreen, screen: screen)
                },
                onCancel: { [weak self] in
                    self?.finish(with: nil, screen: nil)
                }
            )
            windows.append(window)
            window.orderFrontRegardless()
            // Registered after ordering in — that's when AppKit assigns the
            // window number the capture filter needs.
            CaptureExclusions.register(window)
        }

        NSApp.activate(ignoringOtherApps: true)
        windows.first?.makeKey()
    }

    private func finish(with rectInScreen: CGRect?, screen: NSScreen?) {
        guard !finished else { return }
        finished = true

        guard let rect = rectInScreen, let screen = screen else {
            closeWindows()
            completion?(nil, nil, nil)
            return
        }

        // Capture straight through the overlay. `CaptureExclusions` keeps our own
        // windows out of the composite, so there's nothing to hide first and no
        // settle delay to wait out — this used to order the overlay away and
        // then sleep 120 ms before grabbing pixels.
        if let image = ScreenCapture.capture(
            rectInScreenCoords: rect,
            screen: screen,
            requiresChromeExclusion: true
        ) {
            closeWindows()
            completion?(image, rect, screen)
            return
        }

        // Excluding our windows failed, so a capture right now would contain the
        // dimming layer. Take the overlay down and give the window server a
        // moment, the way this always used to work.
        closeWindows()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) { [weak self] in
            let image = ScreenCapture.capture(rectInScreenCoords: rect, screen: screen)
            self?.completion?(image, rect, screen)
        }
    }

    private func closeWindows() {
        if cursorHidden {
            NSCursor.unhide()
            cursorHidden = false
        }
        for w in windows {
            CaptureExclusions.unregister(w)
            w.contentView = nil
            // `orderOut` alone leaves the window in AppKit's list holding on to
            // its view tree; `close()` is what actually lets it go.
            w.close()
        }
        windows.removeAll()
    }

    deinit {
        if cursorHidden {
            NSCursor.unhide()
        }
    }
}
