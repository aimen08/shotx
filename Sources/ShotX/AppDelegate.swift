import Cocoa

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var hotKeyManager: HotKeyManager!
    private var overlayController: OverlayController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupStatusBar()
        setupHotKey()
    }

    private func setupStatusBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            button.title = "◰"
            button.toolTip = "ShotX — ⌥D to capture region"
        }

        let menu = NSMenu()
        menu.addItem(withTitle: "Capture Region (⌥D)", action: #selector(captureNow), keyEquivalent: "")
        menu.addItem(NSMenuItem.separator())
        menu.addItem(withTitle: "Quit ShotX", action: #selector(quit), keyEquivalent: "q")
        statusItem.menu = menu
    }

    private func setupHotKey() {
        hotKeyManager = HotKeyManager()
        hotKeyManager.register { [weak self] in
            self?.captureNow()
        }
    }

    @objc private func captureNow() {
        guard overlayController == nil else { return }
        let controller = OverlayController()
        overlayController = controller
        controller.begin { [weak self] image in
            if let image = image {
                AppDelegate.copyToClipboard(image)
            }
            self?.overlayController = nil
        }
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }

    private static func copyToClipboard(_ image: NSImage) {
        let pb = NSPasteboard.general
        pb.clearContents()
        pb.writeObjects([image])
    }
}
