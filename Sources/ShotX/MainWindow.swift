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
    @EnvironmentObject var shortcuts: ShortcutStore
    private let cols = [GridItem(.adaptive(minimum: 210, maximum: 260), spacing: 16)]

    var body: some View {
        Group {
            if history.entries.isEmpty {
                emptyState
            } else {
                ScrollView {
                    LazyVGrid(columns: cols, spacing: 18) {
                        ForEach(history.entries) { entry in
                            HistoryCard(entry: entry)
                        }
                    }
                    .padding(20)
                }
            }
        }
        .background(Color(NSColor.windowBackgroundColor))
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.accentColor.opacity(0.1))
                    .frame(width: 80, height: 80)
                Image(systemName: "photo.on.rectangle.angled")
                    .font(.system(size: 34, weight: .light))
                    .foregroundStyle(.tint)
            }
            Text("No captures yet")
                .font(.system(size: 15, weight: .semibold))
            Text("Press \(ShortcutFormatter.describe(shortcuts.shortcut)) anywhere to capture a region")
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct HistoryCard: View {
    let entry: CaptureEntry
    @EnvironmentObject var history: HistoryStore
    @State private var image: NSImage?
    @State private var hovering = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            thumbnailArea
            footer
        }
        .onAppear { image = history.image(for: entry) }
        .onHover { hovering = $0 }
        .animation(.easeOut(duration: 0.15), value: hovering)
        .contextMenu {
            Button("Edit…") { edit() }
            Button("Copy") { copy() }
            Button("Save to Desktop") { saveToDesktop() }
            Button("Reveal in Finder") { reveal() }
            Divider()
            Button("Delete", role: .destructive) { history.remove(entry) }
        }
    }

    private var thumbnailArea: some View {
        ZStack(alignment: .bottom) {
            RoundedRectangle(cornerRadius: 10)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.primary.opacity(0.04),
                            Color.primary.opacity(0.09)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            if let image = image {
                Image(nsImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .padding(8)
            }

            if hovering {
                LinearGradient(
                    colors: [.clear, .black.opacity(0.55)],
                    startPoint: .center,
                    endPoint: .bottom
                )
                .clipShape(RoundedRectangle(cornerRadius: 10))

                HStack(spacing: 8) {
                    HistoryActionButton(icon: "pencil.tip", tooltip: "Edit", action: edit)
                    HistoryActionButton(icon: "doc.on.doc", tooltip: "Copy", action: copy)
                    HistoryActionButton(icon: "square.and.arrow.down", tooltip: "Save to Desktop", action: saveToDesktop)
                }
                .padding(.bottom, 10)
            }
        }
        .frame(height: 140)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .strokeBorder(Color.primary.opacity(0.1), lineWidth: 1)
        )
        .shadow(color: .black.opacity(hovering ? 0.18 : 0.0), radius: 10, y: 4)
    }

    private var footer: some View {
        HStack(spacing: 8) {
            Text(entry.createdAt, style: .time)
                .font(.system(size: 11.5, weight: .medium))
                .foregroundStyle(.primary)
            Text("·")
                .foregroundStyle(.tertiary)
            Text(entry.createdAt, style: .date)
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
            Spacer()
            Text("\(Int(entry.width))×\(Int(entry.height))")
                .font(.system(size: 10.5, weight: .medium))
                .foregroundStyle(.tertiary)
                .monospacedDigit()
        }
        .padding(.horizontal, 2)
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

    private func reveal() {
        NSWorkspace.shared.activateFileViewerSelecting([history.fileURL(for: entry)])
    }
}

private struct HistoryActionButton: View {
    let icon: String
    let tooltip: String
    let action: () -> Void
    @State private var hovering = false

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 34, height: 34)
                .background(
                    Circle()
                        .fill(hovering ? Color.accentColor : Color.black.opacity(0.6))
                )
                .overlay(
                    Circle()
                        .strokeBorder(Color.white.opacity(0.18), lineWidth: 0.5)
                )
                .shadow(color: .black.opacity(0.35), radius: 4, y: 2)
        }
        .buttonStyle(.plain)
        .help(tooltip)
        .onHover { hovering = $0 }
        .animation(.easeOut(duration: 0.12), value: hovering)
    }
}

struct SettingsView: View {
    @EnvironmentObject var shortcuts: ShortcutStore
    @EnvironmentObject var history: HistoryStore

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                SettingsCard(
                    icon: "command",
                    tint: .blue,
                    title: "Shortcut",
                    subtitle: "Trigger region capture with a key combination"
                ) {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text("Capture region")
                                .font(.system(size: 13))
                            Spacer()
                            ShortcutRecorder(shortcut: $shortcuts.shortcut)
                                .frame(width: 150, height: 28)
                            Button("Reset") { shortcuts.shortcut = .default }
                                .buttonStyle(.borderless)
                                .foregroundStyle(.secondary)
                                .font(.system(size: 12))
                        }
                        Text("Click the field and press a new combination. Escape to cancel.")
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                    }
                }

                SettingsCard(
                    icon: "photo.stack.fill",
                    tint: .purple,
                    title: "Library",
                    subtitle: "Your capture history"
                ) {
                    HStack {
                        Text("\(history.entries.count) capture\(history.entries.count == 1 ? "" : "s") stored")
                            .font(.system(size: 13))
                            .foregroundStyle(.secondary)
                        Spacer()
                        Button(role: .destructive) {
                            history.clear()
                        } label: {
                            Label("Clear All", systemImage: "trash")
                                .font(.system(size: 12, weight: .medium))
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                        .disabled(history.entries.isEmpty)
                    }
                }

                SettingsCard(
                    icon: "info.circle.fill",
                    tint: .gray,
                    title: "About",
                    subtitle: "ShotX · lightweight screen capture"
                ) {
                    HStack {
                        Text("Version 1.0")
                            .font(.system(size: 13))
                            .foregroundStyle(.secondary)
                        Spacer()
                        Button {
                            NSApp.terminate(nil)
                        } label: {
                            Label("Quit ShotX", systemImage: "power")
                                .font(.system(size: 12, weight: .medium))
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    }
                }
            }
            .padding(20)
        }
        .background(Color(NSColor.windowBackgroundColor))
    }
}

struct SettingsCard<Content: View>: View {
    let icon: String
    let tint: Color
    let title: String
    let subtitle: String
    @ViewBuilder var content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 11) {
                Image(systemName: icon)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(tint)
                    .frame(width: 34, height: 34)
                    .background(
                        RoundedRectangle(cornerRadius: 9)
                            .fill(tint.opacity(0.14))
                    )
                VStack(alignment: .leading, spacing: 1) {
                    Text(title)
                        .font(.system(size: 14, weight: .semibold))
                    Text(subtitle)
                        .font(.system(size: 11.5))
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }

            Divider()

            content()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(NSColor.controlBackgroundColor))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(Color.primary.opacity(0.08), lineWidth: 1)
        )
    }
}
