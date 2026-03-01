import UIKit
import StoreKit

class PaywallViewController: UIViewController {

    private let storeKitManager = StoreKitManager.shared

    // MARK: - UI Components

    private let scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.showsVerticalScrollIndicator = false
        sv.translatesAutoresizingMaskIntoConstraints = false
        return sv
    }()

    private let contentView: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private let closeButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setImage(UIImage(systemName: "xmark"), for: .normal)
        btn.tintColor = AppColors.text
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = L("onboarding.subscription.title")
        label.font = .systemFont(ofSize: 28, weight: .bold)
        label.textColor = AppColors.text
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    // Pro Yearly Card (recommended)
    private let yearlyProCard = UIView()
    private let yearlyProBestBadge = UILabel()
    private let yearlyProTitleLabel = UILabel()
    private let yearlyProPriceLabel = UILabel()
    private let yearlyProMonthlyEquivLabel = UILabel()
    private let yearlySavingsLabel = UILabel()
    private let yearlyProFeaturesStack = UIStackView()

    // Pro Monthly Card
    private let monthlyProCard = UIView()
    private let monthlyProTitleLabel = UILabel()
    private let monthlyProPriceLabel = UILabel()

    // Premium Card
    private let premiumCard = UIView()
    private let premiumBadge = UILabel()
    private let premiumTitleLabel = UILabel()
    private let premiumPriceLabel = UILabel()

    // Bottom section
    private let restoreButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle(L("onboarding.subscription.restore"), for: .normal)
        btn.titleLabel?.font = .systemFont(ofSize: 14)
        btn.setTitleColor(AppColors.textSub, for: .normal)
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }()

    private let termsButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle(L("settings.terms"), for: .normal)
        btn.titleLabel?.font = .systemFont(ofSize: 12)
        btn.setTitleColor(AppColors.textMuted, for: .normal)
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }()

    private let privacyButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle(L("settings.privacy"), for: .normal)
        btn.titleLabel?.font = .systemFont(ofSize: 12)
        btn.setTitleColor(AppColors.textMuted, for: .normal)
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = AppColors.bg
        setupUI()
        loadProducts()
    }

    // MARK: - Setup

    private func setupUI() {
        view.addSubview(closeButton)
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)

        NSLayoutConstraint.activate([
            closeButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            closeButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            closeButton.widthAnchor.constraint(equalToConstant: 30),
            closeButton.heightAnchor.constraint(equalToConstant: 30),

            scrollView.topAnchor.constraint(equalTo: closeButton.bottomAnchor, constant: 8),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
        ])

        closeButton.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)

        setupTitle()
        setupYearlyProCard()
        setupMonthlyProCard()
        setupPremiumCard()
        setupBottomSection()
    }

    private func setupTitle() {
        contentView.addSubview(titleLabel)
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
        ])
    }

    // MARK: - Yearly Pro Card (Recommended)

    private func setupYearlyProCard() {
        yearlyProCard.backgroundColor = AppColors.card
        yearlyProCard.layer.cornerRadius = 16
        yearlyProCard.layer.borderWidth = 2
        yearlyProCard.layer.borderColor = AppColors.accent.cgColor
        yearlyProCard.translatesAutoresizingMaskIntoConstraints = false
        yearlyProCard.isUserInteractionEnabled = true
        yearlyProCard.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(yearlyProTapped)))
        contentView.addSubview(yearlyProCard)

        // BEST badge
        yearlyProBestBadge.text = " BEST "
        yearlyProBestBadge.font = .systemFont(ofSize: 11, weight: .bold)
        yearlyProBestBadge.textColor = .white
        yearlyProBestBadge.backgroundColor = AppColors.accent
        yearlyProBestBadge.layer.cornerRadius = 4
        yearlyProBestBadge.layer.masksToBounds = true
        yearlyProBestBadge.translatesAutoresizingMaskIntoConstraints = false
        yearlyProCard.addSubview(yearlyProBestBadge)

        // Title
        yearlyProTitleLabel.text = "Pro " + L("onboarding.subscription.yearly")
        yearlyProTitleLabel.font = .systemFont(ofSize: 18, weight: .bold)
        yearlyProTitleLabel.textColor = AppColors.text
        yearlyProTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        yearlyProCard.addSubview(yearlyProTitleLabel)

        // Price
        yearlyProPriceLabel.text = "---/yr"
        yearlyProPriceLabel.font = .systemFont(ofSize: 22, weight: .bold)
        yearlyProPriceLabel.textColor = AppColors.text
        yearlyProPriceLabel.translatesAutoresizingMaskIntoConstraints = false
        yearlyProCard.addSubview(yearlyProPriceLabel)

        // Monthly equivalent
        yearlyProMonthlyEquivLabel.text = ""
        yearlyProMonthlyEquivLabel.font = .systemFont(ofSize: 13)
        yearlyProMonthlyEquivLabel.textColor = AppColors.textSub
        yearlyProMonthlyEquivLabel.translatesAutoresizingMaskIntoConstraints = false
        yearlyProCard.addSubview(yearlyProMonthlyEquivLabel)

        // Savings label
        yearlySavingsLabel.text = "50% OFF"
        yearlySavingsLabel.font = .systemFont(ofSize: 12, weight: .semibold)
        yearlySavingsLabel.textColor = AppColors.green
        yearlySavingsLabel.translatesAutoresizingMaskIntoConstraints = false
        yearlyProCard.addSubview(yearlySavingsLabel)

        // Feature list
        let proFeatures = [
            L("onboarding.subscription.benefit.unlimited"),
            "Flash AI",
            L("onboarding.subscription.benefit.themes"),
            L("onboarding.subscription.benefit.no_ads"),
        ]
        yearlyProFeaturesStack.axis = .vertical
        yearlyProFeaturesStack.spacing = 6
        yearlyProFeaturesStack.translatesAutoresizingMaskIntoConstraints = false
        for feature in proFeatures {
            let row = makeFeatureRow(feature)
            yearlyProFeaturesStack.addArrangedSubview(row)
        }
        yearlyProCard.addSubview(yearlyProFeaturesStack)

        NSLayoutConstraint.activate([
            yearlyProCard.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 24),
            yearlyProCard.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            yearlyProCard.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),

            yearlyProBestBadge.topAnchor.constraint(equalTo: yearlyProCard.topAnchor, constant: 16),
            yearlyProBestBadge.leadingAnchor.constraint(equalTo: yearlyProCard.leadingAnchor, constant: 16),

            yearlyProTitleLabel.centerYAnchor.constraint(equalTo: yearlyProBestBadge.centerYAnchor),
            yearlyProTitleLabel.leadingAnchor.constraint(equalTo: yearlyProBestBadge.trailingAnchor, constant: 8),

            yearlyProPriceLabel.topAnchor.constraint(equalTo: yearlyProBestBadge.bottomAnchor, constant: 12),
            yearlyProPriceLabel.leadingAnchor.constraint(equalTo: yearlyProCard.leadingAnchor, constant: 16),

            yearlyProMonthlyEquivLabel.centerYAnchor.constraint(equalTo: yearlyProPriceLabel.centerYAnchor),
            yearlyProMonthlyEquivLabel.leadingAnchor.constraint(equalTo: yearlyProPriceLabel.trailingAnchor, constant: 8),

            yearlySavingsLabel.centerYAnchor.constraint(equalTo: yearlyProPriceLabel.centerYAnchor),
            yearlySavingsLabel.trailingAnchor.constraint(equalTo: yearlyProCard.trailingAnchor, constant: -16),

            yearlyProFeaturesStack.topAnchor.constraint(equalTo: yearlyProPriceLabel.bottomAnchor, constant: 14),
            yearlyProFeaturesStack.leadingAnchor.constraint(equalTo: yearlyProCard.leadingAnchor, constant: 16),
            yearlyProFeaturesStack.trailingAnchor.constraint(equalTo: yearlyProCard.trailingAnchor, constant: -16),
            yearlyProFeaturesStack.bottomAnchor.constraint(equalTo: yearlyProCard.bottomAnchor, constant: -16),
        ])
    }

    // MARK: - Monthly Pro Card

    private func setupMonthlyProCard() {
        monthlyProCard.backgroundColor = AppColors.card
        monthlyProCard.layer.cornerRadius = 16
        monthlyProCard.layer.borderWidth = 1
        monthlyProCard.layer.borderColor = AppColors.border.cgColor
        monthlyProCard.translatesAutoresizingMaskIntoConstraints = false
        monthlyProCard.isUserInteractionEnabled = true
        monthlyProCard.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(monthlyProTapped)))
        contentView.addSubview(monthlyProCard)

        monthlyProTitleLabel.text = "Pro " + L("onboarding.subscription.monthly")
        monthlyProTitleLabel.font = .systemFont(ofSize: 18, weight: .bold)
        monthlyProTitleLabel.textColor = AppColors.text
        monthlyProTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        monthlyProCard.addSubview(monthlyProTitleLabel)

        monthlyProPriceLabel.text = "---/mo"
        monthlyProPriceLabel.font = .systemFont(ofSize: 20, weight: .bold)
        monthlyProPriceLabel.textColor = AppColors.text
        monthlyProPriceLabel.translatesAutoresizingMaskIntoConstraints = false
        monthlyProCard.addSubview(monthlyProPriceLabel)

        NSLayoutConstraint.activate([
            monthlyProCard.topAnchor.constraint(equalTo: yearlyProCard.bottomAnchor, constant: 12),
            monthlyProCard.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            monthlyProCard.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),

            monthlyProTitleLabel.topAnchor.constraint(equalTo: monthlyProCard.topAnchor, constant: 16),
            monthlyProTitleLabel.leadingAnchor.constraint(equalTo: monthlyProCard.leadingAnchor, constant: 16),
            monthlyProTitleLabel.bottomAnchor.constraint(equalTo: monthlyProCard.bottomAnchor, constant: -16),

            monthlyProPriceLabel.centerYAnchor.constraint(equalTo: monthlyProCard.centerYAnchor),
            monthlyProPriceLabel.trailingAnchor.constraint(equalTo: monthlyProCard.trailingAnchor, constant: -16),
        ])
    }

    // MARK: - Premium Card

    private func setupPremiumCard() {
        premiumCard.backgroundColor = AppColors.card
        premiumCard.layer.cornerRadius = 16
        premiumCard.layer.borderWidth = 1
        premiumCard.layer.borderColor = AppColors.border.cgColor
        premiumCard.translatesAutoresizingMaskIntoConstraints = false
        premiumCard.isUserInteractionEnabled = true
        premiumCard.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(premiumTapped)))
        contentView.addSubview(premiumCard)

        premiumBadge.text = " UNLIMITED "
        premiumBadge.font = .systemFont(ofSize: 11, weight: .bold)
        premiumBadge.textColor = .white
        premiumBadge.backgroundColor = AppColors.orange
        premiumBadge.layer.cornerRadius = 4
        premiumBadge.layer.masksToBounds = true
        premiumBadge.translatesAutoresizingMaskIntoConstraints = false
        premiumCard.addSubview(premiumBadge)

        premiumTitleLabel.text = "Premium " + L("onboarding.subscription.monthly")
        premiumTitleLabel.font = .systemFont(ofSize: 18, weight: .bold)
        premiumTitleLabel.textColor = AppColors.text
        premiumTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        premiumCard.addSubview(premiumTitleLabel)

        premiumPriceLabel.text = "---/mo"
        premiumPriceLabel.font = .systemFont(ofSize: 20, weight: .bold)
        premiumPriceLabel.textColor = AppColors.text
        premiumPriceLabel.translatesAutoresizingMaskIntoConstraints = false
        premiumCard.addSubview(premiumPriceLabel)

        NSLayoutConstraint.activate([
            premiumCard.topAnchor.constraint(equalTo: monthlyProCard.bottomAnchor, constant: 12),
            premiumCard.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            premiumCard.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),

            premiumBadge.topAnchor.constraint(equalTo: premiumCard.topAnchor, constant: 16),
            premiumBadge.leadingAnchor.constraint(equalTo: premiumCard.leadingAnchor, constant: 16),

            premiumTitleLabel.centerYAnchor.constraint(equalTo: premiumBadge.centerYAnchor),
            premiumTitleLabel.leadingAnchor.constraint(equalTo: premiumBadge.trailingAnchor, constant: 8),

            premiumPriceLabel.topAnchor.constraint(equalTo: premiumBadge.bottomAnchor, constant: 10),
            premiumPriceLabel.leadingAnchor.constraint(equalTo: premiumCard.leadingAnchor, constant: 16),
            premiumPriceLabel.bottomAnchor.constraint(equalTo: premiumCard.bottomAnchor, constant: -16),
        ])
    }

    // MARK: - Bottom Section

    private func setupBottomSection() {
        contentView.addSubview(restoreButton)

        let linksStack = UIStackView(arrangedSubviews: [termsButton, privacyButton])
        linksStack.axis = .horizontal
        linksStack.spacing = 16
        linksStack.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(linksStack)

        restoreButton.addTarget(self, action: #selector(restoreTapped), for: .touchUpInside)
        termsButton.addTarget(self, action: #selector(termsTapped), for: .touchUpInside)
        privacyButton.addTarget(self, action: #selector(privacyTapped), for: .touchUpInside)

        NSLayoutConstraint.activate([
            restoreButton.topAnchor.constraint(equalTo: premiumCard.bottomAnchor, constant: 24),
            restoreButton.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),

            linksStack.topAnchor.constraint(equalTo: restoreButton.bottomAnchor, constant: 12),
            linksStack.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            linksStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -32),
        ])
    }

    // MARK: - Helpers

    private func makeFeatureRow(_ text: String) -> UIView {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false

        let checkmark = UILabel()
        checkmark.text = "✓"
        checkmark.font = .systemFont(ofSize: 14, weight: .semibold)
        checkmark.textColor = AppColors.accent
        checkmark.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(checkmark)

        let label = UILabel()
        label.text = text
        label.font = .systemFont(ofSize: 14)
        label.textColor = AppColors.textSub
        label.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(label)

        NSLayoutConstraint.activate([
            checkmark.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            checkmark.centerYAnchor.constraint(equalTo: container.centerYAnchor),

            label.leadingAnchor.constraint(equalTo: checkmark.trailingAnchor, constant: 6),
            label.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            label.topAnchor.constraint(equalTo: container.topAnchor),
            label.bottomAnchor.constraint(equalTo: container.bottomAnchor),
        ])

        return container
    }

    // MARK: - Load Products

    private func loadProducts() {
        Task {
            do {
                try await storeKitManager.loadProducts()
                updatePriceLabels()
            } catch {
                // Product loading failed
            }
        }
    }

    private func updatePriceLabels() {
        for product in storeKitManager.products {
            switch product.id {
            case StoreKitManager.ProductID.yearlyPro.rawValue:
                yearlyProPriceLabel.text = product.displayPrice + "/" + L("onboarding.subscription.yearly")
                // Calculate monthly equivalent
                let monthlyPrice = product.price / 12
                let formatter = NumberFormatter()
                formatter.numberStyle = .currency
                formatter.locale = product.priceFormatStyle.locale
                if let formatted = formatter.string(from: monthlyPrice as NSDecimalNumber) {
                    yearlyProMonthlyEquivLabel.text = formatted + "/" + L("onboarding.subscription.monthly")
                }

            case StoreKitManager.ProductID.monthlyPro.rawValue:
                monthlyProPriceLabel.text = product.displayPrice + "/" + L("onboarding.subscription.monthly")

            case StoreKitManager.ProductID.monthlyPremium.rawValue:
                premiumPriceLabel.text = product.displayPrice + "/" + L("onboarding.subscription.monthly")

            default:
                break
            }
        }
    }

    // MARK: - Actions

    @objc private func closeTapped() {
        dismiss(animated: true)
    }

    @objc private func yearlyProTapped() {
        purchaseProduct(id: .yearlyPro)
    }

    @objc private func monthlyProTapped() {
        purchaseProduct(id: .monthlyPro)
    }

    @objc private func premiumTapped() {
        purchaseProduct(id: .monthlyPremium)
    }

    private func purchaseProduct(id: StoreKitManager.ProductID) {
        guard let product = storeKitManager.products.first(where: { $0.id == id.rawValue }) else { return }
        Task {
            do {
                let transaction = try await storeKitManager.purchase(product)
                if transaction != nil {
                    dismiss(animated: true)
                }
            } catch {
                // Purchase failed
            }
        }
    }

    @objc private func restoreTapped() {
        Task {
            do {
                try await storeKitManager.restorePurchases()
                if SubscriptionStatus.shared.isPro {
                    dismiss(animated: true)
                }
            } catch {
                // Restore failed
            }
        }
    }

    @objc private func termsTapped() {
        if let url = URL(string: "https://translatorkeyboard.com/terms") {
            UIApplication.shared.open(url)
        }
    }

    @objc private func privacyTapped() {
        if let url = URL(string: "https://translatorkeyboard.com/privacy") {
            UIApplication.shared.open(url)
        }
    }
}
