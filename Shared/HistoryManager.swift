import Foundation

extension Notification.Name {
    static let historyDidChange = Notification.Name("historyDidChange")
}

final class HistoryManager {
    static let shared = HistoryManager()

    private let defaults: UserDefaults?
    private let historyKey = "history_items"
    private var maxItems: Int { FeatureGate.shared.maxHistoryItems }

    private init() {
        defaults = UserDefaults(suiteName: AppConstants.appGroupIdentifier)
    }

    func addItem(type: HistoryType, original: String, result: String?, metadata: String?) {
        var items = loadItems()
        let item = HistoryItem(
            id: UUID(),
            type: type,
            originalText: original,
            resultText: result,
            metadata: metadata,
            createdAt: Date()
        )
        items.insert(item, at: 0)
        if items.count > maxItems {
            items = Array(items.prefix(maxItems))
        }
        saveItems(items)
    }

    func loadItems() -> [HistoryItem] {
        guard let data = defaults?.data(forKey: historyKey) else { return [] }
        return (try? JSONDecoder().decode([HistoryItem].self, from: data)) ?? []
    }

    func loadItems(ofType type: HistoryType) -> [HistoryItem] {
        return loadItems().filter { $0.type == type }
    }

    func deleteItem(id: UUID) {
        var items = loadItems()
        items.removeAll { $0.id == id }
        saveItems(items)
    }

    func clearAll() {
        saveItems([])
    }

    func weeklyCount(ofType type: HistoryType) -> Int {
        var calendar = Calendar.current
        calendar.firstWeekday = 2 // Monday
        let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date())
        guard let monday = calendar.date(from: components) else { return 0 }
        return loadItems().filter { $0.type == type && $0.createdAt >= monday }.count
    }

    func lastWeekCount(ofType type: HistoryType) -> Int {
        var calendar = Calendar.current
        calendar.firstWeekday = 2 // Monday
        let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date())
        guard let thisMonday = calendar.date(from: components),
              let lastMonday = calendar.date(byAdding: .weekOfYear, value: -1, to: thisMonday) else { return 0 }
        return loadItems().filter { $0.type == type && $0.createdAt >= lastMonday && $0.createdAt < thisMonday }.count
    }

    private func saveItems(_ items: [HistoryItem]) {
        guard let data = try? JSONEncoder().encode(items) else { return }
        defaults?.set(data, forKey: historyKey)
        NotificationCenter.default.post(name: .historyDidChange, object: nil)
    }
}
