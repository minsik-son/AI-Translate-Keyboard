import UIKit

class CorrectionLanguageBar: UIView {

    var onLanguageTap: (() -> Void)?
    var onToneTap: (() -> Void)?
    var onCloseTap: (() -> Void)?

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

    private let closeButton: UIButton = {
        let btn = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 13, weight: .semibold)
        btn.setImage(UIImage(systemName: "xmark", withConfiguration: config), for: .normal)
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

        addSubview(languagePill)
        addSubview(tonePill)
        addSubview(closeButton)

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

            // Close X 버튼 — 오른쪽 상단
            closeButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12),
            closeButton.centerYAnchor.constraint(equalTo: centerYAnchor),
            closeButton.widthAnchor.constraint(equalToConstant: 28),
            closeButton.heightAnchor.constraint(equalToConstant: 28),
        ])

        languagePill.layer.cornerRadius = pillHeight / 2
        languagePill.contentEdgeInsets = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)

        tonePill.layer.cornerRadius = pillHeight / 2
        tonePill.contentEdgeInsets = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        tonePill.setTitle(L("tone.none"), for: .normal)

        languagePill.addTarget(self, action: #selector(pillTapped), for: .touchUpInside)
        tonePill.addTarget(self, action: #selector(tonePillTapped), for: .touchUpInside)
        closeButton.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)

        // 누름 효과 등록
        addWoodPressEffect(to: languagePill)
        addWoodPressEffect(to: tonePill)
        addWoodPressEffect(to: closeButton)
    }

    // MARK: - Actions

    @objc private func pillTapped() { onLanguageTap?() }
    @objc private func tonePillTapped() { onToneTap?() }
    @objc private func closeTapped() { onCloseTap?() }

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

            if theme.hasWoodTexture {
                // 나무 블록 스타일
                for pill in [languagePill, tonePill] {
                    pill.layer.cornerRadius = 10
                    pill.layer.borderWidth = 1
                    pill.layer.borderColor = UIColor(white: 0, alpha: 0.15).cgColor
                    pill.layer.shadowColor = UIColor.black.cgColor
                    pill.layer.shadowOffset = CGSize(width: 0, height: 2)
                    pill.layer.shadowRadius = 3
                    pill.layer.shadowOpacity = 0.3
                    pill.clipsToBounds = false
                }
                languagePill.backgroundColor = theme.keyBackground
                tonePill.backgroundColor = theme.specialKeyBackground
                languagePill.setTitleColor(theme.keyTextColor, for: .normal)
                tonePill.setTitleColor(theme.keyTextColor, for: .normal)
                closeButton.tintColor = theme.keyTextColor.withAlphaComponent(0.7)
            } else {
                // 다른 프리미엄 테마: 기존 스타일
                for pill in [languagePill, tonePill] {
                    pill.layer.cornerRadius = 18
                    pill.layer.borderWidth = 0
                    pill.layer.shadowOpacity = 0
                    pill.clipsToBounds = true
                }
                languagePill.backgroundColor = theme.keyBackground
                tonePill.backgroundColor = theme.keyBackground
                languagePill.setTitleColor(theme.keyTextColor, for: .normal)
                tonePill.setTitleColor(theme.keyTextColor, for: .normal)
                closeButton.tintColor = theme.keyTextColor.withAlphaComponent(0.6)
            }
        } else {
            backgroundColor = .clear
            for pill in [languagePill, tonePill] {
                pill.layer.cornerRadius = 18
                pill.layer.borderWidth = 0
                pill.layer.shadowOpacity = 0
                pill.clipsToBounds = true
            }
            languagePill.backgroundColor = isDark ? UIColor(white: 0.25, alpha: 1) : .white
            languagePill.setTitleColor(isDark ? .white : .label, for: .normal)
            tonePill.backgroundColor = isDark ? UIColor(white: 0.25, alpha: 1) : .white
            tonePill.setTitleColor(isDark ? .white : .label, for: .normal)
            closeButton.tintColor = isDark ? UIColor(white: 0.55, alpha: 1) : .secondaryLabel
        }
    }

    // MARK: - Wood Press Effect

    private func addWoodPressEffect(to button: UIButton) {
        button.addTarget(self, action: #selector(woodButtonDown(_:)), for: .touchDown)
        button.addTarget(self, action: #selector(woodButtonUp(_:)), for: [.touchUpInside, .touchUpOutside, .touchCancel])
    }

    @objc private func woodButtonDown(_ sender: UIButton) {
        UIView.animate(withDuration: 0.08) {
            sender.alpha = 0.6
        }
    }

    @objc private func woodButtonUp(_ sender: UIButton) {
        UIView.animate(withDuration: 0.15) {
            sender.alpha = 1.0
        }
    }
}
