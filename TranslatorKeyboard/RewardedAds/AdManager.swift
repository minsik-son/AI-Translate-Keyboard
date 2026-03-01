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

    func showRewardedAd(from viewController: UIViewController) {
        guard isAdReady else {
            loadRewardedAd()
            return
        }
        guard DailyUsageManager.shared.canWatchRewardedAd else {
            delegate?.adManagerReachedDailyLimit(self)
            return
        }
        // When ad completes, grant bonus
        grantReward()
    }

    var canShowAd: Bool {
        return isAdReady && DailyUsageManager.shared.canWatchRewardedAd
    }

    private func grantReward() {
        DailyUsageManager.shared.recordRewardedAd()
        delegate?.adManagerDidRewardUser(self)
        isAdReady = false
        loadRewardedAd()
    }
}
