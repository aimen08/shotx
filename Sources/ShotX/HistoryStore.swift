import Cocoa
import Combine

struct CaptureEntry: Identifiable, Codable, Equatable {
    let id: UUID
    let filename: String
    let createdAt: Date
    let width: CGFloat
    let height: CGFloat
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
            id: UUID(),
            filename: "\(UUID().uuidString).png",
            createdAt: Date(),
            width: image.size.width,
            height: image.size.height
        )
        let url = historyDir.appendingPathComponent(entry.filename)
        do { try png.write(to: url) } catch { return nil }

        entries.insert(entry, at: 0)
        if entries.count > maxEntries {
            for old in entries.suffix(from: maxEntries) {
                try? FileManager.default.removeItem(at: fileURL(for: old))
            }
            entries = Array(entries.prefix(maxEntries))
        }
        save()
        return entry
    }

    func fileURL(for entry: CaptureEntry) -> URL {
        historyDir.appendingPathComponent(entry.filename)
    }

    func image(for entry: CaptureEntry) -> NSImage? {
        NSImage(contentsOf: fileURL(for: entry))
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
