import UIKit

protocol AdManagerDelegate: AnyObject {
    func adManagerDidRewardUser(_ manager: AdManager, bonusSessions: Int)
    func adManagerDidFailToLoad(_ manager: AdManager, error: Error)
    func adManagerDidDismissAd(_ manager: AdManager)
}

final class AdManager: NSObject {
    static let shared = AdManager()

    weak var delegate: AdManagerDelegate?

    private static let rewardedAdUnitID = "ca-app-pub-xxxxxxxxxxxxx/xxxxxxxxxx" // Replace with real ID
    private static let bonusSessionCount = 30

    private var isAdReady = false

    private override init() {
        super.init()
    }

    func loadRewardedAd() {
        // Google Mobile Ads SDK integration
        // GADRewardedAd.load(withAdUnitID: Self.rewardedAdUnitID, request: GADRequest()) { [weak self] ad, error in
        //     if let error = error {
        //         self?.isAdReady = false
        //         self?.delegate?.adManagerDidFailToLoad(self!, error: error)
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

        // When ad completes, grant bonus sessions
        grantReward()
    }

    var canShowAd: Bool {
        return isAdReady
    }

    private func grantReward() {
        let sessionManager = SessionManager.shared
        sessionManager.addBonusSessions(Self.bonusSessionCount)
        delegate?.adManagerDidRewardUser(self, bonusSessions: Self.bonusSessionCount)

        // Reload next ad
        isAdReady = false
        loadRewardedAd()
    }
}
