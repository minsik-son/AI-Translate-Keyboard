import Foundation

final class StatsManager {
    static let shared = StatsManager()

    private let defaults: UserDefaults?

    private enum Keys {
        static let weeklyWordsTyped = "stats_weekly_words_typed"
        static let weeklyCorrectWords = "stats_weekly_correct_words"
        static let weekStartDate = "stats_week_start_date"
        static let lastWeekAccuracy = "stats_last_week_accuracy"
    }

    private init() {
        defaults = UserDefaults(suiteName: AppConstants.appGroupIdentifier)
    }

    // MARK: - Week Management

    /// 현재 주의 월요일 00:00 반환
    private func currentWeekMonday() -> Date {
        var calendar = Calendar.current
        calendar.firstWeekday = 2 // Monday
        let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date())
        return calendar.date(from: components) ?? Date()
    }

    /// 주간 리셋이 필요한지 확인하고 필요하면 리셋
    func checkAndResetWeeklyStats() {
        let monday = currentWeekMonday()
        let savedDate = defaults?.object(forKey: Keys.weekStartDate) as? Date

        if savedDate == nil || savedDate! < monday {
            // 현재 정확도를 지난주로 이동
            let currentWords = defaults?.integer(forKey: Keys.weeklyWordsTyped) ?? 0
            let currentCorrectWords = defaults?.integer(forKey: Keys.weeklyCorrectWords) ?? 0

            if currentWords > 0 {
                let accuracy = Double(currentCorrectWords) / Double(currentWords) * 100.0
                defaults?.set(accuracy, forKey: Keys.lastWeekAccuracy)
            }

            // 현재 주 초기화
            defaults?.set(0, forKey: Keys.weeklyWordsTyped)
            defaults?.set(0, forKey: Keys.weeklyCorrectWords)
            defaults?.set(monday, forKey: Keys.weekStartDate)
        }
    }

    // MARK: - Increment

    func incrementWordsTyped() {
        let current = defaults?.integer(forKey: Keys.weeklyWordsTyped) ?? 0
        defaults?.set(current + 1, forKey: Keys.weeklyWordsTyped)
    }

    func incrementCorrectWords() {
        let current = defaults?.integer(forKey: Keys.weeklyCorrectWords) ?? 0
        defaults?.set(current + 1, forKey: Keys.weeklyCorrectWords)
    }

    // MARK: - Read

    var weeklyCorrections: Int {
        HistoryManager.shared.weeklyCount(ofType: .correction)
    }

    var weeklyTranslations: Int {
        HistoryManager.shared.weeklyCount(ofType: .translation)
    }

    var weeklyWordsTyped: Int {
        defaults?.integer(forKey: Keys.weeklyWordsTyped) ?? 0
    }

    var weeklyAccuracy: Double {
        let words = defaults?.integer(forKey: Keys.weeklyWordsTyped) ?? 0
        let correct = defaults?.integer(forKey: Keys.weeklyCorrectWords) ?? 0
        guard words > 0 else { return 0 }
        return Double(correct) / Double(words) * 100.0
    }

    var lastWeekCorrections: Int {
        HistoryManager.shared.lastWeekCount(ofType: .correction)
    }

    var lastWeekAccuracy: Double {
        defaults?.double(forKey: Keys.lastWeekAccuracy) ?? 0
    }

    var accuracyChange: Double {
        let current = weeklyAccuracy
        let last = lastWeekAccuracy
        guard last > 0 else { return 0 }
        return current - last
    }
}
