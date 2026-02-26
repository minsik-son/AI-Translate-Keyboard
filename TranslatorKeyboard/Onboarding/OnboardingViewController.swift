import UIKit

class OnboardingViewController: UIViewController {

    // MARK: - Properties

    private let pageViewController = UIPageViewController(
        transitionStyle: .scroll,
        navigationOrientation: .horizontal
    )

    private var pages: [UIViewController] = []
    private var currentIndex = 0

    private let pageControl: UIPageControl = {
        let pc = UIPageControl()
        pc.numberOfPages = 6
        pc.currentPage = 0
        pc.currentPageIndicatorTintColor = .systemBlue
        pc.pageIndicatorTintColor = .systemGray4
        pc.translatesAutoresizingMaskIntoConstraints = false
        pc.isUserInteractionEnabled = false
        return pc
    }()

    private let ctaButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("시작하기", for: .normal)
        btn.titleLabel?.font = .systemFont(ofSize: 18, weight: .semibold)
        btn.backgroundColor = .systemBlue
        btn.setTitleColor(.white, for: .normal)
        btn.layer.cornerRadius = 14
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }()

    private var hasReturnedFromSettings = false

    // Permission page — for success state transition
    private var permissionTitleLabel: UILabel?
    private var permissionStepStack: UIStackView?
    private var successIconView: UIImageView?
    private var successTitleLabel: UILabel?
    private var successDescriptionLabel: UILabel?

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        buildPages()
        setupPageViewController()
        setupBottomControls()
        disableSwipeGesture()
        restoreProgress()
    }

    // MARK: - Page Factory

    private func buildPages() {
        pages = [
            makeWelcomePage(),
            makePermissionPage(),
            makeFeaturePage(icon: "textformat", title: "실시간 번역", description: "키보드에서 바로 번역하세요\n입력하면서 즉시 결과를 확인할 수 있습니다"),
            makeFeaturePage(icon: "globe", title: "다국어 지원", description: "한국어, 영어를 포함한\n다양한 언어를 지원합니다"),
            makeFeaturePage(icon: "hand.draw", title: "스마트 기능", description: "트랙패드 커서 이동, 테마 변경 등\n편리한 기능을 제공합니다"),
            makeSubscriptionPage()
        ]
    }

    // MARK: - Setup

    private func setupPageViewController() {
        addChild(pageViewController)
        view.addSubview(pageViewController.view)
        pageViewController.didMove(toParent: self)
        pageViewController.view.translatesAutoresizingMaskIntoConstraints = false

        if let firstPage = pages.first {
            pageViewController.setViewControllers([firstPage], direction: .forward, animated: false)
        }
    }

    private func setupBottomControls() {
        view.addSubview(pageControl)
        view.addSubview(ctaButton)

        NSLayoutConstraint.activate([
            pageViewController.view.topAnchor.constraint(equalTo: view.topAnchor),
            pageViewController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            pageViewController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            pageViewController.view.bottomAnchor.constraint(equalTo: pageControl.topAnchor, constant: -12),

            pageControl.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            pageControl.bottomAnchor.constraint(equalTo: ctaButton.topAnchor, constant: -16),

            ctaButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            ctaButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            ctaButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            ctaButton.heightAnchor.constraint(equalToConstant: 52),
        ])

        ctaButton.addTarget(self, action: #selector(ctaTapped), for: .touchUpInside)
    }

    private func disableSwipeGesture() {
        for view in pageViewController.view.subviews {
            if let scrollView = view as? UIScrollView {
                scrollView.isScrollEnabled = false
            }
        }
    }

    private func restoreProgress() {
        let defaults = UserDefaults(suiteName: AppConstants.appGroupIdentifier) ?? UserDefaults.standard
        let savedIndex = defaults.integer(forKey: "onboarding_current_page")
        hasReturnedFromSettings = defaults.bool(forKey: "onboarding_returned_from_settings")
        if savedIndex > 0, savedIndex < pages.count {
            currentIndex = savedIndex
            pageViewController.setViewControllers([pages[savedIndex]], direction: .forward, animated: false)
            pageControl.currentPage = savedIndex
            updateCTAForCurrentPage()
        }
    }

    // MARK: - Navigation

    @objc private func ctaTapped() {
        if currentIndex == 1 && !hasReturnedFromSettings {
            // 권한 설정 페이지: 설정 앱 열기
            let defaults = UserDefaults(suiteName: AppConstants.appGroupIdentifier) ?? UserDefaults.standard
            defaults.set(true, forKey: "onboarding_returned_from_settings")
            if let url = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(url)
            }
            return
        }

        if currentIndex == 5 {
            // 구독 페이지 CTA → 온보딩 완료
            completeOnboarding()
            return
        }

        goToPage(currentIndex + 1)
    }

    private func goToPage(_ index: Int) {
        guard index >= 0, index < pages.count else { return }
        let direction: UIPageViewController.NavigationDirection = index > currentIndex ? .forward : .reverse
        currentIndex = index
        pageViewController.setViewControllers([pages[index]], direction: direction, animated: true)
        pageControl.currentPage = index
        updateCTAForCurrentPage()
        let defaults = UserDefaults(suiteName: AppConstants.appGroupIdentifier) ?? UserDefaults.standard
        defaults.set(index, forKey: "onboarding_current_page")
    }

    private func updateCTAForCurrentPage() {
        // 구독 페이지에서는 CTA/pageControl 숨김 (구독 페이지 자체 UI 사용)
        let isSubscriptionPage = currentIndex == 5
        ctaButton.isHidden = isSubscriptionPage
        pageControl.isHidden = isSubscriptionPage

        switch currentIndex {
        case 0:
            ctaButton.setTitle("시작하기", for: .normal)
        case 1:
            ctaButton.setTitle(hasReturnedFromSettings ? "다음" : "설정으로 이동", for: .normal)
        case 2, 3, 4:
            ctaButton.setTitle("다음", for: .normal)
        default:
            break
        }
    }

    private func completeOnboarding() {
        let defaults = UserDefaults(suiteName: AppConstants.appGroupIdentifier) ?? UserDefaults.standard
        defaults.set(true, forKey: AppConstants.UserDefaultsKeys.hasCompletedOnboarding)
        defaults.removeObject(forKey: "onboarding_current_page")
        defaults.removeObject(forKey: "onboarding_returned_from_settings")
        dismiss(animated: true)
    }

    // MARK: - Foreground Notification (권한 설정 복귀 감지)

    private func registerForegroundObserver() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appWillEnterForeground),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )
    }

    @objc private func appWillEnterForeground() {
        guard currentIndex == 1 else { return }
        hasReturnedFromSettings = true
        let defaults = UserDefaults(suiteName: AppConstants.appGroupIdentifier) ?? UserDefaults.standard
        defaults.set(true, forKey: "onboarding_returned_from_settings")
        updateCTAForCurrentPage()
        showPermissionSuccess()
    }

    private func showPermissionSuccess() {
        permissionTitleLabel?.isHidden = true
        permissionStepStack?.isHidden = true

        successIconView?.isHidden = false
        successTitleLabel?.isHidden = false
        successDescriptionLabel?.isHidden = false
        successIconView?.alpha = 0
        successTitleLabel?.alpha = 0
        successDescriptionLabel?.alpha = 0

        UIView.animate(withDuration: 0.4) {
            self.successIconView?.alpha = 1
            self.successTitleLabel?.alpha = 1
            self.successDescriptionLabel?.alpha = 1
        }
    }
}

// MARK: - Welcome Page

private extension OnboardingViewController {
    func makeWelcomePage() -> UIViewController {
        let vc = UIViewController()
        vc.view.backgroundColor = .systemBackground

        let iconView = UIImageView()
        iconView.image = UIImage(systemName: "globe")
        iconView.tintColor = .systemBlue
        iconView.contentMode = .scaleAspectFit
        iconView.translatesAutoresizingMaskIntoConstraints = false

        let titleLabel = UILabel()
        titleLabel.text = "Translator Keyboard"
        titleLabel.font = .systemFont(ofSize: 30, weight: .bold)
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        let subtitleLabel = UILabel()
        subtitleLabel.text = "어디서든 번역하는 키보드"
        subtitleLabel.font = .systemFont(ofSize: 17)
        subtitleLabel.textColor = .secondaryLabel
        subtitleLabel.textAlignment = .center
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false

        vc.view.addSubview(iconView)
        vc.view.addSubview(titleLabel)
        vc.view.addSubview(subtitleLabel)

        NSLayoutConstraint.activate([
            iconView.centerXAnchor.constraint(equalTo: vc.view.centerXAnchor),
            iconView.centerYAnchor.constraint(equalTo: vc.view.centerYAnchor, constant: -80),
            iconView.widthAnchor.constraint(equalToConstant: 100),
            iconView.heightAnchor.constraint(equalToConstant: 100),

            titleLabel.topAnchor.constraint(equalTo: iconView.bottomAnchor, constant: 24),
            titleLabel.leadingAnchor.constraint(equalTo: vc.view.leadingAnchor, constant: 24),
            titleLabel.trailingAnchor.constraint(equalTo: vc.view.trailingAnchor, constant: -24),

            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            subtitleLabel.leadingAnchor.constraint(equalTo: vc.view.leadingAnchor, constant: 24),
            subtitleLabel.trailingAnchor.constraint(equalTo: vc.view.trailingAnchor, constant: -24),
        ])

        return vc
    }
}

// MARK: - Permission Page

private extension OnboardingViewController {
    func makePermissionPage() -> UIViewController {
        let vc = UIViewController()
        vc.view.backgroundColor = .systemBackground

        let titleLabel = UILabel()
        titleLabel.text = L("onboarding.permission.title")
        titleLabel.font = .systemFont(ofSize: 28, weight: .bold)
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        let step1 = makeStepView(
            number: "1",
            text: L("onboarding.permission.step1")
        )
        let step2 = makeStepView(
            number: "2",
            text: L("onboarding.permission.step2")
        )

        let stack = UIStackView(arrangedSubviews: [step1, step2])
        stack.axis = .vertical
        stack.spacing = 20
        stack.translatesAutoresizingMaskIntoConstraints = false

        // Success state UI (initially hidden)
        let sIconView = UIImageView()
        sIconView.image = UIImage(systemName: "checkmark.circle.fill")
        sIconView.tintColor = .systemGreen
        sIconView.contentMode = .scaleAspectFit
        sIconView.translatesAutoresizingMaskIntoConstraints = false
        sIconView.isHidden = true

        let sTitleLabel = UILabel()
        sTitleLabel.text = L("onboarding.permission.success.title")
        sTitleLabel.font = .systemFont(ofSize: 28, weight: .bold)
        sTitleLabel.textAlignment = .center
        sTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        sTitleLabel.isHidden = true

        let sDescLabel = UILabel()
        sDescLabel.text = L("onboarding.permission.success.description")
        sDescLabel.font = .systemFont(ofSize: 17)
        sDescLabel.textColor = .secondaryLabel
        sDescLabel.textAlignment = .center
        sDescLabel.numberOfLines = 0
        sDescLabel.translatesAutoresizingMaskIntoConstraints = false
        sDescLabel.isHidden = true

        vc.view.addSubview(titleLabel)
        vc.view.addSubview(stack)
        vc.view.addSubview(sIconView)
        vc.view.addSubview(sTitleLabel)
        vc.view.addSubview(sDescLabel)

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: vc.view.safeAreaLayoutGuide.topAnchor, constant: 60),
            titleLabel.leadingAnchor.constraint(equalTo: vc.view.leadingAnchor, constant: 24),
            titleLabel.trailingAnchor.constraint(equalTo: vc.view.trailingAnchor, constant: -24),

            stack.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 40),
            stack.leadingAnchor.constraint(equalTo: vc.view.leadingAnchor, constant: 32),
            stack.trailingAnchor.constraint(equalTo: vc.view.trailingAnchor, constant: -32),

            sIconView.centerXAnchor.constraint(equalTo: vc.view.centerXAnchor),
            sIconView.centerYAnchor.constraint(equalTo: vc.view.centerYAnchor, constant: -80),
            sIconView.widthAnchor.constraint(equalToConstant: 80),
            sIconView.heightAnchor.constraint(equalToConstant: 80),

            sTitleLabel.topAnchor.constraint(equalTo: sIconView.bottomAnchor, constant: 24),
            sTitleLabel.leadingAnchor.constraint(equalTo: vc.view.leadingAnchor, constant: 24),
            sTitleLabel.trailingAnchor.constraint(equalTo: vc.view.trailingAnchor, constant: -24),

            sDescLabel.topAnchor.constraint(equalTo: sTitleLabel.bottomAnchor, constant: 8),
            sDescLabel.leadingAnchor.constraint(equalTo: vc.view.leadingAnchor, constant: 24),
            sDescLabel.trailingAnchor.constraint(equalTo: vc.view.trailingAnchor, constant: -24),
        ])

        // Store references for success state transition
        permissionTitleLabel = titleLabel
        permissionStepStack = stack
        successIconView = sIconView
        successTitleLabel = sTitleLabel
        successDescriptionLabel = sDescLabel

        registerForegroundObserver()

        return vc
    }

    func makeStepView(number: String, text: String) -> UIView {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false

        let badge = UILabel()
        badge.text = number
        badge.font = .systemFont(ofSize: 16, weight: .bold)
        badge.textColor = .white
        badge.textAlignment = .center
        badge.backgroundColor = .systemBlue
        badge.layer.cornerRadius = 14
        badge.layer.masksToBounds = true
        badge.translatesAutoresizingMaskIntoConstraints = false

        let label = UILabel()
        label.text = text
        label.font = .systemFont(ofSize: 15)
        label.textColor = .label
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false

        container.addSubview(badge)
        container.addSubview(label)

        NSLayoutConstraint.activate([
            badge.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            badge.topAnchor.constraint(equalTo: container.topAnchor),
            badge.widthAnchor.constraint(equalToConstant: 28),
            badge.heightAnchor.constraint(equalToConstant: 28),

            label.leadingAnchor.constraint(equalTo: badge.trailingAnchor, constant: 12),
            label.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            label.topAnchor.constraint(equalTo: container.topAnchor),
            label.bottomAnchor.constraint(equalTo: container.bottomAnchor),
        ])

        return container
    }
}

// MARK: - Feature Page

private extension OnboardingViewController {
    func makeFeaturePage(icon: String, title: String, description: String) -> UIViewController {
        let vc = UIViewController()
        vc.view.backgroundColor = .systemBackground

        let iconView = UIImageView()
        iconView.image = UIImage(systemName: icon)
        iconView.tintColor = .systemBlue
        iconView.contentMode = .scaleAspectFit
        iconView.translatesAutoresizingMaskIntoConstraints = false

        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .systemFont(ofSize: 28, weight: .bold)
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        let descLabel = UILabel()
        descLabel.text = description
        descLabel.font = .systemFont(ofSize: 16)
        descLabel.textColor = .secondaryLabel
        descLabel.textAlignment = .center
        descLabel.numberOfLines = 0
        descLabel.translatesAutoresizingMaskIntoConstraints = false

        vc.view.addSubview(iconView)
        vc.view.addSubview(titleLabel)
        vc.view.addSubview(descLabel)

        NSLayoutConstraint.activate([
            iconView.centerXAnchor.constraint(equalTo: vc.view.centerXAnchor),
            iconView.centerYAnchor.constraint(equalTo: vc.view.centerYAnchor, constant: -80),
            iconView.widthAnchor.constraint(equalToConstant: 80),
            iconView.heightAnchor.constraint(equalToConstant: 80),

            titleLabel.topAnchor.constraint(equalTo: iconView.bottomAnchor, constant: 24),
            titleLabel.leadingAnchor.constraint(equalTo: vc.view.leadingAnchor, constant: 24),
            titleLabel.trailingAnchor.constraint(equalTo: vc.view.trailingAnchor, constant: -24),

            descLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 12),
            descLabel.leadingAnchor.constraint(equalTo: vc.view.leadingAnchor, constant: 24),
            descLabel.trailingAnchor.constraint(equalTo: vc.view.trailingAnchor, constant: -24),
        ])

        return vc
    }
}

// MARK: - Subscription Page

private extension OnboardingViewController {
    func makeSubscriptionPage() -> UIViewController {
        let vc = UIViewController()
        vc.view.backgroundColor = .systemBackground

        // 상단 닫기 / 복원 버튼
        let closeButton = UIButton(type: .system)
        closeButton.setImage(UIImage(systemName: "xmark"), for: .normal)
        closeButton.tintColor = .label
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        closeButton.addTarget(self, action: #selector(subscriptionCloseTapped), for: .touchUpInside)

        let restoreButton = UIButton(type: .system)
        restoreButton.setTitle("복원", for: .normal)
        restoreButton.titleLabel?.font = .systemFont(ofSize: 15)
        restoreButton.translatesAutoresizingMaskIntoConstraints = false

        // 타이틀
        let titleLabel = UILabel()
        titleLabel.text = "Pro로 업그레이드"
        titleLabel.font = .systemFont(ofSize: 28, weight: .bold)
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        // 혜택 목록
        let benefits = [
            ("checkmark.circle.fill", "무제한 번역"),
            ("sparkles", "고품질 번역"),
            ("nosign", "광고 없음"),
            ("paintpalette.fill", "프리미엄 테마"),
        ]

        let benefitStack = UIStackView()
        benefitStack.axis = .vertical
        benefitStack.spacing = 12
        benefitStack.translatesAutoresizingMaskIntoConstraints = false

        for (icon, text) in benefits {
            let row = makeBenefitRow(icon: icon, text: text)
            benefitStack.addArrangedSubview(row)
        }

        // 무료 체험 배지
        let trialBadge = UILabel()
        trialBadge.text = "  7일 무료 체험  "
        trialBadge.font = .systemFont(ofSize: 14, weight: .semibold)
        trialBadge.textColor = .systemBlue
        trialBadge.backgroundColor = .systemBlue.withAlphaComponent(0.12)
        trialBadge.layer.cornerRadius = 12
        trialBadge.layer.masksToBounds = true
        trialBadge.textAlignment = .center
        trialBadge.translatesAutoresizingMaskIntoConstraints = false

        // 구독 카드
        let monthlyCard = makeSubscriptionCard(price: "$9.99/월", subtitle: "월간 구독", isBest: false)
        let yearlyCard = makeSubscriptionCard(price: "$99.99/년", subtitle: "연간 구독", isBest: true)

        let cardStack = UIStackView(arrangedSubviews: [monthlyCard, yearlyCard])
        cardStack.axis = .horizontal
        cardStack.spacing = 12
        cardStack.distribution = .fillEqually
        cardStack.translatesAutoresizingMaskIntoConstraints = false

        // CTA 버튼
        let startButton = UIButton(type: .system)
        startButton.setTitle("무료 체험 시작", for: .normal)
        startButton.titleLabel?.font = .systemFont(ofSize: 18, weight: .semibold)
        startButton.backgroundColor = .systemBlue
        startButton.setTitleColor(.white, for: .normal)
        startButton.layer.cornerRadius = 14
        startButton.translatesAutoresizingMaskIntoConstraints = false
        startButton.addTarget(self, action: #selector(subscriptionStartTapped), for: .touchUpInside)

        vc.view.addSubview(closeButton)
        vc.view.addSubview(restoreButton)
        vc.view.addSubview(titleLabel)
        vc.view.addSubview(benefitStack)
        vc.view.addSubview(trialBadge)
        vc.view.addSubview(cardStack)
        vc.view.addSubview(startButton)

        NSLayoutConstraint.activate([
            closeButton.topAnchor.constraint(equalTo: vc.view.safeAreaLayoutGuide.topAnchor, constant: 12),
            closeButton.leadingAnchor.constraint(equalTo: vc.view.leadingAnchor, constant: 20),
            closeButton.widthAnchor.constraint(equalToConstant: 32),
            closeButton.heightAnchor.constraint(equalToConstant: 32),

            restoreButton.centerYAnchor.constraint(equalTo: closeButton.centerYAnchor),
            restoreButton.trailingAnchor.constraint(equalTo: vc.view.trailingAnchor, constant: -20),

            titleLabel.topAnchor.constraint(equalTo: closeButton.bottomAnchor, constant: 24),
            titleLabel.leadingAnchor.constraint(equalTo: vc.view.leadingAnchor, constant: 24),
            titleLabel.trailingAnchor.constraint(equalTo: vc.view.trailingAnchor, constant: -24),

            benefitStack.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 28),
            benefitStack.leadingAnchor.constraint(equalTo: vc.view.leadingAnchor, constant: 40),
            benefitStack.trailingAnchor.constraint(equalTo: vc.view.trailingAnchor, constant: -40),

            trialBadge.topAnchor.constraint(equalTo: benefitStack.bottomAnchor, constant: 24),
            trialBadge.centerXAnchor.constraint(equalTo: vc.view.centerXAnchor),
            trialBadge.heightAnchor.constraint(equalToConstant: 28),

            cardStack.topAnchor.constraint(equalTo: trialBadge.bottomAnchor, constant: 20),
            cardStack.leadingAnchor.constraint(equalTo: vc.view.leadingAnchor, constant: 24),
            cardStack.trailingAnchor.constraint(equalTo: vc.view.trailingAnchor, constant: -24),
            cardStack.heightAnchor.constraint(equalToConstant: 100),

            startButton.leadingAnchor.constraint(equalTo: vc.view.leadingAnchor, constant: 24),
            startButton.trailingAnchor.constraint(equalTo: vc.view.trailingAnchor, constant: -24),
            startButton.bottomAnchor.constraint(equalTo: vc.view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            startButton.heightAnchor.constraint(equalToConstant: 52),
        ])

        return vc
    }

    func makeBenefitRow(icon: String, text: String) -> UIView {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false

        let iconView = UIImageView()
        iconView.image = UIImage(systemName: icon)
        iconView.tintColor = .systemBlue
        iconView.contentMode = .scaleAspectFit
        iconView.translatesAutoresizingMaskIntoConstraints = false

        let label = UILabel()
        label.text = text
        label.font = .systemFont(ofSize: 16)
        label.translatesAutoresizingMaskIntoConstraints = false

        container.addSubview(iconView)
        container.addSubview(label)

        NSLayoutConstraint.activate([
            iconView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            iconView.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 24),
            iconView.heightAnchor.constraint(equalToConstant: 24),

            label.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 12),
            label.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            label.centerYAnchor.constraint(equalTo: container.centerYAnchor),

            container.heightAnchor.constraint(equalToConstant: 28),
        ])

        return container
    }

    func makeSubscriptionCard(price: String, subtitle: String, isBest: Bool) -> UIView {
        let card = UIView()
        card.backgroundColor = .secondarySystemBackground
        card.layer.cornerRadius = 12
        card.layer.borderWidth = isBest ? 2 : 1
        card.layer.borderColor = isBest ? UIColor.systemBlue.cgColor : UIColor.systemGray4.cgColor
        card.translatesAutoresizingMaskIntoConstraints = false

        let priceLabel = UILabel()
        priceLabel.text = price
        priceLabel.font = .systemFont(ofSize: 18, weight: .bold)
        priceLabel.textAlignment = .center
        priceLabel.translatesAutoresizingMaskIntoConstraints = false

        let subtitleLabel = UILabel()
        subtitleLabel.text = isBest ? "\(subtitle) (BEST)" : subtitle
        subtitleLabel.font = .systemFont(ofSize: 13)
        subtitleLabel.textColor = .secondaryLabel
        subtitleLabel.textAlignment = .center
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false

        card.addSubview(priceLabel)
        card.addSubview(subtitleLabel)

        NSLayoutConstraint.activate([
            priceLabel.centerXAnchor.constraint(equalTo: card.centerXAnchor),
            priceLabel.centerYAnchor.constraint(equalTo: card.centerYAnchor, constant: -10),

            subtitleLabel.topAnchor.constraint(equalTo: priceLabel.bottomAnchor, constant: 4),
            subtitleLabel.centerXAnchor.constraint(equalTo: card.centerXAnchor),
        ])

        return card
    }

    @objc func subscriptionCloseTapped() {
        completeOnboarding()
    }

    @objc func subscriptionStartTapped() {
        completeOnboarding()
    }
}
