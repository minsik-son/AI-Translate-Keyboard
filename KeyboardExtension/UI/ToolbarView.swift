import UIKit

class ToolbarView: UIView {

    // MARK: - Callbacks

    var onTranslateToggle: (() -> Void)?
    var onEmojiTap: ((String) -> Void)?
    var onEmojiKeyboardToggle: (() -> Void)?
    var onSettingsTap: (() -> Void)?
    var onSuggestionTap: ((String) -> Void)?
    var onSuggestionDismiss: (() -> Void)?

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

    private let suggestionStack: UIStackView = {
        let sv = UIStackView()
        sv.axis = .horizontal
        sv.distribution = .fillEqually
        sv.alignment = .fill
        sv.translatesAutoresizingMaskIntoConstraints = false
        sv.isHidden = true
        return sv
    }()

    private var suggestionButtons: [UIButton] = []
    private var separatorLines: [UIView] = []
    private let bottomBorder = UIView()

    private let dismissButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("✕", for: .normal)
        btn.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        btn.setTitleColor(.label, for: .normal)
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.isHidden = true
        return btn
    }()

    private let dismissSeparator: UIView = {
        let v = UIView()
        v.backgroundColor = .separator
        v.translatesAutoresizingMaskIntoConstraints = false
        v.isHidden = true
        return v
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
        addSubview(suggestionStack)
        addSubview(dismissSeparator)
        addSubview(dismissButton)

        dismissButton.addTarget(self, action: #selector(dismissTapped), for: .touchUpInside)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: topAnchor),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor),

            statusLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            statusLabel.centerYAnchor.constraint(equalTo: centerYAnchor),

            suggestionStack.topAnchor.constraint(equalTo: topAnchor),
            suggestionStack.leadingAnchor.constraint(equalTo: leadingAnchor),
            suggestionStack.trailingAnchor.constraint(equalTo: dismissSeparator.leadingAnchor),
            suggestionStack.bottomAnchor.constraint(equalTo: bottomAnchor),

            dismissSeparator.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            dismissSeparator.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8),
            dismissSeparator.trailingAnchor.constraint(equalTo: dismissButton.leadingAnchor),
            dismissSeparator.widthAnchor.constraint(equalToConstant: 0.5),

            dismissButton.topAnchor.constraint(equalTo: topAnchor),
            dismissButton.trailingAnchor.constraint(equalTo: trailingAnchor),
            dismissButton.bottomAnchor.constraint(equalTo: bottomAnchor),
            dismissButton.widthAnchor.constraint(equalToConstant: 44),
        ])

        for item in toolbarItems {
            let btn = makeToolbarButton(iconName: item.iconName, action: item.action, tag: item.tag)
            stack.addArrangedSubview(btn)
        }

        buildSuggestionButtons()
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
        // suggestion 버튼 색상
        for btn in suggestionButtons {
            btn.setTitleColor(isDark ? .white : .label, for: .normal)
        }
        // dismiss 버튼 색상
        dismissButton.setTitleColor(isDark ? .white : .label, for: .normal)
        // suggestion 배경색 — 키보드 배경과 동일
        let suggestionBg = isDark
            ? UIColor(white: 0.08, alpha: 1)
            : UIColor(red: 0.82, green: 0.84, blue: 0.86, alpha: 1)
        suggestionStack.backgroundColor = suggestionBg
        dismissButton.backgroundColor = suggestionBg
    }

    func showSuggestions(_ suggestions: [String]) {
        for (i, btn) in suggestionButtons.enumerated() {
            if i < suggestions.count {
                btn.setTitle(suggestions[i], for: .normal)
                btn.isHidden = false
            } else {
                btn.setTitle(nil, for: .normal)
                btn.isHidden = true
            }
            btn.titleLabel?.font = .systemFont(ofSize: 15)
        }
        stack.isHidden = true
        suggestionStack.isHidden = false
        separatorLines.forEach { $0.isHidden = false }
        dismissButton.isHidden = false
        dismissSeparator.isHidden = false
        bottomBorder.isHidden = false
        setNeedsLayout()
    }

    func hideSuggestions() {
        suggestionStack.isHidden = true
        stack.isHidden = false
        separatorLines.forEach { $0.isHidden = true }
        dismissButton.isHidden = true
        dismissSeparator.isHidden = true
        bottomBorder.isHidden = true
    }

    private func buildSuggestionButtons() {
        // 버튼 3개만 stack에 추가 (separator 제외)
        for i in 0..<3 {
            let btn = UIButton(type: .system)
            btn.titleLabel?.font = .systemFont(ofSize: 15)
            btn.setTitleColor(.label, for: .normal)
            btn.tag = i
            btn.addTarget(self, action: #selector(suggestionTapped(_:)), for: .touchUpInside)
            suggestionButtons.append(btn)
            suggestionStack.addArrangedSubview(btn)
        }

        // 구분선 2개를 별도 subview로 추가
        for _ in 0..<2 {
            let sep = UIView()
            sep.backgroundColor = .separator
            sep.translatesAutoresizingMaskIntoConstraints = false
            addSubview(sep)
            separatorLines.append(sep)
        }

        // 하단 경계선
        bottomBorder.backgroundColor = .separator
        bottomBorder.translatesAutoresizingMaskIntoConstraints = false
        addSubview(bottomBorder)

        NSLayoutConstraint.activate([
            bottomBorder.leadingAnchor.constraint(equalTo: leadingAnchor),
            bottomBorder.trailingAnchor.constraint(equalTo: trailingAnchor),
            bottomBorder.bottomAnchor.constraint(equalTo: bottomAnchor),
            bottomBorder.heightAnchor.constraint(equalToConstant: 0.5),
        ])

        bottomBorder.isHidden = true
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        guard !suggestionStack.isHidden, suggestionButtons.count == 3 else { return }
        let availableWidth = bounds.width - 44 - 0.5 // dismiss button + separator
        let thirdWidth = availableWidth / 3.0
        for (i, sep) in separatorLines.enumerated() {
            let x = thirdWidth * CGFloat(i + 1)
            let sepHeight = bounds.height * 0.5
            let y = (bounds.height - sepHeight) / 2.0
            sep.frame = CGRect(x: x - 0.25, y: y, width: 0.5, height: sepHeight)
        }
    }

    @objc private func suggestionTapped(_ sender: UIButton) {
        guard let title = sender.title(for: .normal), !title.isEmpty else { return }
        onSuggestionTap?(title)
    }

    @objc private func dismissTapped() {
        onSuggestionDismiss?()
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
