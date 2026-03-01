import Foundation

final class FeatureGate {
    static let shared = FeatureGate()
    private init() {}

    private var currentTier: UserTier {
        return SubscriptionStatus.shared.currentTier
    }

    // MARK: - Daily Usage Caps

    var dailyCorrectionLimit: Int {
        if AdminMode.shared.isEnabled { return Int.max }
        switch currentTier {
        case .free: return 10
        case .pro: return 100
        case .premium: return 300
        }
    }

    var dailyTranslationLimit: Int {
        if AdminMode.shared.isEnabled { return Int.max }
        switch currentTier {
        case .free: return 10
        case .pro: return 100
        case .premium: return 300
        }
    }

    var isPremiumUnlimited: Bool {
        return currentTier == .premium
    }

    // MARK: - Storage Limits

    var maxSavedPhrases: Int {
        if AdminMode.shared.isEnabled { return Int.max }
        switch currentTier {
        case .free: return 5
        case .pro, .premium: return Int.max
        }
    }

    var maxClipboardItems: Int {
        if AdminMode.shared.isEnabled { return Int.max }
        switch currentTier {
        case .free: return 5
        case .pro, .premium: return 30
        }
    }

    var maxHistoryItems: Int {
        if AdminMode.shared.isEnabled { return Int.max }
        switch currentTier {
        case .free: return 50
        case .pro, .premium: return 200
        }
    }

    // MARK: - Feature Locks

    var availableTones: [ToneStyle] {
        if AdminMode.shared.isEnabled { return ToneStyle.allCases }
        switch currentTier {
        case .free: return [.none]
        case .pro, .premium: return ToneStyle.allCases
        }
    }

    func isToneLocked(_ tone: ToneStyle) -> Bool {
        return !availableTones.contains(tone)
    }

    // MARK: - AI Model

    var apiModelName: String {
        switch currentTier {
        case .free: return "gemini-2.5-flash-lite"
        case .pro, .premium: return "gemini-2.5-flash"
        }
    }

    // MARK: - Rewarded Ads

    var maxDailyRewardedAds: Int {
        return 3
    }

    var rewardedAdBonusCount: Int {
        return 5
    }

    var canShowRewardedAd: Bool {
        return currentTier == .free
    }

    // MARK: - Debounce

    var debounceDuration: TimeInterval {
        return 1.0
    }
}
