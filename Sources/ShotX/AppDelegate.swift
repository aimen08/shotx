import Cocoa
import Combine

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var hotKeyManager: HotKeyManager!
    private var overlayController: OverlayController?
    private var popupController: PostCapturePopupController?
    private var annotationController: AnnotationWindowController?
    private var mainWindowController: MainWindowController?
    private var shortcutCancellable: AnyCancellable?

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupStatusBar()
        setupHotKey()
    }

    private func setupStatusBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "scissors", accessibilityDescription: "ShotX")
            button.image?.isTemplate = true
            button.toolTip = "ShotX"
            button.target = self
            button.action = #selector(statusBarClicked(_:))
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }
    }

    @objc private func statusBarClicked(_ sender: NSStatusBarButton) {
        let event = NSApp.currentEvent
        let isRightClick = event?.type == .rightMouseUp
            || (event?.modifierFlags.contains(.control) ?? false)
        if isRightClick {
            showStatusMenu()
        } else {
            showMainWindow()
        }
    }

    private func showStatusMenu() {
        let menu = NSMenu()
        menu.addItem(withTitle: "Capture Region", action: #selector(captureNow), keyEquivalent: "")
        menu.addItem(withTitle: "Show Library…", action: #selector(showMainWindow), keyEquivalent: "")
        menu.addItem(.separator())
        menu.addItem(withTitle: "Quit ShotX", action: #selector(quit), keyEquivalent: "q")
        statusItem.menu = menu
        statusItem.button?.performClick(nil)
        statusItem.menu = nil
    }

    private func setupHotKey() {
        hotKeyManager = HotKeyManager()
        registerCurrentShortcut()
        shortcutCancellable = ShortcutStore.shared.$shortcut
            .dropFirst()
            .sink { [weak self] _ in self?.registerCurrentShortcut() }
    }

    private func registerCurrentShortcut() {
        let s = ShortcutStore.shared.shortcut
        hotKeyManager.register(keyCode: s.keyCode, modifiers: s.modifiers) { [weak self] in
            self?.captureNow()
        }
    }

    @objc func captureNow() {
        guard overlayController == nil else { return }
        let controller = OverlayController()
        overlayController = controller
        controller.begin { [weak self] image in
            self?.overlayController = nil
            guard let self = self, let image = image else { return }
            HistoryStore.shared.add(image)
            ImageSaver.copyToClipboard(image)
            self.showPostCapturePopup(for: image)
        }
    }

    @objc func showMainWindow() {
        if mainWindowController == nil {
            mainWindowController = MainWindowController()
        }
        mainWindowController?.show()
    }

    @objc func quit() {
        NSApp.terminate(nil)
    }

    private func showPostCapturePopup(for image: NSImage) {
        popupController?.dismiss()
        let controller = PostCapturePopupController()
        popupController = controller
        controller.show(image: image, onEdit: { [weak self] in
            self?.openAnnotator(with: image)
        })
    }

    func openAnnotator(with image: NSImage) {
        annotationController = AnnotationWindowController()
        annotationController?.open(image: image) { [weak self] in
            self?.annotationController = nil
        }
    }
}
