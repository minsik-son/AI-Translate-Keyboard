import UIKit

class HomeViewController: UIViewController {

    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = AppColors.bg
        setupNavigation()
        setupScrollView()
        buildContent()
        NotificationCenter.default.addObserver(self, selector: #selector(handleHistoryChange), name: .historyDidChange, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleLanguageChange), name: .languageDidChange, object: nil)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        StatsManager.shared.checkAndResetWeeklyStats()
        refreshStats()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        animateEntrance()
    }

    // MARK: - Setup

    private func setupNavigation() {
        title = L("home.title")
        navigationController?.navigationBar.prefersLargeTitles = false
        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.titleTextAttributes = [.foregroundColor: AppColors.text]
        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
    }

    private func setupScrollView() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])

        contentStack.axis = .vertical
        contentStack.spacing = 16
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentStack)
        NSLayoutConstraint.activate([
            contentStack.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 16),
            contentStack.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 20),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -20),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -32),
            contentStack.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -40),
        ])
    }

    // MARK: - Content

    private let greetingLabel = UILabel()

    // Plan card
    private let planCard = UIView()
    private let planNameLabel = UILabel()
    private let planDescLabel = UILabel()
    private let subscribeButton = UIButton(type: .system)
    private let priceLabel = UILabel()
    private let subscribedStack = UIStackView()

    // Dual circular progress (correction + translation)
    private let corrProgressContainer = UIView()
    private let corrCenterLabel = UILabel()
    private let corrSubLabel = UILabel()
    private var corrTrackLayer = CAShapeLayer()
    private var corrProgressLayer = CAShapeLayer()

    private let transProgressContainer = UIView()
    private let transCenterLabel = UILabel()
    private let transSubLabel = UILabel()
    private var transTrackLayer = CAShapeLayer()
    private var transProgressLayer = CAShapeLayer()

    private let correctionCountLabel = UILabel()
    private let translationCountLabel = UILabel()
    private let clipboardCountLabel = UILabel()
    private let phrasesCountLabel = UILabel()

    // 교정/번역 카드 참조 (소진 시 UI 변경용)
    private var correctionCard: UIView?
    private var translationCard: UIView?
    private let correctionAdBadge = UILabel()
    private let translationAdBadge = UILabel()

    private func buildContent() {
        // Greeting
        greetingLabel.font = .systemFont(ofSize: 14, weight: .regular)
        greetingLabel.textColor = AppColors.textSub
        contentStack.addArrangedSubview(greetingLabel)

        contentStack.setCustomSpacing(16, after: greetingLabel)

        // Plan Status + Daily Usage Card
        buildPlanCard()
        contentStack.addArrangedSubview(planCard)
        contentStack.setCustomSpacing(16, after: planCard)

        // Stats Grid (2x2)
        let statsGrid = buildStatsGrid()
        contentStack.addArrangedSubview(statsGrid)
        contentStack.setCustomSpacing(24, after: statsGrid)

        // Quick Actions
        let quickLabel = UILabel()
        quickLabel.text = L("home.quick_actions")
        quickLabel.font = .systemFont(ofSize: 12, weight: .semibold)
        quickLabel.textColor = AppColors.textMuted
        quickLabel.text = quickLabel.text?.uppercased()
        contentStack.addArrangedSubview(quickLabel)

        let quickActions = buildQuickActions()
        contentStack.addArrangedSubview(quickActions)
    }

    private func buildPlanCard() {
        planCard.backgroundColor = AppColors.card
        planCard.layer.cornerRadius = 14
        planCard.layer.borderWidth = 1
        planCard.layer.borderColor = AppColors.border.cgColor

        // === Top section: plan info ===
        let topStack = UIStackView()
        topStack.axis = .vertical
        topStack.spacing = 6
        topStack.alignment = .leading

        planNameLabel.font = .systemFont(ofSize: 22, weight: .bold)
        planNameLabel.textColor = AppColors.text
        topStack.addArrangedSubview(planNameLabel)

        planDescLabel.font = .systemFont(ofSize: 13)
        planDescLabel.textColor = AppColors.textSub
        planDescLabel.numberOfLines = 0
        topStack.addArrangedSubview(planDescLabel)
        topStack.setCustomSpacing(14, after: planDescLabel)

        // Subscribe button (Free only)
        subscribeButton.setTitle(L("home.plan.subscribe"), for: .normal)
        subscribeButton.titleLabel?.font = .systemFont(ofSize: 14, weight: .bold)
        subscribeButton.setTitleColor(.white, for: .normal)
        subscribeButton.backgroundColor = AppColors.accent
        subscribeButton.layer.cornerRadius = 10
        subscribeButton.contentEdgeInsets = UIEdgeInsets(top: 10, left: 20, bottom: 10, right: 20)
        subscribeButton.addTarget(self, action: #selector(subscribeTapped), for: .touchUpInside)
        topStack.addArrangedSubview(subscribeButton)

        // Price label (Free only)
        priceLabel.font = .systemFont(ofSize: 12)
        priceLabel.textColor = AppColors.textMuted
        topStack.addArrangedSubview(priceLabel)

        // Subscribed badge (Pro/Premium)
        let checkIcon = UIImageView(image: UIImage(systemName: "checkmark.circle.fill"))
        checkIcon.tintColor = AppColors.green
        checkIcon.translatesAutoresizingMaskIntoConstraints = false
        checkIcon.widthAnchor.constraint(equalToConstant: 18).isActive = true
        checkIcon.heightAnchor.constraint(equalToConstant: 18).isActive = true

        let subscribedLabel = UILabel()
        subscribedLabel.text = L("home.plan.subscribed")
        subscribedLabel.font = .systemFont(ofSize: 14, weight: .medium)
        subscribedLabel.textColor = AppColors.green

        subscribedStack.axis = .horizontal
        subscribedStack.spacing = 6
        subscribedStack.alignment = .center
        subscribedStack.addArrangedSubview(checkIcon)
        subscribedStack.addArrangedSubview(subscribedLabel)
        topStack.addArrangedSubview(subscribedStack)

        // Top wrapper with padding
        let topWrapper = UIView()
        topStack.translatesAutoresizingMaskIntoConstraints = false
        topWrapper.addSubview(topStack)
        NSLayoutConstraint.activate([
            topStack.topAnchor.constraint(equalTo: topWrapper.topAnchor, constant: 20),
            topStack.leadingAnchor.constraint(equalTo: topWrapper.leadingAnchor, constant: 20),
            topStack.trailingAnchor.constraint(equalTo: topWrapper.trailingAnchor, constant: -20),
            topStack.bottomAnchor.constraint(equalTo: topWrapper.bottomAnchor, constant: -16),
        ])

        // === Divider ===
        let divider = UIView()
        divider.backgroundColor = AppColors.border
        divider.translatesAutoresizingMaskIntoConstraints = false
        divider.heightAnchor.constraint(equalToConstant: 1).isActive = true

        // === Bottom section: dual circular progress ===
        let circleSize: CGFloat = 80

        // Correction circle
        let corrColumn = UIStackView()
        corrColumn.axis = .vertical
        corrColumn.spacing = 6
        corrColumn.alignment = .center

        corrProgressContainer.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            corrProgressContainer.widthAnchor.constraint(equalToConstant: circleSize),
            corrProgressContainer.heightAnchor.constraint(equalToConstant: circleSize),
        ])
        corrCenterLabel.font = .systemFont(ofSize: 15, weight: .bold)
        corrCenterLabel.textColor = AppColors.text
        corrCenterLabel.textAlignment = .center
        corrCenterLabel.translatesAutoresizingMaskIntoConstraints = false
        corrProgressContainer.addSubview(corrCenterLabel)
        NSLayoutConstraint.activate([
            corrCenterLabel.centerXAnchor.constraint(equalTo: corrProgressContainer.centerXAnchor),
            corrCenterLabel.centerYAnchor.constraint(equalTo: corrProgressContainer.centerYAnchor),
        ])
        corrSubLabel.text = L("home.stat.corrections")
        corrSubLabel.font = .systemFont(ofSize: 12, weight: .medium)
        corrSubLabel.textColor = AppColors.textSub
        corrColumn.addArrangedSubview(corrProgressContainer)
        corrColumn.addArrangedSubview(corrSubLabel)

        // Translation circle
        let transColumn = UIStackView()
        transColumn.axis = .vertical
        transColumn.spacing = 6
        transColumn.alignment = .center

        transProgressContainer.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            transProgressContainer.widthAnchor.constraint(equalToConstant: circleSize),
            transProgressContainer.heightAnchor.constraint(equalToConstant: circleSize),
        ])
        transCenterLabel.font = .systemFont(ofSize: 15, weight: .bold)
        transCenterLabel.textColor = AppColors.text
        transCenterLabel.textAlignment = .center
        transCenterLabel.translatesAutoresizingMaskIntoConstraints = false
        transProgressContainer.addSubview(transCenterLabel)
        NSLayoutConstraint.activate([
            transCenterLabel.centerXAnchor.constraint(equalTo: transProgressContainer.centerXAnchor),
            transCenterLabel.centerYAnchor.constraint(equalTo: transProgressContainer.centerYAnchor),
        ])
        transSubLabel.text = L("home.stat.translations")
        transSubLabel.font = .systemFont(ofSize: 12, weight: .medium)
        transSubLabel.textColor = AppColors.textSub
        transColumn.addArrangedSubview(transProgressContainer)
        transColumn.addArrangedSubview(transSubLabel)

        // Two circles side by side, centered
        let circlesStack = UIStackView(arrangedSubviews: [corrColumn, transColumn])
        circlesStack.axis = .horizontal
        circlesStack.spacing = 32
        circlesStack.alignment = .center
        circlesStack.distribution = .equalCentering

        // Bottom wrapper with padding
        let bottomWrapper = UIView()
        circlesStack.translatesAutoresizingMaskIntoConstraints = false
        bottomWrapper.addSubview(circlesStack)
        NSLayoutConstraint.activate([
            circlesStack.topAnchor.constraint(equalTo: bottomWrapper.topAnchor, constant: 16),
            circlesStack.centerXAnchor.constraint(equalTo: bottomWrapper.centerXAnchor),
            circlesStack.bottomAnchor.constraint(equalTo: bottomWrapper.bottomAnchor, constant: -16),
        ])

        // === Main vertical layout ===
        let mainStack = UIStackView(arrangedSubviews: [topWrapper, divider, bottomWrapper])
        mainStack.axis = .vertical
        mainStack.spacing = 0
        mainStack.translatesAutoresizingMaskIntoConstraints = false
        planCard.addSubview(mainStack)

        NSLayoutConstraint.activate([
            mainStack.topAnchor.constraint(equalTo: planCard.topAnchor),
            mainStack.leadingAnchor.constraint(equalTo: planCard.leadingAnchor),
            mainStack.trailingAnchor.constraint(equalTo: planCard.trailingAnchor),
            mainStack.bottomAnchor.constraint(equalTo: planCard.bottomAnchor),
        ])
    }

    private func setupCircle(container: UIView, trackLayer: inout CAShapeLayer, progressLayer: inout CAShapeLayer, used: Int, total: Int, color: UIColor) {
        trackLayer.removeFromSuperlayer()
        progressLayer.removeFromSuperlayer()

        let size: CGFloat = 80
        let center = CGPoint(x: size / 2, y: size / 2)
        let radius: CGFloat = 32
        let lineWidth: CGFloat = 8
        let startAngle = -CGFloat.pi / 2
        let endAngle = startAngle + 2 * CGFloat.pi

        let circularPath = UIBezierPath(
            arcCenter: center, radius: radius,
            startAngle: startAngle, endAngle: endAngle, clockwise: true
        )

        // Track
        trackLayer = CAShapeLayer()
        trackLayer.path = circularPath.cgPath
        trackLayer.strokeColor = AppColors.border.cgColor
        trackLayer.fillColor = UIColor.clear.cgColor
        trackLayer.lineWidth = lineWidth
        trackLayer.lineCap = .round
        container.layer.addSublayer(trackLayer)

        // Progress
        progressLayer = CAShapeLayer()
        progressLayer.path = circularPath.cgPath
        progressLayer.fillColor = UIColor.clear.cgColor
        progressLayer.lineWidth = lineWidth
        progressLayer.lineCap = .round

        let fraction = total > 0 ? CGFloat(used) / CGFloat(total) : 0
        progressLayer.strokeEnd = min(fraction, 1.0)

        if fraction >= 1.0 {
            progressLayer.strokeColor = UIColor.systemRed.cgColor
        } else if fraction >= 0.7 {
            progressLayer.strokeColor = AppColors.orange.cgColor
        } else {
            progressLayer.strokeColor = color.cgColor
        }

        container.layer.addSublayer(progressLayer)
    }

    @objc private func subscribeTapped() {
        let paywallVC = PaywallViewController()
        paywallVC.modalPresentationStyle = .pageSheet
        present(paywallVC, animated: true)
    }

    private func updatePlanCard() {
        let tier = SubscriptionStatus.shared.currentTier
        let usage = DailyUsageManager.shared

        // Plan info (left column)
        switch tier {
        case .free:
            planNameLabel.text = L("home.plan.free")
            planDescLabel.text = L("home.plan.free_desc")
            subscribeButton.isHidden = false
            priceLabel.isHidden = false
            priceLabel.text = String(format: L("home.plan.price"), "$7.99")
            subscribedStack.isHidden = true
        case .pro:
            planNameLabel.text = L("home.plan.pro")
            planDescLabel.text = L("home.plan.pro_desc")
            subscribeButton.isHidden = true
            priceLabel.isHidden = true
            subscribedStack.isHidden = false
        case .premium:
            planNameLabel.text = L("home.plan.premium")
            planDescLabel.text = L("home.plan.premium_desc")
            subscribeButton.isHidden = true
            priceLabel.isHidden = true
            subscribedStack.isHidden = false
        }

        // Correction circle (remaining / total including bonus)
        let corrUsed = usage.correctionCount
        let corrTotal = FeatureGate.shared.dailyCorrectionLimit
            + (UserDefaults(suiteName: AppConstants.appGroupIdentifier)?.integer(forKey: "bonus_correction_count") ?? 0)

        // Translation circle
        let transUsed = usage.translationCount
        let transTotal = FeatureGate.shared.dailyTranslationLimit
            + (UserDefaults(suiteName: AppConstants.appGroupIdentifier)?.integer(forKey: "bonus_translation_count") ?? 0)

        if tier == .premium && FeatureGate.shared.isPremiumUnlimited {
            corrCenterLabel.text = L("home.plan.unlimited")
            corrCenterLabel.font = .systemFont(ofSize: 20, weight: .bold)
            transCenterLabel.text = L("home.plan.unlimited")
            transCenterLabel.font = .systemFont(ofSize: 20, weight: .bold)
            setupCircle(container: corrProgressContainer, trackLayer: &corrTrackLayer, progressLayer: &corrProgressLayer, used: 1, total: 1, color: AppColors.green)
            setupCircle(container: transProgressContainer, trackLayer: &transTrackLayer, progressLayer: &transProgressLayer, used: 1, total: 1, color: AppColors.green)
            corrProgressLayer.strokeColor = AppColors.green.cgColor
            transProgressLayer.strokeColor = AppColors.green.cgColor
        } else {
            corrCenterLabel.text = "\(corrUsed)/\(corrTotal)"
            corrCenterLabel.font = .systemFont(ofSize: 15, weight: .bold)
            transCenterLabel.text = "\(transUsed)/\(transTotal)"
            transCenterLabel.font = .systemFont(ofSize: 15, weight: .bold)
            setupCircle(container: corrProgressContainer, trackLayer: &corrTrackLayer, progressLayer: &corrProgressLayer, used: corrUsed, total: corrTotal, color: AppColors.orange)
            setupCircle(container: transProgressContainer, trackLayer: &transTrackLayer, progressLayer: &transProgressLayer, used: transUsed, total: transTotal, color: AppColors.blue)
        }
    }

    private func buildStatsGrid() -> UIView {
        let topRow = UIStackView()
        topRow.axis = .horizontal
        topRow.spacing = 12
        topRow.distribution = .fillEqually

        let bottomRow = UIStackView()
        bottomRow.axis = .horizontal
        bottomRow.spacing = 12
        bottomRow.distribution = .fillEqually

        correctionCountLabel.text = "0"
        translationCountLabel.text = "0"
        clipboardCountLabel.text = "0"
        phrasesCountLabel.text = "0"

        let cCard = makeStatCard(
            icon: "pencil", color: AppColors.orange,
            title: L("home.stat.corrections"), valueLabel: correctionCountLabel,
            adBadge: correctionAdBadge
        )
        let correctionTap = UITapGestureRecognizer(target: self, action: #selector(correctionCardTapped))
        cCard.addGestureRecognizer(correctionTap)
        correctionCard = cCard

        let tCard = makeStatCard(
            icon: "globe", color: AppColors.blue,
            title: L("home.stat.translations"), valueLabel: translationCountLabel,
            adBadge: translationAdBadge
        )
        let translationTap = UITapGestureRecognizer(target: self, action: #selector(translationCardTapped))
        tCard.addGestureRecognizer(translationTap)
        translationCard = tCard

        topRow.addArrangedSubview(cCard)
        topRow.addArrangedSubview(tCard)
        let clCard = makeStatCard(
            icon: "doc.on.clipboard", color: AppColors.green,
            title: L("home.stat.clipboard"), valueLabel: clipboardCountLabel
        )
        let clipboardTap = UITapGestureRecognizer(target: self, action: #selector(clipboardCardTapped))
        clCard.addGestureRecognizer(clipboardTap)

        let pCard = makeStatCard(
            icon: "bookmark.fill", color: AppColors.pink,
            title: L("home.stat.phrases"), valueLabel: phrasesCountLabel
        )
        let phrasesTap = UITapGestureRecognizer(target: self, action: #selector(phrasesCardTapped))
        pCard.addGestureRecognizer(phrasesTap)

        bottomRow.addArrangedSubview(clCard)
        bottomRow.addArrangedSubview(pCard)

        let grid = UIStackView(arrangedSubviews: [topRow, bottomRow])
        grid.axis = .vertical
        grid.spacing = 12
        return grid
    }

    private func makeStatCard(icon: String, color: UIColor, title: String, valueLabel: UILabel, adBadge: UILabel? = nil) -> UIView {
        let card = UIView()
        card.backgroundColor = AppColors.card
        card.layer.cornerRadius = 14
        card.layer.borderWidth = 1
        card.layer.borderColor = AppColors.border.cgColor

        let iconBg = UIView()
        iconBg.backgroundColor = color.withAlphaComponent(0.15)
        iconBg.layer.cornerRadius = 16
        iconBg.translatesAutoresizingMaskIntoConstraints = false

        let iconImage = UIImageView(image: UIImage(systemName: icon))
        iconImage.tintColor = color
        iconImage.contentMode = .scaleAspectFit
        iconImage.translatesAutoresizingMaskIntoConstraints = false
        iconBg.addSubview(iconImage)

        let titleLabel = UILabel()
        titleLabel.text = title.uppercased()
        titleLabel.font = .systemFont(ofSize: 11, weight: .semibold)
        titleLabel.textColor = AppColors.textMuted

        valueLabel.font = .systemFont(ofSize: 26, weight: .bold)
        valueLabel.textColor = AppColors.text

        var arrangedViews: [UIView] = [iconBg, titleLabel, valueLabel]

        // 광고 배지 (소진 시 표시)
        if let badge = adBadge {
            badge.text = "▶ " + L("home.watch_ad")
            badge.font = .systemFont(ofSize: 11, weight: .semibold)
            badge.textColor = .white
            badge.backgroundColor = AppColors.accent
            badge.layer.cornerRadius = 8
            badge.clipsToBounds = true
            badge.textAlignment = .center
            badge.isHidden = true
            arrangedViews.append(badge)
        }

        let stack = UIStackView(arrangedSubviews: arrangedViews)
        stack.axis = .vertical
        stack.spacing = 6
        stack.alignment = .leading
        stack.isUserInteractionEnabled = false
        stack.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(stack)

        NSLayoutConstraint.activate([
            iconBg.widthAnchor.constraint(equalToConstant: 32),
            iconBg.heightAnchor.constraint(equalToConstant: 32),
            iconImage.centerXAnchor.constraint(equalTo: iconBg.centerXAnchor),
            iconImage.centerYAnchor.constraint(equalTo: iconBg.centerYAnchor),
            iconImage.widthAnchor.constraint(equalToConstant: 16),
            iconImage.heightAnchor.constraint(equalToConstant: 16),
            stack.topAnchor.constraint(equalTo: card.topAnchor, constant: 16),
            stack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
            stack.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -16),
        ])

        if let badge = adBadge {
            badge.heightAnchor.constraint(equalToConstant: 24).isActive = true
            badge.widthAnchor.constraint(equalTo: stack.widthAnchor).isActive = true
        }

        return card
    }

    private func buildQuickActions() -> UIView {
        let container = UIView()
        container.backgroundColor = AppColors.card
        container.layer.cornerRadius = 14
        container.layer.borderWidth = 1
        container.layer.borderColor = AppColors.border.cgColor

        let stack = UIStackView()
        stack.axis = .vertical
        stack.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: container.topAnchor),
            stack.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            stack.bottomAnchor.constraint(equalTo: container.bottomAnchor),
        ])

        let actions: [(String, String, Int)] = [
            (L("ai_writer.title"), "sparkles", 1),
            (L("history.filter.translate") + " " + L("tab.history"), "globe", 2),
        ]

        for (i, action) in actions.enumerated() {
            let row = makeQuickActionRow(title: action.0, icon: action.1, tag: action.2)
            stack.addArrangedSubview(row)
            if i < actions.count - 1 {
                let sep = UIView()
                sep.backgroundColor = AppColors.border
                sep.translatesAutoresizingMaskIntoConstraints = false
                sep.heightAnchor.constraint(equalToConstant: 0.5).isActive = true
                stack.addArrangedSubview(sep)
            }
        }

        return container
    }

    private func makeQuickActionRow(title: String, icon: String, tag: Int) -> UIView {
        let btn = UIButton(type: .system)
        btn.tag = tag
        btn.addTarget(self, action: #selector(quickActionTapped(_:)), for: .touchUpInside)

        var config = UIButton.Configuration.plain()
        config.title = title
        config.image = UIImage(systemName: icon)
        config.imagePadding = 10
        config.baseForegroundColor = AppColors.text
        config.contentInsets = NSDirectionalEdgeInsets(top: 14, leading: 16, bottom: 14, trailing: 16)

        let chevron = UIImageView(image: UIImage(systemName: "chevron.right"))
        chevron.tintColor = AppColors.textMuted
        chevron.translatesAutoresizingMaskIntoConstraints = false

        btn.configuration = config
        btn.contentHorizontalAlignment = .leading
        btn.addSubview(chevron)
        NSLayoutConstraint.activate([
            chevron.centerYAnchor.constraint(equalTo: btn.centerYAnchor),
            chevron.trailingAnchor.constraint(equalTo: btn.trailingAnchor, constant: -16),
        ])

        return btn
    }

    // MARK: - Actions

    @objc private func quickActionTapped(_ sender: UIButton) {
        guard let tabBar = tabBarController else { return }
        switch sender.tag {
        case 1: tabBar.selectedIndex = 1 // AI Writer
        case 2: tabBar.selectedIndex = 2 // History
        default: break
        }
    }

    @objc private func correctionCardTapped() {
        if !SubscriptionStatus.shared.isPro && DailyUsageManager.shared.remainingCorrections <= 0 {
            presentRewardedAds(mode: .correction)
        } else {
            navigateToHistory(filter: .correction)
        }
    }

    @objc private func translationCardTapped() {
        if !SubscriptionStatus.shared.isPro && DailyUsageManager.shared.remainingTranslations <= 0 {
            presentRewardedAds(mode: .translation)
        } else {
            navigateToHistory(filter: .translation)
        }
    }

    private func presentRewardedAds(mode: RewardMode) {
        if DailyUsageManager.shared.canWatchRewardedAd(for: mode) {
            let rewardVC = RewardedAdsViewController(mode: mode)
            rewardVC.modalPresentationStyle = .fullScreen
            present(rewardVC, animated: true)
        } else {
            let paywallVC = PaywallViewController()
            paywallVC.modalPresentationStyle = .pageSheet
            present(paywallVC, animated: true)
        }
    }

    @objc private func clipboardCardTapped() {
        navigateToHistory(filter: .clipboard)
    }

    @objc private func phrasesCardTapped() {
        navigateToHistory(filter: nil)
    }

    private func navigateToHistory(filter: HistoryType?) {
        guard let tabBar = tabBarController else { return }
        tabBar.selectedIndex = 2
        if let nav = tabBar.viewControllers?[2] as? UINavigationController,
           let historyVC = nav.viewControllers.first as? HistoryViewController {
            historyVC.selectFilter(filter)
        }
    }

    private func updateDailyLimitCards() {
        guard !SubscriptionStatus.shared.isPro else {
            // Pro 유저는 소진 UI 숨김
            correctionAdBadge.isHidden = true
            translationAdBadge.isHidden = true
            correctionCard?.layer.borderColor = AppColors.border.cgColor
            translationCard?.layer.borderColor = AppColors.border.cgColor
            return
        }

        let correctionExhausted = DailyUsageManager.shared.remainingCorrections <= 0
        let translationExhausted = DailyUsageManager.shared.remainingTranslations <= 0

        // 교정 카드
        if correctionExhausted {
            correctionAdBadge.isHidden = false
            correctionCard?.layer.borderColor = AppColors.orange.withAlphaComponent(0.5).cgColor
            correctionCard?.layer.borderWidth = 1.5
        } else {
            correctionAdBadge.isHidden = true
            correctionCard?.layer.borderColor = AppColors.border.cgColor
            correctionCard?.layer.borderWidth = 1
        }

        // 번역 카드
        if translationExhausted {
            translationAdBadge.isHidden = false
            translationCard?.layer.borderColor = AppColors.blue.withAlphaComponent(0.5).cgColor
            translationCard?.layer.borderWidth = 1.5
        } else {
            translationAdBadge.isHidden = true
            translationCard?.layer.borderColor = AppColors.border.cgColor
            translationCard?.layer.borderWidth = 1
        }
    }

    @objc private func handleHistoryChange() {
        refreshStats()
    }

    @objc private func handleLanguageChange() {
        title = L("home.title")
        contentStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        planCard.subviews.forEach { $0.removeFromSuperview() }
        corrTrackLayer.removeFromSuperlayer()
        corrProgressLayer.removeFromSuperlayer()
        transTrackLayer.removeFromSuperlayer()
        transProgressLayer.removeFromSuperlayer()
        buildContent()
        refreshStats()
    }

    // MARK: - Data Refresh

    private func refreshStats() {
        let stats = StatsManager.shared
        let greeting = timeBasedGreeting()
        greetingLabel.text = greeting

        // Plan card update
        updatePlanCard()

        correctionCountLabel.text = "\(stats.weeklyCorrections)"
        translationCountLabel.text = "\(stats.weeklyTranslations)"

        // Free 티어: 일일 할당량 소진 시 카드 UI 변경
        updateDailyLimitCards()

        // Clipboard items count
        let clipboardData = UserDefaults(suiteName: AppConstants.appGroupIdentifier)?.data(forKey: AppConstants.UserDefaultsKeys.clipboardHistory)
        let clipboardCount: Int
        if let data = clipboardData, let items = try? JSONDecoder().decode([ClipboardItem].self, from: data) {
            clipboardCount = items.count
        } else {
            clipboardCount = 0
        }
        clipboardCountLabel.text = "\(clipboardCount)"

        // Saved phrases count
        let phrasesData = UserDefaults(suiteName: AppConstants.appGroupIdentifier)?.data(forKey: AppConstants.UserDefaultsKeys.savedPhrases)
        let phrasesCount: Int
        if let data = phrasesData, let items = try? JSONDecoder().decode([String].self, from: data) {
            phrasesCount = items.count
        } else {
            phrasesCount = 0
        }
        phrasesCountLabel.text = "\(phrasesCount)"
    }

    private func timeBasedGreeting() -> String {
        let hour = Calendar.current.component(.hour, from: Date())
        if hour < 12 {
            return L("home.greeting.morning")
        } else if hour < 18 {
            return L("home.greeting.afternoon")
        } else {
            return L("home.greeting.evening")
        }
    }

    // MARK: - Animations

    private var hasAnimated = false

    private func animateEntrance() {
        guard !hasAnimated else { return }
        hasAnimated = true

        let animatableViews = contentStack.arrangedSubviews
        for v in animatableViews {
            v.alpha = 0
            v.transform = CGAffineTransform(translationX: 0, y: 20)
        }

        for (i, v) in animatableViews.enumerated() {
            UIView.animate(
                withDuration: 0.4,
                delay: Double(i) * 0.05,
                options: .curveEaseOut
            ) {
                v.alpha = 1
                v.transform = .identity
            }
        }

        // Count-up animation for stat labels
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
            self?.animateCountUp()
        }
    }

    private func animateCountUp() {
        let stats = StatsManager.shared
        animateLabel(correctionCountLabel, to: stats.weeklyCorrections)
        animateLabel(translationCountLabel, to: stats.weeklyTranslations)

        let clipboardData = UserDefaults(suiteName: AppConstants.appGroupIdentifier)?.data(forKey: AppConstants.UserDefaultsKeys.clipboardHistory)
        let clipCount: Int
        if let data = clipboardData, let items = try? JSONDecoder().decode([ClipboardItem].self, from: data) {
            clipCount = items.count
        } else {
            clipCount = 0
        }
        animateLabel(clipboardCountLabel, to: clipCount)

        let phrasesData = UserDefaults(suiteName: AppConstants.appGroupIdentifier)?.data(forKey: AppConstants.UserDefaultsKeys.savedPhrases)
        let phrasesCount: Int
        if let data = phrasesData, let items = try? JSONDecoder().decode([String].self, from: data) {
            phrasesCount = items.count
        } else {
            phrasesCount = 0
        }
        animateLabel(phrasesCountLabel, to: phrasesCount)
    }

    private func animateLabel(_ label: UILabel, to target: Int) {
        guard target > 0 else {
            label.text = "0"
            return
        }
        label.text = "0"
        let duration: Double = 1.2
        let steps = min(target, 60)
        let interval = duration / Double(steps)

        for step in 1...steps {
            let delay = interval * Double(step)
            // easeOut: progress accelerates early, decelerates late
            let progress = 1.0 - pow(1.0 - Double(step) / Double(steps), 3.0)
            let value = Int(round(Double(target) * progress))
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak label] in
                label?.text = "\(value)"
            }
        }
    }
}
