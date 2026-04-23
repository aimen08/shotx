import Cocoa
import Combine
import AVFoundation
import ImageIO

struct CaptureEntry: Identifiable, Codable, Equatable {
    enum Kind: String, Codable {
        case image, video, gif
    }

    let id: UUID
    let filename: String
    let createdAt: Date
    let width: CGFloat
    let height: CGFloat
    let kind: Kind
    let duration: TimeInterval?

    init(
        id: UUID = UUID(),
        filename: String,
        createdAt: Date,
        width: CGFloat,
        height: CGFloat,
        kind: Kind = .image,
        duration: TimeInterval? = nil
    ) {
        self.id = id
        self.filename = filename
        self.createdAt = createdAt
        self.width = width
        self.height = height
        self.kind = kind
        self.duration = duration
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        filename = try c.decode(String.self, forKey: .filename)
        createdAt = try c.decode(Date.self, forKey: .createdAt)
        width = try c.decode(CGFloat.self, forKey: .width)
        height = try c.decode(CGFloat.self, forKey: .height)
        // Backwards compat: older entries lack `kind` and `duration`.
        kind = (try? c.decode(Kind.self, forKey: .kind)) ?? .image
        duration = try? c.decode(TimeInterval.self, forKey: .duration)
    }
}

final class HistoryStore: ObservableObject {
    static let shared = HistoryStore()

    @Published private(set) var entries: [CaptureEntry] = []

    private let maxEntries = 100
    private let historyDir: URL
    private let indexURL: URL

    /// In-memory cache of downsampled thumbnails, keyed by entry ID. Auto-evicts
    /// on memory pressure via NSCache's built-in behaviour.
    private let thumbnailCache: NSCache<NSString, NSImage> = {
        let c = NSCache<NSString, NSImage>()
        c.countLimit = 200
        return c
    }()

    init() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let root = appSupport.appendingPathComponent("ShotX", isDirectory: true)
        historyDir = root.appendingPathComponent("History", isDirectory: true)
        indexURL = root.appendingPathComponent("history.json")
        try? FileManager.default.createDirectory(at: historyDir, withIntermediateDirectories: true)
        load()
    }

    private func load() {
        guard let data = try? Data(contentsOf: indexURL),
              let decoded = try? JSONDecoder().decode([CaptureEntry].self, from: data)
        else { return }
        entries = decoded
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(entries) else { return }
        try? data.write(to: indexURL, options: .atomic)
    }

    @discardableResult
    func add(_ image: NSImage) -> CaptureEntry? {
        guard let png = ImageSaver.pngData(from: image) else { return nil }
        let entry = CaptureEntry(
            filename: "\(UUID().uuidString).png",
            createdAt: Date(),
            width: image.size.width,
            height: image.size.height,
            kind: .image
        )
        let url = historyDir.appendingPathComponent(entry.filename)
        do { try png.write(to: url) } catch { return nil }
        register(entry)
        return entry
    }

    @discardableResult
    func add(videoAt sourceURL: URL, duration: TimeInterval, dimensions: CGSize) -> CaptureEntry? {
        let entry = CaptureEntry(
            filename: "\(UUID().uuidString).mp4",
            createdAt: Date(),
            width: dimensions.width,
            height: dimensions.height,
            kind: .video,
            duration: duration
        )
        return moveIntoHistory(sourceURL: sourceURL, entry: entry)
    }

    @discardableResult
    func add(gifAt sourceURL: URL, duration: TimeInterval, dimensions: CGSize) -> CaptureEntry? {
        let entry = CaptureEntry(
            filename: "\(UUID().uuidString).gif",
            createdAt: Date(),
            width: dimensions.width,
            height: dimensions.height,
            kind: .gif,
            duration: duration
        )
        return moveIntoHistory(sourceURL: sourceURL, entry: entry)
    }

    private func moveIntoHistory(sourceURL: URL, entry: CaptureEntry) -> CaptureEntry? {
        let dest = historyDir.appendingPathComponent(entry.filename)
        do {
            if FileManager.default.fileExists(atPath: dest.path) {
                try FileManager.default.removeItem(at: dest)
            }
            try FileManager.default.moveItem(at: sourceURL, to: dest)
        } catch {
            // Fall back to copy if move fails (different volumes)
            do { try FileManager.default.copyItem(at: sourceURL, to: dest) }
            catch { return nil }
        }
        register(entry)
        return entry
    }

    private func register(_ entry: CaptureEntry) {
        entries.insert(entry, at: 0)
        if entries.count > maxEntries {
            for old in entries.suffix(from: maxEntries) {
                try? FileManager.default.removeItem(at: fileURL(for: old))
            }
            entries = Array(entries.prefix(maxEntries))
        }
        save()
    }

    func fileURL(for entry: CaptureEntry) -> URL {
        historyDir.appendingPathComponent(entry.filename)
    }

    func image(for entry: CaptureEntry) -> NSImage? {
        let url = fileURL(for: entry)
        switch entry.kind {
        case .image, .gif:
            return NSImage(contentsOf: url)
        case .video:
            return VideoThumbnail.firstFrame(of: url)
        }
    }

    /// Returns a small, decoded, cached thumbnail suitable for the history grid.
    /// Decodes on a background queue; first call per entry hits disk, subsequent
    /// calls return from the in-memory cache. `@MainActor` so NSImage? doesn't
    /// have to cross an actor boundary when returned to the SwiftUI caller.
    @MainActor
    func thumbnail(for entry: CaptureEntry, maxDim: CGFloat = 300) async -> NSImage? {
        let key = entry.id.uuidString as NSString
        if let cached = thumbnailCache.object(forKey: key) {
            return cached
        }

        let url = fileURL(for: entry)
        let kind = entry.kind

        let image: NSImage? = await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let img: NSImage?
                switch kind {
                case .image, .gif:
                    img = HistoryStore.downsampledImage(at: url, maxDim: maxDim)
                case .video:
                    img = HistoryStore.downsampledVideoFrame(at: url, maxDim: maxDim)
                }
                continuation.resume(returning: img)
            }
        }

        if let image = image {
            thumbnailCache.setObject(image, forKey: key)
        }
        return image
    }

    private static func downsampledImage(at url: URL, maxDim: CGFloat) -> NSImage? {
        guard let src = CGImageSourceCreateWithURL(url as CFURL, nil) else { return nil }
        let opts: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceThumbnailMaxPixelSize: maxDim * 2, // 2x for Retina
            kCGImageSourceShouldCacheImmediately: true
        ]
        guard let cg = CGImageSourceCreateThumbnailAtIndex(src, 0, opts as CFDictionary) else { return nil }
        let pointSize = NSSize(width: CGFloat(cg.width) / 2, height: CGFloat(cg.height) / 2)
        return NSImage(cgImage: cg, size: pointSize)
    }

    private static func downsampledVideoFrame(at url: URL, maxDim: CGFloat) -> NSImage? {
        let asset = AVURLAsset(url: url)
        let gen = AVAssetImageGenerator(asset: asset)
        gen.appliesPreferredTrackTransform = true
        gen.maximumSize = CGSize(width: maxDim * 2, height: maxDim * 2)
        gen.requestedTimeToleranceBefore = .zero
        gen.requestedTimeToleranceAfter = .zero
        let time = CMTime(seconds: 0.1, preferredTimescale: 600)
        guard let cg = try? gen.copyCGImage(at: time, actualTime: nil) else { return nil }
        let pointSize = NSSize(width: CGFloat(cg.width) / 2, height: CGFloat(cg.height) / 2)
        return NSImage(cgImage: cg, size: pointSize)
    }

    func remove(_ entry: CaptureEntry) {
        try? FileManager.default.removeItem(at: fileURL(for: entry))
        thumbnailCache.removeObject(forKey: entry.id.uuidString as NSString)
        entries.removeAll { $0.id == entry.id }
        save()
    }

    func clear() {
        for e in entries {
            try? FileManager.default.removeItem(at: fileURL(for: e))
        }
        thumbnailCache.removeAllObjects()
        entries.removeAll()
        save()
    }
}
