import UIKit

enum KeyboardLanguage: String, CaseIterable {
    case english = "en"
    case korean = "ko"
    case spanish = "es"
    case french = "fr"
    case german = "de"
    case italian = "it"
    case russian = "ru"

    var displayName: String {
        switch self {
        case .english: return "English"
        case .korean: return "한국어"
        case .spanish: return "Español"
        case .french: return "Français"
        case .german: return "Deutsch"
        case .italian: return "Italiano"
        case .russian: return "Русский"
        }
    }

    var shortLabel: String {
        switch self {
        case .english: return "A"
        case .korean: return "한"
        case .spanish: return "ES"
        case .french: return "FR"
        case .german: return "DE"
        case .italian: return "IT"
        case .russian: return "RU"
        }
    }

    var isLatinBased: Bool {
        return self != .korean && self != .russian
    }
}

enum KeyboardPage {
    case letters
    case symbols1
    case symbols2
}

// MARK: - KeyboardLayoutView

class KeyboardLayoutView: UIView {

    var onKeyTap: ((String) -> Void)?
    var onLanguageChanged: ((KeyboardLanguage) -> Void)?
    var onCursorMove: ((Int, Int) -> Void)?  // (horizontal, vertical)
    var onTrackpadModeChanged: ((Bool) -> Void)?

    // Return key appearance — set by controller
    var returnKeyDisplayName: String = L("keyboard.return.go") {
        didSet { if oldValue != returnKeyDisplayName { buildKeyboard() } }
    }
    var returnKeyIsBlue: Bool = true {
        didSet { if oldValue != returnKeyIsBlue { buildKeyboard() } }
    }

    // Mode-aware return key override (Proposal 03)
    private var returnKeyModeOverride: KeyboardMode?
    private var returnKeyHasText: Bool = true

    var showNumberRow: Bool = true {
        didSet { if oldValue != showNumberRow { buildKeyboard() } }
    }

    var pairedLanguage: KeyboardLanguage = .korean {
        didSet { if oldValue != pairedLanguage { buildKeyboard() } }
    }

    private var currentLanguage: KeyboardLanguage = .english
    private var currentPage: KeyboardPage = .letters
    private var isShifted = false
    private var isDark = false
    private var pendingBuildWork: DispatchWorkItem?
    private var customTheme: KeyboardTheme?
    private var gradientLayer: CAGradientLayer?
    private var patternImageView: UIImageView?
    private var woodTileImageView: UIImageView?

    // Backspace long-press repeat
    private var backspaceTimer: Timer?
    private var backspaceRepeatTimer: Timer?

    // Space bar trackpad cursor mode
    private var isTrackpadMode = false
    private var trackpadLastX: CGFloat = 0
    private var trackpadLastY: CGFloat = 0
    private var trackpadAccumulator: CGFloat = 0
    private var trackpadAccumulatorY: CGFloat = 0
    private let trackpadSensitivity: CGFloat = 8   // points per character move
    private let trackpadSensitivityY: CGFloat = 20  // points per line move (higher = slower)
    private let hapticGenerator = UIImpactFeedbackGenerator(style: .light)

    // Axis locking for trackpad
    private enum TrackpadAxis { case none, horizontal, vertical }
    private var lockedAxis: TrackpadAxis = .none
    private var trackpadStartX: CGFloat = 0
    private var trackpadStartY: CGFloat = 0
    private let axisLockThreshold: CGFloat = 10
    private let axisUnlockThreshold: CGFloat = 20

    // CADisplayLink for smooth cursor movement
    private var displayLink: CADisplayLink?

    // Trackpad haptic (lighter than key tap)
    private let selectionHaptic = UISelectionFeedbackGenerator()

    // MARK: - Layout Constants

    // Total = 310pt (toolbar 40 + key area 270).
    // Key area 270pt: topInset(4) + numRow(40) + gap(8) + 3×keyH(46) + 3×rowGap(10) + bottomRow(46) + bottomInset(4)
    private struct Layout {
        static let keyHeight: CGFloat = 46
        static let numberRowHeight: CGFloat = 40
        static let keySpacingH: CGFloat = 6
        static let keySpacingV: CGFloat = 10
        static let numberRowSpacingV: CGFloat = 8
        static let sideInset: CGFloat = 3
        static let topInset: CGFloat = 4
        static let bottomInset: CGFloat = 4
        static let cornerRadius: CGFloat = 5
        static let letterFontSize: CGFloat = 22
        static let specialFontSize: CGFloat = 15
        static let returnFontSize: CGFloat = 15
        static let spaceFontSize: CGFloat = 14
        static let symbolFontSize: CGFloat = 20
    }

    // MARK: - Key Identifiers

    static let shiftKey       = "\u{21E7}"    // ⇧
    static let backKey        = "\u{232B}"    // ⌫
    static let returnKey      = "\u{23CE}"    // ⏎
    static let langKR         = "\u{D55C}"    // 한
    static let langEN         = "EN"
    static let symbolKey      = "123"         // Switch to symbols
    static let moreSymKey     = "#+="         // Switch to more symbols
    static let abcKey         = "ABC"         // Switch back to letters
    static let symbolToggleKey = "+=♥"       // Switch to symbols (bottom row)
    static let globeLangKey   = "__GLOBE_A__" // Globe + language switch

    // MARK: - Key Layouts

    // ── Letter layouts ──

    private static let numberRow: [String] = ["1", "2", "3", "4", "5", "6", "7", "8", "9", "0"]

    private static let englishRows: [[String]] = [
        ["q", "w", "e", "r", "t", "y", "u", "i", "o", "p"],
        ["a", "s", "d", "f", "g", "h", "j", "k", "l"],
        ["\u{21E7}", "z", "x", "c", "v", "b", "n", "m", "\u{232B}"],
        ["+=♥", "__GLOBE_A__", " ", ".", "\u{23CE}"]
    ]

    private static let englishShiftRows: [[String]] = [
        ["Q", "W", "E", "R", "T", "Y", "U", "I", "O", "P"],
        ["A", "S", "D", "F", "G", "H", "J", "K", "L"],
        ["\u{21E7}", "Z", "X", "C", "V", "B", "N", "M", "\u{232B}"],
        ["+=♥", "__GLOBE_A__", " ", ".", "\u{23CE}"]
    ]

    private static let koreanRows: [[String]] = [
        ["\u{3142}", "\u{3148}", "\u{3137}", "\u{3131}", "\u{3145}",
         "\u{315B}", "\u{3155}", "\u{3151}", "\u{3150}", "\u{3154}"],
        ["\u{3141}", "\u{3134}", "\u{3147}", "\u{3139}", "\u{314E}",
         "\u{3157}", "\u{3153}", "\u{314F}", "\u{3163}"],
        ["\u{21E7}", "\u{314B}", "\u{314C}", "\u{314A}", "\u{314D}",
         "\u{3160}", "\u{315C}", "\u{3161}", "\u{232B}"],
        ["+=♥", "__GLOBE_A__", " ", ".", "\u{23CE}"]
    ]

    private static let koreanShiftRows: [[String]] = [
        ["\u{3143}", "\u{3149}", "\u{3138}", "\u{3132}", "\u{3146}",
         "\u{315B}", "\u{3155}", "\u{3151}", "\u{3152}", "\u{3156}"],
        ["\u{3141}", "\u{3134}", "\u{3147}", "\u{3139}", "\u{314E}",
         "\u{3157}", "\u{3153}", "\u{314F}", "\u{3163}"],
        ["\u{21E7}", "\u{314B}", "\u{314C}", "\u{314A}", "\u{314D}",
         "\u{3160}", "\u{315C}", "\u{3161}", "\u{232B}"],
        ["+=♥", "__GLOBE_A__", " ", ".", "\u{23CE}"]
    ]

    // ── Russian ЙЦУКЕН layouts ──

    private static let russianRows: [[String]] = [
        ["й", "ц", "у", "к", "е", "н", "г", "ш", "щ", "з", "х"],
        ["ф", "ы", "в", "а", "п", "р", "о", "л", "д", "ж", "э"],
        ["\u{21E7}", "я", "ч", "с", "м", "и", "т", "ь", "б", "ю", "\u{232B}"],
        ["+=♥", "__GLOBE_A__", " ", ".", "\u{23CE}"]
    ]

    private static let russianShiftRows: [[String]] = [
        ["Й", "Ц", "У", "К", "Е", "Н", "Г", "Ш", "Щ", "З", "Х"],
        ["Ф", "Ы", "В", "А", "П", "Р", "О", "Л", "Д", "Ж", "Э"],
        ["\u{21E7}", "Я", "Ч", "С", "М", "И", "Т", "Ь", "Б", "Ю", "\u{232B}"],
        ["+=♥", "__GLOBE_A__", " ", ".", "\u{23CE}"]
    ]

    // ── Symbol layouts ──

    private static let symbolRows1: [[String]] = [
        ["$", "€", "£", "¥", "¢", "~", "…", "°", "※", "•"],
        ["-", "/", ":", ";", "(", ")", "₩", "&", "@", "\""],
        ["#+=", ".", ",", "?", "!", "'", "\u{232B}"],
        ["ABC", "__GLOBE_A__", " ", ".", "\u{23CE}"]
    ]

    private static let symbolRows2: [[String]] = [
        ["[", "]", "{", "}", "#", "%", "^", "*", "+", "="],
        ["_", "\\", "|", "<", ">", "«", "»", "§", "©", "®"],
        ["123", ".", ",", "?", "!", "'", "\u{232B}"],
        ["ABC", "__GLOBE_A__", " ", ".", "\u{23CE}"]
    ]

    // ── Special keys set ──

    // Space " " and period "." are NOT special — they render WHITE like letter keys.
    private static let specialKeys: Set<String> = [
        "\u{21E7}", "\u{232B}", "\u{23CE}",
        "\u{D55C}", "EN",
        "123", "#+=", "ABC",
        "+=♥", "__GLOBE_A__"
    ]

    // MARK: - Container

    private let keyboardContainer: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private var allKeyButtons: [UIButton] = []
    private var isRebuilding = false

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupContainer()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupContainer() {
        // Enable multi-touch so rapid taps with alternating fingers are never dropped
        isMultipleTouchEnabled = true
        keyboardContainer.isUserInteractionEnabled = false  // touches pass through to self

        addSubview(keyboardContainer)
        NSLayoutConstraint.activate([
            keyboardContainer.topAnchor.constraint(equalTo: topAnchor),
            keyboardContainer.leadingAnchor.constraint(equalTo: leadingAnchor),
            keyboardContainer.trailingAnchor.constraint(equalTo: trailingAnchor),
            keyboardContainer.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
        buildKeyboard()
    }

    // MARK: - Current Layout

    private func currentRows() -> [[String]] {
        switch currentPage {
        case .letters:
            let letterRows: [[String]]
            switch currentLanguage {
            case .korean:
                letterRows = isShifted ? Self.koreanShiftRows : Self.koreanRows
            case .russian:
                letterRows = isShifted ? Self.russianShiftRows : Self.russianRows
            default:
                // English, Spanish, French, German, Italian all use QWERTY
                letterRows = isShifted ? Self.englishShiftRows : Self.englishRows
            }
            return showNumberRow ? [Self.numberRow] + letterRows : letterRows
        case .symbols1:
            return showNumberRow ? [Self.numberRow] + Self.symbolRows1 : Self.symbolRows1
        case .symbols2:
            return showNumberRow ? [Self.numberRow] + Self.symbolRows2 : Self.symbolRows2
        }
    }

    /// Number of keys in the first letter row — used as reference width for mixed row keys.
    /// English/Korean = 10, Russian = 11.
    private var referenceKeyCount: CGFloat {
        let rows = currentRows()
        let letterRowIndex = showNumberRow ? 1 : 0
        guard letterRowIndex < rows.count else { return 10 }
        return CGFloat(rows[letterRowIndex].count)
    }

    // MARK: - Build Keyboard

    private func scheduleBuildKeyboard(delay: TimeInterval = 0.08) {
        pendingBuildWork?.cancel()
        let work = DispatchWorkItem { [weak self] in
            self?.buildKeyboard()
            self?.pendingBuildWork = nil
        }
        pendingBuildWork = work
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: work)
    }

    private func buildKeyboard() {
        guard !isTrackpadMode else { return }  // 트랙패드 중 재빌드 방지
        // 예약된 build가 있으면 취소 (직접 호출 시 중복 방지)
        pendingBuildWork?.cancel()
        pendingBuildWork = nil
        isRebuilding = true
        keyboardContainer.subviews.forEach { $0.removeFromSuperview() }
        allKeyButtons.removeAll()

        let rows = currentRows()
        let totalRows = rows.count
        let isNumberRow = showNumberRow
        var previousRowView: UIView?

        for (rowIndex, rowKeys) in rows.enumerated() {
            let rowView = buildRow(keys: rowKeys, rowIndex: rowIndex, totalRows: totalRows)
            rowView.translatesAutoresizingMaskIntoConstraints = false
            keyboardContainer.addSubview(rowView)

            let topAnchorRef: NSLayoutYAxisAnchor
            let topConstant: CGFloat

            if let prev = previousRowView {
                topAnchorRef = prev.bottomAnchor
                // Smaller gap after number row
                topConstant = (rowIndex == 1 && isNumberRow) ? Layout.numberRowSpacingV : Layout.keySpacingV
            } else {
                topAnchorRef = keyboardContainer.topAnchor
                topConstant = Layout.topInset
            }

            // Number row (rowIndex 0 in letters page) uses shorter height
            let rowHeight: CGFloat = (rowIndex == 0 && isNumberRow) ? Layout.numberRowHeight : Layout.keyHeight

            NSLayoutConstraint.activate([
                rowView.topAnchor.constraint(equalTo: topAnchorRef, constant: topConstant),
                rowView.leadingAnchor.constraint(equalTo: keyboardContainer.leadingAnchor, constant: Layout.sideInset),
                rowView.trailingAnchor.constraint(equalTo: keyboardContainer.trailingAnchor, constant: -Layout.sideInset),
                rowView.heightAnchor.constraint(equalToConstant: rowHeight),
            ])

            previousRowView = rowView
        }

        if let lastRow = previousRowView {
            lastRow.bottomAnchor.constraint(equalTo: keyboardContainer.bottomAnchor, constant: -Layout.bottomInset).isActive = true
        }

        keyboardContainer.layoutIfNeeded()
        isRebuilding = false
    }

    private func buildRow(keys: [String], rowIndex: Int, totalRows: Int) -> UIView {
        let container = UIView()

        if rowIndex == totalRows - 1 {
            buildBottomRow(container: container, keys: keys, rowIndex: rowIndex)
        } else if rowIndex == totalRows - 2 {
            buildMixedRow(container: container, keys: keys, rowIndex: rowIndex)
        } else {
            buildEqualRow(container: container, keys: keys, rowIndex: rowIndex)
        }

        return container
    }

    // MARK: - Row 0 & 1: Equal width keys

    private func buildEqualRow(container: UIView, keys: [String], rowIndex: Int) {
        // In letters page: indent rows with fewer keys than the reference row (first letter row).
        // English/Korean: row 2 has 9 keys vs 10 → indent. Russian: rows 1,2 both 11 → no indent.
        let refCount = Int(referenceKeyCount)
        let needsIndent = (keys.count < refCount && currentPage == .letters && rowIndex > (showNumberRow ? 0 : -1))

        var previousButton: UIButton?
        let firstButton = createKeyButton(keys[0], rowIndex: rowIndex)

        for (i, key) in keys.enumerated() {
            let btn = (i == 0) ? firstButton : createKeyButton(key, rowIndex: rowIndex)
            container.addSubview(btn)

            btn.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                btn.topAnchor.constraint(equalTo: container.topAnchor),
                btn.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            ])

            if let prev = previousButton {
                btn.leadingAnchor.constraint(equalTo: prev.trailingAnchor, constant: Layout.keySpacingH).isActive = true
                btn.widthAnchor.constraint(equalTo: firstButton.widthAnchor).isActive = true
            } else {
                let indent: CGFloat = needsIndent ? 18 : 0
                btn.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: indent).isActive = true
            }

            previousButton = btn
        }

        if let last = previousButton {
            let indent: CGFloat = needsIndent ? 18 : 0
            last.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -indent).isActive = true
        }
    }

    // MARK: - Row 2: Mixed row (shift/mode + letters + backspace)

    private func buildMixedRow(container: UIView, keys: [String], rowIndex: Int) {
        let wideKeyWidth: CGFloat = 42  // Shift/backspace base width

        // Letters page: match letter key widths to 10-key row using multiplier
        if currentPage == .letters {
            var leftWideBtn: UIButton?
            var rightWideBtn: UIButton?
            var letterButtons: [UIButton] = []

            for key in keys {
                let btn = createKeyButton(key, rowIndex: rowIndex)
                btn.translatesAutoresizingMaskIntoConstraints = false
                container.addSubview(btn)

                NSLayoutConstraint.activate([
                    btn.topAnchor.constraint(equalTo: container.topAnchor),
                    btn.bottomAnchor.constraint(equalTo: container.bottomAnchor),
                ])

                if key == Self.shiftKey || key == Self.moreSymKey || key == Self.symbolKey {
                    leftWideBtn = btn
                } else if key == Self.backKey {
                    rightWideBtn = btn
                } else {
                    letterButtons.append(btn)
                }
            }

            guard let shiftBtn = leftWideBtn, let backspaceBtn = rightWideBtn else { return }

            // Each letter key width matches keys in the reference row above
            let keySpacing = Layout.keySpacingH
            let n = referenceKeyCount
            for btn in letterButtons {
                btn.widthAnchor.constraint(
                    equalTo: container.widthAnchor,
                    multiplier: 1.0 / n,
                    constant: -(n - 1) * keySpacing / n
                ).isActive = true
            }

            // Invisible spacer views to distribute leftover space evenly
            let spacerLeft = UIView()
            spacerLeft.translatesAutoresizingMaskIntoConstraints = false
            spacerLeft.isUserInteractionEnabled = false
            container.addSubview(spacerLeft)

            let spacerRight = UIView()
            spacerRight.translatesAutoresizingMaskIntoConstraints = false
            spacerRight.isUserInteractionEnabled = false
            container.addSubview(spacerRight)

            // Spacers are zero-height, just used for width calculation
            NSLayoutConstraint.activate([
                spacerLeft.topAnchor.constraint(equalTo: container.topAnchor),
                spacerLeft.heightAnchor.constraint(equalToConstant: 0),
                spacerRight.topAnchor.constraint(equalTo: container.topAnchor),
                spacerRight.heightAnchor.constraint(equalToConstant: 0),
            ])

            // Layout: shift | spacerLeft | letterKeys | spacerRight | backspace
            shiftBtn.leadingAnchor.constraint(equalTo: container.leadingAnchor).isActive = true
            spacerLeft.leadingAnchor.constraint(equalTo: shiftBtn.trailingAnchor).isActive = true

            // First letter key after left spacer
            if let firstLetter = letterButtons.first {
                firstLetter.leadingAnchor.constraint(equalTo: spacerLeft.trailingAnchor, constant: Layout.keySpacingH).isActive = true
            }

            // Chain letter keys
            for i in 1..<letterButtons.count {
                letterButtons[i].leadingAnchor.constraint(equalTo: letterButtons[i-1].trailingAnchor, constant: Layout.keySpacingH).isActive = true
            }

            // Last letter key to right spacer
            if let lastLetter = letterButtons.last {
                spacerRight.leadingAnchor.constraint(equalTo: lastLetter.trailingAnchor, constant: Layout.keySpacingH).isActive = true
            }

            backspaceBtn.leadingAnchor.constraint(equalTo: spacerRight.trailingAnchor).isActive = true
            backspaceBtn.trailingAnchor.constraint(equalTo: container.trailingAnchor).isActive = true

            // shift.width = wideKeyWidth + spacerLeft.width, backspace.width = wideKeyWidth + spacerRight.width
            shiftBtn.widthAnchor.constraint(equalTo: spacerLeft.widthAnchor, constant: wideKeyWidth).isActive = true
            backspaceBtn.widthAnchor.constraint(equalTo: spacerRight.widthAnchor, constant: wideKeyWidth).isActive = true

            // Equal spacers → even distribution of leftover space
            spacerLeft.widthAnchor.constraint(equalTo: spacerRight.widthAnchor).isActive = true

            return
        }

        // Fallback: symbol pages — original fixed-width behavior
        var letterButtons: [UIButton] = []
        var firstLetter: UIButton?

        for key in keys {
            let btn = createKeyButton(key, rowIndex: rowIndex)
            btn.translatesAutoresizingMaskIntoConstraints = false
            container.addSubview(btn)

            NSLayoutConstraint.activate([
                btn.topAnchor.constraint(equalTo: container.topAnchor),
                btn.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            ])

            if key == Self.shiftKey || key == Self.moreSymKey || key == Self.symbolKey {
                btn.leadingAnchor.constraint(equalTo: container.leadingAnchor).isActive = true
                btn.widthAnchor.constraint(equalToConstant: wideKeyWidth).isActive = true
            } else if key == Self.backKey {
                btn.trailingAnchor.constraint(equalTo: container.trailingAnchor).isActive = true
                btn.widthAnchor.constraint(equalToConstant: wideKeyWidth).isActive = true
            } else {
                if let prev = letterButtons.last ?? container.subviews.first {
                    btn.leadingAnchor.constraint(equalTo: prev.trailingAnchor, constant: Layout.keySpacingH).isActive = true
                }
                if firstLetter == nil {
                    firstLetter = btn
                } else {
                    btn.widthAnchor.constraint(equalTo: firstLetter!.widthAnchor).isActive = true
                }
                letterButtons.append(btn)
            }
        }

        if let lastLetter = letterButtons.last {
            let backspaceBtn = container.subviews.last!
            lastLetter.trailingAnchor.constraint(equalTo: backspaceBtn.leadingAnchor, constant: -Layout.keySpacingH).isActive = true
        }
    }

    // MARK: - Bottom row (+=♥, 🌐A, space, period, return)

    private func buildBottomRow(container: UIView, keys: [String], rowIndex: Int) {
        // 5 keys: +=♥(50), 🌐A(50), space(flexible), .(50), return(74)
        let funcKeyWidth: CGFloat = 50    // +=♥, 🌐A
        let periodKeyWidth: CGFloat = 34  // "."
        let returnKeyWidth: CGFloat = 74  // return

        var previousView: UIButton?

        for key in keys {
            let btn = createKeyButton(key, rowIndex: rowIndex)
            btn.translatesAutoresizingMaskIntoConstraints = false
            container.addSubview(btn)

            NSLayoutConstraint.activate([
                btn.topAnchor.constraint(equalTo: container.topAnchor),
                btn.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            ])

            if key == " " {
                // Space bar: flexible width
                if let prev = previousView {
                    btn.leadingAnchor.constraint(equalTo: prev.trailingAnchor, constant: Layout.keySpacingH).isActive = true
                }
            } else if key == Self.returnKey {
                btn.widthAnchor.constraint(equalToConstant: returnKeyWidth).isActive = true
                btn.trailingAnchor.constraint(equalTo: container.trailingAnchor).isActive = true
                if let prev = previousView {
                    btn.leadingAnchor.constraint(equalTo: prev.trailingAnchor, constant: Layout.keySpacingH).isActive = true
                }
            } else if key == "." {
                btn.widthAnchor.constraint(equalToConstant: periodKeyWidth).isActive = true
                if let prev = previousView {
                    btn.leadingAnchor.constraint(equalTo: prev.trailingAnchor, constant: Layout.keySpacingH).isActive = true
                }
            } else if key == Self.symbolToggleKey || key == Self.globeLangKey || key == Self.abcKey {
                btn.widthAnchor.constraint(equalToConstant: funcKeyWidth).isActive = true
                if let prev = previousView {
                    btn.leadingAnchor.constraint(equalTo: prev.trailingAnchor, constant: Layout.keySpacingH).isActive = true
                } else {
                    btn.leadingAnchor.constraint(equalTo: container.leadingAnchor).isActive = true
                }
            } else {
                // Fallback for any other key
                btn.widthAnchor.constraint(equalToConstant: funcKeyWidth).isActive = true
                if let prev = previousView {
                    btn.leadingAnchor.constraint(equalTo: prev.trailingAnchor, constant: Layout.keySpacingH).isActive = true
                } else {
                    btn.leadingAnchor.constraint(equalTo: container.leadingAnchor).isActive = true
                }
            }

            previousView = btn
        }
    }

    // MARK: - Create Key Button

    private func createKeyButton(_ key: String, rowIndex: Int) -> UIButton {
        let button = UIButton(type: .custom)
        button.accessibilityLabel = key
        // ALL touch handling is done at the VIEW level via touchesBegan/Moved/Ended.
        // Buttons are purely visual — disabling their interaction prevents UIButton's
        // internal touch tracking from stealing/dropping rapid taps.
        button.isUserInteractionEnabled = false

        configureButtonAppearance(button, key: key)

        button.layer.cornerRadius = Layout.cornerRadius

        if let theme = customTheme, theme.hasWoodTexture {
            button.clipsToBounds = false
            button.layer.masksToBounds = false
        } else {
            button.clipsToBounds = true
        }

        allKeyButtons.append(button)
        return button
    }

    private func configureButtonAppearance(_ button: UIButton, key: String) {
        let isSpecial = Self.specialKeys.contains(key)

        // Colors
        if let theme = customTheme {

            // ========================================
            // Return 키 처리
            // ========================================
            if key == Self.returnKey {
                if theme.hasWoodTexture {
                    if case .woodBlock(let borderColor, let shadowColor, let highlightAlpha) = theme.specialKeyVisualStyle {
                        button.backgroundColor = theme.specialKeyBackground
                        applyWoodTextureTile(to: button, theme: theme)
                        button.layer.borderWidth = 1
                        button.layer.borderColor = borderColor.cgColor
                        button.layer.shadowColor = shadowColor.cgColor
                        button.layer.shadowOffset = CGSize(width: 0, height: 3)
                        button.layer.shadowRadius = 1.5
                        button.layer.shadowOpacity = 1.0
                        // 기존 tag 9902 UIView 정리 (v1 마이그레이션 안전 처리)
                        if let oldHv = button.viewWithTag(9902) { oldHv.removeFromSuperview() }
                        applyWoodHighlightGradient(to: button, highlightAlpha: highlightAlpha)
                    }
                    button.setTitleColor(theme.keyTextColor, for: .normal)
                } else {
                    button.backgroundColor = returnKeyIsBlue ? .systemBlue : theme.specialKeyBackground
                    button.setTitleColor(returnKeyIsBlue ? .white : theme.keyTextColor, for: .normal)
                }

            // ========================================
            // 일반 키 처리
            // ========================================
            } else if !isSpecial {
                switch theme.keyVisualStyle {
                case .solid:
                    button.backgroundColor = theme.keyBackground
                case .translucent(let alpha, let tint):
                    button.backgroundColor = tint.withAlphaComponent(alpha)
                case .woodBlock(let borderColor, let shadowColor, let highlightAlpha):
                    button.backgroundColor = theme.keyBackground
                    applyWoodTextureTile(to: button, theme: theme)
                    button.layer.borderWidth = 1
                    button.layer.borderColor = borderColor.cgColor
                    button.layer.shadowColor = shadowColor.cgColor
                    button.layer.shadowOffset = CGSize(width: 0, height: 3)
                    button.layer.shadowRadius = 1.5
                    button.layer.shadowOpacity = 1.0
                    // 기존 tag 9902 UIView 정리 (v1 마이그레이션 안전 처리)
                    if let oldHv = button.viewWithTag(9902) { oldHv.removeFromSuperview() }
                    applyWoodHighlightGradient(to: button, highlightAlpha: highlightAlpha)
                }
                button.setTitleColor(theme.keyTextColor, for: .normal)

            // ========================================
            // 특수 키 처리
            // ========================================
            } else {
                switch theme.specialKeyVisualStyle {
                case .solid:
                    button.backgroundColor = theme.specialKeyBackground
                case .translucent(let alpha, let tint):
                    button.backgroundColor = tint.withAlphaComponent(alpha)
                case .woodBlock(let borderColor, let shadowColor, let highlightAlpha):
                    button.backgroundColor = theme.specialKeyBackground
                    applyWoodTextureTile(to: button, theme: theme)
                    button.layer.borderWidth = 1
                    button.layer.borderColor = borderColor.cgColor
                    button.layer.shadowColor = shadowColor.cgColor
                    button.layer.shadowOffset = CGSize(width: 0, height: 3)
                    button.layer.shadowRadius = 1.5
                    button.layer.shadowOpacity = 1.0
                    // 기존 tag 9902 UIView 정리 (v1 마이그레이션 안전 처리)
                    if let oldHv = button.viewWithTag(9902) { oldHv.removeFromSuperview() }
                    applyWoodHighlightGradient(to: button, highlightAlpha: highlightAlpha)
                }
                button.setTitleColor(theme.keyTextColor, for: .normal)
            }

            // === 음각(Intaglio) 텍스트 이펙트 ===
            if theme.textShadowColor != .clear {
                applyEngravedTextEffect(to: button, theme: theme, key: key)
            }
        } else if key == Self.returnKey {
            button.backgroundColor = returnKeyIsBlue ? UIColor.systemBlue : (isDark ? UIColor(white: 0.37, alpha: 1) : UIColor(red: 0.76, green: 0.78, blue: 0.81, alpha: 1))
            button.setTitleColor(returnKeyIsBlue ? .white : (isDark ? .white : .black), for: .normal)
        } else if isSpecial {
            button.backgroundColor = isDark ? UIColor(white: 0.37, alpha: 1) : UIColor(red: 0.76, green: 0.78, blue: 0.81, alpha: 1)
            button.setTitleColor(isDark ? .white : .black, for: .normal)
        } else {
            button.backgroundColor = isDark ? UIColor(white: 0.42, alpha: 1) : .white
            button.setTitleColor(isDark ? .white : .black, for: .normal)
        }

        // Title / Image
        switch key {
        case Self.shiftKey:
            let config = UIImage.SymbolConfiguration(pointSize: 16, weight: isShifted ? .bold : .regular)
            let imgName = isShifted ? "shift.fill" : "shift"
            button.setImage(UIImage(systemName: imgName, withConfiguration: config), for: .normal)
            button.tintColor = customTheme?.keyTextColor ?? (isDark ? .white : .black)
            if isShifted {
                if customTheme != nil {
                    button.backgroundColor = customTheme!.keyBackground
                } else {
                    button.backgroundColor = isDark ? UIColor(white: 0.55, alpha: 1) : UIColor(white: 0.95, alpha: 1)
                }
            }
            button.setTitle(nil, for: .normal)

        case Self.backKey:
            let config = UIImage.SymbolConfiguration(pointSize: 16, weight: .regular)
            button.setImage(UIImage(systemName: "delete.left", withConfiguration: config), for: .normal)
            button.tintColor = customTheme?.keyTextColor ?? (isDark ? .white : .black)
            button.setTitle(nil, for: .normal)

        case Self.returnKey:
            if returnKeyIsBlue {
                // Action modes (send, search, go, etc.): show text
                button.setTitle(returnKeyDisplayName, for: .normal)
                button.titleLabel?.font = .systemFont(ofSize: Layout.returnFontSize, weight: .medium)
                button.setImage(nil, for: .normal)
            } else {
                // Default/newline mode: show return arrow icon like stock keyboard
                let config = UIImage.SymbolConfiguration(pointSize: 16, weight: .medium)
                button.setImage(UIImage(systemName: "return.left", withConfiguration: config), for: .normal)
                button.tintColor = customTheme?.keyTextColor ?? (isDark ? .white : .black)
                button.setTitle(nil, for: .normal)
            }

        case Self.symbolToggleKey:
            button.setTitle("+=♥", for: .normal)
            button.titleLabel?.font = .systemFont(ofSize: 13, weight: .medium)

        case Self.globeLangKey:
            // Globe icon with language label overlay
            let globeConfig = UIImage.SymbolConfiguration(pointSize: 14, weight: .regular)
            button.setImage(UIImage(systemName: "globe", withConfiguration: globeConfig), for: .normal)
            button.tintColor = customTheme?.keyTextColor ?? (isDark ? .white : .black)
            button.setTitle(nil, for: .normal)
            // Dynamic language label: show the "other" language's short label
            let langLabel = UILabel()
            langLabel.text = (currentLanguage == .english) ? pairedLanguage.shortLabel : "A"
            langLabel.font = .systemFont(ofSize: 9, weight: .bold)
            langLabel.textColor = customTheme?.keyTextColor ?? (isDark ? .white : .black)
            langLabel.translatesAutoresizingMaskIntoConstraints = false
            button.addSubview(langLabel)
            NSLayoutConstraint.activate([
                langLabel.bottomAnchor.constraint(equalTo: button.bottomAnchor, constant: -4),
                langLabel.trailingAnchor.constraint(equalTo: button.trailingAnchor, constant: -8),
            ])

        case Self.langKR, Self.langEN:
            button.setTitle(key == Self.langKR ? "한" : "EN", for: .normal)
            button.titleLabel?.font = .systemFont(ofSize: Layout.specialFontSize, weight: .medium)

        case Self.symbolKey:
            button.setTitle("123", for: .normal)
            button.titleLabel?.font = .systemFont(ofSize: Layout.specialFontSize, weight: .medium)

        case Self.moreSymKey:
            button.setTitle("#+=", for: .normal)
            button.titleLabel?.font = .systemFont(ofSize: Layout.specialFontSize, weight: .medium)

        case Self.abcKey:
            button.setTitle("ABC", for: .normal)
            button.titleLabel?.font = .systemFont(ofSize: Layout.specialFontSize, weight: .medium)

        case " ":
            let spaceTitle: String
            if currentPage == .letters {
                spaceTitle = currentLanguage.displayName
            } else {
                spaceTitle = ""
            }
            button.setTitle(spaceTitle, for: .normal)
            button.titleLabel?.font = .systemFont(ofSize: Layout.spaceFontSize)

        case ".":
            button.setTitle(".", for: .normal)
            button.titleLabel?.font = .systemFont(ofSize: 20, weight: .medium)

        default:
            button.setTitle(key, for: .normal)
            let fontSize: CGFloat = (currentPage == .letters) ? Layout.letterFontSize : Layout.symbolFontSize
            button.titleLabel?.font = .systemFont(ofSize: fontSize)
        }
    }

    // MARK: - View-Level Touch Handling
    //
    // ALL key input is detected here — NOT through UIButton control events.
    // This guarantees every single touch is captured regardless of how fast
    // the user taps, because UIButton's internal touch tracking (which drops
    // rapid sequential taps when isMultipleTouchEnabled=false) is bypassed.

    /// Tracking state for backspace long-press
    private var backspaceTrackingTouch: UITouch?

    /// Tracking state for space bar long-press trackpad
    private var spaceTrackingTouch: UITouch?
    private var spaceLongPressTimer: Timer?
    private var spaceDidEnterTrackpad = false

    /// Tracking state for accent long-press popup
    private var accentTrackingTouch: UITouch?
    private var accentLongPressTimer: Timer?
    private var accentPopupView: AccentPopupView?
    private var accentBaseKey: String?
    private var accentSourceButton: UIButton?

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            let loc = touch.location(in: self)
            guard let button = findButtonAt(loc) else { continue }
            guard let key = button.accessibilityLabel else { continue }
            triggerHaptic()

            // ── Space bar: track for potential trackpad mode ──
            if key == " " && !isTrackpadMode {
                spaceTrackingTouch = touch
                spaceDidEnterTrackpad = false
                trackpadLastX = loc.x
                trackpadLastY = loc.y
                trackpadAccumulator = 0
                trackpadAccumulatorY = 0

                spaceLongPressTimer?.invalidate()
                spaceLongPressTimer = Timer.scheduledTimer(withTimeInterval: 0.4, repeats: false) { [weak self] _ in
                    guard let self = self, self.spaceTrackingTouch != nil else { return }
                    self.spaceDidEnterTrackpad = true
                    self.trackpadStartX = self.trackpadLastX
                    self.trackpadStartY = self.trackpadLastY
                    self.lockedAxis = .none
                    self.enterTrackpadMode()
                }
                flashButton(button)
                continue
            }

            // ── Backspace: fire once + start long-press repeat ──
            if key == Self.backKey {
                backspaceTrackingTouch = touch
                onKeyTap?(Self.backKey)
                flashButton(button)

                backspaceTimer?.invalidate()
                backspaceRepeatTimer?.invalidate()
                backspaceTimer = Timer.scheduledTimer(withTimeInterval: 0.4, repeats: false) { [weak self] _ in
                    self?.backspaceRepeatTimer = Timer.scheduledTimer(withTimeInterval: 0.08, repeats: true) { [weak self] _ in
                        self?.onKeyTap?(Self.backKey)
                    }
                }
                continue
            }

            // ── Accent-capable keys: track for potential long-press ──
            let accentAlternatives = AccentMap.accents(for: currentLanguage)[key] ?? []
            if !accentAlternatives.isEmpty {
                accentTrackingTouch = touch
                accentBaseKey = key
                accentSourceButton = button
                flashButton(button)
                handleKeyAction(key)  // Immediately type the base character

                accentLongPressTimer = Timer.scheduledTimer(withTimeInterval: 0.4, repeats: false) { [weak self] _ in
                    self?.showAccentPopup(accents: accentAlternatives, sourceButton: button)
                }
                continue
            }

            // ── All other keys: handle immediately ──
            flashButton(button)
            handleKeyAction(key)
        }
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        // Accent popup selection tracking
        if let tracked = accentTrackingTouch, touches.contains(tracked), accentPopupView != nil {
            let loc = tracked.location(in: self)
            accentPopupView?.updateSelection(at: loc)
        }

        // Space bar trackpad cursor movement — accumulate only; CADisplayLink fires moves
        if let tracked = spaceTrackingTouch, touches.contains(tracked) {
            if isTrackpadMode {
                let loc = tracked.location(in: self)

                // Axis locking: determine dominant axis after threshold distance
                if lockedAxis == .none {
                    let dx = abs(loc.x - trackpadStartX)
                    let dy = abs(loc.y - trackpadStartY)
                    if dx >= axisLockThreshold || dy >= axisLockThreshold {
                        lockedAxis = (dx >= dy) ? .horizontal : .vertical
                    }
                } else {
                    // Allow axis switch if cross-axis movement exceeds unlock threshold
                    let crossAxisDelta: CGFloat
                    switch lockedAxis {
                    case .horizontal:
                        crossAxisDelta = abs(loc.y - trackpadStartY)
                    case .vertical:
                        crossAxisDelta = abs(loc.x - trackpadStartX)
                    case .none:
                        crossAxisDelta = 0
                    }
                    if crossAxisDelta >= axisUnlockThreshold {
                        trackpadStartX = loc.x
                        trackpadStartY = loc.y
                        trackpadAccumulator = 0
                        trackpadAccumulatorY = 0
                        lockedAxis = .none
                    }
                }

                // Accumulate deltas based on locked axis
                let deltaX = loc.x - trackpadLastX
                let deltaY = loc.y - trackpadLastY
                trackpadLastX = loc.x
                trackpadLastY = loc.y

                if lockedAxis != .vertical {
                    trackpadAccumulator += deltaX
                }
                if lockedAxis != .horizontal {
                    trackpadAccumulatorY += deltaY
                }
            }
        }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            // Accent popup
            if touch === accentTrackingTouch {
                accentLongPressTimer?.invalidate()
                accentLongPressTimer = nil
                if let popup = accentPopupView, let selected = popup.selectedCharacter {
                    onKeyTap?(Self.backKey)
                    onKeyTap?(selected)
                }
                hideAccentPopup()
                accentTrackingTouch = nil
                accentBaseKey = nil
                accentSourceButton = nil
            }
            // Space bar
            if touch === spaceTrackingTouch {
                spaceLongPressTimer?.invalidate()
                spaceLongPressTimer = nil
                if isTrackpadMode {
                    exitTrackpadMode()
                } else if !spaceDidEnterTrackpad {
                    onKeyTap?(" ")
                }
                spaceTrackingTouch = nil
                spaceDidEnterTrackpad = false
            }
            // Backspace
            if touch === backspaceTrackingTouch {
                backspaceTimer?.invalidate()
                backspaceTimer = nil
                backspaceRepeatTimer?.invalidate()
                backspaceRepeatTimer = nil
                backspaceTrackingTouch = nil
            }
        }
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            if touch === accentTrackingTouch {
                accentLongPressTimer?.invalidate()
                accentLongPressTimer = nil
                hideAccentPopup()
                accentTrackingTouch = nil
                accentBaseKey = nil
                accentSourceButton = nil
            }
            if touch === spaceTrackingTouch {
                spaceLongPressTimer?.invalidate()
                spaceLongPressTimer = nil
                if isTrackpadMode { exitTrackpadMode() }
                spaceTrackingTouch = nil
                spaceDidEnterTrackpad = false
            }
            if touch === backspaceTrackingTouch {
                backspaceTimer?.invalidate()
                backspaceTimer = nil
                backspaceRepeatTimer?.invalidate()
                backspaceRepeatTimer = nil
                backspaceTrackingTouch = nil
            }
        }
    }

    // MARK: - Key Action Dispatch

    private func handleKeyAction(_ key: String) {
        switch key {
        case Self.shiftKey:
            isShifted.toggle()
            scheduleBuildKeyboard()

        case Self.langKR:
            currentLanguage = .korean
            isShifted = false
            currentPage = .letters
            scheduleBuildKeyboard()
            onLanguageChanged?(.korean)

        case Self.langEN:
            currentLanguage = .english
            isShifted = false
            currentPage = .letters
            scheduleBuildKeyboard()
            onLanguageChanged?(.english)

        case Self.globeLangKey:
            // Toggle between paired language and English
            if currentLanguage == .english {
                currentLanguage = pairedLanguage
                onLanguageChanged?(pairedLanguage)
            } else {
                currentLanguage = .english
                onLanguageChanged?(.english)
            }
            isShifted = false
            currentPage = .letters
            scheduleBuildKeyboard()

        case Self.symbolToggleKey:
            currentPage = .symbols1
            scheduleBuildKeyboard()

        case Self.symbolKey:
            currentPage = .symbols1
            scheduleBuildKeyboard()

        case Self.moreSymKey:
            currentPage = .symbols2
            scheduleBuildKeyboard()

        case Self.abcKey:
            currentPage = .letters
            isShifted = false
            scheduleBuildKeyboard()

        default:
            onKeyTap?(key)
            if isShifted && !Self.specialKeys.contains(key) && currentPage == .letters {
                isShifted = false
                scheduleBuildKeyboard()
            }
            // ' 키 입력 후 자동으로 문자 키보드로 복귀
            if key == "'" && (currentPage == .symbols1 || currentPage == .symbols2) {
                currentPage = .letters
                scheduleBuildKeyboard()
            }
        }
    }

    // MARK: - Button Lookup

    /// Find the button at a given point (or nearest button for gap touches)
    private func findButtonAt(_ point: CGPoint) -> UIButton? {
        guard !isRebuilding else { return nil }

        // Direct hit — check each button's frame
        for button in allKeyButtons {
            guard let sv = button.superview else { continue }
            let frame = sv.convert(button.frame, to: self)
            guard frame.width > 0 && frame.height > 0 else { continue }
            if frame.contains(point) {
                return button
            }
        }
        // Gap hit — find nearest button
        guard bounds.contains(point), !allKeyButtons.isEmpty else { return nil }
        var closestButton: UIButton?
        var minDistSq: CGFloat = .greatestFiniteMagnitude
        for button in allKeyButtons {
            guard let sv = button.superview else { continue }
            let frame = sv.convert(button.frame, to: self)
            guard frame.width > 0 && frame.height > 0 else { continue }
            let center = CGPoint(x: frame.midX, y: frame.midY)
            let dx = point.x - center.x
            let dy = point.y - center.y
            let distSq = dx * dx + dy * dy
            if distSq < minDistSq {
                minDistSq = distSq
                closestButton = button
            }
        }
        return closestButton
    }

    // MARK: - Visual Feedback

    private func triggerHaptic() {
        let defaults = UserDefaults(suiteName: AppConstants.appGroupIdentifier)
        if let obj = defaults?.object(forKey: AppConstants.UserDefaultsKeys.hapticFeedback) {
            guard (obj as? Bool) == true else { return }
        }
        hapticGenerator.impactOccurred()
    }

    /// Brief background color flash — no transform, no animation delay, no coordinate disruption
    private func flashButton(_ button: UIButton) {
        let flashColor: UIColor

        if let theme = customTheme {
            if theme.hasWoodTexture {
                flashColor = UIColor(white: 1.0, alpha: 0.15)
            } else {
                // 키 배경 밝기 기준으로 자동 판단
                var brightness: CGFloat = 0
                theme.keyBackground.getHue(nil, saturation: nil, brightness: &brightness, alpha: nil)
                if brightness > 0.5 {
                    flashColor = UIColor(white: 0.0, alpha: 0.12)  // 밝은 키 → 어두운 플래시
                } else {
                    flashColor = UIColor(white: 1.0, alpha: 0.25)  // 어두운 키 → 밝은 플래시
                }
            }
        } else {
            flashColor = isDark ? UIColor(white: 0.5, alpha: 1) : UIColor(white: 0.65, alpha: 1)
        }

        if customTheme != nil {
            // 프리미엄/나무 테마: 오버레이 UIView 방식 통일
            let flashView = UIView(frame: button.bounds)
            flashView.backgroundColor = flashColor
            flashView.layer.cornerRadius = Layout.cornerRadius
            flashView.clipsToBounds = true
            flashView.isUserInteractionEnabled = false
            flashView.tag = 9999
            flashView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            button.addSubview(flashView)

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                flashView.removeFromSuperview()
            }
        } else {
            // 기본 테마 (customTheme == nil)
            let original = button.backgroundColor ?? .clear
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            button.backgroundColor = flashColor
            CATransaction.commit()

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                CATransaction.begin()
                CATransaction.setDisableActions(true)
                button.backgroundColor = original
                CATransaction.commit()
            }
        }
    }

    // MARK: - Wood Block Helpers

    /// 키 버튼에 나무 텍스처 타일 패턴 적용
    private func applyWoodTextureTile(to button: UIButton, theme: KeyboardTheme) {
        guard let tileName = theme.woodTileImageName,
              let tileImg = UIImage(named: tileName) else { return }

        let tag = 9901
        if button.viewWithTag(tag) != nil { return }  // 이미 있으면 스킵

        let tv = UIView()
        tv.tag = tag
        tv.isUserInteractionEnabled = false
        tv.backgroundColor = UIColor(patternImage: tileImg)
        tv.alpha = 0.5
        tv.layer.cornerRadius = Layout.cornerRadius
        tv.clipsToBounds = true
        // translatesAutoresizingMaskIntoConstraints = true (기본값 유지)
        tv.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        tv.frame = button.bounds  // 초기 frame 설정
        button.insertSubview(tv, at: 0)
    }

    /// 키 상단 하이라이트 그라디언트 (CAGradientLayer)
    private func applyWoodHighlightGradient(to button: UIButton, highlightAlpha: CGFloat) {
        guard highlightAlpha > 0 else { return }

        let layerName = "woodHighlightGradient"
        if button.layer.sublayers?.contains(where: { $0.name == layerName }) == true { return }

        let gl = CAGradientLayer()
        gl.name = layerName
        gl.colors = [
            UIColor(white: 1, alpha: highlightAlpha).cgColor,
            UIColor.clear.cgColor,
            UIColor(white: 0, alpha: highlightAlpha * 1.5).cgColor,
        ]
        gl.locations = [0, 0.4, 1.0]
        gl.cornerRadius = Layout.cornerRadius
        gl.masksToBounds = true
        gl.frame = button.bounds  // 초기 frame 설정

        // UIView 래퍼 없이 CAGradientLayer를 직접 추가
        // insertSublayer(at: 0)으로 최하위에 배치하여 텍스트 뒤에 렌더링
        button.layer.insertSublayer(gl, at: 0)
    }

    /// 음각(Intaglio) 텍스트 이펙트 — 나무에 파낸 듯한 글자
    private func applyEngravedTextEffect(to button: UIButton, theme: KeyboardTheme, key: String) {
        guard !Self.specialKeys.contains(key) || key == Self.returnKey else {
            button.tintColor = theme.keyTextColor
            return
        }

        if let title = button.title(for: .normal), !title.isEmpty {
            let fontSize: CGFloat
            switch key {
            case Self.returnKey: fontSize = Layout.returnFontSize
            case " ": fontSize = Layout.spaceFontSize
            default: fontSize = Layout.letterFontSize
            }

            // === 음각 효과: 3레이어 구조 ===
            // Layer 1 (최하단): 밝은 하이라이트 (파인 바닥의 빛 반사)
            // Layer 2 (중간): 어두운 그림자 (파인 위쪽 엣지)
            // Layer 3 (최상단): 실제 텍스트

            // 기존 하이라이트 라벨 제거 (재적용 방지)
            button.viewWithTag(9903)?.removeFromSuperview()

            // --- Layer 1: 하이라이트 라벨 (UILabel로 직접 추가) ---
            if theme.textHighlightColor != .clear {
                let highlightLabel = UILabel()
                highlightLabel.tag = 9903
                highlightLabel.text = title
                highlightLabel.font = UIFont.systemFont(ofSize: fontSize, weight: .semibold)
                highlightLabel.textColor = theme.textHighlightColor
                highlightLabel.textAlignment = .center
                highlightLabel.isUserInteractionEnabled = false
                highlightLabel.translatesAutoresizingMaskIntoConstraints = false

                button.addSubview(highlightLabel)
                NSLayoutConstraint.activate([
                    highlightLabel.centerXAnchor.constraint(equalTo: button.centerXAnchor,
                        constant: theme.textHighlightOffset.width),
                    highlightLabel.centerYAnchor.constraint(equalTo: button.centerYAnchor,
                        constant: theme.textHighlightOffset.height),
                ])

                // titleLabel 아래에 배치
                if let titleLabel = button.titleLabel {
                    button.bringSubviewToFront(titleLabel)
                }
            }

            // --- Layer 2+3: 그림자 + 텍스트 (NSAttributedString) ---
            let shadow = NSShadow()
            shadow.shadowColor = theme.textShadowColor
            shadow.shadowOffset = theme.textShadowOffset
            shadow.shadowBlurRadius = 1.5

            let attrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: fontSize, weight: .semibold),
                .foregroundColor: theme.keyTextColor,
                .shadow: shadow,
            ]

            button.setAttributedTitle(NSAttributedString(string: title, attributes: attrs), for: .normal)
        }

        // 아이콘(이미지)에도 음각 효과 강화
        if button.image(for: .normal) != nil {
            button.tintColor = theme.keyTextColor
            button.imageView?.layer.shadowColor = theme.textShadowColor.cgColor
            button.imageView?.layer.shadowOffset = theme.textShadowOffset
            button.imageView?.layer.shadowRadius = 1.5
            button.imageView?.layer.shadowOpacity = 1.0
        }
    }

    // MARK: - Accent Popup

    private func showAccentPopup(accents: [String], sourceButton: UIButton) {
        hideAccentPopup()
        guard let sv = sourceButton.superview else { return }
        let sourceFrame = sv.convert(sourceButton.frame, to: self)
        let popup = AccentPopupView()
        popup.configure(accents: accents, sourceFrame: sourceFrame, in: self)
        addSubview(popup)
        accentPopupView = popup
    }

    private func hideAccentPopup() {
        accentPopupView?.removeFromSuperview()
        accentPopupView = nil
    }

    private func enterTrackpadMode() {
        guard !isTrackpadMode else { return }
        isTrackpadMode = true
        selectionHaptic.prepare()

        // Start CADisplayLink for smooth cursor movement
        displayLink = CADisplayLink(target: self, selector: #selector(trackpadDisplayLinkFired))
        displayLink?.add(to: .main, forMode: .common)

        // Hide all key labels/icons — keep blank key shapes only
        for button in allKeyButtons {
            button.setTitle(nil, for: .normal)
            button.setImage(nil, for: .normal)
            // Hide globe key's langLabel subview
            for sub in button.subviews where sub is UILabel {
                sub.isHidden = true
            }
            // Uniform blank key color
            if let theme = customTheme {
                button.backgroundColor = theme.specialKeyBackground
            } else {
                button.backgroundColor = isDark ? UIColor(white: 0.30, alpha: 1) : UIColor(white: 0.88, alpha: 1)
            }
        }

        onTrackpadModeChanged?(true)
    }

    private func exitTrackpadMode() {
        guard isTrackpadMode else { return }
        isTrackpadMode = false
        lockedAxis = .none

        // Stop CADisplayLink
        displayLink?.invalidate()
        displayLink = nil

        buildKeyboard()  // Full rebuild to restore all key appearances
        onTrackpadModeChanged?(false)
    }

    @objc private func trackpadDisplayLinkFired() {
        var moved = false

        // X-axis
        while trackpadAccumulator > trackpadSensitivity {
            trackpadAccumulator -= trackpadSensitivity
            onCursorMove?(1, 0)
            moved = true
        }
        while trackpadAccumulator < -trackpadSensitivity {
            trackpadAccumulator += trackpadSensitivity
            onCursorMove?(-1, 0)
            moved = true
        }

        // Y-axis — max 1 line per threshold crossing, reset accumulator to prevent multi-line jumps
        if trackpadAccumulatorY > trackpadSensitivityY {
            trackpadAccumulatorY = 0
            onCursorMove?(0, 1)
            moved = true
        } else if trackpadAccumulatorY < -trackpadSensitivityY {
            trackpadAccumulatorY = 0
            onCursorMove?(0, -1)
            moved = true
        }

        if moved {
            triggerTrackpadHaptic()
        }
    }

    private func triggerTrackpadHaptic() {
        let defaults = UserDefaults(suiteName: AppConstants.appGroupIdentifier)
        if let obj = defaults?.object(forKey: AppConstants.UserDefaultsKeys.hapticFeedback) {
            guard (obj as? Bool) == true else { return }
        }
        selectionHaptic.selectionChanged()
    }

    // MARK: - Hit Test
    // Return self for ALL touches within bounds so that touchesBegan always fires.
    // Button lookup is done in touchesBegan via findButtonAt().
    // This also enables seamless touch (no dead zones) and trackpad mode.

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        guard bounds.contains(point) else { return nil }
        return self
    }

    // MARK: - Public Methods

    func applyTheme(_ theme: KeyboardTheme?) {
        customTheme = theme
    }

    func updateAppearance(isDark: Bool) {
        self.isDark = isDark

        if let theme = customTheme {
            // 그라데이션 배경 처리
            if theme.hasGradient, let colors = theme.gradientColors {
                backgroundColor = .clear

                if gradientLayer == nil {
                    let gl = CAGradientLayer()
                    layer.insertSublayer(gl, at: 0)
                    gradientLayer = gl
                }
                gradientLayer?.colors = colors.map { $0.cgColor }
                gradientLayer?.locations = theme.gradientLocations
                gradientLayer?.startPoint = theme.gradientDirection.startPoint
                gradientLayer?.endPoint = theme.gradientDirection.endPoint
                gradientLayer?.frame = bounds
            } else {
                gradientLayer?.removeFromSuperlayer()
                gradientLayer = nil
                backgroundColor = theme.keyboardBackground
            }

            // 패턴 오버레이 처리
            if theme.hasPattern {
                if patternImageView == nil {
                    let iv = UIImageView()
                    iv.contentMode = .scaleToFill
                    iv.isUserInteractionEnabled = false
                    iv.translatesAutoresizingMaskIntoConstraints = false
                    insertSubview(iv, belowSubview: keyboardContainer)
                    NSLayoutConstraint.activate([
                        iv.topAnchor.constraint(equalTo: topAnchor),
                        iv.leadingAnchor.constraint(equalTo: leadingAnchor),
                        iv.trailingAnchor.constraint(equalTo: trailingAnchor),
                        iv.bottomAnchor.constraint(equalTo: bottomAnchor),
                    ])
                    patternImageView = iv
                }
                if let patternImg = ThemePatternRenderer.patternImage(
                    style: theme.patternStyle,
                    tint: theme.patternTint,
                    opacity: theme.patternOpacity,
                    size: CGSize(width: 128, height: 128)
                ) {
                    patternImageView?.backgroundColor = UIColor(patternImage: patternImg)
                    patternImageView?.isHidden = false
                }
            } else {
                patternImageView?.isHidden = true
            }
        } else {
            gradientLayer?.removeFromSuperlayer()
            gradientLayer = nil
            patternImageView?.isHidden = true
            backgroundColor = isDark ? UIColor(white: 0.08, alpha: 1) : UIColor(red: 0.82, green: 0.84, blue: 0.86, alpha: 1)
        }

        // Wood texture tile rendering
        if let theme = customTheme, theme.hasWoodTexture,
           let tileName = theme.woodTileImageName,
           let tileImg = UIImage(named: tileName) {

            if woodTileImageView == nil {
                let iv = UIImageView()
                iv.contentMode = .scaleToFill
                iv.isUserInteractionEnabled = false
                iv.translatesAutoresizingMaskIntoConstraints = false
                insertSubview(iv, belowSubview: keyboardContainer)
                NSLayoutConstraint.activate([
                    iv.topAnchor.constraint(equalTo: topAnchor),
                    iv.bottomAnchor.constraint(equalTo: bottomAnchor),
                    iv.leadingAnchor.constraint(equalTo: leadingAnchor),
                    iv.trailingAnchor.constraint(equalTo: trailingAnchor),
                ])
                woodTileImageView = iv
            }
            woodTileImageView?.backgroundColor = UIColor(patternImage: tileImg)
            woodTileImageView?.alpha = 0.6
            woodTileImageView?.isHidden = false
        } else {
            woodTileImageView?.isHidden = true
        }

        buildKeyboard()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer?.frame = bounds

        // Wood block key texture + gradient frame update
        for button in allKeyButtons {
            let bounds = button.bounds

            // 텍스처 타일 UIView frame 업데이트 (tag 9901)
            if let tv = button.viewWithTag(9901) {
                tv.frame = bounds
            }

            // 하이라이트 그래디언트 CALayer frame 업데이트
            button.layer.sublayers?.forEach { sublayer in
                if sublayer.name == "woodHighlightGradient" {
                    sublayer.frame = bounds
                }
            }
        }
    }

    func getCurrentLanguage() -> KeyboardLanguage {
        return currentLanguage
    }

    func setLanguage(_ language: KeyboardLanguage) {
        currentLanguage = language
        isShifted = false
        currentPage = .letters
        buildKeyboard()
    }

    func setShifted(_ shifted: Bool) {
        guard currentPage == .letters else { return }
        guard isShifted != shifted else { return }
        isShifted = shifted
        buildKeyboard()
    }

    // MARK: - Mode-Aware Return Key (Proposal 03)

    func updateReturnKey(mode: KeyboardMode, hasText: Bool) {
        returnKeyModeOverride = mode
        returnKeyHasText = hasText

        // Find the return key button and update it in-place (no full rebuild)
        guard let returnButton = allKeyButtons.first(where: { $0.accessibilityLabel == Self.returnKey }) else { return }

        let config: (label: String, color: UIColor)
        switch mode {
        case .defaultMode, .phraseInputMode, .quickNoteMode:
            // Don't override — use the standard returnKeyDisplayName/returnKeyIsBlue logic
            returnButton.alpha = 1.0
            returnButton.isUserInteractionEnabled = false // touch handled at view level
            return
        case .translationMode:
            config = (L("keyboard.return.translate"), UIColor(red: 0.192, green: 0.510, blue: 0.965, alpha: 1))
        case .correctionMode:
            config = (L("keyboard.return.correct"), UIColor(red: 1, green: 0.624, blue: 0.263, alpha: 1))
        }

        returnButton.setTitle(config.label, for: .normal)
        returnButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        returnButton.setImage(nil, for: .normal)
        returnButton.backgroundColor = config.color
        returnButton.setTitleColor(.white, for: .normal)
        returnButton.alpha = hasText ? 1.0 : 0.5
    }

    func clearReturnKeyOverride() {
        returnKeyModeOverride = nil
        returnKeyHasText = true
        buildKeyboard()
    }
}
