import Cocoa
import Carbon.HIToolbox
import Combine

struct Shortcut: Codable, Equatable {
    var keyCode: UInt32
    var modifiers: UInt32

    static let `default` = Shortcut(
        keyCode: UInt32(kVK_ANSI_X),
        modifiers: UInt32(optionKey)
    )

    static let defaultColorPicker = Shortcut(
        keyCode: UInt32(kVK_ANSI_C),
        modifiers: UInt32(optionKey | shiftKey)
    )

    static let defaultFullscreen = Shortcut(
        keyCode: UInt32(kVK_ANSI_X),
        modifiers: UInt32(optionKey | shiftKey)
    )

    static let defaultOCR = Shortcut(
        keyCode: UInt32(kVK_ANSI_T),
        modifiers: UInt32(optionKey | shiftKey)
    )
}

final class ShortcutStore: ObservableObject {
    static let shared = ShortcutStore()

    @Published var shortcut: Shortcut {
        didSet { Self.persist(shortcut, key: captureKey) }
    }

    @Published var colorPickerShortcut: Shortcut {
        didSet { Self.persist(colorPickerShortcut, key: colorPickerKey) }
    }

    @Published var fullscreenShortcut: Shortcut {
        didSet { Self.persist(fullscreenShortcut, key: fullscreenKey) }
    }

    @Published var ocrShortcut: Shortcut {
        didSet { Self.persist(ocrShortcut, key: ocrKey) }
    }

    private let captureKey = "com.shotx.shortcut"
    private let colorPickerKey = "com.shotx.colorPickerShortcut"
    private let fullscreenKey = "com.shotx.fullscreenShortcut"
    private let ocrKey = "com.shotx.ocrShortcut"

    init() {
        shortcut = Self.load(key: "com.shotx.shortcut") ?? .default
        colorPickerShortcut = Self.load(key: "com.shotx.colorPickerShortcut") ?? .defaultColorPicker
        fullscreenShortcut = Self.load(key: "com.shotx.fullscreenShortcut") ?? .defaultFullscreen
        ocrShortcut = Self.load(key: "com.shotx.ocrShortcut") ?? .defaultOCR
    }

    private static func load(key: String) -> Shortcut? {
        guard let data = UserDefaults.standard.data(forKey: key),
              let decoded = try? JSONDecoder().decode(Shortcut.self, from: data) else {
            return nil
        }
        return decoded
    }

    private static func persist(_ shortcut: Shortcut, key: String) {
        guard let data = try? JSONEncoder().encode(shortcut) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }
}

enum ShortcutFormatter {
    static func describe(_ s: Shortcut) -> String {
        var parts: [String] = []
        if s.modifiers & UInt32(controlKey) != 0 { parts.append("⌃") }
        if s.modifiers & UInt32(optionKey) != 0 { parts.append("⌥") }
        if s.modifiers & UInt32(shiftKey) != 0 { parts.append("⇧") }
        if s.modifiers & UInt32(cmdKey) != 0 { parts.append("⌘") }
        parts.append(keyName(for: s.keyCode))
        return parts.joined()
    }

    static func keyName(for keyCode: UInt32) -> String {
        if let named = specialKeyNames[keyCode] { return named }
        return letterOrDigit(for: keyCode) ?? "Key \(keyCode)"
    }

    static func menuKeyEquivalent(for keyCode: UInt32) -> String? {
        letterOrDigit(for: keyCode)?.lowercased()
    }

    static func nsModifierFlags(from carbon: UInt32) -> NSEvent.ModifierFlags {
        var flags: NSEvent.ModifierFlags = []
        if carbon & UInt32(cmdKey) != 0 { flags.insert(.command) }
        if carbon & UInt32(optionKey) != 0 { flags.insert(.option) }
        if carbon & UInt32(controlKey) != 0 { flags.insert(.control) }
        if carbon & UInt32(shiftKey) != 0 { flags.insert(.shift) }
        return flags
    }

    private static let specialKeyNames: [UInt32: String] = [
        UInt32(kVK_Return): "↩",
        UInt32(kVK_Tab): "⇥",
        UInt32(kVK_Space): "Space",
        UInt32(kVK_Delete): "⌫",
        UInt32(kVK_Escape): "⎋",
        UInt32(kVK_LeftArrow): "←",
        UInt32(kVK_RightArrow): "→",
        UInt32(kVK_UpArrow): "↑",
        UInt32(kVK_DownArrow): "↓",
        UInt32(kVK_F1): "F1", UInt32(kVK_F2): "F2", UInt32(kVK_F3): "F3",
        UInt32(kVK_F4): "F4", UInt32(kVK_F5): "F5", UInt32(kVK_F6): "F6",
        UInt32(kVK_F7): "F7", UInt32(kVK_F8): "F8", UInt32(kVK_F9): "F9",
        UInt32(kVK_F10): "F10", UInt32(kVK_F11): "F11", UInt32(kVK_F12): "F12"
    ]

    private static func letterOrDigit(for keyCode: UInt32) -> String? {
        let map: [UInt32: String] = [
            UInt32(kVK_ANSI_A): "A", UInt32(kVK_ANSI_B): "B", UInt32(kVK_ANSI_C): "C",
            UInt32(kVK_ANSI_D): "D", UInt32(kVK_ANSI_E): "E", UInt32(kVK_ANSI_F): "F",
            UInt32(kVK_ANSI_G): "G", UInt32(kVK_ANSI_H): "H", UInt32(kVK_ANSI_I): "I",
            UInt32(kVK_ANSI_J): "J", UInt32(kVK_ANSI_K): "K", UInt32(kVK_ANSI_L): "L",
            UInt32(kVK_ANSI_M): "M", UInt32(kVK_ANSI_N): "N", UInt32(kVK_ANSI_O): "O",
            UInt32(kVK_ANSI_P): "P", UInt32(kVK_ANSI_Q): "Q", UInt32(kVK_ANSI_R): "R",
            UInt32(kVK_ANSI_S): "S", UInt32(kVK_ANSI_T): "T", UInt32(kVK_ANSI_U): "U",
            UInt32(kVK_ANSI_V): "V", UInt32(kVK_ANSI_W): "W", UInt32(kVK_ANSI_X): "X",
            UInt32(kVK_ANSI_Y): "Y", UInt32(kVK_ANSI_Z): "Z",
            UInt32(kVK_ANSI_0): "0", UInt32(kVK_ANSI_1): "1", UInt32(kVK_ANSI_2): "2",
            UInt32(kVK_ANSI_3): "3", UInt32(kVK_ANSI_4): "4", UInt32(kVK_ANSI_5): "5",
            UInt32(kVK_ANSI_6): "6", UInt32(kVK_ANSI_7): "7", UInt32(kVK_ANSI_8): "8",
            UInt32(kVK_ANSI_9): "9"
        ]
        return map[keyCode]
    }
}
