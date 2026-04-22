import Cocoa
import SwiftUI

final class MainWindowController {
    private var window: NSWindow?

    func show() {
        if let window = window {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let root = MainView()
            .environmentObject(HistoryStore.shared)
            .environmentObject(ShortcutStore.shared)
        let hosting = NSHostingController(rootView: root)

        let window = NSWindow(contentViewController: hosting)
        window.title = "ShotX"
        window.styleMask = [.titled, .closable, .miniaturizable, .resizable]
        window.setContentSize(NSSize(width: 720, height: 520))
        window.isReleasedWhenClosed = false
        window.center()
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        self.window = window
    }
}

struct MainView: View {
    enum Tab: String, Hashable, CaseIterable {
        case history, settings
        var title: String { self == .history ? "History" : "Settings" }
    }

    @State private var tab: Tab = .history

    var body: some View {
        VStack(spacing: 0) {
            Picker("", selection: $tab) {
                ForEach(Tab.allCases, id: \.self) { t in
                    Text(t.title).tag(t)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .frame(maxWidth: 300)
            .padding(.vertical, 10)

            Divider()

            Group {
                switch tab {
                case .history: HistoryView()
                case .settings: SettingsView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

struct HistoryView: View {
    @EnvironmentObject var history: HistoryStore
    private let cols = [GridItem(.adaptive(minimum: 170), spacing: 14)]

    var body: some View {
        Group {
            if history.entries.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "photo.on.rectangle.angled")
                        .font(.system(size: 44))
                        .foregroundStyle(.tertiary)
                    Text("No captures yet")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                    Text("Press \(ShortcutFormatter.describe(ShortcutStore.shared.shortcut)) to capture a region")
                        .foregroundStyle(.tertiary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVGrid(columns: cols, spacing: 14) {
                        ForEach(history.entries) { entry in
                            HistoryThumbnail(entry: entry)
                        }
                    }
                    .padding(16)
                }
            }
        }
    }
}

struct HistoryThumbnail: View {
    let entry: CaptureEntry
    @EnvironmentObject var history: HistoryStore
    @State private var image: NSImage?

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.secondary.opacity(0.1))
                if let image = image {
                    Image(nsImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .padding(4)
                }
            }
            .frame(height: 120)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(Color.secondary.opacity(0.2))
            )

            HStack {
                Text(entry.createdAt, style: .time)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(Int(entry.width))×\(Int(entry.height))")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .onAppear { image = history.image(for: entry) }
        .contextMenu { contextMenuContent }
        .onTapGesture(count: 2) { copy() }
    }

    @ViewBuilder private var contextMenuContent: some View {
        Button("Copy") { copy() }
        Button("Save to Desktop") { saveToDesktop() }
        Button("Edit…") { edit() }
        Button("Reveal in Finder") {
            NSWorkspace.shared.activateFileViewerSelecting([history.fileURL(for: entry)])
        }
        Divider()
        Button("Delete", role: .destructive) { history.remove(entry) }
    }

    private func copy() {
        guard let image = image else { return }
        ImageSaver.copyToClipboard(image)
    }

    private func saveToDesktop() {
        guard let image = image else { return }
        ImageSaver.saveToDesktop(image)
    }

    private func edit() {
        guard let image = image,
              let appDelegate = NSApp.delegate as? AppDelegate else { return }
        appDelegate.openAnnotator(with: image)
    }
}

struct SettingsView: View {
    @EnvironmentObject var shortcuts: ShortcutStore

    var body: some View {
        Form {
            Section {
                HStack {
                    Text("Capture shortcut")
                    Spacer()
                    ShortcutRecorder(shortcut: $shortcuts.shortcut)
                        .frame(width: 160, height: 26)
                    Button("Reset") { shortcuts.shortcut = .default }
                }
            } header: {
                Text("Shortcut")
            } footer: {
                Text("Click the field and press a key combination. Escape cancels.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section {
                HStack {
                    Text("Clear all captures")
                    Spacer()
                    Button("Clear History", role: .destructive) {
                        HistoryStore.shared.clear()
                    }
                }
            } header: {
                Text("Library")
            }

            Section {
                HStack {
                    Text("ShotX")
                    Spacer()
                    Button("Quit") { NSApp.terminate(nil) }
                }
            }
        }
        .formStyle(.grouped)
        .scrollContentBackground(.hidden)
    }
}
