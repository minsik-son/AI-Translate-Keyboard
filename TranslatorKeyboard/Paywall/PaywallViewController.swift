import UIKit
import StoreKit

class PaywallViewController: UIViewController {

    private let storeKitManager = StoreKitManager.shared

    // MARK: - Pricing Fallbacks (when StoreKit products not available)

    private struct FallbackPrice {
        let display: String
        let monthly: String?
    }

    private let fallbackPrices: [String: FallbackPrice] = [
        StoreKitManager.ProductID.yearlyPro.rawValue: FallbackPrice(display: "$47.99/yr", monthly: "$3.99/mo"),
        StoreKitManager.ProductID.monthlyPro.rawValue: FallbackPrice(display: "$7.99/mo", monthly: nil),
        StoreKitManager.ProductID.monthlyPremium.rawValue: FallbackPrice(display: "$14.99/mo", monthly: nil),
    ]

    // MARK: - State

    private enum SelectedPlan {
        case yearlyPro, monthlyPro, premium
    }
    private var selectedPlan: SelectedPlan = .yearlyPro
    private var isLoading = false

    // MARK: - UI Components

    private let scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.showsVerticalScrollIndicator = false
        sv.translatesAutoresizingMaskIntoConstraints = false
        return sv
    }()

    private let contentStack: UIStackView = {
        let s = UIStackView()
        s.axis = .vertical
        s.spacing = 24
        s.translatesAutoresizingMaskIntoConstraints = false
        return s
    }()

    private let closeButton: UIButton = {
        let btn = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 15, weight: .semibold)
        btn.setImage(UIImage(systemName: "xmark", withConfiguration: config), for: .normal)
        btn.tintColor = AppColors.textSub
        btn.backgroundColor = AppColors.card
        btn.layer.cornerRadius = 15
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }()

    // Plan selector radio views
    private var yearlyRadio = UIView()
    private var monthlyRadio = UIView()
    private var premiumRadio = UIView()

    // Price labels (updated by StoreKit)
    private let yearlyPriceLabel = UILabel()
    private let yearlyBilledLabel = UILabel()
    private let monthlyPriceLabel = UILabel()
    private let premiumPriceLabel = UILabel()

    // Plan selector cards
    private let yearlyCard = UIView()
    private let monthlyCard = UIView()
    private let premiumCard = UIView()

    // CTA Button
    private let ctaButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.titleLabel?.font = .systemFont(ofSize: 17, weight: .bold)
        btn.setTitleColor(.white, for: .normal)
        btn.backgroundColor = AppColors.accent
        btn.layer.cornerRadius = 14
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }()

    private let ctaSpinner: UIActivityIndicatorView = {
        let spinner = UIActivityIndicatorView(style: .medium)
        spinner.color = .white
        spinner.hidesWhenStopped = true
        spinner.translatesAutoresizingMaskIntoConstraints = false
        return spinner
    }()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = AppColors.bg
        setupLayout()
        buildFeatureTable()
        buildPlanSelector()
        buildBottomSection()
        applyFallbackPrices()
        loadProducts()
        updateSelectionState()
    }

    // MARK: - Layout

    private func setupLayout() {
        view.addSubview(closeButton)
        view.addSubview(scrollView)
        view.addSubview(ctaButton)
        scrollView.addSubview(contentStack)
        ctaButton.addSubview(ctaSpinner)

        NSLayoutConstraint.activate([
            closeButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),
            closeButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            closeButton.widthAnchor.constraint(equalToConstant: 30),
            closeButton.heightAnchor.constraint(equalToConstant: 30),

            scrollView.topAnchor.constraint(equalTo: closeButton.bottomAnchor, constant: 8),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: ctaButton.topAnchor, constant: -12),

            contentStack.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 8),
            contentStack.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 24),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -24),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -16),
            contentStack.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -48),

            ctaButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            ctaButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            ctaButton.heightAnchor.constraint(equalToConstant: 54),
            ctaButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -12),

            ctaSpinner.centerXAnchor.constraint(equalTo: ctaButton.centerXAnchor),
            ctaSpinner.centerYAnchor.constraint(equalTo: ctaButton.centerYAnchor),
        ])

        closeButton.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
        ctaButton.addTarget(self, action: #selector(ctaTapped), for: .touchUpInside)

        // Title
        let titleLabel = UILabel()
        titleLabel.text = L("paywall.title")
        titleLabel.font = .systemFont(ofSize: 24, weight: .bold)
        titleLabel.textColor = AppColors.text
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 0
        contentStack.addArrangedSubview(titleLabel)
    }

    // MARK: - Feature Comparison Table

    private func buildFeatureTable() {
        let tableCard = UIView()
        tableCard.backgroundColor = AppColors.card
        tableCard.layer.cornerRadius = 16
        tableCard.layer.borderWidth = 1
        tableCard.layer.borderColor = AppColors.border.cgColor

        let tableStack = UIStackView()
        tableStack.axis = .vertical
        tableStack.spacing = 0
        tableStack.translatesAutoresizingMaskIntoConstraints = false
        tableCard.addSubview(tableStack)

        NSLayoutConstraint.activate([
            tableStack.topAnchor.constraint(equalTo: tableCard.topAnchor, constant: 16),
            tableStack.leadingAnchor.constraint(equalTo: tableCard.leadingAnchor, constant: 16),
            tableStack.trailingAnchor.constraint(equalTo: tableCard.trailingAnchor, constant: -16),
            tableStack.bottomAnchor.constraint(equalTo: tableCard.bottomAnchor, constant: -16),
        ])

        // Header row
        let headerRow = makeTableRow(
            feature: L("paywall.features_header"),
            free: L("paywall.tier.free"),
            pro: L("paywall.tier.pro"),
            premium: L("paywall.tier.premium"),
            isHeader: true
        )
        tableStack.addArrangedSubview(headerRow)
        tableStack.addArrangedSubview(makeSeparator())

        // Feature rows (5 rows — AI model removed per user request, Premium = unlimited)
        let features: [(String, String, String, String)] = [
            (L("paywall.feature.daily_usage"),
             String(format: L("paywall.value.uses"), 10),
             String(format: L("paywall.value.uses"), 100),
             L("paywall.value.unlimited")),

            (L("paywall.feature.tone"),
             L("paywall.value.basic"),
             L("paywall.value.all"),
             L("paywall.value.all")),

            (L("paywall.feature.themes"), "—", "✓", "✓"),

            (L("paywall.feature.no_ads"), "—", "✓", "✓"),

            (L("paywall.feature.phrases"),
             String(format: L("paywall.value.max"), 5),
             L("paywall.value.unlimited"),
             L("paywall.value.unlimited")),
        ]

        for (i, f) in features.enumerated() {
            let row = makeTableRow(feature: f.0, free: f.1, pro: f.2, premium: f.3, isHeader: false)
            tableStack.addArrangedSubview(row)
            if i < features.count - 1 {
                tableStack.addArrangedSubview(makeSeparator())
            }
        }

        contentStack.addArrangedSubview(tableCard)
    }

    private func makeTableRow(feature: String, free: String, pro: String, premium: String, isHeader: Bool) -> UIView {
        let row = UIStackView()
        row.axis = .horizontal
        row.distribution = .fill
        row.alignment = .center
        row.spacing = 4

        let featureLabel = UILabel()
        featureLabel.text = feature
        featureLabel.font = isHeader
            ? .systemFont(ofSize: 12, weight: .bold)
            : .systemFont(ofSize: 13, weight: .regular)
        featureLabel.textColor = isHeader ? AppColors.textMuted : AppColors.text
        featureLabel.numberOfLines = 1
        featureLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
        featureLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        let freeView = makeValueLabel(free, isHeader: isHeader, isCheckOrDash: free == "✓" || free == "—")
        let proView = makeValueLabel(pro, isHeader: isHeader, isCheckOrDash: pro == "✓" || pro == "—")
        let premiumView = makeValueLabel(premium, isHeader: isHeader, isCheckOrDash: premium == "✓" || premium == "—")

        row.addArrangedSubview(featureLabel)
        row.addArrangedSubview(freeView)
        row.addArrangedSubview(proView)
        row.addArrangedSubview(premiumView)

        // Feature label takes remaining space, value columns are fixed width
        let colWidth: CGFloat = 58
        NSLayoutConstraint.activate([
            freeView.widthAnchor.constraint(equalToConstant: colWidth),
            proView.widthAnchor.constraint(equalToConstant: colWidth),
            premiumView.widthAnchor.constraint(equalToConstant: colWidth),
        ])

        let container = UIView()
        row.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(row)
        NSLayoutConstraint.activate([
            row.topAnchor.constraint(equalTo: container.topAnchor, constant: isHeader ? 0 : 10),
            row.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            row.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            row.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: isHeader ? -8 : -10),
        ])

        return container
    }

    private func makeValueLabel(_ text: String, isHeader: Bool, isCheckOrDash: Bool) -> UILabel {
        let label = UILabel()
        label.textAlignment = .center
        label.numberOfLines = 1
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.7

        if isHeader {
            label.text = text
            label.font = .systemFont(ofSize: 11, weight: .bold)
            label.textColor = AppColors.textMuted
        } else if text == "✓" {
            label.text = "✓"
            label.font = .systemFont(ofSize: 16, weight: .bold)
            label.textColor = AppColors.green
        } else if text == "—" {
            label.text = "—"
            label.font = .systemFont(ofSize: 14, weight: .medium)
            label.textColor = AppColors.textMuted
        } else {
            label.text = text
            label.font = .systemFont(ofSize: 12, weight: .medium)
            label.textColor = AppColors.textSub
        }

        return label
    }

    private func makeSeparator() -> UIView {
        let sep = UIView()
        sep.backgroundColor = AppColors.border
        sep.translatesAutoresizingMaskIntoConstraints = false
        sep.heightAnchor.constraint(equalToConstant: 0.5).isActive = true
        return sep
    }

    // MARK: - Plan Selector

    private func buildPlanSelector() {
        // Section header
        let sectionLabel = UILabel()
        sectionLabel.text = L("paywall.plan_section")
        sectionLabel.font = .systemFont(ofSize: 12, weight: .semibold)
        sectionLabel.textColor = AppColors.textMuted
        sectionLabel.text = sectionLabel.text?.uppercased()
        contentStack.addArrangedSubview(sectionLabel)
        contentStack.setCustomSpacing(12, after: sectionLabel)

        // Three plan cards
        yearlyCard.tag = 0
        monthlyCard.tag = 1
        premiumCard.tag = 2

        let yearlyContent = buildPlanRow(
            card: yearlyCard,
            radio: &yearlyRadio,
            title: L("paywall.pro_yearly"),
            priceLabel: yearlyPriceLabel,
            subLabel: yearlyBilledLabel,
            badge: L("paywall.save_percent"),
            badgeColor: AppColors.green,
            action: #selector(yearlyProTapped)
        )
        contentStack.addArrangedSubview(yearlyContent)
        contentStack.setCustomSpacing(10, after: yearlyContent)

        let monthlyContent = buildPlanRow(
            card: monthlyCard,
            radio: &monthlyRadio,
            title: L("paywall.pro_monthly"),
            priceLabel: monthlyPriceLabel,
            subLabel: nil,
            badge: nil,
            badgeColor: nil,
            action: #selector(monthlyProTapped)
        )
        contentStack.addArrangedSubview(monthlyContent)
        contentStack.setCustomSpacing(10, after: monthlyContent)

        let premiumContent = buildPlanRow(
            card: premiumCard,
            radio: &premiumRadio,
            title: L("paywall.premium_monthly"),
            priceLabel: premiumPriceLabel,
            subLabel: nil,
            badge: "UNLIMITED",
            badgeColor: AppColors.orange,
            action: #selector(premiumTapped)
        )
        contentStack.addArrangedSubview(premiumContent)
    }

    private func buildPlanRow(
        card: UIView,
        radio: inout UIView,
        title: String,
        priceLabel: UILabel,
        subLabel: UILabel?,
        badge: String?,
        badgeColor: UIColor?,
        action: Selector
    ) -> UIView {
        card.backgroundColor = AppColors.card
        card.layer.cornerRadius = 14
        card.layer.borderWidth = 1.5
        card.layer.borderColor = AppColors.border.cgColor
        card.isUserInteractionEnabled = true
        card.addGestureRecognizer(UITapGestureRecognizer(target: self, action: action))

        // Radio circle
        let radioOuter = UIView()
        radioOuter.layer.cornerRadius = 11
        radioOuter.layer.borderWidth = 2
        radioOuter.layer.borderColor = AppColors.textMuted.cgColor
        radioOuter.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            radioOuter.widthAnchor.constraint(equalToConstant: 22),
            radioOuter.heightAnchor.constraint(equalToConstant: 22),
        ])

        let radioInner = UIView()
        radioInner.backgroundColor = AppColors.accent
        radioInner.layer.cornerRadius = 6
        radioInner.translatesAutoresizingMaskIntoConstraints = false
        radioInner.isHidden = true
        radioOuter.addSubview(radioInner)
        NSLayoutConstraint.activate([
            radioInner.centerXAnchor.constraint(equalTo: radioOuter.centerXAnchor),
            radioInner.centerYAnchor.constraint(equalTo: radioOuter.centerYAnchor),
            radioInner.widthAnchor.constraint(equalToConstant: 12),
            radioInner.heightAnchor.constraint(equalToConstant: 12),
        ])

        radio = radioOuter

        // Title + badge
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .systemFont(ofSize: 16, weight: .bold)
        titleLabel.textColor = AppColors.text

        let titleRow = UIStackView(arrangedSubviews: [titleLabel])
        titleRow.axis = .horizontal
        titleRow.spacing = 8
        titleRow.alignment = .center

        if let badge = badge, let color = badgeColor {
            let badgeLabel = UILabel()
            badgeLabel.text = "  \(badge)  "
            badgeLabel.font = .systemFont(ofSize: 10, weight: .bold)
            badgeLabel.textColor = .white
            badgeLabel.backgroundColor = color
            badgeLabel.layer.cornerRadius = 4
            badgeLabel.layer.masksToBounds = true
            titleRow.addArrangedSubview(badgeLabel)
        }

        // Price
        priceLabel.font = .systemFont(ofSize: 14, weight: .semibold)
        priceLabel.textColor = AppColors.textSub

        let infoStack = UIStackView(arrangedSubviews: [titleRow, priceLabel])
        infoStack.axis = .vertical
        infoStack.spacing = 2
        infoStack.alignment = .leading

        if let sub = subLabel {
            sub.font = .systemFont(ofSize: 12)
            sub.textColor = AppColors.textMuted
            infoStack.addArrangedSubview(sub)
        }

        // Horizontal: radio + info
        let hStack = UIStackView(arrangedSubviews: [radioOuter, infoStack])
        hStack.axis = .horizontal
        hStack.spacing = 14
        hStack.alignment = .center
        hStack.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(hStack)

        NSLayoutConstraint.activate([
            hStack.topAnchor.constraint(equalTo: card.topAnchor, constant: 14),
            hStack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            hStack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
            hStack.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -14),
        ])

        return card
    }

    // MARK: - Bottom Section

    private func buildBottomSection() {
        let restoreButton = UIButton(type: .system)
        restoreButton.setTitle(L("onboarding.subscription.restore"), for: .normal)
        restoreButton.titleLabel?.font = .systemFont(ofSize: 14)
        restoreButton.setTitleColor(AppColors.textSub, for: .normal)
        restoreButton.addTarget(self, action: #selector(restoreTapped), for: .touchUpInside)

        let termsButton = UIButton(type: .system)
        termsButton.setTitle(L("settings.terms"), for: .normal)
        termsButton.titleLabel?.font = .systemFont(ofSize: 12)
        termsButton.setTitleColor(AppColors.textMuted, for: .normal)
        termsButton.addTarget(self, action: #selector(termsTapped), for: .touchUpInside)

        let dotLabel = UILabel()
        dotLabel.text = "·"
        dotLabel.font = .systemFont(ofSize: 12)
        dotLabel.textColor = AppColors.textMuted

        let privacyButton = UIButton(type: .system)
        privacyButton.setTitle(L("settings.privacy"), for: .normal)
        privacyButton.titleLabel?.font = .systemFont(ofSize: 12)
        privacyButton.setTitleColor(AppColors.textMuted, for: .normal)
        privacyButton.addTarget(self, action: #selector(privacyTapped), for: .touchUpInside)

        let linksStack = UIStackView(arrangedSubviews: [termsButton, dotLabel, privacyButton])
        linksStack.axis = .horizontal
        linksStack.spacing = 6
        linksStack.alignment = .center

        let bottomStack = UIStackView(arrangedSubviews: [restoreButton, linksStack])
        bottomStack.axis = .vertical
        bottomStack.spacing = 8
        bottomStack.alignment = .center

        contentStack.addArrangedSubview(bottomStack)
    }

    // MARK: - Selection State

    private func updateSelectionState() {
        let cards: [(UIView, UIView, SelectedPlan)] = [
            (yearlyCard, yearlyRadio, .yearlyPro),
            (monthlyCard, monthlyRadio, .monthlyPro),
            (premiumCard, premiumRadio, .premium),
        ]

        for (card, radio, plan) in cards {
            let isSelected = plan == selectedPlan
            card.layer.borderWidth = isSelected ? 2.5 : 1.5
            card.layer.borderColor = isSelected ? AppColors.accent.cgColor : AppColors.border.cgColor

            // Radio fill
            radio.layer.borderColor = isSelected ? AppColors.accent.cgColor : AppColors.textMuted.cgColor
            if let inner = radio.subviews.first {
                inner.isHidden = !isSelected
            }

            // Bounce animation
            if isSelected {
                UIView.animate(withDuration: 0.12, animations: {
                    card.transform = CGAffineTransform(scaleX: 0.97, y: 0.97)
                }) { _ in
                    UIView.animate(withDuration: 0.12) {
                        card.transform = .identity
                    }
                }
            }
        }

        // Update CTA text
        let ctaText: String
        switch selectedPlan {
        case .yearlyPro:
            ctaText = L("paywall.cta_subscribe_yearly")
        case .monthlyPro:
            ctaText = L("paywall.cta_subscribe_monthly")
        case .premium:
            ctaText = L("paywall.cta_subscribe_premium")
        }
        ctaButton.setTitle(ctaText, for: .normal)
    }

    // MARK: - Pricing

    private func applyFallbackPrices() {
        let yearlyKey = StoreKitManager.ProductID.yearlyPro.rawValue
        let monthlyKey = StoreKitManager.ProductID.monthlyPro.rawValue
        let premiumKey = StoreKitManager.ProductID.monthlyPremium.rawValue

        yearlyPriceLabel.text = String(format: L("paywall.per_month"), "$3.99")
        yearlyBilledLabel.text = L("paywall.billed_yearly")
        monthlyPriceLabel.text = String(format: L("paywall.per_month"), "$7.99")
        premiumPriceLabel.text = String(format: L("paywall.per_month"), "$14.99")
    }

    private func loadProducts() {
        Task {
            do {
                try await storeKitManager.loadProducts()
                updatePriceLabels()
            } catch {
                // StoreKit failed — fallback prices already displayed
            }
        }
    }

    private func updatePriceLabels() {
        for product in storeKitManager.products {
            switch product.id {
            case StoreKitManager.ProductID.yearlyPro.rawValue:
                let monthlyPrice = product.price / 12
                let formatter = NumberFormatter()
                formatter.numberStyle = .currency
                formatter.locale = product.priceFormatStyle.locale
                if let formatted = formatter.string(from: monthlyPrice as NSDecimalNumber) {
                    yearlyPriceLabel.text = String(format: L("paywall.per_month"), formatted)
                }
                yearlyBilledLabel.text = product.displayPrice

            case StoreKitManager.ProductID.monthlyPro.rawValue:
                monthlyPriceLabel.text = String(format: L("paywall.per_month"), product.displayPrice)

            case StoreKitManager.ProductID.monthlyPremium.rawValue:
                premiumPriceLabel.text = String(format: L("paywall.per_month"), product.displayPrice)

            default:
                break
            }
        }
    }

    // MARK: - Loading State

    private func setLoading(_ loading: Bool) {
        isLoading = loading
        ctaButton.isEnabled = !loading
        if loading {
            ctaButton.setTitle("", for: .normal)
            ctaSpinner.startAnimating()
        } else {
            ctaSpinner.stopAnimating()
            updateSelectionState()
        }
    }

    // MARK: - Error Toast

    private func showError(_ message: String) {
        let toast = UILabel()
        toast.text = "  \(message)  "
        toast.font = .systemFont(ofSize: 14, weight: .medium)
        toast.textColor = .white
        toast.backgroundColor = UIColor.systemRed
        toast.layer.cornerRadius = 10
        toast.clipsToBounds = true
        toast.textAlignment = .center
        toast.alpha = 0
        toast.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(toast)

        NSLayoutConstraint.activate([
            toast.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            toast.bottomAnchor.constraint(equalTo: ctaButton.topAnchor, constant: -12),
            toast.heightAnchor.constraint(equalToConstant: 36),
        ])

        UIView.animate(withDuration: 0.3) { toast.alpha = 1 }
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            UIView.animate(withDuration: 0.3, animations: { toast.alpha = 0 }) { _ in
                toast.removeFromSuperview()
            }
        }
    }

    // MARK: - Actions

    @objc private func closeTapped() {
        dismiss(animated: true)
    }

    @objc private func yearlyProTapped() {
        selectedPlan = .yearlyPro
        updateSelectionState()
    }

    @objc private func monthlyProTapped() {
        selectedPlan = .monthlyPro
        updateSelectionState()
    }

    @objc private func premiumTapped() {
        selectedPlan = .premium
        updateSelectionState()
    }

    @objc private func ctaTapped() {
        guard !isLoading else { return }

        let productId: StoreKitManager.ProductID
        switch selectedPlan {
        case .yearlyPro: productId = .yearlyPro
        case .monthlyPro: productId = .monthlyPro
        case .premium: productId = .monthlyPremium
        }

        purchaseProduct(id: productId)
    }

    private func purchaseProduct(id: StoreKitManager.ProductID) {
        guard let product = storeKitManager.products.first(where: { $0.id == id.rawValue }) else {
            showError(L("paywall.error_loading"))
            return
        }

        setLoading(true)
        Task {
            do {
                let transaction = try await storeKitManager.purchase(product)
                setLoading(false)
                if transaction != nil {
                    showSuccessAndDismiss()
                }
            } catch {
                setLoading(false)
                showError(L("paywall.error_purchase"))
            }
        }
    }

    private func showSuccessAndDismiss() {
        let check = UIImageView(image: UIImage(systemName: "checkmark.circle.fill"))
        check.tintColor = AppColors.green
        check.contentMode = .scaleAspectFit
        check.translatesAutoresizingMaskIntoConstraints = false
        check.alpha = 0
        check.transform = CGAffineTransform(scaleX: 0.3, y: 0.3)
        view.addSubview(check)

        NSLayoutConstraint.activate([
            check.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            check.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            check.widthAnchor.constraint(equalToConstant: 80),
            check.heightAnchor.constraint(equalToConstant: 80),
        ])

        UIView.animate(withDuration: 0.4, delay: 0, usingSpringWithDamping: 0.6, initialSpringVelocity: 0.8) {
            check.alpha = 1
            check.transform = .identity
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.dismiss(animated: true)
        }
    }

    @objc private func restoreTapped() {
        setLoading(true)
        Task {
            do {
                try await storeKitManager.restorePurchases()
                setLoading(false)
                if SubscriptionStatus.shared.isPro {
                    showSuccessAndDismiss()
                } else {
                    showError(L("paywall.error_no_subscription"))
                }
            } catch {
                setLoading(false)
                showError(L("paywall.error_restore"))
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
