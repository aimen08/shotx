import Cocoa
import Combine

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

    func remove(_ entry: CaptureEntry) {
        try? FileManager.default.removeItem(at: fileURL(for: entry))
        entries.removeAll { $0.id == entry.id }
        save()
    }

    func clear() {
        for e in entries {
            try? FileManager.default.removeItem(at: fileURL(for: e))
        }
        entries.removeAll()
        save()
    }
}
