import Cocoa
import CoreGraphics
import SwiftUI

enum Permissions {
    static var screenRecordingGranted: Bool {
        if #available(macOS 11.0, *) {
            return CGPreflightScreenCaptureAccess()
        }
        return true
    }

    static func openScreenRecordingSettings() {
        guard let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture") else { return }
        NSWorkspace.shared.open(url)
    }
}

@MainActor
final class PermissionPromptController: NSObject, NSWindowDelegate {
    private var window: NSWindow?

    func show() {
        if let window = window {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let view = PermissionPromptView(
            onOpenSettings: { Permissions.openScreenRecordingSettings() },
            onQuit: { NSApp.terminate(nil) }
        )
        let hosting = NSHostingController(rootView: view)
        let size = NSSize(width: 420, height: 420)
        hosting.view.frame = NSRect(origin: .zero, size: size)

        let win = NSWindow(
            contentRect: NSRect(origin: .zero, size: size),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        win.title = "ShotX Permissions"
        win.contentView = hosting.view
        win.delegate = self
        win.isReleasedWhenClosed = false
        win.center()
        win.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        window = win
    }

    func dismiss() {
        window?.orderOut(nil)
        window = nil
    }

    nonisolated func windowWillClose(_ notification: Notification) {
        Task { @MainActor in self.window = nil }
    }
}

private struct PermissionPromptView: View {
    let onOpenSettings: () -> Void
    let onQuit: () -> Void

    var body: some View {
        VStack(spacing: 18) {
            iconBadge

            VStack(spacing: 6) {
                Text("Screen Recording Permission Needed")
                    .font(.system(size: 16, weight: .semibold))
                    .multilineTextAlignment(.center)
                Text("ShotX needs Screen Recording access to capture screenshots and record your screen.")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(2)
                    .fixedSize(horizontal: false, vertical: true)
            }

            steps

            Text("Already enabled? After upgrading ShotX, you may need to **remove** the existing entry and **re-add** it for the new build to be trusted.")
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .lineSpacing(2)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 6)

            HStack(spacing: 8) {
                Button(action: onQuit) {
                    Text("Quit")
                        .frame(maxWidth: .infinity)
                }
                .keyboardShortcut("q", modifiers: .command)

                Button(action: onOpenSettings) {
                    Label("Open Settings", systemImage: "gear")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
            }
            .controlSize(.large)
        }
        .padding(24)
        .frame(width: 420, height: 420)
    }

    private var iconBadge: some View {
        ZStack {
            Circle()
                .fill(Color.accentColor.opacity(0.14))
                .frame(width: 72, height: 72)
            Image(systemName: "lock.shield.fill")
                .font(.system(size: 30, weight: .semibold))
                .foregroundStyle(.tint)
        }
    }

    private var steps: some View {
        VStack(alignment: .leading, spacing: 10) {
            step(number: 1, text: "Click **Open Settings** below")
            step(number: 2, text: "Toggle **ShotX** on under Screen Recording")
            step(number: 3, text: "**Quit and re-open** ShotX from the menu bar")
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.primary.opacity(0.05))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .strokeBorder(Color.primary.opacity(0.08), lineWidth: 0.5)
        )
    }

    private func step(number: Int, text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Text("\(number)")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 22, height: 22)
                .background(Circle().fill(Color.accentColor))
            Text(.init(text))
                .font(.system(size: 13))
                .frame(maxWidth: .infinity, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
