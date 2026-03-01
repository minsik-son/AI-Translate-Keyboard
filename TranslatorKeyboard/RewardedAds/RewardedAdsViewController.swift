import UIKit

class RewardedAdsViewController: UIViewController, AdManagerDelegate {

    // MARK: - UI Elements

    private let closeButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setImage(UIImage(systemName: "xmark"), for: .normal)
        btn.tintColor = AppColors.text
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        // TODO: Localize - "Get More Uses"
        label.text = "Get More Uses"
        label.font = .systemFont(ofSize: 24, weight: .bold)
        label.textColor = AppColors.text
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let correctionsCard: UIView = {
        let view = UIView()
        view.backgroundColor = AppColors.card
        view.layer.cornerRadius = 12
        view.layer.borderWidth = 1
        view.layer.borderColor = AppColors.border.cgColor
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let correctionsIconLabel: UILabel = {
        let label = UILabel()
        label.text = "Corrections"
        label.font = .systemFont(ofSize: 15, weight: .medium)
        label.textColor = AppColors.textSub
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let correctionsCountLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 32, weight: .bold)
        label.textColor = AppColors.accent
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let translationsCard: UIView = {
        let view = UIView()
        view.backgroundColor = AppColors.card
        view.layer.cornerRadius = 12
        view.layer.borderWidth = 1
        view.layer.borderColor = AppColors.border.cgColor
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let translationsIconLabel: UILabel = {
        let label = UILabel()
        label.text = "Translations"
        label.font = .systemFont(ofSize: 15, weight: .medium)
        label.textColor = AppColors.textSub
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let translationsCountLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 32, weight: .bold)
        label.textColor = AppColors.accent
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let adsRemainingLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14)
        label.textColor = AppColors.textSub
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let watchAdButton: UIButton = {
        let btn = UIButton(type: .system)
        // TODO: Localize - "Watch ad to get +5"
        btn.setTitle("Watch ad to get +5", for: .normal)
        btn.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        btn.backgroundColor = AppColors.accent
        btn.setTitleColor(.white, for: .normal)
        btn.layer.cornerRadius = 12
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }()

    private let feedbackLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 15, weight: .medium)
        label.textColor = AppColors.green
        label.textAlignment = .center
        label.alpha = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = AppColors.bg
        setupUI()
        updateCounts()
        AdManager.shared.delegate = self
        AdManager.shared.loadRewardedAd()
    }

    // MARK: - Setup

    private func setupUI() {
        view.addSubview(closeButton)
        view.addSubview(titleLabel)
        view.addSubview(correctionsCard)
        correctionsCard.addSubview(correctionsIconLabel)
        correctionsCard.addSubview(correctionsCountLabel)
        view.addSubview(translationsCard)
        translationsCard.addSubview(translationsIconLabel)
        translationsCard.addSubview(translationsCountLabel)
        view.addSubview(adsRemainingLabel)
        view.addSubview(watchAdButton)
        view.addSubview(feedbackLabel)

        NSLayoutConstraint.activate([
            closeButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            closeButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            closeButton.widthAnchor.constraint(equalToConstant: 30),
            closeButton.heightAnchor.constraint(equalToConstant: 30),

            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 60),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),

            // Cards side by side
            correctionsCard.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 32),
            correctionsCard.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            correctionsCard.trailingAnchor.constraint(equalTo: view.centerXAnchor, constant: -8),
            correctionsCard.heightAnchor.constraint(equalToConstant: 100),

            correctionsIconLabel.topAnchor.constraint(equalTo: correctionsCard.topAnchor, constant: 16),
            correctionsIconLabel.centerXAnchor.constraint(equalTo: correctionsCard.centerXAnchor),

            correctionsCountLabel.topAnchor.constraint(equalTo: correctionsIconLabel.bottomAnchor, constant: 8),
            correctionsCountLabel.centerXAnchor.constraint(equalTo: correctionsCard.centerXAnchor),

            translationsCard.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 32),
            translationsCard.leadingAnchor.constraint(equalTo: view.centerXAnchor, constant: 8),
            translationsCard.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            translationsCard.heightAnchor.constraint(equalToConstant: 100),

            translationsIconLabel.topAnchor.constraint(equalTo: translationsCard.topAnchor, constant: 16),
            translationsIconLabel.centerXAnchor.constraint(equalTo: translationsCard.centerXAnchor),

            translationsCountLabel.topAnchor.constraint(equalTo: translationsIconLabel.bottomAnchor, constant: 8),
            translationsCountLabel.centerXAnchor.constraint(equalTo: translationsCard.centerXAnchor),

            // Ads remaining label
            adsRemainingLabel.topAnchor.constraint(equalTo: correctionsCard.bottomAnchor, constant: 32),
            adsRemainingLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            adsRemainingLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),

            // Watch ad button
            watchAdButton.topAnchor.constraint(equalTo: adsRemainingLabel.bottomAnchor, constant: 16),
            watchAdButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            watchAdButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            watchAdButton.heightAnchor.constraint(equalToConstant: 52),

            // Feedback label
            feedbackLabel.topAnchor.constraint(equalTo: watchAdButton.bottomAnchor, constant: 16),
            feedbackLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            feedbackLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
        ])

        closeButton.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
        watchAdButton.addTarget(self, action: #selector(watchAdTapped), for: .touchUpInside)
    }

    // MARK: - Update UI

    private func updateCounts() {
        let remaining = DailyUsageManager.shared
        correctionsCountLabel.text = "\(remaining.remainingCorrections)"
        translationsCountLabel.text = "\(remaining.remainingTranslations)"

        let adsLeft = max(0, FeatureGate.shared.maxDailyRewardedAds - DailyUsageManager.shared.rewardedAdCount)
        // TODO: Localize - "Ads remaining today: X"
        adsRemainingLabel.text = "Ads remaining today: \(adsLeft)"

        let canWatch = DailyUsageManager.shared.canWatchRewardedAd
        watchAdButton.isEnabled = canWatch
        watchAdButton.alpha = canWatch ? 1.0 : 0.5
    }

    private func showFeedback(_ message: String) {
        feedbackLabel.text = message
        feedbackLabel.alpha = 0
        UIView.animate(withDuration: 0.3) {
            self.feedbackLabel.alpha = 1
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            UIView.animate(withDuration: 0.3) {
                self.feedbackLabel.alpha = 0
            }
        }
    }

    // MARK: - Actions

    @objc private func closeTapped() {
        dismiss(animated: true)
    }

    @objc private func watchAdTapped() {
        AdManager.shared.showRewardedAd(from: self)
    }

    // MARK: - AdManagerDelegate

    func adManagerDidRewardUser(_ manager: AdManager) {
        updateCounts()
        // TODO: Localize - "Bonus granted!"
        showFeedback("Bonus granted!")
    }

    func adManagerDidFailToLoad(_ manager: AdManager) {
        showFeedback("Failed to load ad. Try again later.")
    }

    func adManagerDidDismissAd(_ manager: AdManager) {
        // No special handling needed
    }

    func adManagerReachedDailyLimit(_ manager: AdManager) {
        showFeedback("Daily ad limit reached.")
        updateCounts()
    }
}
