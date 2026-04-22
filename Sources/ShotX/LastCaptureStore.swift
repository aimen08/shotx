import Cocoa

struct StoredCapture {
    let rect: CGRect
    let screen: NSScreen
}

enum LastCaptureStore {
    private static let key = "com.shotx.lastCapture"

    static func save(rect: CGRect, screen: NSScreen) {
        let screenIdx = NSScreen.screens.firstIndex(of: screen) ?? 0
        let dict: [String: Any] = [
            "x": rect.origin.x,
            "y": rect.origin.y,
            "w": rect.width,
            "h": rect.height,
            "screen": screenIdx
        ]
        UserDefaults.standard.set(dict, forKey: key)
    }

    static func load() -> StoredCapture? {
        guard let dict = UserDefaults.standard.dictionary(forKey: key),
              let x = dict["x"] as? CGFloat,
              let y = dict["y"] as? CGFloat,
              let w = dict["w"] as? CGFloat,
              let h = dict["h"] as? CGFloat
        else { return nil }
        let idx = (dict["screen"] as? Int) ?? 0
        let screen = NSScreen.screens.indices.contains(idx)
            ? NSScreen.screens[idx]
            : NSScreen.main
        guard let screen = screen else { return nil }
        return StoredCapture(rect: CGRect(x: x, y: y, width: w, height: h), screen: screen)
    }

    static var hasPrevious: Bool { load() != nil }
}
