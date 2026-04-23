import Cocoa
import SwiftUI

enum AllInOneAction: Hashable {
    case area, window, fullscreen, previous, timer, record
}

final class AllInOneController {
    static let shared = AllInOneController()

    private var panel: NSPanel?
    private var clickOutsideMonitor: Any?

    func show(onAction: @escaping (AllInOneAction) -> Void) {
        dismiss()

        let view = AllInOneView(
            onSelect: { [weak self] action in
                self?.dismiss()
                onAction(action)
            }
        )
        let size = NSSize(width: 460, height: 76)
        let hosting = NSHostingController(rootView: view)
        hosting.view.frame = NSRect(origin: .zero, size: size)

        let panel = NSPanel(
            contentRect: NSRect(origin: .zero, size: size),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.isFloatingPanel = true
        panel.level = .statusBar
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = false
        panel.contentViewController = hosting
        panel.collectionBehavior = [.canJoinAllSpaces, .transient, .fullScreenAuxiliary]

        let origin = Self.positionBottomCenter(size: size)
        panel.setFrame(NSRect(origin: origin, size: size), display: true)
        panel.orderFrontRegardless()
        self.panel = panel

        clickOutsideMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            self?.dismiss()
        }
    }

    func dismiss() {
        if let monitor = clickOutsideMonitor {
            NSEvent.removeMonitor(monitor)
            clickOutsideMonitor = nil
        }
        panel?.orderOut(nil)
        panel = nil
    }

    private static func positionBottomCenter(size: NSSize) -> NSPoint {
        guard let screen = NSScreen.main else { return .zero }
        let vf = screen.visibleFrame
        let liftAboveBottom: CGFloat = 80
        return NSPoint(
            x: vf.midX - size.width / 2,
            y: vf.minY + liftAboveBottom
        )
    }
}

private struct AllInOneView: View {
    let onSelect: (AllInOneAction) -> Void

    @State private var appeared = false

    private var options: [Option] {
        [
            Option(action: .area,       icon: "viewfinder",       label: "Area",      enabled: true),
            Option(action: .fullscreen, icon: "display",          label: "Fullscreen", enabled: true),
            Option(action: .window,     icon: "macwindow",        label: "Window",    enabled: true),
            Option(action: .previous,   icon: "arrow.clockwise",  label: "Previous",  enabled: LastCaptureStore.hasPrevious),
            Option(action: .timer,      icon: "timer",            label: "Timer",     enabled: true),
            Option(action: .record,     icon: "video.fill",       label: "Record",    enabled: true)
        ]
    }

    var body: some View {
        HStack(spacing: 2) {
            ForEach(options) { option in
                AllInOneOption(
                    icon: option.icon,
                    label: option.label,
                    enabled: option.enabled
                ) {
                    onSelect(option.action)
                }
            }
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 6)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(panelBackground)
        .scaleEffect(appeared ? 1 : 0.95)
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 10)
        .onAppear {
            withAnimation(.spring(response: 0.32, dampingFraction: 0.82)) {
                appeared = true
            }
        }
    }

    private var panelBackground: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 18).fill(.ultraThinMaterial)
            RoundedRectangle(cornerRadius: 18).fill(Color.black.opacity(0.32))
        }
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .strokeBorder(Color.white.opacity(0.06), lineWidth: 0.5)
        )
        .shadow(color: .black.opacity(0.35), radius: 22, y: 8)
    }

    private struct Option: Identifiable {
        let action: AllInOneAction
        let icon: String
        let label: String
        let enabled: Bool
        var id: AllInOneAction { action }
    }
}

private struct AllInOneOption: View {
    let icon: String
    let label: String
    let enabled: Bool
    let action: () -> Void
    @State private var hovering = false

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .regular))
                    .frame(height: 24)
                Text(label)
                    .font(.system(size: 10.5, weight: .medium))
            }
            .foregroundStyle(foreground)
            .frame(width: 70, height: 56)
            .background(
                RoundedRectangle(cornerRadius: 11)
                    .fill(background)
            )
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
        .onHover { hovering = $0 }
        .animation(.easeOut(duration: 0.12), value: hovering)
    }

    private var foreground: Color {
        if !enabled { return Color.primary.opacity(0.32) }
        if hovering { return Color.white }
        return Color.primary.opacity(0.85)
    }

    private var background: Color {
        if !enabled { return .clear }
        if hovering { return Color.accentColor.opacity(0.9) }
        return .clear
    }
}
