import Cocoa
import Combine
import Carbon.HIToolbox
import UniformTypeIdentifiers

final class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    private var statusItem: NSStatusItem!
    private var hotKeyManager: HotKeyManager!
    private var overlayController: OverlayController?
    private var popupController: PostCapturePopupController?
    private var annotationController: AnnotationWindowController?
    private var mainWindowController: MainWindowController?
    private var countdownController: CountdownController?
    private var windowCaptureController: WindowCaptureController?
    private var shortcutCancellable: AnyCancellable?

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupStatusBar()
        setupHotKey()
    }

    // MARK: - Status bar

    private func setupStatusBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "scissors", accessibilityDescription: "ShotX")
            button.image?.isTemplate = true
            button.toolTip = "ShotX"
        }

        let menu = NSMenu()
        menu.delegate = self
        statusItem.menu = menu
    }

    func menuNeedsUpdate(_ menu: NSMenu) {
        guard menu === statusItem.menu else { return }
        menu.removeAllItems()
        populateStatusMenu(menu)
    }

    private func populateStatusMenu(_ menu: NSMenu) {
        menu.addItem(menuItem(
            title: "All-In-One",
            symbol: "square.grid.2x2",
            action: #selector(showAllInOne)
        ))

        menu.addItem(.separator())

        menu.addItem(menuItem(
            title: "Capture Area",
            symbol: "rectangle.dashed",
            action: #selector(captureNow),
            applyShortcut: true
        ))

        let prev = menuItem(
            title: "Capture Previous Area",
            symbol: "arrow.clockwise",
            action: #selector(capturePreviousArea)
        )
        prev.isEnabled = LastCaptureStore.hasPrevious
        menu.addItem(prev)

        menu.addItem(menuItem(
            title: "Capture Fullscreen",
            symbol: "display",
            action: #selector(captureFullscreen)
        ))

        menu.addItem(menuItem(
            title: "Capture Window",
            symbol: "macwindow",
            action: #selector(captureWindow)
        ))

        menu.addItem(.separator())

        let timerItem = NSMenuItem(title: "Self-Timer", action: nil, keyEquivalent: "")
        timerItem.image = NSImage(systemSymbolName: "timer", accessibilityDescription: nil)
        let timerMenu = NSMenu()
        for seconds in [3, 5, 10] {
            let item = NSMenuItem(
                title: "\(seconds) seconds",
                action: #selector(captureAfterTimer(_:)),
                keyEquivalent: ""
            )
            item.tag = seconds
            item.target = self
            timerMenu.addItem(item)
        }
        timerItem.submenu = timerMenu
        menu.addItem(timerItem)

        menu.addItem(.separator())

        let showDesktop = menuItem(
            title: "Show Desktop Icons",
            symbol: "menubar.dock.rectangle",
            action: #selector(toggleDesktopIcons)
        )
        showDesktop.state = DesktopIcons.isVisible() ? .on : .off
        menu.addItem(showDesktop)

        menu.addItem(menuItem(
            title: "Open…",
            symbol: "folder",
            action: #selector(openImageFile)
        ))
        menu.addItem(menuItem(
            title: "Open from Clipboard",
            symbol: "doc.on.clipboard",
            action: #selector(openFromClipboard),
            keyEquivalent: "v",
            keyEquivalentModifiers: [.command, .shift]
        ))

        menu.addItem(menuItem(
            title: "Pin to the Screen…",
            symbol: "pin",
            action: #selector(pinToScreen)
        ))

        menu.addItem(.separator())

        menu.addItem(menuItem(
            title: "Capture History…",
            symbol: "clock.arrow.circlepath",
            action: #selector(showHistory)
        ))

        menu.addItem(.separator())

        menu.addItem(menuItem(
            title: "About ShotX",
            symbol: nil,
            action: #selector(showAbout)
        ))
        menu.addItem(menuItem(
            title: "Settings…",
            symbol: nil,
            action: #selector(showSettings),
            keyEquivalent: ",",
            keyEquivalentModifiers: .command
        ))
        menu.addItem(menuItem(
            title: "Quit ShotX",
            symbol: nil,
            action: #selector(quit),
            keyEquivalent: "q",
            keyEquivalentModifiers: .command
        ))
    }

    private func menuItem(
        title: String,
        symbol: String?,
        action: Selector,
        keyEquivalent: String = "",
        keyEquivalentModifiers: NSEvent.ModifierFlags = [],
        applyShortcut: Bool = false
    ) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: action, keyEquivalent: keyEquivalent)
        item.keyEquivalentModifierMask = keyEquivalentModifiers
        item.target = self
        if let symbol = symbol {
            item.image = NSImage(systemSymbolName: symbol, accessibilityDescription: nil)
        }
        if applyShortcut {
            let s = ShortcutStore.shared.shortcut
            if let ke = ShortcutFormatter.menuKeyEquivalent(for: s.keyCode) {
                item.keyEquivalent = ke
                item.keyEquivalentModifierMask = ShortcutFormatter.nsModifierFlags(from: s.modifiers)
            }
        }
        return item
    }

    // MARK: - Hot key

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

    // MARK: - Capture actions

    @objc func captureNow() {
        guard overlayController == nil else { return }
        let controller = OverlayController()
        overlayController = controller
        controller.begin { [weak self] image, rect, screen in
            self?.overlayController = nil
            guard let self = self, let image = image else { return }
            if let rect = rect, let screen = screen {
                LastCaptureStore.save(rect: rect, screen: screen)
            }
            self.handleCapturedImage(image)
        }
    }

    @objc private func captureFullscreen() {
        let mouseLoc = NSEvent.mouseLocation
        let screen = NSScreen.screens.first(where: { $0.frame.contains(mouseLoc) }) ?? NSScreen.main
        guard let screen = screen else { return }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
            guard let self = self,
                  let image = ScreenCapture.capture(rectInScreenCoords: screen.frame, screen: screen)
            else { return }
            LastCaptureStore.save(rect: screen.frame, screen: screen)
            self.handleCapturedImage(image)
        }
    }

    @objc private func capturePreviousArea() {
        guard let stored = LastCaptureStore.load() else {
            NSSound.beep()
            return
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { [weak self] in
            guard let self = self,
                  let image = ScreenCapture.capture(rectInScreenCoords: stored.rect, screen: stored.screen)
            else { return }
            self.handleCapturedImage(image)
        }
    }

    @objc private func captureAfterTimer(_ sender: NSMenuItem) {
        let seconds = sender.tag
        guard overlayController == nil else { return }

        let controller = OverlayController()
        overlayController = controller
        controller.begin { [weak self] _, rect, screen in
            self?.overlayController = nil
            guard let self = self, let rect = rect, let screen = screen else { return }

            self.countdownController?.cancel()
            let cd = CountdownController()
            self.countdownController = cd
            cd.start(seconds: seconds) { [weak self] in
                guard let self = self else { return }
                self.countdownController = nil
                guard let image = ScreenCapture.capture(rectInScreenCoords: rect, screen: screen) else { return }
                LastCaptureStore.save(rect: rect, screen: screen)
                self.handleCapturedImage(image)
            }
        }
    }

    @objc private func captureWindow() {
        guard windowCaptureController == nil else { return }
        let controller = WindowCaptureController()
        windowCaptureController = controller
        controller.begin { [weak self] image in
            self?.windowCaptureController = nil
            guard let image = image else { return }
            self?.handleCapturedImage(image)
        }
    }

    @objc private func pinToScreen() {
        guard overlayController == nil else { return }
        let controller = OverlayController()
        overlayController = controller
        controller.begin { [weak self] image, rect, screen in
            self?.overlayController = nil
            guard let image = image else { return }
            if let rect = rect, let screen = screen {
                LastCaptureStore.save(rect: rect, screen: screen)
            }
            HistoryStore.shared.add(image)
            PinnedImageController.shared.pin(image)
        }
    }

    @objc private func toggleDesktopIcons() {
        DesktopIcons.toggle()
    }

    @objc private func showAllInOne() {
        AllInOneController.shared.show { [weak self] action in
            guard let self = self else { return }
            switch action {
            case .area:       self.captureNow()
            case .window:     self.captureWindow()
            case .fullscreen: self.captureFullscreen()
            case .previous:   self.capturePreviousArea()
            case .timer:
                // Tag=3 replicates the 3-second path
                let item = NSMenuItem()
                item.tag = 3
                self.captureAfterTimer(item)
            }
        }
    }

    @objc private func openFromClipboard() {
        let pb = NSPasteboard.general
        if let image = NSImage(pasteboard: pb) {
            openAnnotator(with: image)
        } else {
            ToastController.shared.show(
                message: "No image on the clipboard",
                icon: "exclamationmark.triangle.fill",
                tint: .systemOrange
            )
        }
    }

    @objc private func openImageFile() {
        let panel = NSOpenPanel()
        if #available(macOS 12.0, *) {
            panel.allowedContentTypes = [.png, .jpeg, .tiff, .heic, .bmp, .gif]
        }
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.prompt = "Open"
        NSApp.activate(ignoringOtherApps: true)
        panel.begin { [weak self] response in
            if response == .OK, let url = panel.url, let image = NSImage(contentsOf: url) {
                self?.openAnnotator(with: image)
            }
        }
    }

    // MARK: - Shared post-capture

    private func handleCapturedImage(_ image: NSImage) {
        HistoryStore.shared.add(image)
        ImageSaver.copyToClipboard(image)
        showPostCapturePopup(for: image)
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

    // MARK: - Windows

    @objc func showMainWindow() {
        if mainWindowController == nil {
            mainWindowController = MainWindowController()
        }
        mainWindowController?.show()
    }

    @objc private func showHistory() {
        if mainWindowController == nil {
            mainWindowController = MainWindowController()
        }
        mainWindowController?.show(tab: .history)
    }

    @objc private func showSettings() {
        if mainWindowController == nil {
            mainWindowController = MainWindowController()
        }
        mainWindowController?.show(tab: .settings)
    }

    @objc private func showAbout() {
        NSApp.activate(ignoringOtherApps: true)
        NSApp.orderFrontStandardAboutPanel(options: [
            .applicationName: "ShotX",
            .applicationVersion: "1.0",
            .credits: NSAttributedString(
                string: "Lightweight screen capture for macOS.",
                attributes: [.font: NSFont.systemFont(ofSize: 11)]
            )
        ])
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }
}
