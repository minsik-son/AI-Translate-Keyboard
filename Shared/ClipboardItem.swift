import Foundation

struct ClipboardItem: Codable, Identifiable {
    let id: UUID
    let text: String
    let copiedAt: Date
    var preview: String { String(text.prefix(50)) }
}
