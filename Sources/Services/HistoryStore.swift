import Foundation
import AppKit
import Combine

/// Menyimpan & mengelola riwayat clipboard (persisten di Application Support).
/// Versi gratis dibatasi [freeLimit] item tak-terpin; Pro = tak terbatas.
@MainActor
final class HistoryStore: ObservableObject {
    @Published private(set) var items: [ClipItem] = []
    @Published var isPro = false { didSet { trim(); save() } }

    let freeLimit = 25
    private let fileURL: URL

    init() {
        let fm = FileManager.default
        let base = fm.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        let dir = base.appendingPathComponent("ClipNest", isDirectory: true)
        try? fm.createDirectory(at: dir, withIntermediateDirectories: true)
        fileURL = dir.appendingPathComponent("history.json")
        load()
    }

    // MARK: mutations
    func add(_ item: ClipItem) {
        if item.kind == .text,
           let idx = items.firstIndex(where: { $0.kind == .text && $0.text == item.text }) {
            var existing = items.remove(at: idx)
            existing.date = Date()
            items.insert(existing, at: 0)
        } else {
            items.insert(item, at: 0)
        }
        trim()
        save()
    }

    func togglePin(_ item: ClipItem) {
        guard let idx = items.firstIndex(where: { $0.id == item.id }) else { return }
        items[idx].pinned.toggle()
        save()
    }

    func delete(_ item: ClipItem) {
        items.removeAll { $0.id == item.id }
        save()
    }

    func clearUnpinned() {
        items.removeAll { !$0.pinned }
        save()
    }

    /// Salin item kembali ke clipboard sistem.
    func copyToPasteboard(_ item: ClipItem) {
        let pb = NSPasteboard.general
        pb.clearContents()
        switch item.kind {
        case .text:
            pb.setString(item.text, forType: .string)
        case .image:
            if let data = item.imageData { pb.setData(data, forType: .png) }
        }
    }

    // MARK: helpers
    /// Daftar untuk ditampilkan: pinned dulu, lalu terbaru.
    func filtered(_ query: String) -> [ClipItem] {
        let base = query.isEmpty ? items : items.filter {
            $0.kind == .text && $0.text.localizedCaseInsensitiveContains(query)
        }
        return base.sorted { a, b in
            if a.pinned != b.pinned { return a.pinned && !b.pinned }
            return a.date > b.date
        }
    }

    private func trim() {
        guard !isPro else { return }
        let unpinnedIds = items.filter { !$0.pinned }.map { $0.id }
        if unpinnedIds.count > freeLimit {
            let remove = Set(unpinnedIds.suffix(unpinnedIds.count - freeLimit))
            items.removeAll { remove.contains($0.id) }
        }
    }

    private func load() {
        guard let data = try? Data(contentsOf: fileURL),
              let decoded = try? JSONDecoder().decode([ClipItem].self, from: data) else { return }
        items = decoded
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(items) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }
}
