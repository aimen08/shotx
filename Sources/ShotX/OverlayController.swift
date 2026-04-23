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
        }

        NSApp.activate(ignoringOtherApps: true)
        windows.first?.makeKey()
    }

    private func finish(with rectInScreen: CGRect?, screen: NSScreen?) {
        guard !finished else { return }
        finished = true
        closeWindows()

        guard let rect = rectInScreen, let screen = screen else {
            completion?(nil, nil, nil)
            return
        }

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
        for w in windows { w.orderOut(nil) }
        windows.removeAll()
    }

    deinit {
        if cursorHidden {
            NSCursor.unhide()
        }
    }
}
