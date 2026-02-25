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
    private let suggestionManager = SuggestionManager()

    // MARK: - Constraints

    private var heightConstraint: NSLayoutConstraint?
    private var keyboardTopToToolbarConstraint: NSLayoutConstraint?
    private var keyboardTopToTranslationConstraint: NSLayoutConstraint?
    private let hapticFeedback = UIImpactFeedbackGenerator(style: .medium)

    // Status message
    private var statusMessageTimer: DispatchWorkItem?

    private var isAutocorrectEnabled: Bool {
        let defaults = UserDefaults(suiteName: AppConstants.appGroupIdentifier)
        if let obj = defaults?.object(forKey: AppConstants.UserDefaultsKeys.autoComplete) {
            return (obj as? Bool) ?? false
        }
        return true
    }

    // Suggestion dismiss state
    private var isSuggestionDismissedForCurrentWord = false

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
        checkAutoCapitalize()
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
            isSuggestionDismissedForCurrentWord = false
        }

        checkAutoCapitalize()
        updateSuggestions()
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
        toolbarView.onSettingsTap = { [weak self] in
            self?.openContainingApp()
        }
        toolbarView.onSuggestionTap = { [weak self] suggestion in
            self?.applySuggestion(suggestion)
        }
        toolbarView.onSuggestionDismiss = { [weak self] in
            self?.dismissSuggestions()
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
        keyboardLayoutView.onLanguageChanged = { [weak self] lang in
            self?.commitDefaultComposing()
            let code: String = (lang == .korean) ? "korean" : "english"
            AppGroupManager.shared.set(code, forKey: AppConstants.UserDefaultsKeys.keyboardLayout)
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

        if let savedLang = AppGroupManager.shared.string(forKey: AppConstants.UserDefaultsKeys.keyboardLayout) {
            let lang: KeyboardLanguage = (savedLang == "korean") ? .korean : .english
            keyboardLayoutView.setLanguage(lang)
        }
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
            toolbarView.hideSuggestions()
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
            showStatusMessage(L("keyboard.error.full_access"))
            return
        }

        guard sessionManager.canTranslate else {
            showStatusMessage(L("keyboard.error.session_limit"))
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
            isSuggestionDismissedForCurrentWord = false

        case " ":
            commitDefaultComposing()
            textDocumentProxy.insertText(" ")

        default:
            isSuggestionDismissedForCurrentWord = false
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

        checkAutoCapitalize()
        updateSuggestions()
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
                showStatusMessage(String(format: L("keyboard.error.max_chars"), AppConstants.Limits.maxCharacters))
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
            if vertical < 0 {
                moveUp()
            } else {
                moveDown()
            }
        }
    }

    /// Estimate visual line width based on screen width and current language.
    private var estimatedCharsPerLine: Int {
        let screenWidth = UIScreen.main.bounds.width
        let textWidth = screenWidth * 0.85  // ~85% of screen for typical text view margins
        let lang = keyboardLayoutView.getCurrentLanguage()
        let avgCharWidth: CGFloat = (lang == .korean) ? 17 : 9
        return max(10, Int(textWidth / avgCharWidth))
    }

    /// Move cursor up one line.
    /// Uses actual \n positions when available, falls back to estimated offset for soft-wrapped text.
    private func moveUp() {
        guard let before = textDocumentProxy.documentContextBeforeInput, !before.isEmpty else { return }

        // Find the last newline before cursor — that's the start of current line
        guard let currentLineStart = before.lastIndex(of: "\n") else {
            // No \n found — soft-wrapped text, use estimated offset
            textDocumentProxy.adjustTextPosition(byCharacterOffset: -estimatedCharsPerLine)
            return
        }

        let currentColumn = before.distance(from: before.index(after: currentLineStart), to: before.endIndex)

        // Find the previous line
        let textBeforeCurrentLine = before[before.startIndex..<currentLineStart]
        let prevLineStart: String.Index
        if let prevNewline = textBeforeCurrentLine.lastIndex(of: "\n") {
            prevLineStart = textBeforeCurrentLine.index(after: prevNewline)
        } else {
            prevLineStart = textBeforeCurrentLine.startIndex
        }

        let prevLineLength = before.distance(from: prevLineStart, to: currentLineStart)
        let targetColumn = min(currentColumn, prevLineLength)

        // Move back: current column chars + newline char + remaining chars in prev line
        let offset = -(currentColumn + 1 + (prevLineLength - targetColumn))
        textDocumentProxy.adjustTextPosition(byCharacterOffset: offset)
    }

    /// Move cursor down one line.
    /// Uses actual \n positions when available, falls back to estimated offset for soft-wrapped text.
    private func moveDown() {
        let after = textDocumentProxy.documentContextAfterInput ?? ""

        // Try \n-based accurate movement
        guard !after.isEmpty, let currentLineEnd = after.firstIndex(of: "\n") else {
            // No context, empty, or no \n — use estimated offset
            textDocumentProxy.adjustTextPosition(byCharacterOffset: estimatedCharsPerLine)
            return
        }

        // Calculate current column position
        let before = textDocumentProxy.documentContextBeforeInput ?? ""
        let currentColumn: Int
        if let lastNewline = before.lastIndex(of: "\n") {
            currentColumn = before.distance(from: before.index(after: lastNewline), to: before.endIndex)
        } else {
            currentColumn = before.count
        }

        // Find the next line's length
        let nextLineStart = after.index(after: currentLineEnd)
        let nextLineEnd: String.Index
        if let nextNewline = after[nextLineStart...].firstIndex(of: "\n") {
            nextLineEnd = nextNewline
        } else {
            nextLineEnd = after.endIndex
        }

        let nextLineLength = after.distance(from: nextLineStart, to: nextLineEnd)
        let targetColumn = min(currentColumn, nextLineLength)

        // Offset = chars remaining on current line + 1 (newline) + targetColumn
        let charsToCurrentLineEnd = after.distance(from: after.startIndex, to: currentLineEnd)
        let offset = charsToCurrentLineEnd + 1 + targetColumn
        textDocumentProxy.adjustTextPosition(byCharacterOffset: offset)
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

    // MARK: - Autocorrect Suggestions

    private func currentTypingWord() -> String? {
        guard let context = textDocumentProxy.documentContextBeforeInput else { return nil }
        let components = context.components(separatedBy: CharacterSet.whitespacesAndNewlines)
        return components.last?.isEmpty == false ? components.last : nil
    }

    private func dismissSuggestions() {
        isSuggestionDismissedForCurrentWord = true
        toolbarView.hideSuggestions()
    }

    private func updateSuggestions() {
        guard currentMode == .defaultMode, isAutocorrectEnabled else {
            toolbarView.hideSuggestions(); return
        }
        guard !isSuggestionDismissedForCurrentWord else { return }
        let currentLang = keyboardLayoutView.getCurrentLanguage()
        let isComposing = !defaultTextInputHandler.composingText.isEmpty
        let context = textDocumentProxy.documentContextBeforeInput
        let word = currentTypingWord()

        let result = suggestionManager.getSuggestions(
            context: context, currentWord: word,
            isComposing: isComposing, language: currentLang
        )
        switch result.mode {
        case .none: toolbarView.hideSuggestions()
        case .autocorrect, .prediction: toolbarView.showSuggestions(result.suggestions)
        }
    }

    private func applySuggestion(_ suggestion: String) {
        let word = currentTypingWord()
        if let word = word, !word.isEmpty {
            commitDefaultComposing()
            for _ in 0..<word.count { textDocumentProxy.deleteBackward() }
        }
        textDocumentProxy.insertText(suggestion + " ")
        toolbarView.hideSuggestions()
        checkAutoCapitalize()
        DispatchQueue.main.async { [weak self] in
            self?.updateSuggestions()
        }
    }

    // MARK: - Return Key

    private func updateReturnKeyAppearance() {
        let returnType = textDocumentProxy.returnKeyType ?? .default

        switch returnType {
        case .go:
            keyboardLayoutView.returnKeyDisplayName = L("keyboard.return.go")
            keyboardLayoutView.returnKeyIsBlue = true
        case .search:
            keyboardLayoutView.returnKeyDisplayName = L("keyboard.return.search")
            keyboardLayoutView.returnKeyIsBlue = true
        case .send:
            keyboardLayoutView.returnKeyDisplayName = L("keyboard.return.send")
            keyboardLayoutView.returnKeyIsBlue = true
        case .done:
            keyboardLayoutView.returnKeyDisplayName = L("keyboard.return.done")
            keyboardLayoutView.returnKeyIsBlue = true
        case .next:
            keyboardLayoutView.returnKeyDisplayName = L("keyboard.return.next")
            keyboardLayoutView.returnKeyIsBlue = true
        case .join:
            keyboardLayoutView.returnKeyDisplayName = L("keyboard.return.join")
            keyboardLayoutView.returnKeyIsBlue = true
        case .route:
            keyboardLayoutView.returnKeyDisplayName = L("keyboard.return.route")
            keyboardLayoutView.returnKeyIsBlue = true
        case .emergencyCall:
            keyboardLayoutView.returnKeyDisplayName = L("keyboard.return.emergency")
            keyboardLayoutView.returnKeyIsBlue = true
        case .continue:
            keyboardLayoutView.returnKeyDisplayName = L("keyboard.return.continue")
            keyboardLayoutView.returnKeyIsBlue = true
        default:
            // .default — used in text editors, messaging body, notes → newline
            keyboardLayoutView.returnKeyDisplayName = L("keyboard.return.newline")
            keyboardLayoutView.returnKeyIsBlue = false
        }
    }

    // MARK: - Open Containing App

    @objc protocol URLOpener {
        func open(_ url: URL, options: [String: Any], completionHandler: ((Bool) -> Void)?)
    }

    private func openContainingApp() {
        guard let url = URL(string: "translatorkeyboard://settings") else { return }
        var responder: UIResponder? = self
        while let r = responder {
            if let opener = r as? URLOpener {
                opener.open(url, options: [:], completionHandler: nil)
                return
            }
            responder = r.next
        }
    }

    // MARK: - Auto Capitalize

    private func checkAutoCapitalize() {
        guard AppGroupManager.shared.bool(forKey: AppConstants.UserDefaultsKeys.autoCapitalize) else { return }
        guard currentMode == .defaultMode else { return }
        guard keyboardLayoutView.getCurrentLanguage() == .english else { return }

        let shouldCapitalize: Bool
        let context = textDocumentProxy.documentContextBeforeInput

        if context == nil || context?.isEmpty == true {
            shouldCapitalize = true
        } else if let text = context,
                  text.hasSuffix(". ") || text.hasSuffix("? ") || text.hasSuffix("! ") || text.hasSuffix("\n") {
            shouldCapitalize = true
        } else {
            shouldCapitalize = false
        }

        if shouldCapitalize {
            keyboardLayoutView.setShifted(true)
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
            showStatusMessage(L("keyboard.error.timeout"))
        case .offline:
            showStatusMessage(L("keyboard.error.offline"))
        case .rateLimited:
            showStatusMessage(L("keyboard.error.rate_limited"))
        case .networkError, .serverError, .invalidResponse:
            showStatusMessage(L("keyboard.error.translate_failed"))
        }
    }

    func translationManagerDidStartTranslating(_ manager: TranslationManager) {
        toolbarView.showStatusMessage(L("keyboard.status.translating"))
    }
}
