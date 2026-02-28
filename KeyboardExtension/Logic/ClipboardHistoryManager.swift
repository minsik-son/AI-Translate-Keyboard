import Foundation

final class ClipboardHistoryManager {
    static let shared = ClipboardHistoryManager()

    private let maxItems = 30
    private let maxTextLength = 2000

    private init() {}

    func getItems() -> [ClipboardItem] {
        guard let defaults = UserDefaults(suiteName: AppConstants.appGroupIdentifier),
              let data = defaults.data(forKey: AppConstants.UserDefaultsKeys.clipboardHistory) else {
            return []
        }
        return (try? JSONDecoder().decode([ClipboardItem].self, from: data)) ?? []
    }

    func addItem(_ text: String) {
        let trimmed = String(text.prefix(maxTextLength))
        guard !trimmed.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }

        var items = getItems()

        // Remove duplicate
        items.removeAll { $0.text == trimmed }

        let newItem = ClipboardItem(id: UUID(), text: trimmed, copiedAt: Date())
        items.insert(newItem, at: 0)

        // Enforce max count
        if items.count > maxItems {
            items = Array(items.prefix(maxItems))
        }

        save(items)
    }

    func deleteItem(at index: Int) {
        var items = getItems()
        guard index >= 0, index < items.count else { return }
        items.remove(at: index)
        save(items)
    }

    func clearAll() {
        save([])
    }

    private func save(_ items: [ClipboardItem]) {
        guard let defaults = UserDefaults(suiteName: AppConstants.appGroupIdentifier),
              let data = try? JSONEncoder().encode(items) else { return }
        defaults.set(data, forKey: AppConstants.UserDefaultsKeys.clipboardHistory)
    }
}
