import Cocoa

final class OverlayController {
    private var windows: [OverlayWindow] = []
    private var completion: ((NSImage?, CGRect?, NSScreen?) -> Void)?
    private var finished = false
    private var cursorPushed = false

    func begin(completion: @escaping (NSImage?, CGRect?, NSScreen?) -> Void) {
        self.completion = completion

        // Order windows on screen FIRST (no activation required for orderFrontRegardless).
        // For an .accessory app, NSApp.activate can take a beat — doing it before
        // showing windows produces a noticeable delay between shortcut press and overlay.
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
            // Re-apply the crosshair exactly when the window becomes key —
            // catches the case where activation happens after our initial
            // cursor attempts.
            NotificationCenter.default.addObserver(
                forName: NSWindow.didBecomeKeyNotification,
                object: window,
                queue: .main
            ) { _ in
                NSCursor.crosshair.set()
            }
            windows.append(window)
            window.orderFrontRegardless()
        }

        // Then bring the app forward and make one window key for keyboard input.
        NSApp.activate(ignoringOtherApps: true)
        windows.first?.makeKey()

        // Cursor rects only activate on the key window, and across multiple
        // screens only one window is key. Push the crosshair globally so it
        // shows immediately on every screen without requiring a click.
        NSCursor.crosshair.push()
        cursorPushed = true

        // Set the cursor explicitly too; push() sets current on the stack but
        // WindowServer tracks separately based on the last real mouse event.
        NSCursor.crosshair.set()

        // Decouple-and-warp: detach the on-screen cursor from physical mouse
        // motion, warp it to its current position, re-attach. This forces
        // WindowServer to fully re-evaluate which cursor should be displayed
        // without any visible jitter. More reliable than synthesised events,
        // which can be dropped by the event tap machinery.
        DispatchQueue.main.async {
            guard let primary = NSScreen.screens.first else { return }
            let loc = NSEvent.mouseLocation
            let cgPoint = CGPoint(x: loc.x, y: primary.frame.height - loc.y)

            CGAssociateMouseAndMouseCursorPosition(0)
            CGWarpMouseCursorPosition(cgPoint)
            CGAssociateMouseAndMouseCursorPosition(1)

            NSCursor.crosshair.set()
        }

        // Aggressive retry: set the cursor on multiple upcoming frames to
        // cover any timing where the overlay window hadn't become key yet
        // when the earlier calls happened.
        for delay in [0.016, 0.033, 0.05, 0.1] {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                NSCursor.crosshair.set()
            }
        }
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
        if cursorPushed {
            NSCursor.pop()
            cursorPushed = false
        }
        for w in windows {
            NotificationCenter.default.removeObserver(self, name: NSWindow.didBecomeKeyNotification, object: w)
            w.orderOut(nil)
        }
        windows.removeAll()
    }
}
