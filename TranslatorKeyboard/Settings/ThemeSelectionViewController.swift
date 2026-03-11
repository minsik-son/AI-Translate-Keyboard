import UIKit

class ThemeSelectionViewController: UIViewController {

    private let freeThemes = KeyboardTheme.allThemes
    private let premiumThemes = KeyboardTheme.allPremiumThemes
    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.minimumInteritemSpacing = 14
        layout.minimumLineSpacing = 16
        layout.sectionInset = UIEdgeInsets(top: 16, left: 20, bottom: 20, right: 20)
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.backgroundColor = .clear
        cv.translatesAutoresizingMaskIntoConstraints = false
        cv.dataSource = self
        cv.delegate = self
        cv.register(ThemeCell.self, forCellWithReuseIdentifier: ThemeCell.reuseId)
        cv.register(PremiumThemeCell.self, forCellWithReuseIdentifier: PremiumThemeCell.reuseId)
        cv.register(ThemeSectionHeader.self,
                    forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
                    withReuseIdentifier: ThemeSectionHeader.reuseId)
        return cv
    }()

    private var selectedThemeId: String = "default"

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = L("settings.keyboard_theme")
        view.backgroundColor = AppColors.bg
        navigationController?.navigationBar.prefersLargeTitles = true

        view.addSubview(collectionView)
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])

        selectedThemeId = AppGroupManager.shared.string(forKey: AppConstants.UserDefaultsKeys.keyboardTheme) ?? "default"
        NotificationCenter.default.addObserver(self, selector: #selector(handleLanguageChange), name: .languageDidChange, object: nil)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        collectionView.reloadData()
    }

    @objc private func handleLanguageChange() {
        navigationItem.title = L("settings.keyboard_theme")
        collectionView.reloadData()
    }

    private func indexPath(forThemeId id: String) -> IndexPath? {
        if let index = freeThemes.firstIndex(where: { $0.id == id }) {
            return IndexPath(item: index, section: 0)
        }
        if let index = premiumThemes.firstIndex(where: { $0.id == id }) {
            return IndexPath(item: index, section: 1)
        }
        return nil
    }
}

// MARK: - UICollectionViewDataSource & Delegate

extension ThemeSelectionViewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 2
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return section == 0 ? freeThemes.count : premiumThemes.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let theme: KeyboardTheme
        if indexPath.section == 0 {
            theme = freeThemes[indexPath.item]
        } else {
            theme = premiumThemes[indexPath.item]
        }

        let isPro = SubscriptionStatus.shared.isPro
        let isLocked = theme.isPremium && !isPro
        let isSelected = theme.id == selectedThemeId

        if indexPath.section == 1 {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: PremiumThemeCell.reuseId, for: indexPath) as! PremiumThemeCell
            cell.configure(theme: theme, isSelected: isSelected, isLocked: isLocked)
            return cell
        } else {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ThemeCell.reuseId, for: indexPath) as! ThemeCell
            cell.configure(theme: theme, isSelected: isSelected, isLocked: isLocked)
            return cell
        }
    }

    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let header = collectionView.dequeueReusableSupplementaryView(
            ofKind: kind,
            withReuseIdentifier: ThemeSectionHeader.reuseId,
            for: indexPath
        ) as! ThemeSectionHeader

        if indexPath.section == 0 {
            header.configure(title: L("theme.section_free"), showBadge: false)
        } else {
            header.configure(title: L("theme.section_premium"), showBadge: true)
        }
        return header
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        return CGSize(width: collectionView.bounds.width, height: 44)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let totalSpacing: CGFloat = 20 * 2 + 14
        let width = (collectionView.bounds.width - totalSpacing) / 2

        if indexPath.section == 1 {
            return CGSize(width: floor(width), height: floor(width) * 1.45)
        } else {
            return CGSize(width: floor(width), height: floor(width) * 1.15)
        }
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let theme: KeyboardTheme
        if indexPath.section == 0 {
            theme = freeThemes[indexPath.item]
        } else {
            theme = premiumThemes[indexPath.item]
        }

        let isPro = SubscriptionStatus.shared.isPro
        if theme.isPremium && !isPro {
            guard self.presentedViewController == nil else { return }

            let paywallVC = PaywallViewController()
            paywallVC.modalPresentationStyle = .pageSheet
            self.present(paywallVC, animated: true)
            return
        }

        let previousId = selectedThemeId
        selectedThemeId = theme.id
        AppGroupManager.shared.set(theme.id, forKey: AppConstants.UserDefaultsKeys.keyboardTheme)

        ThemePatternRenderer.clearCache()

        var indexPaths = [indexPath]
        if let prevPath = self.indexPath(forThemeId: previousId), prevPath != indexPath {
            indexPaths.append(prevPath)
        }
        collectionView.reloadItems(at: indexPaths)

        // Selection animation
        if let cell = collectionView.cellForItem(at: indexPath) {
            UIView.animate(withDuration: 0.15, animations: {
                cell.transform = CGAffineTransform(scaleX: 0.96, y: 0.96)
            }) { _ in
                UIView.animate(withDuration: 0.15) {
                    cell.transform = .identity
                }
            }
        }
    }
}

// MARK: - ThemeSectionHeader

private class ThemeSectionHeader: UICollectionReusableView {
    static let reuseId = "ThemeSectionHeader"

    private let titleLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 16, weight: .bold)
        l.textColor = AppColors.text
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let proBadge: UILabel = {
        let l = UILabel()
        l.text = "PRO"
        l.font = .systemFont(ofSize: 10, weight: .heavy)
        l.textColor = .white
        l.backgroundColor = AppColors.accent
        l.textAlignment = .center
        l.layer.cornerRadius = 4
        l.clipsToBounds = true
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(titleLabel)
        addSubview(proBadge)

        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            titleLabel.centerYAnchor.constraint(equalTo: centerYAnchor),

            proBadge.leadingAnchor.constraint(equalTo: titleLabel.trailingAnchor, constant: 8),
            proBadge.centerYAnchor.constraint(equalTo: centerYAnchor),
            proBadge.widthAnchor.constraint(equalToConstant: 34),
            proBadge.heightAnchor.constraint(equalToConstant: 18),
        ])
    }

    required init?(coder: NSCoder) { fatalError() }

    func configure(title: String, showBadge: Bool) {
        titleLabel.text = title
        proBadge.isHidden = !showBadge

        isAccessibilityElement = true
        accessibilityLabel = showBadge ? "\(title) PRO" : title
        accessibilityTraits = .header
    }
}

// MARK: - ThemeCell

private class ThemeCell: UICollectionViewCell {

    static let reuseId = "ThemeCell"

    private let cardView: UIView = {
        let v = UIView()
        v.layer.cornerRadius = 14
        v.clipsToBounds = true
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private let previewContainer: UIView = {
        let v = UIView()
        v.layer.cornerRadius = 8
        v.clipsToBounds = true
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    // 3 rows of mini keys for QWERTY preview
    private var keyRows: [[UIView]] = []

    private let nameLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 13, weight: .semibold)
        l.textAlignment = .left
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let colorDotsStack: UIStackView = {
        let sv = UIStackView()
        sv.axis = .horizontal
        sv.spacing = 4
        sv.translatesAutoresizingMaskIntoConstraints = false
        return sv
    }()

    private var dotViews: [UIView] = []

    private let checkmark: UIImageView = {
        let config = UIImage.SymbolConfiguration(pointSize: 18, weight: .bold)
        let iv = UIImageView(image: UIImage(systemName: "checkmark.circle.fill", withConfiguration: config))
        iv.tintColor = AppColors.accent
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.isHidden = true
        return iv
    }()

    private let lockOverlay: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor(white: 0.5, alpha: 0.4)
        v.layer.cornerRadius = 8
        v.clipsToBounds = true
        v.isHidden = true
        v.isUserInteractionEnabled = false
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private let lockIcon: UIImageView = {
        let config = UIImage.SymbolConfiguration(pointSize: 22, weight: .medium)
        let iv = UIImageView(image: UIImage(systemName: "lock.fill", withConfiguration: config))
        iv.tintColor = .white
        iv.isUserInteractionEnabled = false
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        lockOverlay.isHidden = true
        checkmark.isHidden = true
        cardView.layer.borderColor = UIColor.clear.cgColor
        cardView.layer.borderWidth = 1
        nameLabel.textColor = AppColors.text
        accessibilityLabel = nil
        accessibilityHint = nil
        accessibilityTraits = .button
    }

    private func setupViews() {
        contentView.addSubview(cardView)
        cardView.addSubview(previewContainer)
        cardView.addSubview(nameLabel)
        cardView.addSubview(colorDotsStack)
        cardView.addSubview(checkmark)

        // Mini keyboard: 3 rows (10, 9, 7 keys)
        let keyCounts = [10, 9, 7]
        for count in keyCounts {
            let row = UIStackView()
            row.axis = .horizontal
            row.spacing = 2
            row.distribution = .fillEqually
            row.translatesAutoresizingMaskIntoConstraints = false

            var rowKeys: [UIView] = []
            for _ in 0..<count {
                let kv = UIView()
                kv.layer.cornerRadius = 2
                rowKeys.append(kv)
                row.addArrangedSubview(kv)
            }
            keyRows.append(rowKeys)
            previewContainer.addSubview(row)
        }

        // Lock overlay — added AFTER key rows to ensure Z-order on top
        previewContainer.addSubview(lockOverlay)
        lockOverlay.addSubview(lockIcon)

        // 4 color palette dots
        for _ in 0..<4 {
            let dot = UIView()
            dot.layer.cornerRadius = 4
            dot.translatesAutoresizingMaskIntoConstraints = false
            dot.widthAnchor.constraint(equalToConstant: 8).isActive = true
            dot.heightAnchor.constraint(equalToConstant: 8).isActive = true
            dotViews.append(dot)
            colorDotsStack.addArrangedSubview(dot)
        }

        NSLayoutConstraint.activate([
            cardView.topAnchor.constraint(equalTo: contentView.topAnchor),
            cardView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            cardView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            cardView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),

            previewContainer.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 10),
            previewContainer.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 10),
            previewContainer.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -10),

            nameLabel.topAnchor.constraint(equalTo: previewContainer.bottomAnchor, constant: 10),
            nameLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 12),
            nameLabel.trailingAnchor.constraint(equalTo: checkmark.leadingAnchor, constant: -4),

            colorDotsStack.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 6),
            colorDotsStack.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 12),
            colorDotsStack.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -10),

            checkmark.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -10),
            checkmark.centerYAnchor.constraint(equalTo: nameLabel.centerYAnchor),

            lockOverlay.topAnchor.constraint(equalTo: previewContainer.topAnchor),
            lockOverlay.leadingAnchor.constraint(equalTo: previewContainer.leadingAnchor),
            lockOverlay.trailingAnchor.constraint(equalTo: previewContainer.trailingAnchor),
            lockOverlay.bottomAnchor.constraint(equalTo: previewContainer.bottomAnchor),

            lockIcon.centerXAnchor.constraint(equalTo: lockOverlay.centerXAnchor),
            lockIcon.centerYAnchor.constraint(equalTo: lockOverlay.centerYAnchor),
        ])

        // Layout key rows
        let rows = previewContainer.subviews.compactMap { $0 as? UIStackView }
        for (i, row) in rows.enumerated() {
            let hPadding: CGFloat = i == 2 ? 12 : (i == 1 ? 6 : 4)
            NSLayoutConstraint.activate([
                row.leadingAnchor.constraint(equalTo: previewContainer.leadingAnchor, constant: hPadding),
                row.trailingAnchor.constraint(equalTo: previewContainer.trailingAnchor, constant: -hPadding),
                row.heightAnchor.constraint(equalToConstant: 14),
            ])
            if i == 0 {
                row.topAnchor.constraint(equalTo: previewContainer.topAnchor, constant: 6).isActive = true
            } else {
                row.topAnchor.constraint(equalTo: rows[i - 1].bottomAnchor, constant: 3).isActive = true
            }
            if i == rows.count - 1 {
                row.bottomAnchor.constraint(equalTo: previewContainer.bottomAnchor, constant: -6).isActive = true
            }
        }

        cardView.layer.borderWidth = 2
        cardView.layer.borderColor = UIColor.clear.cgColor
    }

    func configure(theme: KeyboardTheme, isSelected: Bool, isLocked: Bool) {
        cardView.backgroundColor = AppColors.card
        previewContainer.backgroundColor = theme.keyboardBackground

        for rowKeys in keyRows {
            for kv in rowKeys {
                kv.backgroundColor = theme.keyBackground
            }
        }
        if let lastRow = keyRows.last, lastRow.count >= 2 {
            lastRow.first?.backgroundColor = theme.specialKeyBackground
            lastRow.last?.backgroundColor = theme.specialKeyBackground
        }

        nameLabel.text = theme.localizedDisplayName

        let colors = [theme.keyboardBackground, theme.keyBackground, theme.specialKeyBackground, theme.keyTextColor]
        for (i, dot) in dotViews.enumerated() where i < colors.count {
            dot.backgroundColor = colors[i]
            dot.layer.borderWidth = 0.5
            dot.layer.borderColor = AppColors.border.cgColor
        }

        lockOverlay.isHidden = !isLocked
        checkmark.isHidden = isLocked || !isSelected

        if isLocked {
            nameLabel.textColor = AppColors.textMuted
            cardView.layer.borderColor = AppColors.border.cgColor
            cardView.layer.borderWidth = 1
        } else {
            nameLabel.textColor = AppColors.text
            checkmark.isHidden = !isSelected
            cardView.layer.borderColor = isSelected ? AppColors.accent.cgColor : AppColors.border.cgColor
            cardView.layer.borderWidth = isSelected ? 2 : 1
        }

        // VoiceOver
        isAccessibilityElement = true
        if isLocked {
            accessibilityLabel = "\(theme.localizedDisplayName), \(L("theme.section_premium")), \(L("accessibility.locked"))"
            accessibilityHint = L("accessibility.theme_locked_hint")
            accessibilityTraits = .button
        } else if isSelected {
            accessibilityLabel = "\(theme.localizedDisplayName), \(L("accessibility.selected"))"
            accessibilityTraits = [.button, .selected]
            accessibilityHint = nil
        } else {
            accessibilityLabel = theme.localizedDisplayName
            accessibilityTraits = .button
            accessibilityHint = L("accessibility.theme_select_hint")
        }
    }
}

// MARK: - PreviewKeyboardLayout

private enum PreviewKeyboardLayout {

    static func rows(for language: String) -> (row1: [String], row2: [String], row3: [String]) {
        switch language {
        case "ko":
            return (
                ["ㅂ","ㅈ","ㄷ","ㄱ","ㅅ","ㅛ","ㅕ","ㅑ","ㅐ","ㅔ"],
                ["ㅁ","ㄴ","ㅇ","ㄹ","ㅎ","ㅗ","ㅓ","ㅏ","ㅣ"],
                ["ㅋ","ㅌ","ㅊ","ㅍ","ㅠ","ㅜ","ㅡ"]
            )
        case "ru":
            return (
                ["Й","Ц","У","К","Е","Н","Г","Ш","Щ","З"],
                ["Ф","Ы","В","А","П","Р","О","Л","Д"],
                ["Я","Ч","С","М","И","Т","Ь"]
            )
        case "ja":
            return (
                ["あ","か","さ","た","な","は","ま","や","ら","わ"],
                ["い","き","し","ち","に","ひ","み","ゆ","り"],
                ["う","く","す","つ","ぬ","ふ","む"]
            )
        case "fr":
            return (
                ["A","Z","E","R","T","Y","U","I","O","P"],
                ["Q","S","D","F","G","H","J","K","L"],
                ["W","X","C","V","B","N","M"]
            )
        case "de":
            return (
                ["Q","W","E","R","T","Z","U","I","O","P"],
                ["A","S","D","F","G","H","J","K","L"],
                ["Y","X","C","V","B","N","M"]
            )
        default:
            return (
                ["Q","W","E","R","T","Y","U","I","O","P"],
                ["A","S","D","F","G","H","J","K","L"],
                ["Z","X","C","V","B","N","M"]
            )
        }
    }

    static func bottomRow(for language: String) -> (numKey: String, spaceLabel: String) {
        switch language {
        case "ko": return ("123", "간격")
        case "ja": return ("123", "空白")
        case "zh-Hans": return ("123", "空格")
        case "ru": return ("123", "пробел")
        case "es": return ("123", "espacio")
        case "fr": return ("123", "espace")
        case "de": return ("123", "Leerzeichen")
        case "it": return ("123", "spazio")
        default: return ("123", "space")
        }
    }
}

// MARK: - PremiumThemeCell

private class PremiumThemeCell: UICollectionViewCell {

    static let reuseId = "PremiumThemeCell"

    private let cardView: UIView = {
        let v = UIView()
        v.layer.cornerRadius = 16
        v.clipsToBounds = true
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private let previewContainer: UIView = {
        let v = UIView()
        v.layer.cornerRadius = 10
        v.clipsToBounds = true
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private var previewGradientLayer: CAGradientLayer?
    private var previewPatternView: UIView?

    private var keyLabels: [[UILabel]] = []
    private var specialKeyLabels: [UILabel] = []
    private var bottomKeyLabels: [UILabel] = []

    private var rowStacks: [UIStackView] = []
    private var bottomStack: UIStackView!

    private let nameLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 13, weight: .bold)
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let subtitleLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 10)
        l.textColor = .secondaryLabel
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let colorDotsStack: UIStackView = {
        let sv = UIStackView()
        sv.axis = .horizontal
        sv.spacing = 4
        sv.translatesAutoresizingMaskIntoConstraints = false
        return sv
    }()

    private var dotViews: [UIView] = []

    private let checkmark: UIImageView = {
        let config = UIImage.SymbolConfiguration(pointSize: 18, weight: .bold)
        let iv = UIImageView(image: UIImage(systemName: "checkmark.circle.fill", withConfiguration: config))
        iv.tintColor = AppColors.accent
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.isHidden = true
        return iv
    }()

    private let lockOverlay: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor(white: 0, alpha: 0.35)
        v.layer.cornerRadius = 10
        v.clipsToBounds = true
        v.isHidden = true
        v.isUserInteractionEnabled = false
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private let lockIcon: UIImageView = {
        let config = UIImage.SymbolConfiguration(pointSize: 28, weight: .medium)
        let iv = UIImageView(image: UIImage(systemName: "lock.fill", withConfiguration: config))
        iv.tintColor = .white
        iv.isUserInteractionEnabled = false
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }

    required init?(coder: NSCoder) { fatalError() }

    override func prepareForReuse() {
        super.prepareForReuse()
        lockOverlay.isHidden = true
        checkmark.isHidden = true
        previewGradientLayer?.removeFromSuperlayer()
        previewGradientLayer = nil
        previewPatternView?.isHidden = true
        cardView.layer.borderColor = UIColor.clear.cgColor
        cardView.layer.borderWidth = 1
        accessibilityLabel = nil
        accessibilityHint = nil
        accessibilityTraits = .button
    }

    private func setupViews() {
        contentView.addSubview(cardView)
        cardView.addSubview(previewContainer)
        cardView.addSubview(nameLabel)
        cardView.addSubview(subtitleLabel)
        cardView.addSubview(colorDotsStack)
        cardView.addSubview(checkmark)

        // 3행 키보드 행 생성
        for rowIndex in 0..<3 {
            let stack = UIStackView()
            stack.axis = .horizontal
            stack.spacing = 2
            stack.distribution = .fillEqually
            stack.translatesAutoresizingMaskIntoConstraints = false

            var labels: [UILabel] = []
            let keyCount = rowIndex == 0 ? 10 : (rowIndex == 1 ? 9 : 7)

            if rowIndex == 2 {
                let shiftLabel = makeKeyLabel(text: "⇧", isSpecial: true)
                stack.addArrangedSubview(shiftLabel)
                specialKeyLabels.append(shiftLabel)
            }

            for _ in 0..<keyCount {
                let label = makeKeyLabel(text: "", isSpecial: false)
                labels.append(label)
                stack.addArrangedSubview(label)
            }

            if rowIndex == 2 {
                let bsLabel = makeKeyLabel(text: "⌫", isSpecial: true)
                stack.addArrangedSubview(bsLabel)
                specialKeyLabels.append(bsLabel)
            }

            keyLabels.append(labels)
            rowStacks.append(stack)
            previewContainer.addSubview(stack)
        }

        // 하단 행: 123 | 🌐 | space(넓게) | . | ↵
        bottomStack = UIStackView()
        bottomStack.axis = .horizontal
        bottomStack.spacing = 2
        bottomStack.translatesAutoresizingMaskIntoConstraints = false

        let numLabel = makeKeyLabel(text: "123", isSpecial: true)
        let globeLabel = makeKeyLabel(text: "🌐", isSpecial: true)
        let spaceLabel = makeKeyLabel(text: "space", isSpecial: false)
        let periodLabel = makeKeyLabel(text: ".", isSpecial: false)
        let returnLabel = makeKeyLabel(text: "↵", isSpecial: true)

        bottomKeyLabels = [numLabel, globeLabel, spaceLabel, periodLabel, returnLabel]

        bottomStack.addArrangedSubview(numLabel)
        bottomStack.addArrangedSubview(globeLabel)
        bottomStack.addArrangedSubview(spaceLabel)
        bottomStack.addArrangedSubview(periodLabel)
        bottomStack.addArrangedSubview(returnLabel)
        previewContainer.addSubview(bottomStack)

        // 잠금 오버레이 (키 위에)
        previewContainer.addSubview(lockOverlay)
        lockOverlay.addSubview(lockIcon)

        // 컬러 도트 4개
        for _ in 0..<4 {
            let dot = UIView()
            dot.layer.cornerRadius = 4
            dot.translatesAutoresizingMaskIntoConstraints = false
            dot.widthAnchor.constraint(equalToConstant: 8).isActive = true
            dot.heightAnchor.constraint(equalToConstant: 8).isActive = true
            dotViews.append(dot)
            colorDotsStack.addArrangedSubview(dot)
        }

        setupConstraints()
    }

    private func makeKeyLabel(text: String, isSpecial: Bool) -> UILabel {
        let l = UILabel()
        l.text = text
        l.textAlignment = .center
        l.font = .systemFont(ofSize: isSpecial ? 7 : 8.5, weight: isSpecial ? .semibold : .medium)
        l.layer.cornerRadius = 3
        l.clipsToBounds = true
        l.translatesAutoresizingMaskIntoConstraints = false
        l.heightAnchor.constraint(equalToConstant: 22).isActive = true
        return l
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            cardView.topAnchor.constraint(equalTo: contentView.topAnchor),
            cardView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            cardView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            cardView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),

            previewContainer.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 10),
            previewContainer.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 10),
            previewContainer.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -10),

            nameLabel.topAnchor.constraint(equalTo: previewContainer.bottomAnchor, constant: 10),
            nameLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 12),
            nameLabel.trailingAnchor.constraint(equalTo: checkmark.leadingAnchor, constant: -4),

            subtitleLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 2),
            subtitleLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 12),
            subtitleLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -12),

            colorDotsStack.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 6),
            colorDotsStack.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 12),
            colorDotsStack.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -10),

            checkmark.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -10),
            checkmark.centerYAnchor.constraint(equalTo: nameLabel.centerYAnchor),

            lockOverlay.topAnchor.constraint(equalTo: previewContainer.topAnchor),
            lockOverlay.leadingAnchor.constraint(equalTo: previewContainer.leadingAnchor),
            lockOverlay.trailingAnchor.constraint(equalTo: previewContainer.trailingAnchor),
            lockOverlay.bottomAnchor.constraint(equalTo: previewContainer.bottomAnchor),

            lockIcon.centerXAnchor.constraint(equalTo: lockOverlay.centerXAnchor),
            lockIcon.centerYAnchor.constraint(equalTo: lockOverlay.centerYAnchor),
        ])

        // 키보드 행 레이아웃
        for (i, stack) in rowStacks.enumerated() {
            let hPadding: CGFloat = i == 2 ? 4 : (i == 1 ? 6 : 4)
            NSLayoutConstraint.activate([
                stack.leadingAnchor.constraint(equalTo: previewContainer.leadingAnchor, constant: hPadding),
                stack.trailingAnchor.constraint(equalTo: previewContainer.trailingAnchor, constant: -hPadding),
            ])
            if i == 0 {
                stack.topAnchor.constraint(equalTo: previewContainer.topAnchor, constant: 6).isActive = true
            } else {
                stack.topAnchor.constraint(equalTo: rowStacks[i - 1].bottomAnchor, constant: 3).isActive = true
            }
        }

        // 하단 행
        NSLayoutConstraint.activate([
            bottomStack.leadingAnchor.constraint(equalTo: previewContainer.leadingAnchor, constant: 4),
            bottomStack.trailingAnchor.constraint(equalTo: previewContainer.trailingAnchor, constant: -4),
            bottomStack.topAnchor.constraint(equalTo: rowStacks.last!.bottomAnchor, constant: 3),
            bottomStack.bottomAnchor.constraint(equalTo: previewContainer.bottomAnchor, constant: -6),
        ])

        // Space 키 flex 비율
        let numL = bottomKeyLabels[0]
        let globeL = bottomKeyLabels[1]
        let spaceL = bottomKeyLabels[2]
        let periodL = bottomKeyLabels[3]
        let returnL = bottomKeyLabels[4]
        spaceL.widthAnchor.constraint(equalTo: numL.widthAnchor, multiplier: 4.0).isActive = true
        globeL.widthAnchor.constraint(equalTo: numL.widthAnchor, multiplier: 0.8).isActive = true
        periodL.widthAnchor.constraint(equalTo: numL.widthAnchor, multiplier: 0.6).isActive = true
        returnL.widthAnchor.constraint(equalTo: numL.widthAnchor, multiplier: 1.2).isActive = true

        cardView.layer.borderWidth = 1
        cardView.layer.borderColor = UIColor.clear.cgColor
    }

    func configure(theme: KeyboardTheme, isSelected: Bool, isLocked: Bool) {
        cardView.backgroundColor = AppColors.card

        // 1. 그라데이션 배경
        if theme.hasGradient, let colors = theme.gradientColors {
            previewContainer.backgroundColor = .clear
            if previewGradientLayer == nil {
                let gl = CAGradientLayer()
                previewContainer.layer.insertSublayer(gl, at: 0)
                previewGradientLayer = gl
            }
            previewGradientLayer?.colors = colors.map { $0.cgColor }
            previewGradientLayer?.locations = theme.gradientLocations
            previewGradientLayer?.startPoint = theme.gradientDirection.startPoint
            previewGradientLayer?.endPoint = theme.gradientDirection.endPoint
            previewGradientLayer?.frame = previewContainer.bounds
        } else {
            previewGradientLayer?.removeFromSuperlayer()
            previewGradientLayer = nil
            previewContainer.backgroundColor = theme.keyboardBackground
        }

        // 2. 패턴 오버레이
        if theme.hasPattern {
            if previewPatternView == nil {
                let pv = UIView()
                pv.isUserInteractionEnabled = false
                pv.translatesAutoresizingMaskIntoConstraints = false
                previewContainer.insertSubview(pv, belowSubview: lockOverlay)
                NSLayoutConstraint.activate([
                    pv.topAnchor.constraint(equalTo: previewContainer.topAnchor),
                    pv.leadingAnchor.constraint(equalTo: previewContainer.leadingAnchor),
                    pv.trailingAnchor.constraint(equalTo: previewContainer.trailingAnchor),
                    pv.bottomAnchor.constraint(equalTo: previewContainer.bottomAnchor),
                ])
                previewPatternView = pv
            }
            if let img = ThemePatternRenderer.patternImage(
                style: theme.patternStyle, tint: theme.patternTint,
                opacity: theme.patternOpacity, size: CGSize(width: 64, height: 64)
            ) {
                previewPatternView?.backgroundColor = UIColor(patternImage: img)
                previewPatternView?.isHidden = false
            }
        } else {
            previewPatternView?.isHidden = true
        }

        // 3. 키 레이블 언어별 설정
        let lang = LocalizationManager.shared.currentLanguage.rawValue
        let layout = PreviewKeyboardLayout.rows(for: lang)
        let bottom = PreviewKeyboardLayout.bottomRow(for: lang)

        let rows = [layout.row1, layout.row2, layout.row3]
        for (i, rowLabels) in keyLabels.enumerated() {
            for (j, label) in rowLabels.enumerated() {
                label.text = j < rows[i].count ? rows[i][j] : ""
                switch theme.keyVisualStyle {
                case .solid:
                    label.backgroundColor = theme.keyBackground
                case .translucent(let alpha, let tint):
                    label.backgroundColor = tint.withAlphaComponent(alpha)
                }
                label.textColor = theme.keyTextColor
            }
        }

        // 특수 키 (⇧, ⌫)
        for label in specialKeyLabels {
            switch theme.specialKeyVisualStyle {
            case .solid:
                label.backgroundColor = theme.specialKeyBackground
            case .translucent(let alpha, let tint):
                label.backgroundColor = tint.withAlphaComponent(alpha)
            }
            label.textColor = theme.keyTextColor
        }

        // 하단 행
        bottomKeyLabels[0].text = bottom.numKey
        bottomKeyLabels[2].text = bottom.spaceLabel
        for (i, label) in bottomKeyLabels.enumerated() {
            let isSpecialKey = (i == 0 || i == 1 || i == 4)
            if isSpecialKey {
                switch theme.specialKeyVisualStyle {
                case .solid: label.backgroundColor = theme.specialKeyBackground
                case .translucent(let a, let t): label.backgroundColor = t.withAlphaComponent(a)
                }
            } else {
                switch theme.keyVisualStyle {
                case .solid: label.backgroundColor = theme.keyBackground
                case .translucent(let a, let t): label.backgroundColor = t.withAlphaComponent(a)
                }
            }
            label.textColor = theme.keyTextColor
        }

        // 4. 테마 정보
        nameLabel.text = theme.localizedDisplayName
        nameLabel.textColor = isLocked ? AppColors.textMuted : AppColors.text

        let englishName = theme.id
            .replacingOccurrences(of: "premium_", with: "")
            .replacingOccurrences(of: "_", with: " ")
            .capitalized
        subtitleLabel.text = englishName
        subtitleLabel.textColor = AppColors.textMuted

        // 컬러 도트
        let dotColors = [theme.keyboardBackground, theme.keyBackground, theme.specialKeyBackground, theme.keyTextColor]
        for (i, dot) in dotViews.enumerated() where i < dotColors.count {
            dot.backgroundColor = dotColors[i]
            dot.layer.borderWidth = 0.5
            dot.layer.borderColor = AppColors.border.cgColor
        }

        // 5. 잠금/선택 상태
        lockOverlay.isHidden = !isLocked
        checkmark.isHidden = isLocked || !isSelected

        if isLocked {
            cardView.layer.borderColor = AppColors.border.cgColor
            cardView.layer.borderWidth = 1
        } else {
            cardView.layer.borderColor = isSelected ? AppColors.accent.cgColor : AppColors.border.cgColor
            cardView.layer.borderWidth = isSelected ? 2.5 : 1
        }

        // 6. VoiceOver
        isAccessibilityElement = true
        if isLocked {
            accessibilityLabel = "\(theme.localizedDisplayName), \(L("theme.section_premium")), \(L("accessibility.locked"))"
            accessibilityHint = L("accessibility.theme_locked_hint")
            accessibilityTraits = .button
        } else if isSelected {
            accessibilityLabel = "\(theme.localizedDisplayName), \(L("accessibility.selected"))"
            accessibilityTraits = [.button, .selected]
        } else {
            accessibilityLabel = theme.localizedDisplayName
            accessibilityTraits = .button
            accessibilityHint = L("accessibility.theme_select_hint")
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        previewGradientLayer?.frame = previewContainer.bounds
    }
}
