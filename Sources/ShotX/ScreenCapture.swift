import Cocoa
import CoreGraphics

enum ScreenCapture {
    /// Captures a region given in AppKit global coordinates
    /// (origin at the bottom-left of the primary screen).
    static func capture(rectInScreenCoords rect: CGRect, screen: NSScreen) -> NSImage? {
        guard let primary = NSScreen.screens.first else { return nil }

        // CGWindowListCreateImage expects top-left origin on the primary screen.
        let flippedY = primary.frame.height - rect.origin.y - rect.height
        let captureRect = CGRect(
            x: rect.origin.x,
            y: flippedY,
            width: rect.width,
            height: rect.height
        )

        guard let cgImage = CGWindowListCreateImage(
            captureRect,
            .optionOnScreenOnly,
            kCGNullWindowID,
            [.bestResolution]
        ) else {
            return nil
        }

        return NSImage(cgImage: cgImage, size: rect.size)
    }
}
