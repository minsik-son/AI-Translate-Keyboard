import UIKit

class TranslationInputView: UIView {

    var onTextChanged: ((String) -> Void)?
    var onClearText: (() -> Void)?
    var onHeightChanged: ((CGFloat) -> Void)?

    var maxCharacters: Int = AppConstants.Limits.maxCharacters

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
        label.lineBreakMode = .byCharWrapping
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

    private let clearButton: UIButton = {
        let btn = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 13, weight: .semibold)
        btn.setImage(UIImage(systemName: "xmark.circle.fill", withConfiguration: config), for: .normal)
        btn.tintColor = .tertiaryLabel
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.isHidden = true
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

    // MARK: - TextKit Stack (커서 계산용, 재사용)
    private let cursorTextStorage = NSTextStorage()
    private let cursorLayoutManager = NSLayoutManager()
    private lazy var cursorTextContainer: NSTextContainer = {
        let tc = NSTextContainer(size: .zero)
        tc.lineFragmentPadding = 0
        return tc
    }()
    private var isCursorTextKitSetUp = false

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
        containerView.addSubview(clearButton)

        NSLayoutConstraint.activate([
            // Container fills self with margins
            containerView.topAnchor.constraint(equalTo: topAnchor, constant: 4),
            containerView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            containerView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
            containerView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -4),

            // Close button — top-right, fixed position
            clearButton.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 7),
            clearButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -2),
            clearButton.widthAnchor.constraint(equalToConstant: 30),
            clearButton.heightAnchor.constraint(equalToConstant: 30),

            // Counter — top-right, next to close button
            counterLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 12),
            counterLabel.trailingAnchor.constraint(equalTo: clearButton.leadingAnchor, constant: -4),

            // Input label — fills left area, multi-line, no max height
            inputLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 10),
            inputLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 10),
            // Fixed offset: close margin 2 + close 30 + gap 4 + counter max 42 + gap 6 = 84
            inputLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -84),

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
        clearButton.addTarget(self, action: #selector(clearTapped), for: .touchUpInside)

        updateDisplay()
    }

    private func startCursorBlink() {
        cursorTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            self?.cursorView.isHidden.toggle()
        }
    }

    // MARK: - Actions

    @objc private func clearTapped() {
        onClearText?()
        clear()
    }

    // MARK: - Public Methods

    func insertText(_ text: String) {
        guard textBuffer.count + text.count <= maxCharacters else { return }
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
        clearButton.isHidden = text.isEmpty
        updateCounter(count: text.count)
        notifyHeightChangeIfNeeded()
        layoutIfNeeded()
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
            clearButton.tintColor = theme.keyTextColor.withAlphaComponent(0.4)
            placeholderLabel.textColor = theme.keyTextColor.withAlphaComponent(0.4)
        } else {
            backgroundColor = .clear
            containerView.backgroundColor = isDark ? UIColor(white: 0.18, alpha: 1) : UIColor(white: 0.95, alpha: 1)
            clearButton.tintColor = isDark ? UIColor(white: 0.4, alpha: 1) : .tertiaryLabel
            inputLabel.textColor = isDark ? .white : .label
            placeholderLabel.textColor = isDark ? UIColor(white: 0.6, alpha: 1) : UIColor.placeholderText.withAlphaComponent(0.5)
        }
    }

    /// Returns the ideal height based on current text content (no max limit)
    func idealHeight() -> CGFloat {
        let maxWidth = inputLabel.frame.width
        guard maxWidth > 0 else { return TranslationInputView.minHeight }

        guard let text = inputLabel.text, !text.isEmpty else { return TranslationInputView.minHeight }

        // Use sizeThatFits to match UILabel's own rendering exactly
        let labelHeight = inputLabel.sizeThatFits(CGSize(width: maxWidth, height: .greatestFiniteMagnitude)).height

        // Label height + vertical padding (top 10 + bottom 10) + container padding (top 4 + bottom 4)
        let neededHeight = ceil(labelHeight) + 20 + 8

        return max(neededHeight, TranslationInputView.minHeight)
    }

    // MARK: - Private

    private func updateDisplay() {
        inputLabel.text = textBuffer
        placeholderLabel.isHidden = !textBuffer.isEmpty
        counterLabel.isHidden = textBuffer.isEmpty
        clearButton.isHidden = textBuffer.isEmpty
        updateCounter(count: textBuffer.count)
        notifyHeightChangeIfNeeded()
        layoutIfNeeded()
        updateCursorPosition()
    }

    private func updateCounter(count: Int) {
        let max = maxCharacters
        counterLabel.text = "\(count)/\(max)"
        if count >= max {
            counterLabel.textColor = .systemRed
        } else if count >= AppConstants.Limits.warningCharacters {
            counterLabel.textColor = .systemOrange
        } else {
            counterLabel.textColor = .tertiaryLabel
        }
    }

    private func setupCursorTextKitIfNeeded() {
        guard !isCursorTextKitSetUp else { return }
        cursorTextStorage.addLayoutManager(cursorLayoutManager)
        cursorLayoutManager.addTextContainer(cursorTextContainer)
        isCursorTextKitSetUp = true
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

        let maxWidth = inputLabel.frame.width
        guard maxWidth > 0 else {
            cursorLeading?.constant = 0
            cursorTop?.constant = 0
            return
        }

        let font = inputLabel.font!

        // ─── TextKit 1 스택 재사용 ───
        setupCursorTextKitIfNeeded()

        // 텍스트 컨테이너 크기 업데이트
        cursorTextContainer.size = CGSize(width: maxWidth, height: .greatestFiniteMagnitude)
        cursorTextContainer.lineBreakMode = inputLabel.lineBreakMode

        // 텍스트 교체 (기존 내용 제거 후 새 텍스트 설정)
        let fullRange = NSRange(location: 0, length: cursorTextStorage.length)
        cursorTextStorage.replaceCharacters(in: fullRange, with: text)

        // 폰트 + paragraphStyle 적용
        let newFullRange = NSRange(location: 0, length: cursorTextStorage.length)
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineBreakMode = inputLabel.lineBreakMode
        cursorTextStorage.addAttribute(.font, value: font, range: newFullRange)
        cursorTextStorage.addAttribute(.paragraphStyle, value: paragraphStyle, range: newFullRange)

        // 레이아웃 강제 계산
        cursorLayoutManager.ensureLayout(for: cursorTextContainer)

        // ═══════════════════════════════════════════════════════════
        // CASE 1: 텍스트가 "\n"으로 끝남 → 다음 빈 줄의 맨 앞에 커서
        // ═══════════════════════════════════════════════════════════
        if text.hasSuffix("\n") {
            let lastCharRange = NSRange(location: max(0, cursorTextStorage.length - 1), length: 1)
            let glyphRange = cursorLayoutManager.glyphRange(forCharacterRange: lastCharRange, actualCharacterRange: nil)

            if glyphRange.location != NSNotFound {
                let lineRect = cursorLayoutManager.lineFragmentRect(forGlyphAt: glyphRange.location, effectiveRange: nil)
                cursorLeading?.constant = 0
                cursorTop?.constant = lineRect.origin.y + lineRect.size.height
            } else {
                cursorLeading?.constant = 0
                cursorTop?.constant = 0
            }
            return
        }

        // ═══════════════════════════════════════════════════════════
        // CASE 2: 일반 텍스트 → 마지막 글자 뒤에 커서
        // ═══════════════════════════════════════════════════════════
        let lastCharIndex = cursorTextStorage.length - 1
        guard lastCharIndex >= 0 else {
            cursorLeading?.constant = 0
            cursorTop?.constant = 0
            return
        }

        let lastCharRange = NSRange(location: lastCharIndex, length: 1)
        let glyphRange = cursorLayoutManager.glyphRange(forCharacterRange: lastCharRange, actualCharacterRange: nil)

        guard glyphRange.length > 0, glyphRange.location != NSNotFound else {
            cursorLeading?.constant = 0
            cursorTop?.constant = 0
            return
        }

        let lastGlyphIndex = glyphRange.location

        // 마지막 글리프가 속한 줄의 프레임
        let lineFragmentRect = cursorLayoutManager.lineFragmentRect(forGlyphAt: lastGlyphIndex, effectiveRange: nil)

        // 마지막 글리프의 줄 내 위치 (advance 기반 좌표)
        let glyphLocation = cursorLayoutManager.location(forGlyphAt: lastGlyphIndex)

        // X: CTFont의 advance width 사용 (ink bounds가 아닌 타이포그래피 전진 너비)
        let ctFont = font as CTFont
        var character: UniChar = (text as NSString).character(at: lastCharIndex)
        var glyph: CGGlyph = 0
        var advance = CGSize.zero

        var cursorX: CGFloat
        if CTFontGetGlyphsForCharacters(ctFont, &character, &glyph, 1) {
            CTFontGetAdvancesForGlyphs(ctFont, .horizontal, &glyph, &advance, 1)
            cursorX = glyphLocation.x + advance.width
        } else {
            // Fallback: surrogate pair 등 BMP 밖 문자 (이모지 등)
            let singleGlyphRange = NSRange(location: lastGlyphIndex, length: 1)
            let rect = cursorLayoutManager.boundingRect(forGlyphRange: singleGlyphRange, in: cursorTextContainer)
            cursorX = rect.maxX
        }

        // Y: 줄 프레임의 시작 Y
        let cursorY = lineFragmentRect.origin.y

        cursorLeading?.constant = min(cursorX, maxWidth)
        cursorTop?.constant = max(0, cursorY)
    }
}
