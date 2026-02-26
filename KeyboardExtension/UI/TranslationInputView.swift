import UIKit

class TranslationInputView: UIView {

    var onTextChanged: ((String) -> Void)?
    var onCloseTranslation: (() -> Void)?
    var onHeightChanged: ((CGFloat) -> Void)?

    private var textBuffer: String = ""

    private static let minHeight: CGFloat = 44

    // ═══════════════════════════════════════
    // Multi-line: |텍스트          [counter] [X]
    // When empty: |번역할 텍스트 입력         [X]
    // ═══════════════════════════════════════

    private let inputLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 15)
        label.textColor = .label
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        label.translatesAutoresizingMaskIntoConstraints = false
        label.setContentHuggingPriority(.required, for: .vertical)
        label.setContentCompressionResistancePriority(.required, for: .vertical)
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
        label.text = L("translation.placeholder")
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
        label.isHidden = true
        label.setContentHuggingPriority(.required, for: .horizontal)
        label.setContentCompressionResistancePriority(.required, for: .horizontal)
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
    private var cursorTop: NSLayoutConstraint?
    private var lastNotifiedHeight: CGFloat = 0

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

        NSLayoutConstraint.activate([
            // Container fills self with margins
            containerView.topAnchor.constraint(equalTo: topAnchor, constant: 4),
            containerView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            containerView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
            containerView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -4),

            // Close button — top-right, fixed position
            closeButton.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 7),
            closeButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -2),
            closeButton.widthAnchor.constraint(equalToConstant: 30),
            closeButton.heightAnchor.constraint(equalToConstant: 30),

            // Counter — top-right, next to close button
            counterLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 12),
            counterLabel.trailingAnchor.constraint(equalTo: closeButton.leadingAnchor, constant: -4),

            // Input label — fills left area, multi-line, no max height
            inputLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 10),
            inputLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 10),
            inputLabel.trailingAnchor.constraint(lessThanOrEqualTo: counterLabel.leadingAnchor, constant: -6),

            // Placeholder
            placeholderLabel.topAnchor.constraint(equalTo: inputLabel.topAnchor),
            placeholderLabel.leadingAnchor.constraint(equalTo: inputLabel.leadingAnchor),

            // Cursor — thin bar
            cursorView.widthAnchor.constraint(equalToConstant: 1.5),
            cursorView.heightAnchor.constraint(equalToConstant: 18),
        ])

        // Low-priority bottom constraint — label sizes by content hugging, text stays at top
        let bottomConstraint = inputLabel.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -10)
        bottomConstraint.priority = .defaultLow
        bottomConstraint.isActive = true

        // Cursor positioned by leading (x) and top (y) relative to inputLabel
        cursorLeading = cursorView.leadingAnchor.constraint(equalTo: inputLabel.leadingAnchor)
        cursorLeading?.isActive = true
        cursorTop = cursorView.topAnchor.constraint(equalTo: inputLabel.topAnchor)
        cursorTop?.isActive = true

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
        notifyHeightChangeIfNeeded()
        updateCursorPosition()
    }

    func setPlaceholder(_ text: String) {
        placeholderLabel.text = text
    }

    private var customTheme: KeyboardTheme?

    func applyTheme(_ theme: KeyboardTheme?) {
        customTheme = theme
    }

    func updateAppearance(isDark: Bool) {
        if let theme = customTheme {
            backgroundColor = theme.toolbarBackground
            containerView.backgroundColor = theme.keyBackground
            inputLabel.textColor = theme.keyTextColor
            closeButton.tintColor = theme.keyTextColor.withAlphaComponent(0.4)
            placeholderLabel.textColor = theme.keyTextColor.withAlphaComponent(0.4)
        } else {
            backgroundColor = .clear
            containerView.backgroundColor = isDark ? UIColor(white: 0.18, alpha: 1) : UIColor(white: 0.95, alpha: 1)
            closeButton.tintColor = isDark ? UIColor(white: 0.4, alpha: 1) : .tertiaryLabel
            inputLabel.textColor = isDark ? .white : .label
            placeholderLabel.textColor = isDark ? UIColor(white: 0.6, alpha: 1) : UIColor.placeholderText.withAlphaComponent(0.5)
        }
    }

    /// Width used for text layout calculations (must match idealHeight and updateCursorPosition)
    private var textLayoutWidth: CGFloat {
        return bounds.width - 8 * 2 - 10 - 6 - 40 - 30  // margins, padding, counter, close
    }

    /// Returns the ideal height based on current text content (no max limit)
    func idealHeight() -> CGFloat {
        let maxWidth = textLayoutWidth
        guard maxWidth > 0 else { return TranslationInputView.minHeight }

        let text = (inputLabel.text ?? "") as NSString
        if text.length == 0 { return TranslationInputView.minHeight }

        let boundingRect = text.boundingRect(
            with: CGSize(width: maxWidth, height: .greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: [.font: inputLabel.font!],
            context: nil
        )

        // Label height + vertical padding (top 10 + bottom 10) + container padding (top 4 + bottom 4)
        let neededHeight = ceil(boundingRect.height) + 20 + 8

        return max(neededHeight, TranslationInputView.minHeight)
    }

    // MARK: - Private

    private func updateDisplay() {
        inputLabel.text = textBuffer
        placeholderLabel.isHidden = !textBuffer.isEmpty
        counterLabel.isHidden = textBuffer.isEmpty
        updateCounter(count: textBuffer.count)
        notifyHeightChangeIfNeeded()
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

    private func notifyHeightChangeIfNeeded() {
        layoutIfNeeded()
        let newHeight = idealHeight()
        if abs(newHeight - lastNotifiedHeight) > 1 {
            lastNotifiedHeight = newHeight
            onHeightChanged?(newHeight)
        }
    }

    private func updateCursorPosition() {
        guard let text = inputLabel.text, !text.isEmpty else {
            cursorLeading?.constant = 0
            cursorTop?.constant = 0
            return
        }

        let maxWidth = textLayoutWidth
        guard maxWidth > 0 else {
            cursorLeading?.constant = 0
            cursorTop?.constant = 0
            return
        }

        let font = inputLabel.font!
        let attrs: [NSAttributedString.Key: Any] = [.font: font]
        let lineHeight = ceil(font.lineHeight)

        // Text ends with \n — cursor goes to the beginning of the next empty line
        if text.hasSuffix("\n") {
            let measureText = text + " "
            let rect = (measureText as NSString).boundingRect(
                with: CGSize(width: maxWidth, height: .greatestFiniteMagnitude),
                options: [.usesLineFragmentOrigin, .usesFontLeading],
                attributes: attrs, context: nil
            )
            cursorLeading?.constant = 0
            cursorTop?.constant = max(0, ceil(rect.height) - lineHeight)
            return
        }

        // Y: boundingRect (matches idealHeight measurement)
        let fullRect = (text as NSString).boundingRect(
            with: CGSize(width: maxWidth, height: .greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: attrs, context: nil
        )
        cursorTop?.constant = max(0, ceil(fullRect.height) - lineHeight)

        // X: TextKit for accurate last-glyph position (handles soft-wrap)
        let attributedText = NSAttributedString(string: text, attributes: attrs)
        let textStorage = NSTextStorage(attributedString: attributedText)
        let layoutManager = NSLayoutManager()
        let textContainer = NSTextContainer(size: CGSize(width: maxWidth, height: .greatestFiniteMagnitude))
        textContainer.lineFragmentPadding = 0
        layoutManager.addTextContainer(textContainer)
        textStorage.addLayoutManager(layoutManager)
        layoutManager.ensureLayout(for: textContainer)

        let numberOfGlyphs = layoutManager.numberOfGlyphs
        guard numberOfGlyphs > 0 else {
            cursorLeading?.constant = 0
            return
        }
        let lastGlyphIndex = numberOfGlyphs - 1
        let lastGlyphRect = layoutManager.boundingRect(
            forGlyphRange: NSRange(location: lastGlyphIndex, length: 1),
            in: textContainer
        )
        cursorLeading?.constant = min(lastGlyphRect.maxX, maxWidth)
    }
}
