import Cocoa
import SwiftUI

enum AllInOneAction: Hashable {
    case area, window, fullscreen, previous, timer
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
            },
            onCancel: { [weak self] in self?.dismiss() }
        )
        let size = NSSize(width: 240, height: 260)
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

        let origin = Self.positionNearCursor(size: size)
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

    private static func positionNearCursor(size: NSSize) -> NSPoint {
        let mouse = NSEvent.mouseLocation
        guard let screen = NSScreen.screens.first(where: { $0.frame.contains(mouse) }) ?? NSScreen.main
        else { return .zero }
        let vf = screen.visibleFrame
        let margin: CGFloat = 12
        var x = mouse.x - size.width / 2
        var y = mouse.y - size.height - 16
        if y < vf.minY + margin { y = mouse.y + 16 }
        x = min(max(vf.minX + margin, x), vf.maxX - size.width - margin)
        y = min(max(vf.minY + margin, y), vf.maxY - size.height - margin)
        return NSPoint(x: x, y: y)
    }
}

private struct AllInOneView: View {
    let onSelect: (AllInOneAction) -> Void
    let onCancel: () -> Void

    @State private var appeared = false

    var body: some View {
        VStack(spacing: 4) {
            header
            actionRow(icon: "rectangle.dashed", title: "Capture Area", kind: .area)
            actionRow(icon: "macwindow", title: "Capture Window", kind: .window)
            actionRow(icon: "display", title: "Capture Fullscreen", kind: .fullscreen)
            actionRow(icon: "arrow.clockwise", title: "Previous Area", kind: .previous, enabled: LastCaptureStore.hasPrevious)
            actionRow(icon: "timer", title: "Self-Timer (3s)", kind: .timer)
        }
        .padding(10)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(Color.white.opacity(0.1), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.35), radius: 22, y: 8)
        .scaleEffect(appeared ? 1 : 0.94)
        .opacity(appeared ? 1 : 0)
        .onAppear {
            withAnimation(.spring(response: 0.34, dampingFraction: 0.78)) {
                appeared = true
            }
        }
    }

    private var header: some View {
        HStack {
            Text("Capture")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
            Spacer()
            Button(action: onCancel) {
                Image(systemName: "xmark")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(.secondary)
                    .frame(width: 18, height: 18)
                    .background(Color.primary.opacity(0.08))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 6)
        .padding(.top, 4)
        .padding(.bottom, 2)
    }

    @ViewBuilder
    private func actionRow(icon: String, title: String, kind: AllInOneAction, enabled: Bool = true) -> some View {
        AllInOneRow(icon: icon, title: title, enabled: enabled) {
            onSelect(kind)
        }
    }
}

private struct AllInOneRow: View {
    let icon: String
    let title: String
    let enabled: Bool
    let action: () -> Void
    @State private var hovering = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(hovering && enabled ? Color.white : Color.primary.opacity(enabled ? 0.85 : 0.35))
                    .frame(width: 26, height: 26)
                    .background(
                        RoundedRectangle(cornerRadius: 7)
                            .fill(hovering && enabled ? Color.accentColor : Color.primary.opacity(0.08))
                    )
                Text(title)
                    .font(.system(size: 12.5, weight: .medium))
                    .foregroundStyle(enabled ? Color.primary : Color.secondary.opacity(0.7))
                Spacer()
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(hovering && enabled ? Color.primary.opacity(0.06) : .clear)
            )
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
        .onHover { hovering = $0 }
        .animation(.easeOut(duration: 0.1), value: hovering)
    }
}
