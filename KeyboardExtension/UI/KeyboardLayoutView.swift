import UIKit

enum KeyboardLanguage {
    case english
    case korean
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
    var returnKeyDisplayName: String = "이동" {
        didSet { if oldValue != returnKeyDisplayName { buildKeyboard() } }
    }
    var returnKeyIsBlue: Bool = true {
        didSet { if oldValue != returnKeyIsBlue { buildKeyboard() } }
    }

    private var currentLanguage: KeyboardLanguage = .english
    private var currentPage: KeyboardPage = .letters
    private var isShifted = false
    private var isDark = false

    // Backspace long-press repeat
    private var backspaceTimer: Timer?
    private var backspaceRepeatTimer: Timer?

    // Space bar trackpad cursor mode
    private var isTrackpadMode = false
    private var trackpadLastX: CGFloat = 0
    private var trackpadLastY: CGFloat = 0
    private var trackpadAccumulator: CGFloat = 0
    private var trackpadAccumulatorY: CGFloat = 0
    private let trackpadSensitivity: CGFloat = 6   // points per character move
    private let trackpadSensitivityY: CGFloat = 12  // points per line move (higher = slower)

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

    private let numberRow: [String] = ["1", "2", "3", "4", "5", "6", "7", "8", "9", "0"]

    private let englishRows: [[String]] = [
        ["q", "w", "e", "r", "t", "y", "u", "i", "o", "p"],
        ["a", "s", "d", "f", "g", "h", "j", "k", "l"],
        ["\u{21E7}", "z", "x", "c", "v", "b", "n", "m", "\u{232B}"],
        ["+=♥", "__GLOBE_A__", " ", ".", "\u{23CE}"]
    ]

    private let englishShiftRows: [[String]] = [
        ["Q", "W", "E", "R", "T", "Y", "U", "I", "O", "P"],
        ["A", "S", "D", "F", "G", "H", "J", "K", "L"],
        ["\u{21E7}", "Z", "X", "C", "V", "B", "N", "M", "\u{232B}"],
        ["+=♥", "__GLOBE_A__", " ", ".", "\u{23CE}"]
    ]

    private let koreanRows: [[String]] = [
        ["\u{3142}", "\u{3148}", "\u{3137}", "\u{3131}", "\u{3145}",
         "\u{315B}", "\u{3155}", "\u{3151}", "\u{3150}", "\u{3154}"],
        ["\u{3141}", "\u{3134}", "\u{3147}", "\u{3139}", "\u{314E}",
         "\u{3157}", "\u{3153}", "\u{314F}", "\u{3163}"],
        ["\u{21E7}", "\u{314B}", "\u{314C}", "\u{314A}", "\u{314D}",
         "\u{3160}", "\u{315C}", "\u{3161}", "\u{232B}"],
        ["+=♥", "__GLOBE_A__", " ", ".", "\u{23CE}"]
    ]

    private let koreanShiftRows: [[String]] = [
        ["\u{3143}", "\u{3149}", "\u{3138}", "\u{3132}", "\u{3146}",
         "\u{315B}", "\u{3155}", "\u{3151}", "\u{3152}", "\u{3156}"],
        ["\u{3141}", "\u{3134}", "\u{3147}", "\u{3139}", "\u{314E}",
         "\u{3157}", "\u{3153}", "\u{314F}", "\u{3163}"],
        ["\u{21E7}", "\u{314B}", "\u{314C}", "\u{314A}", "\u{314D}",
         "\u{3160}", "\u{315C}", "\u{3161}", "\u{232B}"],
        ["+=♥", "__GLOBE_A__", " ", ".", "\u{23CE}"]
    ]

    // ── Symbol layouts ──

    private let symbolRows1: [[String]] = [
        ["$", "€", "£", "¥", "¢", "~", "…", "°", "※", "•"],
        ["-", "/", ":", ";", "(", ")", "₩", "&", "@", "\""],
        ["#+=", ".", ",", "?", "!", "'", "\u{232B}"],
        ["ABC", "__GLOBE_A__", " ", ".", "\u{23CE}"]
    ]

    private let symbolRows2: [[String]] = [
        ["[", "]", "{", "}", "#", "%", "^", "*", "+", "="],
        ["_", "\\", "|", "<", ">", "«", "»", "§", "©", "®"],
        ["123", ".", ",", "?", "!", "'", "\u{232B}"],
        ["ABC", "__GLOBE_A__", " ", ".", "\u{23CE}"]
    ]

    // ── Special keys set ──

    // Space " " and period "." are NOT special — they render WHITE like letter keys.
    private let specialKeys: Set<String> = [
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
            switch (currentLanguage, isShifted) {
            case (.english, false): letterRows = englishRows
            case (.english, true):  letterRows = englishShiftRows
            case (.korean, false):  letterRows = koreanRows
            case (.korean, true):   letterRows = koreanShiftRows
            }
            return [numberRow] + letterRows
        case .symbols1:
            return [numberRow] + symbolRows1
        case .symbols2:
            return [numberRow] + symbolRows2
        }
    }

    // MARK: - Build Keyboard

    private func buildKeyboard() {
        guard !isTrackpadMode else { return }  // 트랙패드 중 재빌드 방지
        keyboardContainer.subviews.forEach { $0.removeFromSuperview() }
        allKeyButtons.removeAll()

        let rows = currentRows()
        let totalRows = rows.count
        let isNumberRow = true  // All pages have number row at index 0
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
        // In letters page: row 0 = number row (10 keys), row 1 = first letter row (10 keys),
        // row 2 = second letter row (9 keys, needs indent)
        let needsIndent = (keys.count == 9 && currentPage == .letters)

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
        let wideKeyWidth: CGFloat = 42  // Shift/backspace width — matches stock iOS keyboard
        var letterButtons: [UIButton] = []
        var firstLetter: UIButton?

        for (_, key) in keys.enumerated() {
            let btn = createKeyButton(key, rowIndex: rowIndex)
            btn.translatesAutoresizingMaskIntoConstraints = false
            container.addSubview(btn)

            NSLayoutConstraint.activate([
                btn.topAnchor.constraint(equalTo: container.topAnchor),
                btn.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            ])

            if key == Self.shiftKey || key == Self.moreSymKey || key == Self.symbolKey {
                // Left wide key
                btn.leadingAnchor.constraint(equalTo: container.leadingAnchor).isActive = true
                btn.widthAnchor.constraint(equalToConstant: wideKeyWidth).isActive = true
            } else if key == Self.backKey {
                // Backspace - right side
                btn.trailingAnchor.constraint(equalTo: container.trailingAnchor).isActive = true
                btn.widthAnchor.constraint(equalToConstant: wideKeyWidth).isActive = true
            } else {
                // Letter/symbol key
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

        // Connect last letter to backspace
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
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOffset = CGSize(width: 0, height: 1)
        button.layer.shadowOpacity = isDark ? 0.4 : 0.2
        button.layer.shadowRadius = 0.5
        button.clipsToBounds = false

        allKeyButtons.append(button)
        return button
    }

    private func configureButtonAppearance(_ button: UIButton, key: String) {
        let isSpecial = specialKeys.contains(key)

        // Colors
        if key == Self.returnKey {
            button.backgroundColor = returnKeyIsBlue ? UIColor.systemBlue : (isDark ? UIColor(white: 0.37, alpha: 1) : UIColor(red: 0.76, green: 0.78, blue: 0.81, alpha: 1))
            button.setTitleColor(returnKeyIsBlue ? .white : (isDark ? .white : .black), for: .normal)
        } else if isSpecial {
            // Lighter gray matching stock iOS keyboard special keys
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
            button.tintColor = isDark ? .white : .black
            if isShifted {
                button.backgroundColor = isDark ? UIColor(white: 0.55, alpha: 1) : UIColor(white: 0.95, alpha: 1)
            }
            button.setTitle(nil, for: .normal)

        case Self.backKey:
            let config = UIImage.SymbolConfiguration(pointSize: 16, weight: .regular)
            button.setImage(UIImage(systemName: "delete.left", withConfiguration: config), for: .normal)
            button.tintColor = isDark ? .white : .black
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
                button.tintColor = isDark ? .white : .black
                button.setTitle(nil, for: .normal)
            }

        case Self.symbolToggleKey:
            button.setTitle("+=♥", for: .normal)
            button.titleLabel?.font = .systemFont(ofSize: 13, weight: .medium)

        case Self.globeLangKey:
            // Globe icon with small "A" overlay
            let globeConfig = UIImage.SymbolConfiguration(pointSize: 14, weight: .regular)
            button.setImage(UIImage(systemName: "globe", withConfiguration: globeConfig), for: .normal)
            button.tintColor = isDark ? .white : .black
            button.setTitle(nil, for: .normal)
            // Add "A" label overlay
            let langLabel = UILabel()
            langLabel.text = "A"
            langLabel.font = .systemFont(ofSize: 9, weight: .bold)
            langLabel.textColor = isDark ? .white : .black
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
            let spaceTitle = (currentLanguage == .korean && currentPage == .letters) ? "간격" : ""
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

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            let loc = touch.location(in: self)
            guard let button = findButtonAt(loc) else { continue }
            guard let key = button.accessibilityLabel else { continue }

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

            // ── All other keys: handle immediately ──
            flashButton(button)
            handleKeyAction(key)
        }
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        // Space bar trackpad cursor movement
        if let tracked = spaceTrackingTouch, touches.contains(tracked) {
            if isTrackpadMode {
                let loc = tracked.location(in: self)

                // X-axis (left/right)
                let deltaX = loc.x - trackpadLastX
                trackpadLastX = loc.x
                trackpadAccumulator += deltaX

                while trackpadAccumulator > trackpadSensitivity {
                    trackpadAccumulator -= trackpadSensitivity
                    onCursorMove?(1, 0)
                }
                while trackpadAccumulator < -trackpadSensitivity {
                    trackpadAccumulator += trackpadSensitivity
                    onCursorMove?(-1, 0)
                }

                // Y-axis (up/down)
                let deltaY = loc.y - trackpadLastY
                trackpadLastY = loc.y
                trackpadAccumulatorY += deltaY

                while trackpadAccumulatorY > trackpadSensitivityY {
                    trackpadAccumulatorY -= trackpadSensitivityY
                    onCursorMove?(0, 1)   // down
                }
                while trackpadAccumulatorY < -trackpadSensitivityY {
                    trackpadAccumulatorY += trackpadSensitivityY
                    onCursorMove?(0, -1)  // up
                }
            }
        }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
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
            buildKeyboard()

        case Self.langKR:
            currentLanguage = .korean
            isShifted = false
            currentPage = .letters
            buildKeyboard()
            onLanguageChanged?(.korean)

        case Self.langEN:
            currentLanguage = .english
            isShifted = false
            currentPage = .letters
            buildKeyboard()
            onLanguageChanged?(.english)

        case Self.globeLangKey:
            // Toggle between Korean and English
            if currentLanguage == .korean {
                currentLanguage = .english
                onLanguageChanged?(.english)
            } else {
                currentLanguage = .korean
                onLanguageChanged?(.korean)
            }
            isShifted = false
            currentPage = .letters
            buildKeyboard()

        case Self.symbolToggleKey:
            currentPage = .symbols1
            buildKeyboard()

        case Self.symbolKey:
            currentPage = .symbols1
            buildKeyboard()

        case Self.moreSymKey:
            currentPage = .symbols2
            buildKeyboard()

        case Self.abcKey:
            currentPage = .letters
            isShifted = false
            buildKeyboard()

        default:
            onKeyTap?(key)
            if isShifted && !specialKeys.contains(key) && currentPage == .letters {
                isShifted = false
                buildKeyboard()
            }
        }
    }

    // MARK: - Button Lookup

    /// Find the button at a given point (or nearest button for gap touches)
    private func findButtonAt(_ point: CGPoint) -> UIButton? {
        // Direct hit — check each button's frame
        for button in allKeyButtons {
            guard let sv = button.superview else { continue }
            let frame = sv.convert(button.frame, to: self)
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
            let center = sv.convert(button.center, to: self)
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

    /// Brief background color flash — no transform, no animation delay, no coordinate disruption
    private func flashButton(_ button: UIButton) {
        let original = button.backgroundColor ?? .clear
        button.backgroundColor = isDark ? UIColor(white: 0.6, alpha: 1) : UIColor(white: 0.75, alpha: 1)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
            button.backgroundColor = original
        }
    }

    private func enterTrackpadMode() {
        guard !isTrackpadMode else { return }
        isTrackpadMode = true

        // Hide all key labels/icons — keep blank key shapes only
        for button in allKeyButtons {
            button.setTitle(nil, for: .normal)
            button.setImage(nil, for: .normal)
            // Hide globe key's langLabel subview
            for sub in button.subviews where sub is UILabel {
                sub.isHidden = true
            }
            // Uniform blank key color
            button.backgroundColor = isDark ? UIColor(white: 0.30, alpha: 1) : UIColor(white: 0.88, alpha: 1)
            button.layer.shadowOpacity = 0
        }

        onTrackpadModeChanged?(true)
    }

    private func exitTrackpadMode() {
        guard isTrackpadMode else { return }
        isTrackpadMode = false
        buildKeyboard()  // Full rebuild to restore all key appearances
        onTrackpadModeChanged?(false)
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

    func updateAppearance(isDark: Bool) {
        self.isDark = isDark
        backgroundColor = isDark ? UIColor(white: 0.08, alpha: 1) : UIColor(red: 0.82, green: 0.84, blue: 0.86, alpha: 1)
        buildKeyboard()
    }

    func getCurrentLanguage() -> KeyboardLanguage {
        return currentLanguage
    }
}
