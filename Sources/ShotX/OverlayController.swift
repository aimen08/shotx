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

        // Without a real mouse event WindowServer keeps showing whatever
        // cursor the previous app had. Force re-evaluation via two stacked
        // mechanisms since neither is 100% reliable on its own.
        DispatchQueue.main.async {
            NSCursor.crosshair.set()
            guard let primary = NSScreen.screens.first else { return }
            let mouseLoc = NSEvent.mouseLocation
            let cgY = primary.frame.height - mouseLoc.y
            let cgPoint = CGPoint(x: mouseLoc.x, y: cgY)

            // 1) Synthesize a mouse-moved event at the session tap. Session-
            //    level doesn't require Accessibility permission the way
            //    cghidEventTap does, so this actually fires for ad-hoc users.
            if let event = CGEvent(
                mouseEventSource: nil,
                mouseType: .mouseMoved,
                mouseCursorPosition: cgPoint,
                mouseButton: .left
            ) {
                event.post(tap: .cgSessionEventTap)
            }

            // 2) Warp the cursor 1px away and back. The tiny jitter is barely
            //    perceptible and guarantees WindowServer re-evaluates cursor.
            let jitter = CGPoint(x: mouseLoc.x + 1, y: cgY)
            CGWarpMouseCursorPosition(jitter)
            CGWarpMouseCursorPosition(cgPoint)
            CGAssociateMouseAndMouseCursorPosition(1)

            NSCursor.crosshair.set()
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
        for w in windows { w.orderOut(nil) }
        windows.removeAll()
    }
}
