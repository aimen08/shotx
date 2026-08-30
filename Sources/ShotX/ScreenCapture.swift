import Cocoa
import CoreGraphics

/// Window numbers of ShotX's own transient chrome — the selection overlay, the
/// countdown, the recording viewfinder, toasts, the post-capture popup.
///
/// Every capture filters these out of the window list, so our own UI can never
/// end up in a screenshot even while it's still on screen. That's what lets the
/// capture paths run synchronously: they used to order our windows out and then
/// sleep 120–200 ms hoping the window server had caught up before grabbing
/// pixels.
///
/// Only transient chrome registers here. Windows the user could legitimately
/// want inside a screenshot — pinned images, the annotator, the main window —
/// stay visible to the capture.
///
/// Main-thread only, like the AppKit windows it tracks.
enum CaptureExclusions {
    private static var live: Set<Int> = []
    private static var retired: [Int] = []
    private static let retiredLimit = 64

    static func register(_ window: NSWindow?) {
        guard let n = window?.windowNumber, n > 0 else { return }
        live.insert(n)
    }

    /// Retires a window number rather than dropping it. `close()` returns before
    /// the window server has necessarily stopped compositing the window, and a
    /// capture landing in that gap must not pick it up. Window numbers are never
    /// reused, so a stale entry can't shadow another window later.
    static func unregister(_ window: NSWindow?) {
        guard let n = window?.windowNumber, n > 0 else { return }
        live.remove(n)
        guard !retired.contains(n) else { return }
        retired.append(n)
        if retired.count > retiredLimit {
            retired.removeFirst(retired.count - retiredLimit)
        }
    }

    static var windowIDs: Set<CGWindowID> {
        Set((live.union(retired)).compactMap { $0 > 0 ? CGWindowID($0) : nil })
    }
}

enum ScreenCapture {
    /// Captures a region given in AppKit global coordinates
    /// (origin at the bottom-left of the primary screen).
    ///
    /// - Parameter requiresChromeExclusion: when true, returns nil instead of
    ///   falling back to a plain composite. Callers that capture while a
    ///   full-screen overlay of ours is still up pass this — a fallback frame
    ///   there would contain the dimming layer and crosshair.
    static func capture(
        rectInScreenCoords rect: CGRect,
        screen: NSScreen,
        requiresChromeExclusion: Bool = false
    ) -> NSImage? {
        guard let primary = NSScreen.screens.first else { return nil }

        // CGWindowListCreateImage expects top-left origin on the primary screen.
        let flippedY = primary.frame.height - rect.origin.y - rect.height
        let captureRect = CGRect(
            x: rect.origin.x,
            y: flippedY,
            width: rect.width,
            height: rect.height
        )

        guard let cgImage = cgImage(of: captureRect, requiresChromeExclusion: requiresChromeExclusion) else {
            return nil
        }
        return NSImage(cgImage: cgImage, size: rect.size)
    }

    /// Composites everything on screen except our own transient chrome.
    private static func cgImage(of rect: CGRect, requiresChromeExclusion: Bool) -> CGImage? {
        let excluded = CaptureExclusions.windowIDs
        if !excluded.isEmpty, let image = compositeExcluding(excluded, in: rect) {
            return image
        }
        if requiresChromeExclusion { return nil }
        return CGWindowListCreateImage(rect, .optionOnScreenOnly, kCGNullWindowID, [.bestResolution])
    }

    /// Builds the capture from an explicit front-to-back window list with the
    /// excluded IDs removed. Returns nil if the window list can't be built, so
    /// the caller can decide between a plain composite and giving up.
    private static func compositeExcluding(_ excluded: Set<CGWindowID>, in rect: CGRect) -> CGImage? {
        let infos = (CGWindowListCopyWindowInfo(.optionOnScreenOnly, kCGNullWindowID) as? [[String: Any]]) ?? []
        let ids: [CGWindowID] = infos.compactMap { info in
            guard let id = info[kCGWindowNumber as String] as? CGWindowID,
                  !excluded.contains(id)
            else { return nil }
            return id
        }
        guard !ids.isEmpty else { return nil }

        // CGImage(windowListFromArrayScreenBounds:) wants a CFArray of window IDs
        // stuffed into pointer-sized slots rather than boxed numbers.
        var pointers = ids.map { UnsafeRawPointer(bitPattern: UInt($0)) }
        guard let array = CFArrayCreate(nil, &pointers, pointers.count, nil) else { return nil }
        return CGImage(
            windowListFromArrayScreenBounds: rect,
            windowArray: array,
            imageOption: [.bestResolution]
        )
    }
}
