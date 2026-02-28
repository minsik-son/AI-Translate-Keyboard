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
        navigationController?.navigationBar.prefersLargeTitles = true
        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.largeTitleTextAttributes = [.foregroundColor: AppColors.text]
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
    private let reportCard = UIView()
    private let reportWordsLabel = UILabel()
    private let reportCorrectionsLabel = UILabel()
    private let reportAccuracyLabel = UILabel()
    private let reportChangeLabel = UILabel()

    private let correctionCountLabel = UILabel()
    private let translationCountLabel = UILabel()
    private let clipboardCountLabel = UILabel()
    private let phrasesCountLabel = UILabel()

    private func buildContent() {
        // Greeting
        greetingLabel.font = .systemFont(ofSize: 14, weight: .regular)
        greetingLabel.textColor = AppColors.textSub
        contentStack.addArrangedSubview(greetingLabel)

        let titleLabel = UILabel()
        titleLabel.text = L("home.title")
        titleLabel.font = .systemFont(ofSize: 28, weight: .bold)
        titleLabel.textColor = AppColors.text
        contentStack.addArrangedSubview(titleLabel)

        contentStack.setCustomSpacing(24, after: titleLabel)

        // Weekly Report Card
        buildReportCard()
        contentStack.addArrangedSubview(reportCard)
        contentStack.setCustomSpacing(16, after: reportCard)

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

    private func buildReportCard() {
        reportCard.backgroundColor = AppColors.accentSoft
        reportCard.layer.cornerRadius = 14
        reportCard.layer.borderWidth = 1
        reportCard.layer.borderColor = AppColors.accent.withAlphaComponent(0.3).cgColor

        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 8
        stack.translatesAutoresizingMaskIntoConstraints = false
        reportCard.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: reportCard.topAnchor, constant: 18),
            stack.leadingAnchor.constraint(equalTo: reportCard.leadingAnchor, constant: 18),
            stack.trailingAnchor.constraint(equalTo: reportCard.trailingAnchor, constant: -18),
            stack.bottomAnchor.constraint(equalTo: reportCard.bottomAnchor, constant: -18),
        ])

        let headerLabel = UILabel()
        headerLabel.text = "✨ " + L("home.weekly_report")
        headerLabel.font = .systemFont(ofSize: 15, weight: .semibold)
        headerLabel.textColor = AppColors.text
        stack.addArrangedSubview(headerLabel)
        stack.setCustomSpacing(12, after: headerLabel)

        reportWordsLabel.font = .systemFont(ofSize: 15, weight: .medium)
        reportWordsLabel.textColor = AppColors.text
        stack.addArrangedSubview(reportWordsLabel)

        reportCorrectionsLabel.font = .systemFont(ofSize: 15, weight: .medium)
        reportCorrectionsLabel.textColor = AppColors.text
        stack.addArrangedSubview(reportCorrectionsLabel)

        reportAccuracyLabel.font = .systemFont(ofSize: 15, weight: .medium)
        reportAccuracyLabel.textColor = AppColors.text
        stack.addArrangedSubview(reportAccuracyLabel)

        reportChangeLabel.font = .systemFont(ofSize: 13, weight: .regular)
        reportChangeLabel.textColor = AppColors.textSub
        stack.addArrangedSubview(reportChangeLabel)
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

        topRow.addArrangedSubview(makeStatCard(
            icon: "pencil", color: AppColors.orange,
            title: L("home.stat.corrections"), valueLabel: correctionCountLabel
        ))
        topRow.addArrangedSubview(makeStatCard(
            icon: "globe", color: AppColors.blue,
            title: L("home.stat.translations"), valueLabel: translationCountLabel
        ))
        bottomRow.addArrangedSubview(makeStatCard(
            icon: "doc.on.clipboard", color: AppColors.green,
            title: L("home.stat.clipboard"), valueLabel: clipboardCountLabel
        ))
        bottomRow.addArrangedSubview(makeStatCard(
            icon: "bookmark.fill", color: AppColors.pink,
            title: L("home.stat.phrases"), valueLabel: phrasesCountLabel
        ))

        let grid = UIStackView(arrangedSubviews: [topRow, bottomRow])
        grid.axis = .vertical
        grid.spacing = 12
        return grid
    }

    private func makeStatCard(icon: String, color: UIColor, title: String, valueLabel: UILabel) -> UIView {
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

        let stack = UIStackView(arrangedSubviews: [iconBg, titleLabel, valueLabel])
        stack.axis = .vertical
        stack.spacing = 6
        stack.alignment = .leading
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

    @objc private func handleHistoryChange() {
        refreshStats()
    }

    // MARK: - Data Refresh

    private func refreshStats() {
        let stats = StatsManager.shared
        let greeting = timeBasedGreeting()
        greetingLabel.text = greeting
        title = L("home.title")

        reportWordsLabel.text = "\(stats.weeklyWordsTyped) " + L("home.words_typed")
        reportCorrectionsLabel.text = "Gemini \(stats.weeklyCorrections)" + L("home.corrections")
        let accuracy = stats.weeklyAccuracy
        reportAccuracyLabel.text = L("home.accuracy") + " \(String(format: "%.1f", accuracy))%"
        let change = stats.accuracyChange
        if change != 0 {
            let sign = change > 0 ? "+" : ""
            reportChangeLabel.text = L("home.vs_last_week") + " \(sign)\(String(format: "%.1f", change))%"
            reportChangeLabel.textColor = change > 0 ? AppColors.green : AppColors.orange
        } else {
            reportChangeLabel.text = nil
        }

        correctionCountLabel.text = "\(stats.weeklyCorrections)"
        translationCountLabel.text = "\(stats.weeklyTranslations)"

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
