import Foundation
import AppKit

enum ClipKind: String, Codable {
    case text
    case image
}

/// Satu entri riwayat clipboard.
struct ClipItem: Identifiable, Codable, Equatable {
    let id: UUID
    var kind: ClipKind
    var text: String        // teks (untuk item teks) atau label (untuk gambar)
    var imageData: Data?    // PNG (untuk item gambar)
    var date: Date
    var pinned: Bool

    init(id: UUID = UUID(),
         kind: ClipKind,
         text: String,
         imageData: Data? = nil,
         date: Date = Date(),
         pinned: Bool = false) {
        self.id = id
        self.kind = kind
        self.text = text
        self.imageData = imageData
        self.date = date
        self.pinned = pinned
    }

    var preview: String {
        switch kind {
        case .text:
            let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
            return trimmed.isEmpty ? "(empty)" : trimmed
        case .image:
            return "🖼 Image"
        }
    }

    var image: NSImage? {
        guard let imageData else { return nil }
        return NSImage(data: imageData)
    }
}
