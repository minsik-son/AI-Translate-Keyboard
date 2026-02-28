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
        pc.numberOfPages = 5
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

    // Setup page state
    private var hasVisitedSettings = false

    // Verification page state
    private var pollingTimer: Timer?
    private var timeoutTimer: Timer?
    private var verificationStatusLabel: UILabel!
    private var verificationPassed = false

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
            makeWelcomePage(),           // 0
            makeSetupPage(),             // 1
            makeVerificationPage(),      // 2
            makeFeaturesPage(),          // 3
            makeSubscriptionPage()       // 4
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
        let savedIndex = min(defaults.integer(forKey: "onboarding_current_page"), pages.count - 1)

        if savedIndex > 0, savedIndex < pages.count {
            currentIndex = savedIndex
            pageViewController.setViewControllers([pages[savedIndex]], direction: .forward, animated: false)
            pageControl.currentPage = savedIndex
        }

        hasVisitedSettings = defaults.bool(forKey: "onboarding_returned_from_settings")
        updateCTAForCurrentPage()
    }

    // MARK: - Navigation

    @objc private func ctaTapped() {
        switch currentIndex {
        case 1:
            if !hasVisitedSettings {
                hasVisitedSettings = true
                let defaults = UserDefaults(suiteName: AppConstants.appGroupIdentifier) ?? UserDefaults.standard
                defaults.set(true, forKey: "onboarding_returned_from_settings")
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
                return
            } else {
                goToPage(2)
                return
            }
        case 2:
            if verificationPassed {
                goToPage(3)
            }
            return
        case 4:
            completeOnboarding()
            return
        default:
            goToPage(currentIndex + 1)
        }
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

        if index == 2 {
            startPolling()
        }
    }

    private func updateCTAForCurrentPage() {
        let isSubscriptionPage = currentIndex == 4
        ctaButton.isHidden = isSubscriptionPage
        pageControl.isHidden = isSubscriptionPage

        switch currentIndex {
        case 0:
            ctaButton.setTitle(L("onboarding.cta.start"), for: .normal)
            ctaButton.isEnabled = true
            ctaButton.backgroundColor = .systemBlue
        case 1:
            ctaButton.setTitle(hasVisitedSettings ? L("onboarding.cta.done_settings") : L("onboarding.cta.go_settings"), for: .normal)
            ctaButton.isEnabled = true
            ctaButton.backgroundColor = .systemBlue
        case 2:
            ctaButton.setTitle(L("onboarding.cta.next"), for: .normal)
            ctaButton.isEnabled = verificationPassed
            ctaButton.backgroundColor = verificationPassed ? .systemBlue : .systemGray4
        case 3:
            ctaButton.setTitle(L("onboarding.cta.next"), for: .normal)
            ctaButton.isEnabled = true
            ctaButton.backgroundColor = .systemBlue
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

    // MARK: - Keyboard Detection

    private func registerForegroundObserver() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidBecomeActive),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
    }

    @objc private func appDidBecomeActive() {
        guard currentIndex == 1, hasVisitedSettings else { return }
        updateCTAForCurrentPage()
    }

    // MARK: - Verification Polling

    private func startPolling() {
        stopPolling()
        verificationPassed = false
        updateCTAForCurrentPage()

        AppGroupManager.shared.removeObject(forKey: AppConstants.UserDefaultsKeys.keyboardFullAccessEnabled)

        verificationStatusLabel?.text = L("onboarding.verify.instruction")
        verificationStatusLabel?.textColor = .secondaryLabel

        pollingTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            self?.checkKeyboardStatus()
        }

        timeoutTimer = Timer.scheduledTimer(withTimeInterval: 15.0, repeats: false) { [weak self] _ in
            self?.handleTimeout()
        }
    }

    private func stopPolling() {
        pollingTimer?.invalidate()
        pollingTimer = nil
        timeoutTimer?.invalidate()
        timeoutTimer = nil
    }

    private func checkKeyboardStatus() {
        let defaults = UserDefaults(suiteName: AppConstants.appGroupIdentifier)
        guard let value = defaults?.object(forKey: AppConstants.UserDefaultsKeys.keyboardFullAccessEnabled) as? Bool else {
            return
        }

        if value {
            showVerificationSuccess()
        } else {
            showFullAccessRequired()
        }
    }

    private func showVerificationSuccess() {
        stopPolling()
        verificationPassed = true
        verificationStatusLabel?.text = L("onboarding.verify.success")
        verificationStatusLabel?.textColor = .systemGreen
        updateCTAForCurrentPage()
    }

    private func showFullAccessRequired() {
        stopPolling()

        guard let page = pages[safe: 2] else { return }

        // Remove existing extra views
        for subview in page.view.subviews where subview.tag == 901 || subview.tag == 902 {
            subview.removeFromSuperview()
        }

        verificationStatusLabel?.text = L("onboarding.verify.no_full_access")
        verificationStatusLabel?.textColor = .systemOrange

        let descLabel = UILabel()
        descLabel.text = L("onboarding.verify.full_access_desc")
        descLabel.font = .systemFont(ofSize: 14)
        descLabel.textColor = .secondaryLabel
        descLabel.textAlignment = .center
        descLabel.numberOfLines = 0
        descLabel.translatesAutoresizingMaskIntoConstraints = false
        descLabel.tag = 901

        let settingsButton = UIButton(type: .system)
        settingsButton.setTitle(L("onboarding.verify.go_settings"), for: .normal)
        settingsButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        settingsButton.translatesAutoresizingMaskIntoConstraints = false
        settingsButton.tag = 902
        settingsButton.addTarget(self, action: #selector(openSettingsFromVerification), for: .touchUpInside)

        page.view.addSubview(descLabel)
        page.view.addSubview(settingsButton)

        NSLayoutConstraint.activate([
            descLabel.topAnchor.constraint(equalTo: verificationStatusLabel.bottomAnchor, constant: 8),
            descLabel.leadingAnchor.constraint(equalTo: page.view.leadingAnchor, constant: 32),
            descLabel.trailingAnchor.constraint(equalTo: page.view.trailingAnchor, constant: -32),

            settingsButton.topAnchor.constraint(equalTo: descLabel.bottomAnchor, constant: 16),
            settingsButton.centerXAnchor.constraint(equalTo: page.view.centerXAnchor),
        ])
    }

    private func handleTimeout() {
        stopPolling()

        guard let page = pages[safe: 2] else { return }

        // Remove existing extra views
        for subview in page.view.subviews where subview.tag == 901 || subview.tag == 902 {
            subview.removeFromSuperview()
        }

        verificationStatusLabel?.text = L("onboarding.verify.timeout")
        verificationStatusLabel?.textColor = .systemRed

        let descLabel = UILabel()
        descLabel.text = L("onboarding.verify.timeout_desc")
        descLabel.font = .systemFont(ofSize: 14)
        descLabel.textColor = .secondaryLabel
        descLabel.textAlignment = .center
        descLabel.numberOfLines = 0
        descLabel.translatesAutoresizingMaskIntoConstraints = false
        descLabel.tag = 901

        let retryButton = UIButton(type: .system)
        retryButton.setTitle(L("onboarding.verify.retry"), for: .normal)
        retryButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        retryButton.translatesAutoresizingMaskIntoConstraints = false
        retryButton.tag = 902
        retryButton.addTarget(self, action: #selector(retryFromSetup), for: .touchUpInside)

        page.view.addSubview(descLabel)
        page.view.addSubview(retryButton)

        NSLayoutConstraint.activate([
            descLabel.topAnchor.constraint(equalTo: verificationStatusLabel.bottomAnchor, constant: 8),
            descLabel.leadingAnchor.constraint(equalTo: page.view.leadingAnchor, constant: 32),
            descLabel.trailingAnchor.constraint(equalTo: page.view.trailingAnchor, constant: -32),

            retryButton.topAnchor.constraint(equalTo: descLabel.bottomAnchor, constant: 16),
            retryButton.centerXAnchor.constraint(equalTo: page.view.centerXAnchor),
        ])
    }

    @objc private func openSettingsFromVerification() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }

    @objc private func retryFromSetup() {
        // Clean up extra views from verification page
        if let page = pages[safe: 2] {
            for subview in page.view.subviews where subview.tag == 901 || subview.tag == 902 {
                subview.removeFromSuperview()
            }
        }
        goToPage(1)
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
        subtitleLabel.text = L("onboarding.welcome.subtitle")
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

// MARK: - Setup Page (Keyboard + Full Access + Trust)

private extension OnboardingViewController {
    func makeSetupPage() -> UIViewController {
        let vc = UIViewController()
        vc.view.backgroundColor = .systemBackground

        // Title
        let titleLabel = UILabel()
        titleLabel.text = L("onboarding.permission.title")
        titleLabel.font = .systemFont(ofSize: 28, weight: .bold)
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        // Trust header with lock icon
        let trustHeaderStack = UIStackView()
        trustHeaderStack.axis = .horizontal
        trustHeaderStack.spacing = 6
        trustHeaderStack.alignment = .center
        trustHeaderStack.translatesAutoresizingMaskIntoConstraints = false

        let lockIcon = UIImageView()
        lockIcon.image = UIImage(systemName: "lock.shield.fill")
        lockIcon.tintColor = .secondaryLabel
        lockIcon.contentMode = .scaleAspectFit
        lockIcon.translatesAutoresizingMaskIntoConstraints = false

        let trustHeaderLabel = UILabel()
        trustHeaderLabel.text = L("onboarding.trust.title")
        trustHeaderLabel.font = .systemFont(ofSize: 15, weight: .semibold)
        trustHeaderLabel.textColor = .secondaryLabel
        trustHeaderLabel.translatesAutoresizingMaskIntoConstraints = false

        trustHeaderStack.addArrangedSubview(lockIcon)
        trustHeaderStack.addArrangedSubview(trustHeaderLabel)

        NSLayoutConstraint.activate([
            lockIcon.widthAnchor.constraint(equalToConstant: 18),
            lockIcon.heightAnchor.constraint(equalToConstant: 18),
        ])

        // Trust items
        let trustItems = [
            L("onboarding.trust.no_passwords"),
            L("onboarding.trust.no_storage"),
            L("onboarding.trust.ai_only"),
        ]

        let trustStack = UIStackView()
        trustStack.axis = .vertical
        trustStack.spacing = 12
        trustStack.translatesAutoresizingMaskIntoConstraints = false

        for item in trustItems {
            let row = makeTrustRow(text: item)
            trustStack.addArrangedSubview(row)
        }

        // Divider
        let divider = UIView()
        divider.backgroundColor = .separator
        divider.translatesAutoresizingMaskIntoConstraints = false

        // Steps
        let step1View = makeSetupStepView(number: "1", text: L("onboarding.permission.step1"))
        let step2View = makeSetupStepView(number: "2", text: L("onboarding.permission.step2"))

        let stepStack = UIStackView(arrangedSubviews: [step1View, step2View])
        stepStack.axis = .vertical
        stepStack.spacing = 20
        stepStack.translatesAutoresizingMaskIntoConstraints = false

        vc.view.addSubview(titleLabel)
        vc.view.addSubview(trustHeaderStack)
        vc.view.addSubview(trustStack)
        vc.view.addSubview(divider)
        vc.view.addSubview(stepStack)

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: vc.view.safeAreaLayoutGuide.topAnchor, constant: 60),
            titleLabel.leadingAnchor.constraint(equalTo: vc.view.leadingAnchor, constant: 24),
            titleLabel.trailingAnchor.constraint(equalTo: vc.view.trailingAnchor, constant: -24),

            trustHeaderStack.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 32),
            trustHeaderStack.leadingAnchor.constraint(equalTo: vc.view.leadingAnchor, constant: 32),

            trustStack.topAnchor.constraint(equalTo: trustHeaderStack.bottomAnchor, constant: 16),
            trustStack.leadingAnchor.constraint(equalTo: vc.view.leadingAnchor, constant: 32),
            trustStack.trailingAnchor.constraint(equalTo: vc.view.trailingAnchor, constant: -32),

            divider.topAnchor.constraint(equalTo: trustStack.bottomAnchor, constant: 28),
            divider.leadingAnchor.constraint(equalTo: vc.view.leadingAnchor, constant: 32),
            divider.trailingAnchor.constraint(equalTo: vc.view.trailingAnchor, constant: -32),
            divider.heightAnchor.constraint(equalToConstant: 0.5),

            stepStack.topAnchor.constraint(equalTo: divider.bottomAnchor, constant: 28),
            stepStack.leadingAnchor.constraint(equalTo: vc.view.leadingAnchor, constant: 32),
            stepStack.trailingAnchor.constraint(equalTo: vc.view.trailingAnchor, constant: -32),
        ])

        registerForegroundObserver()
        return vc
    }

    func makeSetupStepView(number: String, text: String) -> UIView {
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

    func makeTrustRow(text: String) -> UIView {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false

        let checkmark = UIImageView()
        checkmark.image = UIImage(systemName: "checkmark.circle.fill")
        checkmark.tintColor = .systemGreen
        checkmark.contentMode = .scaleAspectFit
        checkmark.translatesAutoresizingMaskIntoConstraints = false

        let label = UILabel()
        label.text = text
        label.font = .systemFont(ofSize: 15)
        label.textColor = .label
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false

        container.addSubview(checkmark)
        container.addSubview(label)

        NSLayoutConstraint.activate([
            checkmark.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            checkmark.topAnchor.constraint(equalTo: container.topAnchor, constant: 2),
            checkmark.widthAnchor.constraint(equalToConstant: 24),
            checkmark.heightAnchor.constraint(equalToConstant: 24),

            label.leadingAnchor.constraint(equalTo: checkmark.trailingAnchor, constant: 12),
            label.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            label.topAnchor.constraint(equalTo: container.topAnchor),
            label.bottomAnchor.constraint(equalTo: container.bottomAnchor),
        ])

        return container
    }
}

// MARK: - Verification Page

private extension OnboardingViewController {
    func makeVerificationPage() -> UIViewController {
        let vc = UIViewController()
        vc.view.backgroundColor = .systemBackground

        let titleLabel = UILabel()
        titleLabel.text = L("onboarding.verify.title")
        titleLabel.font = .systemFont(ofSize: 28, weight: .bold)
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        let instructionLabel = UILabel()
        instructionLabel.text = L("onboarding.verify.instruction")
        instructionLabel.font = .systemFont(ofSize: 16)
        instructionLabel.textColor = .secondaryLabel
        instructionLabel.textAlignment = .center
        instructionLabel.numberOfLines = 0
        instructionLabel.translatesAutoresizingMaskIntoConstraints = false

        let textField = UITextField()
        textField.placeholder = L("onboarding.verify.placeholder")
        textField.borderStyle = .roundedRect
        textField.backgroundColor = .secondarySystemBackground
        textField.font = .systemFont(ofSize: 17)
        textField.textAlignment = .center
        textField.autocorrectionType = .no
        textField.autocapitalizationType = .none
        textField.translatesAutoresizingMaskIntoConstraints = false

        let statusLabel = UILabel()
        statusLabel.text = L("onboarding.verify.instruction")
        statusLabel.font = .systemFont(ofSize: 15)
        statusLabel.textColor = .secondaryLabel
        statusLabel.textAlignment = .center
        statusLabel.numberOfLines = 0
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        self.verificationStatusLabel = statusLabel

        let tapGesture = UITapGestureRecognizer(target: textField, action: #selector(UIResponder.resignFirstResponder))
        tapGesture.cancelsTouchesInView = false
        vc.view.addGestureRecognizer(tapGesture)

        vc.view.addSubview(titleLabel)
        vc.view.addSubview(instructionLabel)
        vc.view.addSubview(textField)
        vc.view.addSubview(statusLabel)

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: vc.view.safeAreaLayoutGuide.topAnchor, constant: 60),
            titleLabel.leadingAnchor.constraint(equalTo: vc.view.leadingAnchor, constant: 24),
            titleLabel.trailingAnchor.constraint(equalTo: vc.view.trailingAnchor, constant: -24),

            instructionLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 16),
            instructionLabel.leadingAnchor.constraint(equalTo: vc.view.leadingAnchor, constant: 32),
            instructionLabel.trailingAnchor.constraint(equalTo: vc.view.trailingAnchor, constant: -32),

            textField.topAnchor.constraint(equalTo: instructionLabel.bottomAnchor, constant: 32),
            textField.leadingAnchor.constraint(equalTo: vc.view.leadingAnchor, constant: 32),
            textField.trailingAnchor.constraint(equalTo: vc.view.trailingAnchor, constant: -32),
            textField.heightAnchor.constraint(equalToConstant: 48),

            statusLabel.topAnchor.constraint(equalTo: textField.bottomAnchor, constant: 24),
            statusLabel.leadingAnchor.constraint(equalTo: vc.view.leadingAnchor, constant: 32),
            statusLabel.trailingAnchor.constraint(equalTo: vc.view.trailingAnchor, constant: -32),
        ])

        return vc
    }
}

// MARK: - Features Page (Consolidated)

private extension OnboardingViewController {
    func makeFeaturesPage() -> UIViewController {
        let vc = UIViewController()
        vc.view.backgroundColor = .systemBackground

        let titleLabel = UILabel()
        titleLabel.text = L("onboarding.features.title")
        titleLabel.font = .systemFont(ofSize: 28, weight: .bold)
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        let features: [(icon: String, title: String, description: String)] = [
            ("textformat", L("onboarding.features.translate"), L("onboarding.features.translate_desc")),
            ("pencil.and.outline", L("onboarding.features.correct"), L("onboarding.features.correct_desc")),
            ("doc.on.clipboard", L("onboarding.features.clipboard"), L("onboarding.features.clipboard_desc")),
        ]

        let featureStack = UIStackView()
        featureStack.axis = .vertical
        featureStack.spacing = 28
        featureStack.translatesAutoresizingMaskIntoConstraints = false

        for feature in features {
            let row = makeFeatureRow(icon: feature.icon, title: feature.title, description: feature.description)
            featureStack.addArrangedSubview(row)
        }

        vc.view.addSubview(titleLabel)
        vc.view.addSubview(featureStack)

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: vc.view.safeAreaLayoutGuide.topAnchor, constant: 60),
            titleLabel.leadingAnchor.constraint(equalTo: vc.view.leadingAnchor, constant: 24),
            titleLabel.trailingAnchor.constraint(equalTo: vc.view.trailingAnchor, constant: -24),

            featureStack.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 40),
            featureStack.leadingAnchor.constraint(equalTo: vc.view.leadingAnchor, constant: 32),
            featureStack.trailingAnchor.constraint(equalTo: vc.view.trailingAnchor, constant: -32),
        ])

        return vc
    }

    func makeFeatureRow(icon: String, title: String, description: String) -> UIView {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false

        let iconView = UIImageView()
        iconView.image = UIImage(systemName: icon)
        iconView.tintColor = .systemBlue
        iconView.contentMode = .scaleAspectFit
        iconView.translatesAutoresizingMaskIntoConstraints = false

        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .systemFont(ofSize: 17, weight: .semibold)
        titleLabel.textColor = .label
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        let descLabel = UILabel()
        descLabel.text = description
        descLabel.font = .systemFont(ofSize: 14)
        descLabel.textColor = .secondaryLabel
        descLabel.numberOfLines = 0
        descLabel.translatesAutoresizingMaskIntoConstraints = false

        container.addSubview(iconView)
        container.addSubview(titleLabel)
        container.addSubview(descLabel)

        NSLayoutConstraint.activate([
            iconView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            iconView.topAnchor.constraint(equalTo: container.topAnchor, constant: 2),
            iconView.widthAnchor.constraint(equalToConstant: 32),
            iconView.heightAnchor.constraint(equalToConstant: 32),

            titleLabel.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            titleLabel.topAnchor.constraint(equalTo: container.topAnchor),

            descLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            descLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            descLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            descLabel.bottomAnchor.constraint(equalTo: container.bottomAnchor),
        ])

        return container
    }
}

// MARK: - Subscription Page

private extension OnboardingViewController {
    func makeSubscriptionPage() -> UIViewController {
        let vc = UIViewController()
        vc.view.backgroundColor = .systemBackground

        let closeButton = UIButton(type: .system)
        closeButton.setImage(UIImage(systemName: "xmark"), for: .normal)
        closeButton.tintColor = .label
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        closeButton.addTarget(self, action: #selector(subscriptionCloseTapped), for: .touchUpInside)

        let restoreButton = UIButton(type: .system)
        restoreButton.setTitle(L("onboarding.subscription.restore"), for: .normal)
        restoreButton.titleLabel?.font = .systemFont(ofSize: 15)
        restoreButton.translatesAutoresizingMaskIntoConstraints = false

        let titleLabel = UILabel()
        titleLabel.text = L("onboarding.subscription.title")
        titleLabel.font = .systemFont(ofSize: 28, weight: .bold)
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        let benefits = [
            ("checkmark.circle.fill", L("onboarding.subscription.benefit.unlimited")),
            ("sparkles", L("onboarding.subscription.benefit.quality")),
            ("nosign", L("onboarding.subscription.benefit.no_ads")),
            ("paintpalette.fill", L("onboarding.subscription.benefit.themes")),
        ]

        let benefitStack = UIStackView()
        benefitStack.axis = .vertical
        benefitStack.spacing = 12
        benefitStack.translatesAutoresizingMaskIntoConstraints = false

        for (icon, text) in benefits {
            let row = makeBenefitRow(icon: icon, text: text)
            benefitStack.addArrangedSubview(row)
        }

        let trialBadge = UILabel()
        trialBadge.text = L("onboarding.subscription.trial_badge")
        trialBadge.font = .systemFont(ofSize: 14, weight: .semibold)
        trialBadge.textColor = .systemBlue
        trialBadge.backgroundColor = .systemBlue.withAlphaComponent(0.12)
        trialBadge.layer.cornerRadius = 12
        trialBadge.layer.masksToBounds = true
        trialBadge.textAlignment = .center
        trialBadge.translatesAutoresizingMaskIntoConstraints = false

        let monthlyCard = makeSubscriptionCard(price: "$9.99/월", subtitle: L("onboarding.subscription.monthly"), isBest: false)
        let yearlyCard = makeSubscriptionCard(price: "$99.99/년", subtitle: L("onboarding.subscription.yearly"), isBest: true)

        let cardStack = UIStackView(arrangedSubviews: [monthlyCard, yearlyCard])
        cardStack.axis = .horizontal
        cardStack.spacing = 12
        cardStack.distribution = .fillEqually
        cardStack.translatesAutoresizingMaskIntoConstraints = false

        let startButton = UIButton(type: .system)
        startButton.setTitle(L("onboarding.subscription.start_trial"), for: .normal)
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
        subtitleLabel.text = isBest ? "\(subtitle) \(L("onboarding.subscription.best_label"))" : subtitle
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

// MARK: - Collection Safe Subscript

private extension Collection {
    subscript(safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}
