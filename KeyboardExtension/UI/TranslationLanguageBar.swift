import UIKit

class TranslationLanguageBar: UIView {

    var onSourceTap: (() -> Void)?
    var onTargetTap: (() -> Void)?
    var onSwapTap: (() -> Void)?

    private let sourcePill: UIButton = {
        let btn = UIButton(type: .custom)
        btn.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        btn.setTitleColor(.label, for: .normal)
        btn.backgroundColor = .white
        btn.clipsToBounds = true
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }()

    private let targetPill: UIButton = {
        let btn = UIButton(type: .custom)
        btn.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        btn.setTitleColor(.label, for: .normal)
        btn.backgroundColor = .white
        btn.clipsToBounds = true
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }()

    private let swapButton: UIButton = {
        let btn = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 16, weight: .medium)
        btn.setImage(UIImage(systemName: "arrow.left.arrow.right", withConfiguration: config), for: .normal)
        btn.tintColor = .secondaryLabel
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }()

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup

    private func setupViews() {
        backgroundColor = .clear

        addSubview(sourcePill)
        addSubview(swapButton)
        addSubview(targetPill)

        let pillHeight: CGFloat = 36

        NSLayoutConstraint.activate([
            // Swap button — centered
            swapButton.centerXAnchor.constraint(equalTo: centerXAnchor),
            swapButton.centerYAnchor.constraint(equalTo: centerYAnchor),
            swapButton.widthAnchor.constraint(equalToConstant: 40),
            swapButton.heightAnchor.constraint(equalToConstant: pillHeight),

            // Source pill — left side
            sourcePill.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            sourcePill.centerYAnchor.constraint(equalTo: centerYAnchor),
            sourcePill.trailingAnchor.constraint(equalTo: swapButton.leadingAnchor, constant: -4),
            sourcePill.heightAnchor.constraint(equalToConstant: pillHeight),

            // Target pill — right side
            targetPill.leadingAnchor.constraint(equalTo: swapButton.trailingAnchor, constant: 4),
            targetPill.centerYAnchor.constraint(equalTo: centerYAnchor),
            targetPill.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            targetPill.heightAnchor.constraint(equalToConstant: pillHeight),
        ])

        sourcePill.layer.cornerRadius = pillHeight / 2
        targetPill.layer.cornerRadius = pillHeight / 2

        sourcePill.addTarget(self, action: #selector(sourceTapped), for: .touchUpInside)
        targetPill.addTarget(self, action: #selector(targetTapped), for: .touchUpInside)
        swapButton.addTarget(self, action: #selector(swapTapped), for: .touchUpInside)
    }

    // MARK: - Actions

    @objc private func sourceTapped() { onSourceTap?() }
    @objc private func targetTapped() { onTargetTap?() }
    @objc private func swapTapped() { onSwapTap?() }

    // MARK: - Public

    private var customTheme: KeyboardTheme?

    func applyTheme(_ theme: KeyboardTheme?) {
        customTheme = theme
    }

    func updateLanguageNames(source: String, target: String) {
        sourcePill.setTitle(source, for: .normal)
        targetPill.setTitle(target, for: .normal)
    }

    func updateAppearance(isDark: Bool) {
        if let theme = customTheme {
            backgroundColor = theme.toolbarBackground
            sourcePill.backgroundColor = theme.keyBackground
            targetPill.backgroundColor = theme.keyBackground
            sourcePill.setTitleColor(theme.keyTextColor, for: .normal)
            targetPill.setTitleColor(theme.keyTextColor, for: .normal)
            swapButton.tintColor = theme.keyTextColor.withAlphaComponent(0.6)
        } else {
            backgroundColor = .clear
            sourcePill.backgroundColor = isDark ? UIColor(white: 0.25, alpha: 1) : .white
            targetPill.backgroundColor = isDark ? UIColor(white: 0.25, alpha: 1) : .white
            sourcePill.setTitleColor(isDark ? .white : .label, for: .normal)
            targetPill.setTitleColor(isDark ? .white : .label, for: .normal)
            swapButton.tintColor = isDark ? UIColor(white: 0.55, alpha: 1) : .secondaryLabel
        }
    }
}
