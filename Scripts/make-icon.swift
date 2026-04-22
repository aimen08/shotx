#!/usr/bin/env swift
import Cocoa
import Foundation

// Run from project root: ./Scripts/make-icon.swift
// Produces Resources/AppIcon.icns

let projectRoot = FileManager.default.currentDirectoryPath
let resourcesDir = "\(projectRoot)/Resources"
let iconsetDir = "\(resourcesDir)/AppIcon.iconset"
let icnsPath = "\(resourcesDir)/AppIcon.icns"

try? FileManager.default.createDirectory(atPath: iconsetDir, withIntermediateDirectories: true)

func renderPNG(size: Int) -> Data? {
    let s = CGFloat(size)
    let img = NSImage(size: NSSize(width: s, height: s))
    img.lockFocus()

    // Background squircle with vertical gradient.
    let cornerRadius = s * 0.224
    let rect = NSRect(x: 0, y: 0, width: s, height: s)
    let bgPath = NSBezierPath(roundedRect: rect, xRadius: cornerRadius, yRadius: cornerRadius)

    let gradient = NSGradient(colors: [
        NSColor(srgbRed: 0.18, green: 0.58, blue: 1.0, alpha: 1.0),
        NSColor(srgbRed: 0.02, green: 0.28, blue: 0.78, alpha: 1.0)
    ])!
    gradient.draw(in: bgPath, angle: -90)

    // Soft top highlight
    bgPath.addClip()
    let highlight = NSGradient(colors: [
        NSColor(white: 1.0, alpha: 0.18),
        NSColor(white: 1.0, alpha: 0.0)
    ])!
    highlight.draw(in: NSRect(x: 0, y: s * 0.55, width: s, height: s * 0.45), angle: -90)

    // Viewfinder corner brackets
    let inset = s * 0.20
    let cornerLen = s * 0.16
    let cornerWidth = s * 0.06
    let frame = NSRect(x: inset, y: inset, width: s - 2 * inset, height: s - 2 * inset)

    NSColor.white.setStroke()
    let corners = NSBezierPath()
    corners.lineWidth = cornerWidth
    corners.lineCapStyle = .round
    corners.lineJoinStyle = .round

    // Top-left
    corners.move(to: NSPoint(x: frame.minX, y: frame.maxY - cornerLen))
    corners.line(to: NSPoint(x: frame.minX, y: frame.maxY))
    corners.line(to: NSPoint(x: frame.minX + cornerLen, y: frame.maxY))

    // Top-right
    corners.move(to: NSPoint(x: frame.maxX - cornerLen, y: frame.maxY))
    corners.line(to: NSPoint(x: frame.maxX, y: frame.maxY))
    corners.line(to: NSPoint(x: frame.maxX, y: frame.maxY - cornerLen))

    // Bottom-right
    corners.move(to: NSPoint(x: frame.maxX, y: frame.minY + cornerLen))
    corners.line(to: NSPoint(x: frame.maxX, y: frame.minY))
    corners.line(to: NSPoint(x: frame.maxX - cornerLen, y: frame.minY))

    // Bottom-left
    corners.move(to: NSPoint(x: frame.minX + cornerLen, y: frame.minY))
    corners.line(to: NSPoint(x: frame.minX, y: frame.minY))
    corners.line(to: NSPoint(x: frame.minX, y: frame.minY + cornerLen))

    corners.stroke()

    // Center X
    let xRadius = s * 0.07
    let xLine = s * 0.07
    let cx = s / 2
    let cy = s / 2
    let xPath = NSBezierPath()
    xPath.lineWidth = xLine
    xPath.lineCapStyle = .round
    xPath.move(to: NSPoint(x: cx - xRadius, y: cy - xRadius))
    xPath.line(to: NSPoint(x: cx + xRadius, y: cy + xRadius))
    xPath.move(to: NSPoint(x: cx + xRadius, y: cy - xRadius))
    xPath.line(to: NSPoint(x: cx - xRadius, y: cy + xRadius))
    NSColor.white.setStroke()
    xPath.stroke()

    img.unlockFocus()

    guard let tiff = img.tiffRepresentation,
          let rep = NSBitmapImageRep(data: tiff)
    else { return nil }
    rep.size = NSSize(width: size, height: size)
    return rep.representation(using: .png, properties: [:])
}

let sizes: [(name: String, pixels: Int)] = [
    ("icon_16x16.png", 16),
    ("icon_16x16@2x.png", 32),
    ("icon_32x32.png", 32),
    ("icon_32x32@2x.png", 64),
    ("icon_128x128.png", 128),
    ("icon_128x128@2x.png", 256),
    ("icon_256x256.png", 256),
    ("icon_256x256@2x.png", 512),
    ("icon_512x512.png", 512),
    ("icon_512x512@2x.png", 1024)
]

print("→ Rendering icon at \(sizes.count) sizes…")
for (name, pixels) in sizes {
    guard let data = renderPNG(size: pixels) else {
        FileHandle.standardError.write(Data("✗ Failed: \(name)\n".utf8))
        continue
    }
    try? data.write(to: URL(fileURLWithPath: "\(iconsetDir)/\(name)"))
    print("  ✓ \(name)  (\(pixels)px)")
}

print("→ Packing into \(icnsPath)")
let iconutil = Process()
iconutil.launchPath = "/usr/bin/iconutil"
iconutil.arguments = ["-c", "icns", iconsetDir, "-o", icnsPath]
try iconutil.run()
iconutil.waitUntilExit()

guard iconutil.terminationStatus == 0 else {
    FileHandle.standardError.write(Data("✗ iconutil failed\n".utf8))
    exit(1)
}
print("✓ \(icnsPath)")
