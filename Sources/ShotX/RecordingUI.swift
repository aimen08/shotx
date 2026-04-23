import Cocoa
import SwiftUI

struct RecordingOptions {
    var showCursor: Bool = true
    var highlightClicks: Bool = false
    var captureSystemAudio: Bool = false
    var captureMicrophone: Bool = false
}

struct RecordingOptionsView: View {
    let dimensions: CGSize
    let onRecordVideo: (RecordingOptions) -> Void
    let onRecordGIF: (RecordingOptions) -> Void
    let onCancel: () -> Void

    @State private var showCursor = true
    @State private var highlightClicks = false
    @State private var captureSystemAudio = false
    @State private var captureMicrophone = false
    @State private var appeared = false

    private var currentOptions: RecordingOptions {
        RecordingOptions(
            showCursor: showCursor,
            highlightClicks: highlightClicks,
            captureSystemAudio: captureSystemAudio,
            captureMicrophone: captureMicrophone
        )
    }

    var body: some View {
        VStack(spacing: 8) {
            settingsStrip
            recordStack
        }
        .padding(10)
        .frame(width: 360)
        .scaleEffect(appeared ? 1 : 0.95)
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 10)
        .onAppear {
            withAnimation(.spring(response: 0.32, dampingFraction: 0.82)) {
                appeared = true
            }
        }
    }

    private var settingsStrip: some View {
        HStack(spacing: 10) {
            DimensionDisplay(width: Int(dimensions.width), height: Int(dimensions.height))
            Spacer(minLength: 6)
            HStack(spacing: 2) {
                CompactToggle(icon: "mic", binding: $captureMicrophone, enabled: true, tooltip: "Microphone")
                CompactToggle(icon: "speaker.wave.2", binding: $captureSystemAudio, enabled: true, tooltip: "System audio")
                CompactToggle(icon: "cursorarrow", binding: $showCursor, enabled: true, tooltip: "Show cursor")
                CompactToggle(icon: "cursorarrow.click", binding: $highlightClicks, enabled: true, tooltip: "Highlight clicks")
                CompactToggle(icon: "camera", binding: .constant(false), enabled: false, tooltip: "Camera — coming soon")
                CompactToggle(icon: "keyboard", binding: .constant(false), enabled: false, tooltip: "Keystrokes — coming soon")
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(cardBackground)
    }

    private var recordStack: some View {
        VStack(spacing: 0) {
            CompactRecordRow(
                iconText: "GIF",
                label: "Record GIF",
                suffix: "",
                enabled: true,
                prominent: false,
                action: { onRecordGIF(currentOptions) }
            )
            Rectangle()
                .fill(Color.white.opacity(0.06))
                .frame(height: 0.5)
            CompactRecordRow(
                iconSystem: "video.fill",
                label: "Record Video",
                suffix: "↩",
                enabled: true,
                prominent: true,
                action: { onRecordVideo(currentOptions) }
            )
            .keyboardShortcut(.defaultAction)
        }
        .background(cardBackground)
    }

    private var cardBackground: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 11).fill(.ultraThinMaterial)
            RoundedRectangle(cornerRadius: 11).fill(Color.black.opacity(0.28))
        }
        .overlay(
            RoundedRectangle(cornerRadius: 11)
                .strokeBorder(Color.white.opacity(0.06), lineWidth: 0.5)
        )
        .shadow(color: .black.opacity(0.28), radius: 14, y: 4)
    }
}

private struct DimensionDisplay: View {
    let width: Int
    let height: Int
    var body: some View {
        HStack(spacing: 6) {
            Text("\(width)")
                .monospacedDigit()
                .font(.system(size: 12.5, weight: .semibold, design: .rounded))
            Text("×")
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
            Text("\(height)")
                .monospacedDigit()
                .font(.system(size: 12.5, weight: .semibold, design: .rounded))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.black.opacity(0.25))
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .strokeBorder(Color.white.opacity(0.05), lineWidth: 0.5)
                )
        )
    }
}

private struct CompactToggle: View {
    let icon: String
    @Binding var binding: Bool
    let enabled: Bool
    let tooltip: String
    @State private var hovering = false

    var body: some View {
        Button {
            if enabled { binding.toggle() }
        } label: {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(foreground)
                .frame(width: 28, height: 24)
                .background(
                    RoundedRectangle(cornerRadius: 5)
                        .fill(background)
                )
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
        .onHover { hovering = $0 }
        .help(tooltip)
        .animation(.easeOut(duration: 0.1), value: binding)
        .animation(.easeOut(duration: 0.1), value: hovering)
    }

    private var foreground: Color {
        if !enabled { return Color.primary.opacity(0.28) }
        if binding { return .white }
        return Color.primary.opacity(0.75)
    }

    private var background: Color {
        if binding && enabled { return Color.accentColor }
        if hovering && enabled { return Color.white.opacity(0.08) }
        return .clear
    }
}

private struct CompactRecordRow: View {
    var iconSystem: String? = nil
    var iconText: String? = nil
    let label: String
    var suffix: String = ""
    let enabled: Bool
    let prominent: Bool
    let action: () -> Void
    @State private var hovering = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 11) {
                ZStack {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(iconBackground)
                        .frame(width: 26, height: 18)
                    if let t = iconText {
                        Text(t)
                            .font(.system(size: 8.5, weight: .heavy))
                            .foregroundStyle(.white)
                    } else if let s = iconSystem {
                        Image(systemName: s)
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(.white)
                    }
                }
                Text(label)
                    .font(.system(size: 12.5, weight: .semibold))
                    .foregroundStyle(enabled ? Color.primary : Color.secondary.opacity(0.65))
                Spacer()
                if !suffix.isEmpty {
                    Text(suffix)
                        .font(.system(size: 10.5, weight: .medium))
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 9)
            .background(rowBackground)
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
        .onHover { hovering = $0 }
        .animation(.easeOut(duration: 0.1), value: hovering)
    }

    private var iconBackground: Color {
        if !enabled { return Color.white.opacity(0.1) }
        if prominent { return Color.white.opacity(0.24) }
        return Color.white.opacity(0.14)
    }

    @ViewBuilder
    private var rowBackground: some View {
        if !enabled {
            Color.clear
        } else if prominent {
            LinearGradient(
                colors: [
                    Color.accentColor.opacity(hovering ? 0.92 : 0.78),
                    Color.accentColor.opacity(hovering ? 0.78 : 0.62)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        } else if hovering {
            Color.white.opacity(0.05)
        } else {
            Color.clear
        }
    }
}

// MARK: - Stop pill

final class RecordingStopState: ObservableObject {
    @Published var elapsed: TimeInterval = 0
}

struct RecordingStopView: View {
    @ObservedObject var state: RecordingStopState
    let onStop: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            ZStack {
                Circle().fill(Color.red).frame(width: 10, height: 10)
                Circle().fill(Color.red).frame(width: 10, height: 10)
                    .blur(radius: 3)
                    .opacity(0.8)
            }

            Text(formatted)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(.primary)

            Rectangle()
                .fill(Color.white.opacity(0.15))
                .frame(width: 1, height: 16)
                .padding(.horizontal, 2)

            Button(action: onStop) {
                HStack(spacing: 5) {
                    Image(systemName: "stop.fill")
                        .font(.system(size: 10, weight: .bold))
                    Text("Stop")
                        .font(.system(size: 12, weight: .semibold))
                        .lineLimit(1)
                        .fixedSize()
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(
                    LinearGradient(
                        colors: [.red, .red.opacity(0.78)],
                        startPoint: .top, endPoint: .bottom
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 7))
                .shadow(color: .red.opacity(0.4), radius: 4, y: 1)
            }
            .buttonStyle(.plain)
            .fixedSize()
            .keyboardShortcut(".", modifiers: .command)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 12).fill(.ultraThinMaterial)
                RoundedRectangle(cornerRadius: 12).fill(Color.black.opacity(0.25))
            }
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(Color.white.opacity(0.1), lineWidth: 0.5)
        )
        .shadow(color: .black.opacity(0.35), radius: 18, y: 6)
    }

    private var formatted: String {
        let total = Int(state.elapsed)
        let h = total / 3600
        let m = (total / 60) % 60
        let s = total % 60
        if h > 0 { return String(format: "%d:%02d:%02d", h, m, s) }
        return String(format: "%02d:%02d", m, s)
    }
}
