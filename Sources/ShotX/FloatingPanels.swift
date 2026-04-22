import Cocoa
import SwiftUI

// MARK: - Countdown

final class CountdownController {
    private var panel: NSPanel?
    private var timer: Timer?
    private var cancelled = false

    func start(seconds initial: Int, onFinish: @escaping () -> Void) {
        var remaining = initial
        let state = CountdownState(seconds: remaining)

        let hosting = NSHostingController(rootView: CountdownView(
            state: state,
            onCancel: { [weak self] in
                self?.cancel()
            }
        ))
        hosting.view.frame = NSRect(x: 0, y: 0, width: 180, height: 180)

        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 180, height: 180),
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

        if let screen = NSScreen.main {
            let size = NSSize(width: 180, height: 180)
            let frame = NSRect(
                x: screen.visibleFrame.midX - size.width / 2,
                y: screen.visibleFrame.midY - size.height / 2,
                width: size.width,
                height: size.height
            )
            panel.setFrame(frame, display: true)
        }
        panel.orderFrontRegardless()
        self.panel = panel

        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] t in
            guard let self = self, !self.cancelled else {
                t.invalidate()
                return
            }
            remaining -= 1
            if remaining <= 0 {
                t.invalidate()
                self.cleanup()
                onFinish()
            } else {
                state.seconds = remaining
            }
        }
    }

    func cancel() {
        cancelled = true
        cleanup()
    }

    private func cleanup() {
        timer?.invalidate()
        timer = nil
        panel?.orderOut(nil)
        panel = nil
    }
}

final class CountdownState: ObservableObject {
    @Published var seconds: Int
    init(seconds: Int) { self.seconds = seconds }
}

private struct CountdownView: View {
    @ObservedObject var state: CountdownState
    let onCancel: () -> Void

    var body: some View {
        Button(action: onCancel) {
            VStack(spacing: 6) {
                Text("\(state.seconds)")
                    .font(.system(size: 72, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(.primary)
                Text("Click to cancel")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .buttonStyle(.plain)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 22))
        .overlay(
            RoundedRectangle(cornerRadius: 22)
                .strokeBorder(Color.white.opacity(0.12), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.35), radius: 24, y: 10)
    }
}

// MARK: - Toast

final class ToastController {
    static let shared = ToastController()

    private var panel: NSPanel?
    private var timer: Timer?

    private static let size = NSSize(width: 320, height: 64)

    func show(
        message: String,
        icon: String = "checkmark.circle.fill",
        tint: NSColor = .systemGreen,
        duration: TimeInterval = 3.0
    ) {
        dismiss()

        let view = ToastView(
            message: message,
            icon: icon,
            tint: Color(nsColor: tint),
            onDismiss: { [weak self] in self?.dismiss() }
        )
        let hosting = NSHostingController(rootView: view)
        hosting.view.frame = NSRect(origin: .zero, size: Self.size)

        let panel = NSPanel(
            contentRect: NSRect(origin: .zero, size: Self.size),
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

        if let screen = NSScreen.main {
            let margin: CGFloat = 24
            let frame = NSRect(
                x: screen.visibleFrame.minX + margin,
                y: screen.visibleFrame.minY + margin,
                width: Self.size.width,
                height: Self.size.height
            )
            panel.setFrame(frame, display: true)
        }
        panel.orderFrontRegardless()
        self.panel = panel

        timer = Timer.scheduledTimer(withTimeInterval: duration, repeats: false) { [weak self] _ in
            self?.dismiss()
        }
    }

    func dismiss() {
        timer?.invalidate()
        timer = nil
        panel?.orderOut(nil)
        panel = nil
    }
}

private struct ToastView: View {
    let message: String
    let icon: String
    let tint: Color
    let onDismiss: () -> Void
    @State private var appeared = false

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(tint)
            Text(message)
                .font(.system(size: 12.5, weight: .medium))
                .lineLimit(2)
                .multilineTextAlignment(.leading)
            Spacer(minLength: 0)
            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(.secondary)
                    .frame(width: 18, height: 18)
                    .background(Color.primary.opacity(0.08))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
        }
        .padding(12)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(Color.white.opacity(0.1), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.28), radius: 18, y: 6)
        .scaleEffect(appeared ? 1 : 0.92)
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 14)
        .onAppear {
            withAnimation(.spring(response: 0.38, dampingFraction: 0.78)) {
                appeared = true
            }
        }
    }
}
