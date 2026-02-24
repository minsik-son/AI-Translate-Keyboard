import Foundation

class SessionManager {
    static let shared = SessionManager()

    private let appGroup = AppGroupManager.shared

    private init() {
        resetIfNewDay()
    }

    var remainingSessions: Int {
        let used = appGroup.integer(forKey: AppConstants.UserDefaultsKeys.dailySessionCount)
        let bonus = appGroup.integer(forKey: AppConstants.UserDefaultsKeys.bonusSessions)
        let total = AppConstants.Limits.freeSessionsPerDay + bonus
        return max(0, total - used)
    }

    var canTranslate: Bool {
        if SubscriptionStatus.shared.isPro { return true }
        resetIfNewDay()
        return remainingSessions > 0
    }

    func useSession() {
        guard !SubscriptionStatus.shared.isPro else { return }
        resetIfNewDay()
        let current = appGroup.integer(forKey: AppConstants.UserDefaultsKeys.dailySessionCount)
        appGroup.set(current + 1, forKey: AppConstants.UserDefaultsKeys.dailySessionCount)
    }

    func addBonusSessions(_ count: Int) {
        let current = appGroup.integer(forKey: AppConstants.UserDefaultsKeys.bonusSessions)
        appGroup.set(current + count, forKey: AppConstants.UserDefaultsKeys.bonusSessions)
    }

    private func resetIfNewDay() {
        let today = Calendar.current.startOfDay(for: Date())
        if let lastDate = appGroup.date(forKey: AppConstants.UserDefaultsKeys.lastSessionDate),
           Calendar.current.isDate(lastDate, inSameDayAs: today) {
            return
        }
        appGroup.set(0, forKey: AppConstants.UserDefaultsKeys.dailySessionCount)
        appGroup.set(today, forKey: AppConstants.UserDefaultsKeys.lastSessionDate)
    }
}
