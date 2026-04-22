import Cocoa

final class OverlayController {
    private var windows: [OverlayWindow] = []
    private var completion: ((NSImage?) -> Void)?
    private var finished = false

    func begin(completion: @escaping (NSImage?) -> Void) {
        self.completion = completion

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
    }

    private func finish(with rectInScreen: CGRect?, screen: NSScreen?) {
        guard !finished else { return }
        finished = true
        closeWindows()

        guard let rect = rectInScreen, let screen = screen else {
            completion?(nil)
            return
        }

        // Give the overlay a moment to actually leave the screen before capturing.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) { [weak self] in
            let image = ScreenCapture.capture(rectInScreenCoords: rect, screen: screen)
            self?.completion?(image)
        }
    }

    private func closeWindows() {
        for w in windows { w.orderOut(nil) }
        windows.removeAll()
    }
}
