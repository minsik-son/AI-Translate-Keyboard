import UIKit

class CorrectionLanguageBar: UIView {

    var onLanguageTap: (() -> Void)?
    var onToneTap: (() -> Void)?

    private let languagePill: UIButton = {
        let btn = UIButton(type: .custom)
        btn.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        btn.setTitleColor(.label, for: .normal)
        btn.backgroundColor = .white
        btn.clipsToBounds = true
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }()

    private let tonePill: UIButton = {
        let btn = UIButton(type: .custom)
        btn.titleLabel?.font = .systemFont(ofSize: 14, weight: .medium)
        btn.setTitleColor(.label, for: .normal)
        btn.backgroundColor = .white
        btn.clipsToBounds = true
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

        addSubview(languagePill)
        addSubview(tonePill)

        let pillHeight: CGFloat = 36

        NSLayoutConstraint.activate([
            languagePill.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            languagePill.centerYAnchor.constraint(equalTo: centerYAnchor),
            languagePill.heightAnchor.constraint(equalToConstant: pillHeight),
            languagePill.widthAnchor.constraint(greaterThanOrEqualToConstant: 80),

            tonePill.leadingAnchor.constraint(equalTo: languagePill.trailingAnchor, constant: 8),
            tonePill.centerYAnchor.constraint(equalTo: centerYAnchor),
            tonePill.heightAnchor.constraint(equalToConstant: pillHeight),
            tonePill.widthAnchor.constraint(greaterThanOrEqualToConstant: 80),
        ])

        languagePill.layer.cornerRadius = pillHeight / 2
        languagePill.contentEdgeInsets = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)

        tonePill.layer.cornerRadius = pillHeight / 2
        tonePill.contentEdgeInsets = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        tonePill.setTitle("기본", for: .normal)

        languagePill.addTarget(self, action: #selector(pillTapped), for: .touchUpInside)
        tonePill.addTarget(self, action: #selector(tonePillTapped), for: .touchUpInside)
    }

    // MARK: - Actions

    @objc private func pillTapped() { onLanguageTap?() }
    @objc private func tonePillTapped() { onToneTap?() }

    // MARK: - Public

    private var customTheme: KeyboardTheme?

    func applyTheme(_ theme: KeyboardTheme?) {
        customTheme = theme
    }

    func updateLanguageName(_ name: String) {
        languagePill.setTitle(name, for: .normal)
    }

    func updateToneName(_ name: String) {
        tonePill.setTitle(name, for: .normal)
    }

    func updateAppearance(isDark: Bool) {
        if let theme = customTheme {
            backgroundColor = theme.toolbarBackground
            languagePill.backgroundColor = theme.keyBackground
            languagePill.setTitleColor(theme.keyTextColor, for: .normal)
            tonePill.backgroundColor = theme.keyBackground
            tonePill.setTitleColor(theme.keyTextColor, for: .normal)
        } else {
            backgroundColor = .clear
            languagePill.backgroundColor = isDark ? UIColor(white: 0.25, alpha: 1) : .white
            languagePill.setTitleColor(isDark ? .white : .label, for: .normal)
            tonePill.backgroundColor = isDark ? UIColor(white: 0.25, alpha: 1) : .white
            tonePill.setTitleColor(isDark ? .white : .label, for: .normal)
        }
    }
}
