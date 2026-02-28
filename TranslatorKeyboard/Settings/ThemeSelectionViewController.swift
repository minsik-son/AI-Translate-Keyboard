import UIKit

class ThemeSelectionViewController: UIViewController {

    private let themes = KeyboardTheme.allThemes

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
        return cv
    }()

    private var selectedThemeId: String = "default"

    override func viewDidLoad() {
        super.viewDidLoad()
        title = L("settings.keyboard_theme")
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
    }
}

// MARK: - UICollectionViewDataSource & Delegate

extension ThemeSelectionViewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        themes.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ThemeCell.reuseId, for: indexPath) as! ThemeCell
        let theme = themes[indexPath.item]
        cell.configure(theme: theme, isSelected: theme.id == selectedThemeId)
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let totalSpacing: CGFloat = 20 * 2 + 14
        let width = (collectionView.bounds.width - totalSpacing) / 2
        return CGSize(width: floor(width), height: floor(width) * 1.15)
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let previousId = selectedThemeId
        let theme = themes[indexPath.item]
        selectedThemeId = theme.id
        AppGroupManager.shared.set(theme.id, forKey: AppConstants.UserDefaultsKeys.keyboardTheme)

        var indexPaths = [indexPath]
        if let prevIndex = themes.firstIndex(where: { $0.id == previousId }) {
            let prevPath = IndexPath(item: prevIndex, section: 0)
            if prevPath != indexPath { indexPaths.append(prevPath) }
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

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
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

    func configure(theme: KeyboardTheme, isSelected: Bool) {
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

        nameLabel.text = theme.displayName
        nameLabel.textColor = AppColors.text

        // Color palette dots
        let colors = [theme.keyboardBackground, theme.keyBackground, theme.specialKeyBackground, theme.keyTextColor]
        for (i, dot) in dotViews.enumerated() where i < colors.count {
            dot.backgroundColor = colors[i]
            dot.layer.borderWidth = 0.5
            dot.layer.borderColor = AppColors.border.cgColor
        }

        checkmark.isHidden = !isSelected
        cardView.layer.borderColor = isSelected ? AppColors.accent.cgColor : AppColors.border.cgColor
        cardView.layer.borderWidth = isSelected ? 2 : 1
    }
}
