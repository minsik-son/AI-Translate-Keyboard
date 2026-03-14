import UIKit

// MARK: - Theme Category

enum ThemeCategory: String, CaseIterable {
    case all         = "theme.category_all"
    case free        = "theme.category_free"
    case neon        = "theme.category_neon"
    case nature      = "theme.category_nature"
    case animation   = "theme.category_animation"
    case space       = "theme.category_space"
    case minimal     = "theme.category_minimal"

    var localizedName: String { L(rawValue) }
}

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

    // MARK: - Category Tag Map
    // 태그가 없는 테마는 "전체"에만 표시됨
    private static let themeTagMap: [String: Set<ThemeCategory>] = [
        // 무료 테마 12개: .free 태그 일괄 부여 (allThemes에서 자동 처리)

        // 프리미엄 - 네온
        "premium_midnight_aurora":  [.neon, .space],
        "premium_starlit_night":    [.neon, .space],
        "premium_matrix_pulse":     [.neon, .animation],
        "premium_digital_rain":     [.neon, .animation],

        // 프리미엄 - 자연
        "premium_ocean_abyss":      [.nature],
        "premium_sunset_ember":     [.nature],
        "premium_volcanic_ember":   [.nature],
        "premium_northern_lights":  [.nature],
        "premium_sakura_breeze":    [.nature],
        "premium_deep_ocean":       [.nature],
        "premium_dark_walnut":      [.nature],
        "premium_natural_oak":      [.nature],
        "premium_mercury_ripple":   [.nature, .animation],

        // 프리미엄 - 우주
        "premium_stardust_drift":   [.space, .animation],
        "premium_edge_glow_green":  [.neon, .animation],
        "premium_edge_glow_red":    [.neon, .animation],
        "premium_edge_glow_blue":   [.neon, .animation],
        "premium_edge_glow_yellow": [.neon, .animation],
        "premium_edge_glow_purple": [.neon, .animation],

        // 프리미엄 - 미니멀
        "premium_rose_gold":        [.minimal],
        "premium_frost_crystal":    [.minimal],
        "premium_brushed_steel":    [.minimal],
    ]

    private var selectedCategory: ThemeCategory = .all
    private var filteredFreeThemes: [KeyboardTheme] = []
    private var filteredPremiumThemes: [KeyboardTheme] = []

    // MARK: - Category Tab Bar

    private lazy var categoryScrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.showsHorizontalScrollIndicator = false
        sv.translatesAutoresizingMaskIntoConstraints = false
        sv.backgroundColor = AppColors.bg
        return sv
    }()

    private lazy var categoryStack: UIStackView = {
        let sv = UIStackView()
        sv.axis = .horizontal
        sv.spacing = 8
        sv.translatesAutoresizingMaskIntoConstraints = false
        return sv
    }()

    private var categoryButtons: [UIButton] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = L("settings.keyboard_theme")
        view.backgroundColor = AppColors.bg
        navigationController?.navigationBar.prefersLargeTitles = true

        setupCategoryTabBar()

        view.addSubview(collectionView)
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: categoryScrollView.bottomAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])

        selectedThemeId = AppGroupManager.shared.string(forKey: AppConstants.UserDefaultsKeys.keyboardTheme) ?? "default"
        applyFilter()   // 초기 필터 적용 (전체)

        NotificationCenter.default.addObserver(self, selector: #selector(handleLanguageChange), name: .languageDidChange, object: nil)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        selectedThemeId = AppGroupManager.shared.string(forKey: AppConstants.UserDefaultsKeys.keyboardTheme) ?? "default"
        applyFilter()
    }

    @objc private func handleLanguageChange() {
        navigationItem.title = L("settings.keyboard_theme")
        // 카테고리 버튼 텍스트 갱신
        for (index, button) in categoryButtons.enumerated() {
            let category = ThemeCategory.allCases[index]
            button.setTitle(category.localizedName, for: .normal)
        }
        collectionView.reloadData()
    }

    private func findIndexPath(forThemeId id: String) -> IndexPath? {
        if let index = freeThemes.firstIndex(where: { $0.id == id }) {
            return IndexPath(item: index, section: 0)
        }
        if let index = premiumThemes.firstIndex(where: { $0.id == id }) {
            return IndexPath(item: index, section: 1)
        }
        return nil
    }

    /// 필터된 배열에서 테마 ID로 IndexPath 찾기
    private func findFilteredIndexPath(forThemeId id: String) -> IndexPath? {
        if let index = filteredFreeThemes.firstIndex(where: { $0.id == id }) {
            return IndexPath(item: index, section: 0)
        }
        if let index = filteredPremiumThemes.firstIndex(where: { $0.id == id }) {
            let premiumSection = filteredFreeThemes.isEmpty ? 0 : 1
            return IndexPath(item: index, section: premiumSection)
        }
        return nil
    }

    // MARK: - Filtering

    private func applyFilter() {
        switch selectedCategory {
        case .all:
            filteredFreeThemes = freeThemes
            filteredPremiumThemes = premiumThemes
        case .free:
            filteredFreeThemes = freeThemes
            filteredPremiumThemes = []
        default:
            filteredFreeThemes = freeThemes.filter { theme in
                Self.themeTagMap[theme.id]?.contains(selectedCategory) == true
            }
            filteredPremiumThemes = premiumThemes.filter { theme in
                Self.themeTagMap[theme.id]?.contains(selectedCategory) == true
            }
        }
        collectionView.reloadData()
    }

    private func setupCategoryTabBar() {
        view.addSubview(categoryScrollView)
        categoryScrollView.addSubview(categoryStack)

        NSLayoutConstraint.activate([
            categoryScrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            categoryScrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            categoryScrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            categoryScrollView.heightAnchor.constraint(equalToConstant: 48),

            categoryStack.topAnchor.constraint(equalTo: categoryScrollView.topAnchor, constant: 8),
            categoryStack.leadingAnchor.constraint(equalTo: categoryScrollView.leadingAnchor, constant: 20),
            categoryStack.trailingAnchor.constraint(equalTo: categoryScrollView.trailingAnchor, constant: -20),
            categoryStack.bottomAnchor.constraint(equalTo: categoryScrollView.bottomAnchor, constant: -8),
            categoryStack.heightAnchor.constraint(equalToConstant: 32),
        ])

        for (index, category) in ThemeCategory.allCases.enumerated() {
            let button = UIButton(type: .system)
            button.setTitle(category.localizedName, for: .normal)
            button.titleLabel?.font = .systemFont(ofSize: 13, weight: .semibold)
            button.layer.cornerRadius = 16
            button.clipsToBounds = true
            button.tag = index
            button.contentEdgeInsets = UIEdgeInsets(top: 6, left: 16, bottom: 6, right: 16)
            button.addTarget(self, action: #selector(categoryTapped(_:)), for: .touchUpInside)

            categoryButtons.append(button)
            categoryStack.addArrangedSubview(button)
        }

        updateCategoryButtonStyles()
    }

    @objc private func categoryTapped(_ sender: UIButton) {
        let categories = ThemeCategory.allCases
        guard sender.tag < categories.count else { return }

        selectedCategory = categories[sender.tag]
        updateCategoryButtonStyles()
        applyFilter()

        // 탭 변경 시 컬렉션뷰 맨 위로 스크롤
        if collectionView.numberOfSections > 0,
           collectionView.numberOfItems(inSection: 0) > 0 {
            collectionView.scrollToItem(at: IndexPath(item: 0, section: 0),
                                         at: .top, animated: false)
        } else {
            collectionView.setContentOffset(.zero, animated: false)
        }
    }

    private func updateCategoryButtonStyles() {
        for (index, button) in categoryButtons.enumerated() {
            let category = ThemeCategory.allCases[index]
            let isSelected = category == selectedCategory

            if isSelected {
                button.backgroundColor = AppColors.accent
                button.setTitleColor(.white, for: .normal)
                button.layer.borderWidth = 0
            } else {
                button.backgroundColor = AppColors.card
                button.setTitleColor(AppColors.textSub, for: .normal)
                button.layer.borderWidth = 1
                button.layer.borderColor = AppColors.border.cgColor
            }
        }
    }
}

// MARK: - UICollectionViewDataSource & Delegate

extension ThemeSelectionViewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        var count = 0
        if !filteredFreeThemes.isEmpty { count += 1 }
        if !filteredPremiumThemes.isEmpty { count += 1 }
        return count
    }

    /// 실제 섹션 인덱스 → free/premium 판별
    private enum SectionType {
        case free, premium
    }

    private func sectionType(for section: Int) -> SectionType {
        if !filteredFreeThemes.isEmpty {
            return section == 0 ? .free : .premium
        }
        return .premium
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        switch sectionType(for: section) {
        case .free:    return filteredFreeThemes.count
        case .premium: return filteredPremiumThemes.count
        }
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let theme: KeyboardTheme
        let type = sectionType(for: indexPath.section)
        switch type {
        case .free:    theme = filteredFreeThemes[indexPath.item]
        case .premium: theme = filteredPremiumThemes[indexPath.item]
        }

        #if DEBUG
        let isLocked = false
        #else
        let isPro = SubscriptionStatus.shared.isPro
        let isLocked = theme.isPremium && !isPro
        #endif
        let isSelected = theme.id == selectedThemeId

        switch type {
        case .premium:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: PremiumThemeCell.reuseId, for: indexPath) as! PremiumThemeCell
            cell.configure(theme: theme, isSelected: isSelected, isLocked: isLocked)
            return cell
        case .free:
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

        switch sectionType(for: indexPath.section) {
        case .free:
            header.configure(title: L("theme.section_free"), showBadge: false)
        case .premium:
            header.configure(title: L("theme.section_premium"), showBadge: true)
        }
        return header
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        // 섹션에 아이템이 없으면 헤더도 숨김 (안전장치)
        let itemCount = collectionView.numberOfItems(inSection: section)
        guard itemCount > 0 else { return .zero }
        return CGSize(width: collectionView.bounds.width, height: 44)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let totalSpacing: CGFloat = 20 * 2 + 14
        let width = (collectionView.bounds.width - totalSpacing) / 2
        switch sectionType(for: indexPath.section) {
        case .premium:
            return CGSize(width: floor(width), height: floor(width) * 1.45)
        case .free:
            return CGSize(width: floor(width), height: floor(width) * 1.15)
        }
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let theme: KeyboardTheme
        switch sectionType(for: indexPath.section) {
        case .free:    theme = filteredFreeThemes[indexPath.item]
        case .premium: theme = filteredPremiumThemes[indexPath.item]
        }

        #if DEBUG
        // 개발 모드: Paywall 건너뜀
        #else
        let isPro = SubscriptionStatus.shared.isPro
        if theme.isPremium && !isPro {
            guard self.presentedViewController == nil else { return }
            let paywallVC = PaywallViewController()
            paywallVC.modalPresentationStyle = .pageSheet
            self.present(paywallVC, animated: true)
            return
        }
        #endif

        let previousId = selectedThemeId
        selectedThemeId = theme.id
        AppGroupManager.shared.set(theme.id, forKey: AppConstants.UserDefaultsKeys.keyboardTheme)
        ThemePatternRenderer.clearCache()

        // 필터된 배열에서 이전 선택 찾기 (안전 검증 포함)
        var indexPaths = [indexPath]
        if let prevPath = findFilteredIndexPath(forThemeId: previousId),
           prevPath != indexPath,
           prevPath.section < collectionView.numberOfSections,
           prevPath.item < collectionView.numberOfItems(inSection: prevPath.section) {
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

        // lockOverlay: added AFTER key rows for correct Z-order
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
        // Last row: make first and last keys use special key color
        if let lastRow = keyRows.last, lastRow.count >= 2 {
            lastRow.first?.backgroundColor = theme.specialKeyBackground
            lastRow.last?.backgroundColor = theme.specialKeyBackground
        }

        nameLabel.text = theme.localizedDisplayName

        // Color palette dots
        let colors = [theme.keyboardBackground, theme.keyBackground, theme.specialKeyBackground, theme.keyTextColor]
        for (i, dot) in dotViews.enumerated() where i < colors.count {
            dot.backgroundColor = colors[i]
            dot.layer.borderWidth = 0.5
            dot.layer.borderColor = AppColors.border.cgColor
        }

        // Lock state
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

        // VoiceOver accessibility
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
    private var bottomRow: UIView!

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

        // woodBlock cleanup
        for rowLabels in keyLabels {
            for label in rowLabels {
                label.clipsToBounds = true
                label.layer.borderWidth = 0
                label.layer.shadowOpacity = 0
            }
        }
        for label in specialKeyLabels {
            label.clipsToBounds = true
            label.layer.borderWidth = 0
            label.layer.shadowOpacity = 0
        }
        for label in bottomKeyLabels {
            label.clipsToBounds = true
            label.layer.borderWidth = 0
            label.layer.shadowOpacity = 0
        }

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

        // Bottom row
        bottomRow = UIView()
        bottomRow.translatesAutoresizingMaskIntoConstraints = false

        let numLabel = makeKeyLabel(text: "123", isSpecial: true)
        let globeLabel = makeKeyLabel(text: "🌐", isSpecial: true)
        let spaceLabel = makeKeyLabel(text: "space", isSpecial: false)
        let periodLabel = makeKeyLabel(text: ".", isSpecial: false)
        let returnLabel = makeKeyLabel(text: "↵", isSpecial: true)

        bottomKeyLabels = [numLabel, globeLabel, spaceLabel, periodLabel, returnLabel]

        for label in bottomKeyLabels {
            bottomRow.addSubview(label)
        }

        previewContainer.addSubview(bottomRow)

        // Lock overlay
        previewContainer.addSubview(lockOverlay)
        lockOverlay.addSubview(lockIcon)

        // Color dots
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

        // Keyboard rows layout
        for (i, stack) in rowStacks.enumerated() {
            let hPadding: CGFloat = i == 2 ? 2 : (i == 1 ? 4 : 4)
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

        // Bottom row container
        NSLayoutConstraint.activate([
            bottomRow.leadingAnchor.constraint(equalTo: previewContainer.leadingAnchor, constant: 4),
            bottomRow.trailingAnchor.constraint(equalTo: previewContainer.trailingAnchor, constant: -4),
            bottomRow.topAnchor.constraint(equalTo: rowStacks.last!.bottomAnchor, constant: 3),
            bottomRow.bottomAnchor.constraint(equalTo: previewContainer.bottomAnchor, constant: -6),
        ])

        // Bottom row labels — pure Auto Layout chaining + ratio constraints
        let spacing: CGFloat = 2
        let numL = bottomKeyLabels[0]
        let globeL = bottomKeyLabels[1]
        let spaceL = bottomKeyLabels[2]
        let periodL = bottomKeyLabels[3]
        let returnL = bottomKeyLabels[4]

        NSLayoutConstraint.activate([
            numL.topAnchor.constraint(equalTo: bottomRow.topAnchor),
            numL.bottomAnchor.constraint(equalTo: bottomRow.bottomAnchor),
            globeL.topAnchor.constraint(equalTo: bottomRow.topAnchor),
            globeL.bottomAnchor.constraint(equalTo: bottomRow.bottomAnchor),
            spaceL.topAnchor.constraint(equalTo: bottomRow.topAnchor),
            spaceL.bottomAnchor.constraint(equalTo: bottomRow.bottomAnchor),
            periodL.topAnchor.constraint(equalTo: bottomRow.topAnchor),
            periodL.bottomAnchor.constraint(equalTo: bottomRow.bottomAnchor),
            returnL.topAnchor.constraint(equalTo: bottomRow.topAnchor),
            returnL.bottomAnchor.constraint(equalTo: bottomRow.bottomAnchor),

            numL.leadingAnchor.constraint(equalTo: bottomRow.leadingAnchor),
            globeL.leadingAnchor.constraint(equalTo: numL.trailingAnchor, constant: spacing),
            spaceL.leadingAnchor.constraint(equalTo: globeL.trailingAnchor, constant: spacing),
            periodL.leadingAnchor.constraint(equalTo: spaceL.trailingAnchor, constant: spacing),
            returnL.leadingAnchor.constraint(equalTo: periodL.trailingAnchor, constant: spacing),
            returnL.trailingAnchor.constraint(equalTo: bottomRow.trailingAnchor),

            globeL.widthAnchor.constraint(equalTo: numL.widthAnchor, multiplier: 0.8),
            spaceL.widthAnchor.constraint(equalTo: numL.widthAnchor, multiplier: 4.0),
            periodL.widthAnchor.constraint(equalTo: numL.widthAnchor, multiplier: 0.6),
            returnL.widthAnchor.constraint(equalTo: numL.widthAnchor, multiplier: 1.2),
        ])

        cardView.layer.borderWidth = 1
        cardView.layer.borderColor = UIColor.clear.cgColor
    }

    func configure(theme: KeyboardTheme, isSelected: Bool, isLocked: Bool) {
        cardView.backgroundColor = AppColors.card

        // 1. Gradient background
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

        // 2. Pattern overlay
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

        // 3. Key labels by language
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
                case .woodBlock(let borderColor, let shadowColor, _):
                    label.backgroundColor = theme.keyBackground
                    label.layer.borderWidth = 0.5
                    label.layer.borderColor = borderColor.cgColor
                    label.clipsToBounds = false
                    label.layer.shadowColor = shadowColor.cgColor
                    label.layer.shadowOffset = CGSize(width: 0, height: 1.5)
                    label.layer.shadowRadius = 0.8
                    label.layer.shadowOpacity = 1.0
                case .edgeGlow(let borderColor, let glowColor):
                    label.backgroundColor = .clear
                    label.layer.borderWidth = 0.5
                    label.layer.borderColor = borderColor.withAlphaComponent(0.5).cgColor
                    label.clipsToBounds = false
                    label.layer.shadowColor = glowColor.cgColor
                    label.layer.shadowOffset = .zero
                    label.layer.shadowRadius = 1.5
                    label.layer.shadowOpacity = 0.3
                }
                label.textColor = theme.keyTextColor
            }
        }

        for label in specialKeyLabels {
            switch theme.specialKeyVisualStyle {
            case .solid:
                label.backgroundColor = theme.specialKeyBackground
            case .translucent(let alpha, let tint):
                label.backgroundColor = tint.withAlphaComponent(alpha)
            case .woodBlock(let borderColor, let shadowColor, _):
                label.backgroundColor = theme.specialKeyBackground
                label.layer.borderWidth = 0.5
                label.layer.borderColor = borderColor.cgColor
                label.clipsToBounds = false
                label.layer.shadowColor = shadowColor.cgColor
                label.layer.shadowOffset = CGSize(width: 0, height: 1.5)
                label.layer.shadowRadius = 0.8
                label.layer.shadowOpacity = 1.0
            case .edgeGlow(let borderColor, let glowColor):
                label.backgroundColor = .clear
                label.layer.borderWidth = 0.5
                label.layer.borderColor = borderColor.withAlphaComponent(0.5).cgColor
                label.clipsToBounds = false
                label.layer.shadowColor = glowColor.cgColor
                label.layer.shadowOffset = .zero
                label.layer.shadowRadius = 1.5
                label.layer.shadowOpacity = 0.3
            }
            label.textColor = theme.keyTextColor
        }

        bottomKeyLabels[0].text = bottom.numKey
        bottomKeyLabels[2].text = bottom.spaceLabel
        for (i, label) in bottomKeyLabels.enumerated() {
            let isSpecial = (i == 0 || i == 1 || i == 4)
            if isSpecial {
                switch theme.specialKeyVisualStyle {
                case .solid: label.backgroundColor = theme.specialKeyBackground
                case .translucent(let a, let t): label.backgroundColor = t.withAlphaComponent(a)
                case .woodBlock(let borderColor, let shadowColor, _):
                    label.backgroundColor = theme.specialKeyBackground
                    label.layer.borderWidth = 0.5
                    label.layer.borderColor = borderColor.cgColor
                    label.clipsToBounds = false
                    label.layer.shadowColor = shadowColor.cgColor
                    label.layer.shadowOffset = CGSize(width: 0, height: 1.5)
                    label.layer.shadowRadius = 0.8
                    label.layer.shadowOpacity = 1.0
                case .edgeGlow(let borderColor, let glowColor):
                    label.backgroundColor = .clear
                    label.layer.borderWidth = 0.5
                    label.layer.borderColor = borderColor.withAlphaComponent(0.5).cgColor
                    label.clipsToBounds = false
                    label.layer.shadowColor = glowColor.cgColor
                    label.layer.shadowOffset = .zero
                    label.layer.shadowRadius = 1.5
                    label.layer.shadowOpacity = 0.3
                }
            } else {
                switch theme.keyVisualStyle {
                case .solid: label.backgroundColor = theme.keyBackground
                case .translucent(let a, let t): label.backgroundColor = t.withAlphaComponent(a)
                case .woodBlock(let borderColor, let shadowColor, _):
                    label.backgroundColor = theme.keyBackground
                    label.layer.borderWidth = 0.5
                    label.layer.borderColor = borderColor.cgColor
                    label.clipsToBounds = false
                    label.layer.shadowColor = shadowColor.cgColor
                    label.layer.shadowOffset = CGSize(width: 0, height: 1.5)
                    label.layer.shadowRadius = 0.8
                    label.layer.shadowOpacity = 1.0
                case .edgeGlow(let borderColor, let glowColor):
                    label.backgroundColor = .clear
                    label.layer.borderWidth = 0.5
                    label.layer.borderColor = borderColor.withAlphaComponent(0.5).cgColor
                    label.clipsToBounds = false
                    label.layer.shadowColor = glowColor.cgColor
                    label.layer.shadowOffset = .zero
                    label.layer.shadowRadius = 1.5
                    label.layer.shadowOpacity = 0.3
                }
            }
            label.textColor = theme.keyTextColor
        }

        // 4. Theme info
        nameLabel.text = theme.localizedDisplayName
        nameLabel.textColor = isLocked ? AppColors.textMuted : AppColors.text

        let englishName = theme.id
            .replacingOccurrences(of: "premium_", with: "")
            .replacingOccurrences(of: "_", with: " ")
            .capitalized
        subtitleLabel.text = englishName
        subtitleLabel.textColor = AppColors.textMuted

        let dotColors = [theme.keyboardBackground, theme.keyBackground, theme.specialKeyBackground, theme.keyTextColor]
        for (i, dot) in dotViews.enumerated() where i < dotColors.count {
            dot.backgroundColor = dotColors[i]
            dot.layer.borderWidth = 0.5
            dot.layer.borderColor = AppColors.border.cgColor
        }

        // 5. Lock/selection state
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
