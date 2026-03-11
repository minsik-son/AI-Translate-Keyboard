import UIKit

class ThemeSelectionViewController: UIViewController {

    private let freeThemes = KeyboardTheme.allThemes
    private let premiumThemes = KeyboardTheme.allPremiumThemes
    private var isPaywallPresenting = false

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
        isPaywallPresenting = false
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
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ThemeCell.reuseId, for: indexPath) as! ThemeCell

        let theme: KeyboardTheme
        if indexPath.section == 0 {
            theme = freeThemes[indexPath.item]
        } else {
            theme = premiumThemes[indexPath.item]
        }

        let isPro = SubscriptionStatus.shared.isPro
        let isLocked = theme.isPremium && !isPro
        let isSelected = theme.id == selectedThemeId

        cell.configure(theme: theme, isSelected: isSelected, isLocked: isLocked)
        return cell
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
        return CGSize(width: floor(width), height: floor(width) * 1.15)
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
            guard !isPaywallPresenting else { return }
            isPaywallPresenting = true

            let paywallVC = PaywallViewController()
            paywallVC.modalPresentationStyle = .pageSheet
            self.present(paywallVC, animated: true)
            return
        }

        let previousId = selectedThemeId
        selectedThemeId = theme.id
        AppGroupManager.shared.set(theme.id, forKey: AppConstants.UserDefaultsKeys.keyboardTheme)

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
