import Foundation

final class DailyUsageManager {
    static let shared = DailyUsageManager()

    private let defaults: UserDefaults?

    private let correctionCountKey = "daily_correction_count"
    private let translationCountKey = "daily_translation_count"
    private let rewardedAdCountKey = "daily_rewarded_ad_count"
    private let bonusCorrectionKey = "bonus_correction_count"
    private let bonusTranslationKey = "bonus_translation_count"
    private let lastResetDateKey = "daily_usage_last_reset"

    private init() {
        defaults = UserDefaults(suiteName: AppConstants.appGroupIdentifier)
        resetIfNewDay()
    }

    // MARK: - Usage Counts

    var correctionCount: Int {
        resetIfNewDay()
        return defaults?.integer(forKey: correctionCountKey) ?? 0
    }

    var translationCount: Int {
        resetIfNewDay()
        return defaults?.integer(forKey: translationCountKey) ?? 0
    }

    var remainingCorrections: Int {
        let limit = FeatureGate.shared.dailyCorrectionLimit
        let bonus = defaults?.integer(forKey: bonusCorrectionKey) ?? 0
        let used = correctionCount
        return max(0, (limit + bonus) - used)
    }

    var remainingTranslations: Int {
        let limit = FeatureGate.shared.dailyTranslationLimit
        let bonus = defaults?.integer(forKey: bonusTranslationKey) ?? 0
        let used = translationCount
        return max(0, (limit + bonus) - used)
    }

    // MARK: - Record Usage

    func recordCorrection() {
        resetIfNewDay()
        let count = (defaults?.integer(forKey: correctionCountKey) ?? 0) + 1
        defaults?.set(count, forKey: correctionCountKey)
    }

    func recordTranslation() {
        resetIfNewDay()
        let count = (defaults?.integer(forKey: translationCountKey) ?? 0) + 1
        defaults?.set(count, forKey: translationCountKey)
    }

    // MARK: - Limit Check

    func canUseCorrection() -> Bool {
        if FeatureGate.shared.isPremiumUnlimited { return true }
        return remainingCorrections > 0
    }

    func canUseTranslation() -> Bool {
        if FeatureGate.shared.isPremiumUnlimited { return true }
        return remainingTranslations > 0
    }

    // MARK: - Rewarded Ads

    var rewardedAdCount: Int {
        resetIfNewDay()
        return defaults?.integer(forKey: rewardedAdCountKey) ?? 0
    }

    var canWatchRewardedAd: Bool {
        return FeatureGate.shared.canShowRewardedAd
            && rewardedAdCount < FeatureGate.shared.maxDailyRewardedAds
    }

    func recordRewardedAd() {
        let count = rewardedAdCount + 1
        defaults?.set(count, forKey: rewardedAdCountKey)

        let bonus = FeatureGate.shared.rewardedAdBonusCount
        let currentCorrectionBonus = defaults?.integer(forKey: bonusCorrectionKey) ?? 0
        let currentTranslationBonus = defaults?.integer(forKey: bonusTranslationKey) ?? 0
        defaults?.set(currentCorrectionBonus + bonus, forKey: bonusCorrectionKey)
        defaults?.set(currentTranslationBonus + bonus, forKey: bonusTranslationKey)
    }

    // MARK: - Midnight Reset

    private func resetIfNewDay() {
        let today = Calendar.current.startOfDay(for: Date())
        let lastReset = defaults?.object(forKey: lastResetDateKey) as? Date ?? .distantPast

        if today > lastReset {
            defaults?.set(0, forKey: correctionCountKey)
            defaults?.set(0, forKey: translationCountKey)
            defaults?.set(0, forKey: rewardedAdCountKey)
            defaults?.set(0, forKey: bonusCorrectionKey)
            defaults?.set(0, forKey: bonusTranslationKey)
            defaults?.set(today, forKey: lastResetDateKey)
        }
    }
}
