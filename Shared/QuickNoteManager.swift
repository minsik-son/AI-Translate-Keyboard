import Foundation

class QuickNoteManager {
    static let shared = QuickNoteManager()

    private let defaults = UserDefaults(suiteName: AppConstants.appGroupIdentifier)
    private let key = AppConstants.UserDefaultsKeys.quickNotes

    private init() {}

    // MARK: - CRUD

    func getAllNotes() -> [QuickNote] {
        return load().sorted { $0.updatedAt > $1.updatedAt }
    }

    func addNote(_ content: String) {
        let trimmed = String(content.prefix(AppConstants.Limits.quickNoteMaxLength))
        var notes = load()
        let newNote = QuickNote(content: trimmed)
        notes.insert(newNote, at: 0)
        if notes.count > AppConstants.Limits.quickNoteMaxCount {
            notes = Array(notes.prefix(AppConstants.Limits.quickNoteMaxCount))
        }
        save(notes)
    }

    func updateNote(id: UUID, content: String) {
        let trimmed = String(content.prefix(AppConstants.Limits.quickNoteMaxLength))
        var notes = load()
        guard let index = notes.firstIndex(where: { $0.id == id }) else { return }
        notes[index].content = trimmed
        notes[index].updatedAt = Date()
        save(notes)
    }

    func deleteNote(id: UUID) {
        var notes = load()
        notes.removeAll { $0.id == id }
        save(notes)
    }

    // MARK: - Persistence (CC-7: 동시성 안전)

    private func load() -> [QuickNote] {
        guard let data = defaults?.data(forKey: key) else { return [] }
        return (try? JSONDecoder().decode([QuickNote].self, from: data)) ?? []
    }

    private func save(_ notes: [QuickNote]) {
        guard let data = try? JSONEncoder().encode(notes) else { return }
        defaults?.set(data, forKey: key)
    }
}
