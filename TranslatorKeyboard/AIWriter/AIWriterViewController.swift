import UIKit

class AIWriterViewController: UIViewController {

    private var selectedTone = "casual"

    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()
    private let inputTextView = UITextView()
    private let generateButton = UIButton(type: .system)
    private let resultCard = UIView()
    private let resultLabel = UILabel()
    private let loadingIndicator = UIActivityIndicatorView(style: .medium)
    private let copyButton = UIButton(type: .system)
    private let regenerateButton = UIButton(type: .system)
    private var lastPrompt = ""

    // Part A: 수평 스크롤 톤 pill
    private lazy var toneScrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.showsHorizontalScrollIndicator = false
        sv.showsVerticalScrollIndicator = false
        sv.translatesAutoresizingMaskIntoConstraints = false
        return sv
    }()

    private lazy var toneStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 8
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

    // Part E: 남은 횟수 배지
    private lazy var remainingBadge: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 11, weight: .bold)
        label.textColor = .white
        label.backgroundColor = UIColor.white.withAlphaComponent(0.3)
        label.textAlignment = .center
        label.layer.cornerRadius = 10
        label.clipsToBounds = true
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = AppColors.bg
        navigationItem.title = L("ai_writer.title")
        setupNavigation()
        setupUI()
        updateGenerateButton()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateGenerateButton()
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

    private func setupUI() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.keyboardDismissMode = .interactive
        view.addSubview(scrollView)
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])

        contentStack.axis = .vertical
        contentStack.spacing = 16
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentStack)
        NSLayoutConstraint.activate([
            contentStack.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 8),
            contentStack.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 20),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -20),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -32),
            contentStack.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -40),
        ])

        // Subtitle
        let subtitle = UILabel()
        subtitle.text = L("ai_writer.subtitle")
        subtitle.font = .systemFont(ofSize: 14)
        subtitle.textColor = AppColors.textSub
        contentStack.addArrangedSubview(subtitle)

        // Tone pills (수평 스크롤)
        setupTonePills()
        contentStack.addArrangedSubview(toneScrollView)
        contentStack.setCustomSpacing(20, after: toneScrollView)

        // Input area
        setupInputArea()

        // Result card (hidden initially)
        setupResultCard()

        // Tap outside to dismiss keyboard
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tapGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(tapGesture)
    }

    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }

    private func setupTonePills() {
        toneScrollView.addSubview(toneStack)
        NSLayoutConstraint.activate([
            toneStack.leadingAnchor.constraint(equalTo: toneScrollView.contentLayoutGuide.leadingAnchor),
            toneStack.trailingAnchor.constraint(equalTo: toneScrollView.contentLayoutGuide.trailingAnchor),
            toneStack.topAnchor.constraint(equalTo: toneScrollView.contentLayoutGuide.topAnchor),
            toneStack.bottomAnchor.constraint(equalTo: toneScrollView.contentLayoutGuide.bottomAnchor),
            toneStack.heightAnchor.constraint(equalTo: toneScrollView.frameLayoutGuide.heightAnchor),
        ])

        let tones: [(String, String, String)] = [
            ("casual", "\u{1F4AC}", L("tone.casual")),
            ("formal", "\u{1F3A9}", L("tone.formal")),
            ("polished", "\u{2728}", L("tone.polished")),
            ("friendly", "\u{1F60A}", L("tone.friendly")),
        ]

        for (i, tone) in tones.enumerated() {
            let btn = UIButton(type: .system)
            btn.setTitle("\(tone.1) \(tone.2)", for: .normal)
            btn.titleLabel?.font = .systemFont(ofSize: 13, weight: .medium)
            btn.layer.cornerRadius = 16
            btn.contentEdgeInsets = UIEdgeInsets(top: 8, left: 14, bottom: 8, right: 14)
            btn.tag = i
            btn.addTarget(self, action: #selector(toneTapped(_:)), for: .touchUpInside)
            toneStack.addArrangedSubview(btn)
        }

        updateToneAppearance()
    }

    private func setupInputArea() {
        let inputContainer = UIView()
        inputContainer.backgroundColor = AppColors.card
        inputContainer.layer.cornerRadius = 14
        inputContainer.layer.borderWidth = 1
        inputContainer.layer.borderColor = AppColors.border.cgColor

        inputTextView.backgroundColor = .clear
        inputTextView.font = .systemFont(ofSize: 15)
        inputTextView.textColor = AppColors.text
        inputTextView.tintColor = AppColors.accent
        inputTextView.delegate = self
        inputTextView.translatesAutoresizingMaskIntoConstraints = false

        generateButton.setTitle(L("ai_writer.generate"), for: .normal)
        generateButton.titleLabel?.font = .systemFont(ofSize: 14, weight: .semibold)
        generateButton.backgroundColor = AppColors.accent
        generateButton.setTitleColor(.white, for: .normal)
        generateButton.layer.cornerRadius = 10
        generateButton.translatesAutoresizingMaskIntoConstraints = false
        generateButton.addTarget(self, action: #selector(generateTapped), for: .touchUpInside)

        // 남은 횟수 배지
        generateButton.addSubview(remainingBadge)
        NSLayoutConstraint.activate([
            remainingBadge.trailingAnchor.constraint(equalTo: generateButton.trailingAnchor, constant: -12),
            remainingBadge.centerYAnchor.constraint(equalTo: generateButton.centerYAnchor),
            remainingBadge.widthAnchor.constraint(greaterThanOrEqualToConstant: 20),
            remainingBadge.heightAnchor.constraint(equalToConstant: 20),
        ])
        remainingBadge.isHidden = true

        inputContainer.addSubview(inputTextView)
        inputContainer.addSubview(generateButton)
        inputContainer.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            inputTextView.topAnchor.constraint(equalTo: inputContainer.topAnchor, constant: 12),
            inputTextView.leadingAnchor.constraint(equalTo: inputContainer.leadingAnchor, constant: 12),
            inputTextView.trailingAnchor.constraint(equalTo: inputContainer.trailingAnchor, constant: -12),
            inputTextView.heightAnchor.constraint(greaterThanOrEqualToConstant: 100),

            generateButton.topAnchor.constraint(equalTo: inputTextView.bottomAnchor, constant: 10),
            generateButton.trailingAnchor.constraint(equalTo: inputContainer.trailingAnchor, constant: -12),
            generateButton.bottomAnchor.constraint(equalTo: inputContainer.bottomAnchor, constant: -12),
            generateButton.heightAnchor.constraint(equalToConstant: 36),
            generateButton.widthAnchor.constraint(greaterThanOrEqualToConstant: 100),
        ])

        contentStack.addArrangedSubview(inputContainer)
    }

    private func setupResultCard() {
        resultCard.backgroundColor = AppColors.card
        resultCard.layer.cornerRadius = 14
        resultCard.layer.borderWidth = 1
        resultCard.layer.borderColor = AppColors.accent.withAlphaComponent(0.3).cgColor
        resultCard.isHidden = true

        let headerLabel = UILabel()
        headerLabel.text = L("ai_writer.result")
        headerLabel.font = .systemFont(ofSize: 13, weight: .semibold)
        headerLabel.textColor = AppColors.accent

        let resultCloseButton = UIButton(type: .system)
        let closeConfig = UIImage.SymbolConfiguration(pointSize: 14, weight: .medium)
        resultCloseButton.setImage(UIImage(systemName: "xmark", withConfiguration: closeConfig), for: .normal)
        resultCloseButton.tintColor = .secondaryLabel
        resultCloseButton.addTarget(self, action: #selector(closeResultTapped), for: .touchUpInside)
        resultCloseButton.translatesAutoresizingMaskIntoConstraints = false

        let headerRow = UIView()
        headerRow.translatesAutoresizingMaskIntoConstraints = false
        headerLabel.translatesAutoresizingMaskIntoConstraints = false
        headerRow.addSubview(headerLabel)
        headerRow.addSubview(resultCloseButton)
        NSLayoutConstraint.activate([
            headerLabel.leadingAnchor.constraint(equalTo: headerRow.leadingAnchor),
            headerLabel.centerYAnchor.constraint(equalTo: headerRow.centerYAnchor),
            resultCloseButton.trailingAnchor.constraint(equalTo: headerRow.trailingAnchor),
            resultCloseButton.centerYAnchor.constraint(equalTo: headerRow.centerYAnchor),
            resultCloseButton.widthAnchor.constraint(equalToConstant: 44),
            resultCloseButton.heightAnchor.constraint(equalToConstant: 44),
            headerRow.heightAnchor.constraint(equalToConstant: 44),
        ])

        resultLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        resultLabel.textColor = AppColors.text
        resultLabel.numberOfLines = 0

        loadingIndicator.color = AppColors.accent
        loadingIndicator.hidesWhenStopped = true

        copyButton.setTitle(L("ai_writer.copy"), for: .normal)
        copyButton.titleLabel?.font = .systemFont(ofSize: 13, weight: .medium)
        copyButton.setTitleColor(AppColors.text, for: .normal)
        copyButton.backgroundColor = AppColors.cardHover
        copyButton.layer.cornerRadius = 8
        copyButton.contentEdgeInsets = UIEdgeInsets(top: 8, left: 14, bottom: 8, right: 14)
        copyButton.addTarget(self, action: #selector(copyTapped), for: .touchUpInside)

        regenerateButton.setTitle(L("ai_writer.regenerate"), for: .normal)
        regenerateButton.titleLabel?.font = .systemFont(ofSize: 13, weight: .medium)
        regenerateButton.setTitleColor(AppColors.text, for: .normal)
        regenerateButton.backgroundColor = AppColors.cardHover
        regenerateButton.layer.cornerRadius = 8
        regenerateButton.contentEdgeInsets = UIEdgeInsets(top: 8, left: 14, bottom: 8, right: 14)
        regenerateButton.addTarget(self, action: #selector(regenerateTapped), for: .touchUpInside)

        let btnStack = UIStackView(arrangedSubviews: [copyButton, regenerateButton])
        btnStack.axis = .horizontal
        btnStack.spacing = 10

        let stack = UIStackView(arrangedSubviews: [headerRow, loadingIndicator, resultLabel, btnStack])
        stack.axis = .vertical
        stack.spacing = 12
        stack.alignment = .leading
        stack.translatesAutoresizingMaskIntoConstraints = false
        resultCard.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: resultCard.topAnchor, constant: 4),
            stack.leadingAnchor.constraint(equalTo: resultCard.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: resultCard.trailingAnchor, constant: -16),
            stack.bottomAnchor.constraint(equalTo: resultCard.bottomAnchor, constant: -16),
            headerRow.leadingAnchor.constraint(equalTo: stack.leadingAnchor),
            headerRow.trailingAnchor.constraint(equalTo: stack.trailingAnchor),
        ])

        contentStack.addArrangedSubview(resultCard)
    }

    // MARK: - Actions

    @objc private func toneTapped(_ sender: UIButton) {
        let tones = ["casual", "formal", "polished", "friendly"]
        selectedTone = tones[sender.tag]
        UIView.animate(withDuration: 0.25, delay: 0, options: .curveEaseOut) {
            for case let btn as UIButton in self.toneStack.arrangedSubviews {
                let isSelected = tones[btn.tag] == self.selectedTone
                btn.backgroundColor = isSelected ? AppColors.accent : AppColors.card
                btn.setTitleColor(isSelected ? .white : AppColors.textMuted, for: .normal)
                btn.transform = isSelected ? CGAffineTransform(scaleX: 1.04, y: 1.04) : .identity
            }
        }
    }

    private func updateToneAppearance() {
        let tones = ["casual", "formal", "polished", "friendly"]
        for case let btn as UIButton in toneStack.arrangedSubviews {
            let isSelected = tones[btn.tag] == selectedTone
            btn.backgroundColor = isSelected ? AppColors.accent : AppColors.card
            btn.setTitleColor(isSelected ? .white : AppColors.textMuted, for: .normal)
            btn.transform = isSelected ? CGAffineTransform(scaleX: 1.04, y: 1.04) : .identity
        }
    }

    private func updateGenerateButtonState() {
        let hasText = !(inputTextView.text?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true)
        generateButton.alpha = hasText ? 1.0 : 0.4
        generateButton.isEnabled = hasText
    }

    private func updateGenerateButton() {
        let tier = SubscriptionStatus.shared.currentTier

        if tier == .free {
            let remaining = DailyUsageManager.shared.remainingComposes
            if remaining > 0 {
                showGenerateState(remaining: remaining)
            } else {
                showWatchAdState()
            }
        } else {
            showGenerateState(remaining: nil)
        }
    }

    private func showGenerateState(remaining: Int?) {
        generateButton.removeTarget(self, action: #selector(watchAdTapped), for: .touchUpInside)
        generateButton.addTarget(self, action: #selector(generateTapped), for: .touchUpInside)
        generateButton.setTitle(L("ai_writer.generate"), for: .normal)
        generateButton.backgroundColor = AppColors.accent

        if let remaining = remaining {
            remainingBadge.isHidden = false
            remainingBadge.text = "\(remaining)"
        } else {
            remainingBadge.isHidden = true
        }
        updateGenerateButtonState()
    }

    private func showWatchAdState() {
        generateButton.removeTarget(self, action: #selector(generateTapped), for: .touchUpInside)
        generateButton.addTarget(self, action: #selector(watchAdTapped), for: .touchUpInside)
        generateButton.setTitle(L("ai_writer.watch_ad_to_write"), for: .normal)
        generateButton.backgroundColor = UIColor.systemOrange
        remainingBadge.isHidden = true
        updateGenerateButtonState()
    }

    @objc private func generateTapped() {
        guard let prompt = inputTextView.text?.trimmingCharacters(in: .whitespacesAndNewlines),
              !prompt.isEmpty else { return }
        lastPrompt = prompt
        requestCompose(prompt: prompt)
    }

    @objc private func watchAdTapped() {
        let rewardVC = RewardedAdsViewController(mode: .compose)
        rewardVC.modalPresentationStyle = .pageSheet
        if let sheet = rewardVC.sheetPresentationController {
            sheet.detents = [.medium()]
        }
        present(rewardVC, animated: true)
    }

    @objc private func closeResultTapped() {
        UIView.animate(withDuration: 0.2) {
            self.resultCard.alpha = 0
        } completion: { _ in
            self.resultCard.isHidden = true
            self.resultCard.alpha = 1
            self.resultLabel.text = nil
        }
    }

    @objc private func copyTapped() {
        UIPasteboard.general.string = resultLabel.text
        copyButton.setTitle(L("ai_writer.copied"), for: .normal)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
            self?.copyButton.setTitle(L("ai_writer.copy"), for: .normal)
        }
    }

    @objc private func regenerateTapped() {
        requestCompose(prompt: lastPrompt)
    }

    // MARK: - API

    private func requestCompose(prompt: String) {
        guard DailyUsageManager.shared.canUseCompose() else {
            showComposeLimitReachedAlert()
            return
        }

        resultCard.isHidden = false
        resultLabel.text = nil
        copyButton.isHidden = true
        regenerateButton.isHidden = true
        loadingIndicator.startAnimating()

        let langCode = AppGroupManager.shared.string(forKey: AppConstants.UserDefaultsKeys.appLanguage) ?? "ko"
        let body: [String: String] = [
            "prompt": prompt,
            "tone": selectedTone,
            "language": langCode,
        ]

        guard let url = URL(string: AppConstants.API.baseURL + "/api/compose"),
              let jsonData = try? JSONSerialization.data(withJSONObject: body) else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = jsonData
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = AppConstants.API.timeout

        URLSession.shared.dataTask(with: request) { [weak self] data, _, error in
            DispatchQueue.main.async {
                self?.loadingIndicator.stopAnimating()
                self?.copyButton.isHidden = false
                self?.regenerateButton.isHidden = false

                guard let data = data, error == nil,
                      let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                      let message = json["message"] as? String else {
                    self?.resultLabel.text = "Error: Failed to generate message."
                    return
                }
                self?.resultLabel.text = message
                DailyUsageManager.shared.recordCompose()
                self?.updateGenerateButton()
            }
        }.resume()
    }

    private func showComposeLimitReachedAlert() {
        let tier = SubscriptionStatus.shared.currentTier

        if tier == .free {
            let alert = UIAlertController(
                title: L("compose.limit.title"),
                message: L("compose.limit.free_message"),
                preferredStyle: .alert
            )
            if DailyUsageManager.shared.canWatchComposeRewardedAd {
                alert.addAction(UIAlertAction(
                    title: L("compose.limit.watch_ad"),
                    style: .default
                ) { [weak self] _ in
                    self?.showRewardedAdForCompose()
                })
            }
            alert.addAction(UIAlertAction(
                title: L("compose.limit.upgrade"),
                style: .default
            ) { [weak self] _ in
                self?.presentPaywall()
            })
            alert.addAction(UIAlertAction(
                title: L("common.cancel"),
                style: .cancel
            ))
            present(alert, animated: true)
        } else {
            let alert = UIAlertController(
                title: L("compose.limit.title"),
                message: String(format: L("compose.limit.pro_message"),
                              FeatureGate.shared.dailyComposeLimit),
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(
                title: L("compose.limit.upgrade_premium"),
                style: .default
            ) { [weak self] _ in
                self?.presentPaywall()
            })
            alert.addAction(UIAlertAction(
                title: L("common.ok"),
                style: .cancel
            ))
            present(alert, animated: true)
        }
    }

    private func showRewardedAdForCompose() {
        let rewardVC = RewardedAdsViewController(mode: .compose)
        rewardVC.modalPresentationStyle = .fullScreen
        present(rewardVC, animated: true)
    }

    private func presentPaywall() {
        let paywallVC = PaywallViewController()
        paywallVC.modalPresentationStyle = .pageSheet
        present(paywallVC, animated: true)
    }
}

// MARK: - UITextViewDelegate

extension AIWriterViewController: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        updateGenerateButtonState()
    }
}
