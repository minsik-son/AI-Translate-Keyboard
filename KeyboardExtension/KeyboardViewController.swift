import UIKit

enum KeyboardMode {
    case defaultMode
    case translationMode
}

class KeyboardViewController: UIInputViewController {

    private var currentMode: KeyboardMode = .defaultMode

    // MARK: - UI Components

    private lazy var toolbarView = ToolbarView()
    private lazy var translationLanguageBar = TranslationLanguageBar()
    private lazy var translationInputView = TranslationInputView()
    private lazy var keyboardLayoutView = KeyboardLayoutView()
    private lazy var emojiKeyboardView = EmojiKeyboardView()
    private lazy var languagePickerView = LanguagePickerView()
    private var isEmojiMode = false

    // MARK: - Logic Managers

    private let textInputHandler = TextInputHandler()
    private let defaultTextInputHandler = TextInputHandler()
    private var defaultModeComposingLength: Int = 0
    private lazy var textProxyManager = TextProxyManager(textDocumentProxy: textDocumentProxy)
    private let translationManager = TranslationManager()
    private let sessionManager = SessionManager.shared

    // MARK: - Constraints

    private var heightConstraint: NSLayoutConstraint?
    private var keyboardTopToToolbarConstraint: NSLayoutConstraint?
    private var keyboardTopToTranslationConstraint: NSLayoutConstraint?
    private let hapticFeedback = UIImpactFeedbackGenerator(style: .medium)

    // Status message
    private var statusMessageTimer: DispatchWorkItem?

    // Language state
    private var sourceLanguageCode: String = "ko"
    private var targetLanguageCode: String = "en"
    private var isLanguagePickerVisible = false

    // MARK: - Layout Constants

    private struct Heights {
        static let toolbar: CGFloat = 40
        static let translationLanguageBar: CGFloat = 44
        static let translationInput: CGFloat = 44
        // Toolbar 40 + key area 270 = 310pt total.
        static let totalDefault: CGFloat = 310
        static let totalTranslation: CGFloat = 358   // langBar 44 + input 44 + key area 270
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupDelegates()
        setupCallbacks()
        switchMode(to: .defaultMode)
        restoreState()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupHeightConstraint()
        textProxyManager.updateProxy(textDocumentProxy)
        updateReturnKeyAppearance()
    }

    override func textDidChange(_ textInput: UITextInput?) {
        super.textDidChange(textInput)
        updateKeyboardAppearance()
        updateReturnKeyAppearance()

        // CRITICAL: Reset Korean composition state when text context changes
        // (e.g., after sending a message, the text field is cleared by the app)
        // Without this, leftover composing characters contaminate the next input.
        if currentMode == .defaultMode {
            defaultTextInputHandler.clear()
            defaultModeComposingLength = 0
        }
    }

    // MARK: - Height

    private func setupHeightConstraint() {
        guard heightConstraint == nil, let inputView = self.inputView else { return }
        // DO NOT set translatesAutoresizingMaskIntoConstraints = false on inputView
        // iOS system manages the keyboard extension's inputView width via autoresizing masks
        heightConstraint = inputView.heightAnchor.constraint(equalToConstant: Heights.totalDefault)
        heightConstraint?.priority = .defaultHigh
        heightConstraint?.isActive = true
    }

    private func updateHeight(for mode: KeyboardMode, animated: Bool = true) {
        let newHeight: CGFloat
        switch mode {
        case .defaultMode:
            newHeight = Heights.totalDefault
        case .translationMode:
            newHeight = Heights.totalTranslation
        }

        heightConstraint?.constant = newHeight

        if animated {
            UIView.animate(withDuration: 0.2) {
                self.inputView?.superview?.layoutIfNeeded()
            }
        }
    }

    // MARK: - Setup UI

    private func setupUI() {
        guard let inputView = self.inputView else { return }
        inputView.backgroundColor = .clear

        // Add main views — toolbar and translationLanguageBar+translationInput occupy the SAME top position
        // Only one group is visible at a time
        [toolbarView, translationLanguageBar, translationInputView, keyboardLayoutView, emojiKeyboardView].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            inputView.addSubview($0)
        }
        emojiKeyboardView.isHidden = true

        // Language picker (initially hidden, overlays everything)
        languagePickerView.translatesAutoresizingMaskIntoConstraints = false
        languagePickerView.isHidden = true
        inputView.addSubview(languagePickerView)

        NSLayoutConstraint.activate([
            // Toolbar — pinned to top
            toolbarView.topAnchor.constraint(equalTo: inputView.topAnchor),
            toolbarView.leadingAnchor.constraint(equalTo: inputView.leadingAnchor),
            toolbarView.trailingAnchor.constraint(equalTo: inputView.trailingAnchor),
            toolbarView.heightAnchor.constraint(equalToConstant: Heights.toolbar),

            // Translation Language Bar — pinned to top
            translationLanguageBar.topAnchor.constraint(equalTo: inputView.topAnchor),
            translationLanguageBar.leadingAnchor.constraint(equalTo: inputView.leadingAnchor),
            translationLanguageBar.trailingAnchor.constraint(equalTo: inputView.trailingAnchor),
            translationLanguageBar.heightAnchor.constraint(equalToConstant: Heights.translationLanguageBar),

            // Translation Input — below language bar
            translationInputView.topAnchor.constraint(equalTo: translationLanguageBar.bottomAnchor),
            translationInputView.leadingAnchor.constraint(equalTo: inputView.leadingAnchor),
            translationInputView.trailingAnchor.constraint(equalTo: inputView.trailingAnchor),
            translationInputView.heightAnchor.constraint(equalToConstant: Heights.translationInput),

            // Keyboard Layout
            keyboardLayoutView.leadingAnchor.constraint(equalTo: inputView.leadingAnchor),
            keyboardLayoutView.trailingAnchor.constraint(equalTo: inputView.trailingAnchor),
            keyboardLayoutView.bottomAnchor.constraint(equalTo: inputView.bottomAnchor),

            // Emoji Keyboard — same position as keyboard layout
            emojiKeyboardView.leadingAnchor.constraint(equalTo: inputView.leadingAnchor),
            emojiKeyboardView.trailingAnchor.constraint(equalTo: inputView.trailingAnchor),
            emojiKeyboardView.bottomAnchor.constraint(equalTo: inputView.bottomAnchor),

            // Language Picker - overlays the whole keyboard
            languagePickerView.topAnchor.constraint(equalTo: inputView.topAnchor),
            languagePickerView.leadingAnchor.constraint(equalTo: inputView.leadingAnchor),
            languagePickerView.trailingAnchor.constraint(equalTo: inputView.trailingAnchor),
            languagePickerView.bottomAnchor.constraint(equalTo: inputView.bottomAnchor),
        ])

        // Keyboard top switches between toolbar bottom and translation input bottom
        keyboardTopToToolbarConstraint = keyboardLayoutView.topAnchor.constraint(equalTo: toolbarView.bottomAnchor)
        keyboardTopToTranslationConstraint = keyboardLayoutView.topAnchor.constraint(equalTo: translationInputView.bottomAnchor)
        keyboardTopToToolbarConstraint?.isActive = true

        // Emoji keyboard top follows toolbar
        emojiKeyboardView.topAnchor.constraint(equalTo: toolbarView.bottomAnchor).isActive = true

        // Initially hide translation views
        translationLanguageBar.isHidden = true
        translationInputView.isHidden = true
    }

    // MARK: - Delegates

    private func setupDelegates() {
        textInputHandler.delegate = self
        translationManager.delegate = self
    }

    // MARK: - Callbacks

    private func setupCallbacks() {
        // Toolbar — default mode only
        toolbarView.onTranslateToggle = { [weak self] in
            self?.toggleTranslationMode()
        }
        toolbarView.onEmojiTap = { [weak self] emoji in
            self?.textDocumentProxy.insertText(emoji)
        }
        toolbarView.onEmojiKeyboardToggle = { [weak self] in
            self?.toggleEmojiKeyboard()
        }

        // Translation Input — close button
        translationInputView.onCloseTranslation = { [weak self] in
            self?.exitTranslationMode()
        }

        // Translation Language Bar
        translationLanguageBar.onSourceTap = { [weak self] in
            self?.showLanguagePicker(initialTab: .source)
        }
        translationLanguageBar.onTargetTap = { [weak self] in
            self?.showLanguagePicker(initialTab: .target)
        }
        translationLanguageBar.onSwapTap = { [weak self] in
            self?.swapLanguages()
        }

        // Keyboard layout
        keyboardLayoutView.onKeyTap = { [weak self] key in
            self?.handleKeyTap(key)
        }
        keyboardLayoutView.onLanguageChanged = { [weak self] _ in
            self?.commitDefaultComposing()
        }
        keyboardLayoutView.onCursorMove = { [weak self] horizontal, vertical in
            self?.handleCursorMove(horizontal: horizontal, vertical: vertical)
        }
        keyboardLayoutView.onTrackpadModeChanged = { [weak self] active in
            if active {
                // Commit any in-progress Korean composition before moving cursor
                self?.commitDefaultComposing()
            }
        }

        // Emoji keyboard
        emojiKeyboardView.onEmojiSelected = { [weak self] emoji in
            guard let self = self else { return }
            if emoji == KeyboardLayoutView.backKey {
                self.textDocumentProxy.deleteBackward()
            } else {
                self.textDocumentProxy.insertText(emoji)
            }
        }
        emojiKeyboardView.onBackToKeyboard = { [weak self] in
            self?.hideEmojiKeyboard()
        }

        // Language picker
        languagePickerView.onLanguageSelected = { [weak self] tab, language in
            self?.handleLanguageSelection(tab: tab, language: language)
        }
        languagePickerView.onDismiss = { [weak self] in
            self?.hideLanguagePicker()
        }
    }

    // MARK: - State Restoration

    private func restoreState() {
        if let sourceLang = AppGroupManager.shared.string(forKey: AppConstants.UserDefaultsKeys.sourceLanguage) {
            sourceLanguageCode = sourceLang
        }
        if let targetLang = AppGroupManager.shared.string(forKey: AppConstants.UserDefaultsKeys.targetLanguage) {
            targetLanguageCode = targetLang
        }
        translationManager.setLanguages(source: sourceLanguageCode, target: targetLanguageCode)
        updateLanguageLabels()
    }

    // MARK: - Mode Switching

    func switchMode(to mode: KeyboardMode) {
        currentMode = mode
        hideEmojiKeyboard()

        switch mode {
        case .defaultMode:
            // Show toolbar, hide translation views
            toolbarView.isHidden = false
            translationLanguageBar.isHidden = true
            translationInputView.isHidden = true
            translationManager.cancelPending()
            textProxyManager.reset()
            keyboardTopToTranslationConstraint?.isActive = false
            keyboardTopToToolbarConstraint?.isActive = true

        case .translationMode:
            // Hide toolbar, show translation language bar + input
            toolbarView.isHidden = true
            translationLanguageBar.isHidden = false
            translationInputView.isHidden = false
            textInputHandler.clear()
            translationInputView.clear()
            keyboardTopToToolbarConstraint?.isActive = false
            keyboardTopToTranslationConstraint?.isActive = true
        }

        updateHeight(for: mode)
    }

    private func toggleTranslationMode() {
        switch currentMode {
        case .defaultMode:
            enterTranslationMode()
        case .translationMode:
            exitTranslationMode()
        }
    }

    private func enterTranslationMode() {
        commitDefaultComposing()

        guard hasFullAccess() else {
            showStatusMessage("전체 접근을 허용해주세요")
            return
        }

        guard sessionManager.canTranslate else {
            showStatusMessage("오늘의 번역 횟수를 모두 사용했습니다")
            return
        }

        sessionManager.useSession()
        switchMode(to: .translationMode)
    }

    private func exitTranslationMode() {
        textInputHandler.commitComposing()
        translationManager.cancelPending()
        textProxyManager.reset()
        defaultTextInputHandler.clear()
        defaultModeComposingLength = 0
        hideLanguagePicker()
        switchMode(to: .defaultMode)
    }

    // MARK: - Emoji Keyboard

    private func toggleEmojiKeyboard() {
        if isEmojiMode { hideEmojiKeyboard() } else { showEmojiKeyboard() }
    }

    private func showEmojiKeyboard() {
        isEmojiMode = true
        keyboardLayoutView.isHidden = true
        emojiKeyboardView.isHidden = false
    }

    private func hideEmojiKeyboard() {
        isEmojiMode = false
        emojiKeyboardView.isHidden = true
        keyboardLayoutView.isHidden = false
    }

    private func hasFullAccess() -> Bool {
        if #available(iOSApplicationExtension 11.0, *) {
            return self.hasFullAccess
        }
        return false
    }

    // MARK: - Language Picker

    private func showLanguagePicker(initialTab: LanguagePickerView.Tab = .source) {
        guard !isLanguagePickerVisible else {
            hideLanguagePicker()
            return
        }
        isLanguagePickerVisible = true
        languagePickerView.configure(
            sourceCode: sourceLanguageCode,
            targetCode: targetLanguageCode,
            initialTab: initialTab
        )
        languagePickerView.isHidden = false
        languagePickerView.alpha = 0
        UIView.animate(withDuration: 0.2) {
            self.languagePickerView.alpha = 1
        }
    }

    private func hideLanguagePicker() {
        guard isLanguagePickerVisible else { return }
        isLanguagePickerVisible = false
        UIView.animate(withDuration: 0.15, animations: {
            self.languagePickerView.alpha = 0
        }) { _ in
            self.languagePickerView.isHidden = true
        }
    }

    private func handleLanguageSelection(tab: LanguagePickerView.Tab, language: LanguageItem) {
        switch tab {
        case .source:
            sourceLanguageCode = language.code
            AppGroupManager.shared.set(language.code, forKey: AppConstants.UserDefaultsKeys.sourceLanguage)
        case .target:
            targetLanguageCode = language.code
            AppGroupManager.shared.set(language.code, forKey: AppConstants.UserDefaultsKeys.targetLanguage)
        }

        translationManager.setLanguages(source: sourceLanguageCode, target: targetLanguageCode)
        updateLanguageLabels()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            self?.hideLanguagePicker()
        }
    }

    private func swapLanguages() {
        let temp = sourceLanguageCode
        sourceLanguageCode = targetLanguageCode
        targetLanguageCode = temp

        AppGroupManager.shared.set(sourceLanguageCode, forKey: AppConstants.UserDefaultsKeys.sourceLanguage)
        AppGroupManager.shared.set(targetLanguageCode, forKey: AppConstants.UserDefaultsKeys.targetLanguage)
        translationManager.setLanguages(source: sourceLanguageCode, target: targetLanguageCode)
        updateLanguageLabels()
    }

    private func updateLanguageLabels() {
        let sourceName = languageDisplayName(for: sourceLanguageCode)
        let targetName = languageDisplayName(for: targetLanguageCode)
        translationLanguageBar.updateLanguageNames(source: sourceName, target: targetName)
    }

    private func languageDisplayName(for code: String) -> String {
        return LanguagePickerView.supportedLanguages.first(where: { $0.code == code })?.displayName ?? code
    }

    // MARK: - Key Handling

    private func handleKeyTap(_ key: String) {
        switch currentMode {
        case .defaultMode:
            handleDefaultModeKey(key)
        case .translationMode:
            handleTranslationModeKey(key)
        }
    }

    private func handleDefaultModeKey(_ key: String) {
        switch key {
        case KeyboardLayoutView.backKey:
            if !defaultTextInputHandler.composingText.isEmpty {
                textDocumentProxy.deleteBackward()
                defaultModeComposingLength = 0
                defaultTextInputHandler.handleBackspace()
                if !defaultTextInputHandler.composingText.isEmpty {
                    textDocumentProxy.insertText(defaultTextInputHandler.composingText)
                    defaultModeComposingLength = 1
                }
            } else {
                textDocumentProxy.deleteBackward()
            }

        case KeyboardLayoutView.returnKey:
            commitDefaultComposing()
            textDocumentProxy.insertText("\n")

        case " ":
            commitDefaultComposing()
            textDocumentProxy.insertText(" ")

        default:
            let isKorean = isKoreanJamo(key)
            if isKorean, let char = key.first {
                if defaultModeComposingLength > 0 {
                    textDocumentProxy.deleteBackward()
                    defaultModeComposingLength = 0
                }

                let oldBufferCount = defaultTextInputHandler.buffer.count
                defaultTextInputHandler.handleKey(char, isKorean: true)

                let newBufferCount = defaultTextInputHandler.buffer.count
                if newBufferCount > oldBufferCount {
                    let committedChars = String(defaultTextInputHandler.buffer.suffix(newBufferCount - oldBufferCount))
                    textDocumentProxy.insertText(committedChars)
                    defaultTextInputHandler.resetBuffer()
                }

                if !defaultTextInputHandler.composingText.isEmpty {
                    textDocumentProxy.insertText(defaultTextInputHandler.composingText)
                    defaultModeComposingLength = 1
                }
            } else {
                commitDefaultComposing()
                textDocumentProxy.insertText(key)
            }
        }
    }

    private func commitDefaultComposing() {
        if defaultModeComposingLength > 0 {
            defaultTextInputHandler.commitComposing()
            defaultTextInputHandler.resetBuffer()
            defaultModeComposingLength = 0
        }
    }

    private func handleTranslationModeKey(_ key: String) {
        switch key {
        case KeyboardLayoutView.backKey:
            textInputHandler.handleBackspace()

        case KeyboardLayoutView.returnKey:
            textInputHandler.commitComposing()

        case " ":
            textInputHandler.handleSpace()

        default:
            if textInputHandler.totalLength >= AppConstants.Limits.maxCharacters {
                hapticFeedback.impactOccurred()
                showStatusMessage("최대 \(AppConstants.Limits.maxCharacters)자까지 입력 가능합니다")
                return
            }

            let isKorean = isKoreanJamo(key)
            if let char = key.first {
                textInputHandler.handleKey(char, isKorean: isKorean)
            }
        }
    }

    private func isKoreanJamo(_ key: String) -> Bool {
        guard let scalar = key.unicodeScalars.first else { return false }
        return (0x3131...0x3163).contains(scalar.value)
    }

    // MARK: - Trackpad Cursor Movement

    private func handleCursorMove(horizontal: Int, vertical: Int) {
        if horizontal != 0 {
            textDocumentProxy.adjustTextPosition(byCharacterOffset: horizontal)
        }
        if vertical != 0 {
            moveCursorVertically(by: vertical)
        }
    }

    private func moveCursorVertically(by direction: Int) {
        if direction < 0 {
            // Move up
            guard let before = textDocumentProxy.documentContextBeforeInput else { return }
            let lines = before.components(separatedBy: "\n")
            guard lines.count >= 2 else { return }
            let currentLine = lines.last!
            let previousLine = lines[lines.count - 2]
            let col = currentLine.count
            let targetCol = min(col, previousLine.count)
            let moveBack = currentLine.count + 1 + (previousLine.count - targetCol)
            textDocumentProxy.adjustTextPosition(byCharacterOffset: -moveBack)
        } else {
            // Move down
            guard let after = textDocumentProxy.documentContextAfterInput,
                  let before = textDocumentProxy.documentContextBeforeInput else { return }
            let currentLine = before.components(separatedBy: "\n").last ?? ""
            let col = currentLine.count
            let afterLines = after.components(separatedBy: "\n")
            guard afterLines.count >= 2 else { return }
            let nextLine = afterLines[1]
            let remainingCurrentLine = afterLines[0].count
            let targetCol = min(col, nextLine.count)
            let moveForward = remainingCurrentLine + 1 + targetCol
            textDocumentProxy.adjustTextPosition(byCharacterOffset: moveForward)
        }
    }

    // MARK: - Status Messages

    private func showStatusMessage(_ message: String) {
        statusMessageTimer?.cancel()
        toolbarView.showStatusMessage(message)

        let workItem = DispatchWorkItem { [weak self] in
            self?.toolbarView.hideStatusMessage()
        }
        statusMessageTimer = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0, execute: workItem)
    }

    // MARK: - Return Key

    private func updateReturnKeyAppearance() {
        let returnType = textDocumentProxy.returnKeyType ?? .default

        switch returnType {
        case .go:
            keyboardLayoutView.returnKeyDisplayName = "이동"
            keyboardLayoutView.returnKeyIsBlue = true
        case .search:
            keyboardLayoutView.returnKeyDisplayName = "검색"
            keyboardLayoutView.returnKeyIsBlue = true
        case .send:
            keyboardLayoutView.returnKeyDisplayName = "전송"
            keyboardLayoutView.returnKeyIsBlue = true
        case .done:
            keyboardLayoutView.returnKeyDisplayName = "완료"
            keyboardLayoutView.returnKeyIsBlue = true
        case .next:
            keyboardLayoutView.returnKeyDisplayName = "다음"
            keyboardLayoutView.returnKeyIsBlue = true
        case .join:
            keyboardLayoutView.returnKeyDisplayName = "가입"
            keyboardLayoutView.returnKeyIsBlue = true
        case .route:
            keyboardLayoutView.returnKeyDisplayName = "경로"
            keyboardLayoutView.returnKeyIsBlue = true
        case .emergencyCall:
            keyboardLayoutView.returnKeyDisplayName = "긴급"
            keyboardLayoutView.returnKeyIsBlue = true
        case .continue:
            keyboardLayoutView.returnKeyDisplayName = "계속"
            keyboardLayoutView.returnKeyIsBlue = true
        default:
            // .default — used in text editors, messaging body, notes → newline
            keyboardLayoutView.returnKeyDisplayName = "줄바꿈"
            keyboardLayoutView.returnKeyIsBlue = false
        }
    }

    // MARK: - Appearance

    private func updateKeyboardAppearance() {
        let isDark = textDocumentProxy.keyboardAppearance == .dark
        keyboardLayoutView.updateAppearance(isDark: isDark)
        emojiKeyboardView.updateAppearance(isDark: isDark)
        toolbarView.updateAppearance(isDark: isDark)
        translationLanguageBar.updateAppearance(isDark: isDark)
        translationInputView.updateAppearance(isDark: isDark)
    }
}

// MARK: - TextInputHandlerDelegate

extension KeyboardViewController: TextInputHandlerDelegate {
    func textInputHandler(_ handler: TextInputHandler, didUpdateBuffer text: String) {
        let displayText = handler.fullText
        translationInputView.setDisplayText(displayText)
        translationManager.requestTranslation(text: displayText)
    }

    func textInputHandler(_ handler: TextInputHandler, didUpdateComposing text: String) {
        let displayText = handler.fullText
        translationInputView.setDisplayText(displayText)
        translationManager.requestTranslation(text: displayText)
    }
}

// MARK: - TranslationManagerDelegate

extension KeyboardViewController: TranslationManagerDelegate {
    func translationManager(_ manager: TranslationManager, didTranslate text: String, from source: String, to target: String) {
        textProxyManager.updateProxy(textDocumentProxy)
        textProxyManager.replaceText(with: text)
    }

    func translationManager(_ manager: TranslationManager, didFailWithError error: TranslationError) {
        switch error {
        case .timeout:
            showStatusMessage("번역 시간 초과")
        case .offline:
            showStatusMessage("오프라인입니다")
        case .rateLimited:
            showStatusMessage("잠시 후 다시 시도해주세요")
        case .networkError, .serverError, .invalidResponse:
            showStatusMessage("번역 실패")
        }
    }

    func translationManagerDidStartTranslating(_ manager: TranslationManager) {
        toolbarView.showStatusMessage("번역 중...")
    }
}
