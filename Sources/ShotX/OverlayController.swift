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

        // WindowServer tracks the cursor based on the last mouse event, which
        // was in whatever app the user was in when they pressed the shortcut.
        // Without a real mouse event it keeps showing the previous cursor.
        // Synthesize a mouse-moved event at the current location — zero visible
        // movement, but it forces WindowServer to re-evaluate cursor tracking.
        DispatchQueue.main.async {
            NSCursor.crosshair.set()
            guard let primary = NSScreen.screens.first else { return }
            let mouseLoc = NSEvent.mouseLocation
            let cgPoint = CGPoint(x: mouseLoc.x, y: primary.frame.height - mouseLoc.y)
            if let event = CGEvent(
                mouseEventSource: nil,
                mouseType: .mouseMoved,
                mouseCursorPosition: cgPoint,
                mouseButton: .left
            ) {
                event.post(tap: .cghidEventTap)
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
        for w in windows { w.orderOut(nil) }
        windows.removeAll()
    }
}
