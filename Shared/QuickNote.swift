import Foundation

struct QuickNote: Codable, Identifiable {
    let id: UUID
    var content: String
    let createdAt: Date
    var updatedAt: Date

    init(content: String) {
        self.id = UUID()
        self.content = content
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}
