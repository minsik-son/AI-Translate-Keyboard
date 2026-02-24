import UIKit

class ToolbarView: UIView {

    // MARK: - Callbacks

    var onTranslateToggle: (() -> Void)?
    var onEmojiTap: ((String) -> Void)?
    var onEmojiKeyboardToggle: (() -> Void)?
    var onSettingsTap: (() -> Void)?

    // MARK: - Toolbar button definitions

    private struct ToolbarItem {
        let iconName: String
        let action: Selector
        let tag: Int
    }

    private let toolbarItems: [ToolbarItem] = [
        ToolbarItem(iconName: "t.circle.fill", action: #selector(logoTapped), tag: 0),
        ToolbarItem(iconName: "face.smiling", action: #selector(emojiButtonTapped), tag: 1),
        ToolbarItem(iconName: "face.smiling.inverse", action: #selector(emoticonTapped), tag: 2),
        ToolbarItem(iconName: "doc.on.clipboard", action: #selector(clipboardTapped), tag: 3),
        ToolbarItem(iconName: "checklist", action: #selector(checklistTapped), tag: 4),
        ToolbarItem(iconName: "character.book.closed.fill", action: #selector(translateTapped), tag: 5),
        ToolbarItem(iconName: "gearshape", action: #selector(settingsTapped), tag: 6),
    ]

    // MARK: - Views

    private let stack: UIStackView = {
        let sv = UIStackView()
        sv.axis = .horizontal
        sv.distribution = .equalSpacing
        sv.alignment = .center
        sv.translatesAutoresizingMaskIntoConstraints = false
        return sv
    }()

    private let statusLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12)
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        label.isHidden = true
        return label
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

        addSubview(stack)
        addSubview(statusLabel)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: topAnchor),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor),

            statusLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            statusLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
        ])

        for item in toolbarItems {
            let btn = makeToolbarButton(iconName: item.iconName, action: item.action, tag: item.tag)
            stack.addArrangedSubview(btn)
        }
    }

    private func makeToolbarButton(iconName: String, action: Selector, tag: Int) -> UIButton {
        let btn = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 20, weight: .regular)
        btn.setImage(UIImage(systemName: iconName, withConfiguration: config), for: .normal)
        btn.tintColor = .label
        btn.tag = tag
        btn.addTarget(self, action: action, for: .touchUpInside)
        btn.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            btn.widthAnchor.constraint(equalToConstant: 36),
            btn.heightAnchor.constraint(equalToConstant: 40),
        ])
        return btn
    }

    // MARK: - Public Methods

    func showStatusMessage(_ message: String) {
        statusLabel.text = message
        statusLabel.isHidden = false
    }

    func hideStatusMessage() {
        statusLabel.isHidden = true
    }

    func updateAppearance(isDark: Bool) {
        backgroundColor = isDark ? UIColor(white: 0.12, alpha: 1) : .clear
        for case let btn as UIButton in stack.arrangedSubviews {
            btn.tintColor = isDark ? .white : .label
        }
    }

    // MARK: - Actions

    @objc private func logoTapped() {
        // App branding — no-op for now
    }

    @objc private func emojiButtonTapped() {
        onEmojiKeyboardToggle?()
    }

    @objc private func emoticonTapped() {
        // Emoticon panel — no-op for now
    }

    @objc private func clipboardTapped() {
        if let text = UIPasteboard.general.string {
            onEmojiTap?(text)
        }
    }

    @objc private func checklistTapped() {
        // Checklist — no-op for now
    }

    @objc private func translateTapped() {
        onTranslateToggle?()
    }

    @objc private func settingsTapped() {
        onSettingsTap?()
    }
}
