import UIKit

protocol AdManagerDelegate: AnyObject {
    func adManagerDidRewardUser(_ manager: AdManager)
    func adManagerDidFailToLoad(_ manager: AdManager)
    func adManagerDidDismissAd(_ manager: AdManager)
    func adManagerReachedDailyLimit(_ manager: AdManager)
}

final class AdManager: NSObject {
    static let shared = AdManager()
    weak var delegate: AdManagerDelegate?

    private static let rewardedAdUnitID = "ca-app-pub-xxxxxxxxxxxxx/xxxxxxxxxx" // Replace with real ID

    private var isAdReady = false
    private(set) var currentMode: RewardMode = .correction

    private override init() {
        super.init()
    }

    func loadRewardedAd() {
        // Google Mobile Ads SDK integration
        // GADRewardedAd.load(withAdUnitID: Self.rewardedAdUnitID, request: GADRequest()) { [weak self] ad, error in
        //     if let error = error {
        //         self?.isAdReady = false
        //         self?.delegate?.adManagerDidFailToLoad(self!)
        //         return
        //     }
        //     self?.rewardedAd = ad
        //     self?.isAdReady = true
        // }

        // Placeholder until Google Mobile Ads SDK is integrated
        isAdReady = true
    }

    func showRewardedAd(from viewController: UIViewController, mode: RewardMode) {
        currentMode = mode
        guard isAdReady else {
            loadRewardedAd()
            return
        }
        let canWatch: Bool
        if mode == .compose {
            canWatch = DailyUsageManager.shared.canWatchComposeRewardedAd
        } else {
            canWatch = DailyUsageManager.shared.canWatchRewardedAd(for: mode)
        }
        guard canWatch else {
            delegate?.adManagerReachedDailyLimit(self)
            return
        }
        // When ad completes, grant bonus
        grantReward(mode: mode)
    }

    func canShowAd(for mode: RewardMode) -> Bool {
        if mode == .compose {
            return isAdReady && DailyUsageManager.shared.canWatchComposeRewardedAd
        }
        return isAdReady && DailyUsageManager.shared.canWatchRewardedAd(for: mode)
    }

    private func grantReward(mode: RewardMode) {
        switch mode {
        case .compose:
            DailyUsageManager.shared.recordComposeRewardedAd()
        case .correction, .translation:
            DailyUsageManager.shared.recordRewardedAd(for: mode)
        }
        delegate?.adManagerDidRewardUser(self)
        isAdReady = false
        loadRewardedAd()
    }
}
