import UIKit

class TranslationInputView: UIView {

    var onTextChanged: ((String) -> Void)?
    var onCloseTranslation: (() -> Void)?

    private var textBuffer: String = ""

    // ═══════════════════════════════════════
    // SINGLE LINE:  |텍스트       [counter] [X]
    // When empty:   |번역할 텍스트 입력      [X]
    // ═══════════════════════════════════════

    private let inputLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 15)
        label.textColor = .label
        label.numberOfLines = 1
        label.lineBreakMode = .byTruncatingTail
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let cursorView: UIView = {
        let v = UIView()
        v.backgroundColor = .systemBlue
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private let placeholderLabel: UILabel = {
        let label = UILabel()
        label.text = "번역할 텍스트를 입력하세요"
        label.font = .systemFont(ofSize: 15)
        label.textColor = UIColor.placeholderText.withAlphaComponent(0.5)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let counterLabel: UILabel = {
        let label = UILabel()
        label.font = .monospacedDigitSystemFont(ofSize: 10, weight: .regular)
        label.textColor = .tertiaryLabel
        label.textAlignment = .right
        label.translatesAutoresizingMaskIntoConstraints = false
        label.isHidden = true  // only show when typing
        return label
    }()

    private let closeButton: UIButton = {
        let btn = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 13, weight: .semibold)
        btn.setImage(UIImage(systemName: "xmark", withConfiguration: config), for: .normal)
        btn.tintColor = .tertiaryLabel
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }()

    private let containerView: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor(white: 0.95, alpha: 1)
        v.layer.cornerRadius = 8
        v.clipsToBounds = true
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private var cursorTimer: Timer?
    private var cursorLeading: NSLayoutConstraint?

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
        startCursorBlink()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        cursorTimer?.invalidate()
    }

    // MARK: - Setup

    private func setupViews() {
        backgroundColor = .clear

        addSubview(containerView)

        containerView.addSubview(inputLabel)
        containerView.addSubview(placeholderLabel)
        containerView.addSubview(cursorView)
        containerView.addSubview(counterLabel)
        containerView.addSubview(closeButton)

        // Container — grey rounded rect with margins
        // Right-side buttons: [counter] [X]
        // Left-side: cursor + text input (flexible)

        NSLayoutConstraint.activate([
            // Container fills self with margins
            containerView.topAnchor.constraint(equalTo: topAnchor, constant: 4),
            containerView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            containerView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
            containerView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -4),

            // Close button — far right
            closeButton.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            closeButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -2),
            closeButton.widthAnchor.constraint(equalToConstant: 30),
            closeButton.heightAnchor.constraint(equalToConstant: 30),

            // Counter (between text and close)
            counterLabel.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            counterLabel.trailingAnchor.constraint(equalTo: closeButton.leadingAnchor, constant: -4),

            // Input label — left side, flexible
            inputLabel.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            inputLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 10),
            inputLabel.trailingAnchor.constraint(lessThanOrEqualTo: counterLabel.leadingAnchor, constant: -6),

            // Placeholder
            placeholderLabel.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            placeholderLabel.leadingAnchor.constraint(equalTo: inputLabel.leadingAnchor),

            // Cursor — thin bar aligned with text
            cursorView.widthAnchor.constraint(equalToConstant: 1.5),
            cursorView.heightAnchor.constraint(equalToConstant: 18),
            cursorView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
        ])

        cursorLeading = cursorView.leadingAnchor.constraint(equalTo: inputLabel.leadingAnchor)
        cursorLeading?.isActive = true

        // Actions
        closeButton.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)

        updateDisplay()
    }

    private func startCursorBlink() {
        cursorTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            self?.cursorView.isHidden.toggle()
        }
    }

    // MARK: - Actions

    @objc private func closeTapped() { onCloseTranslation?() }

    // MARK: - Public Methods

    func insertText(_ text: String) {
        guard textBuffer.count + text.count <= AppConstants.Limits.maxCharacters else { return }
        textBuffer += text
        updateDisplay()
        onTextChanged?(textBuffer)
    }

    func deleteBackward() {
        guard !textBuffer.isEmpty else { return }
        textBuffer.removeLast()
        updateDisplay()
        onTextChanged?(textBuffer)
    }

    func clear() {
        textBuffer = ""
        updateDisplay()
        onTextChanged?(textBuffer)
    }

    var currentText: String { return textBuffer }

    func setDisplayText(_ text: String) {
        inputLabel.text = text
        placeholderLabel.isHidden = !text.isEmpty
        counterLabel.isHidden = text.isEmpty
        updateCounter(count: text.count)
        updateCursorPosition()
    }

    func updateAppearance(isDark: Bool) {
        backgroundColor = .clear
        containerView.backgroundColor = isDark ? UIColor(white: 0.18, alpha: 1) : UIColor(white: 0.95, alpha: 1)
        closeButton.tintColor = isDark ? UIColor(white: 0.4, alpha: 1) : .tertiaryLabel
        inputLabel.textColor = isDark ? .white : .label
    }

    // MARK: - Private

    private func updateDisplay() {
        inputLabel.text = textBuffer
        placeholderLabel.isHidden = !textBuffer.isEmpty
        counterLabel.isHidden = textBuffer.isEmpty
        updateCounter(count: textBuffer.count)
        updateCursorPosition()
    }

    private func updateCounter(count: Int) {
        let max = AppConstants.Limits.maxCharacters
        counterLabel.text = "\(count)/\(max)"
        if count >= max {
            counterLabel.textColor = .systemRed
        } else if count >= AppConstants.Limits.warningCharacters {
            counterLabel.textColor = .systemOrange
        } else {
            counterLabel.textColor = .tertiaryLabel
        }
    }

    private func updateCursorPosition() {
        guard let text = inputLabel.text, !text.isEmpty else {
            cursorLeading?.constant = 0
            return
        }
        let size = (text as NSString).size(withAttributes: [.font: inputLabel.font!])
        let maxWidth = inputLabel.bounds.width
        cursorLeading?.constant = min(size.width, maxWidth)
    }
}
