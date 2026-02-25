import UIKit

class ThemeSelectionViewController: UIViewController {

    private let themes = KeyboardTheme.allThemes

    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.minimumInteritemSpacing = 12
        layout.minimumLineSpacing = 16
        layout.sectionInset = UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.backgroundColor = .systemGroupedBackground
        cv.translatesAutoresizingMaskIntoConstraints = false
        cv.dataSource = self
        cv.delegate = self
        cv.register(ThemeCell.self, forCellWithReuseIdentifier: ThemeCell.reuseId)
        return cv
    }()

    private var selectedThemeId: String = "default"

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "키보드 테마"
        view.backgroundColor = .systemGroupedBackground

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
        let totalSpacing: CGFloat = 20 * 2 + 12 * 2  // sectionInset + interitem
        let width = (collectionView.bounds.width - totalSpacing) / 3
        return CGSize(width: floor(width), height: floor(width) + 28)
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let theme = themes[indexPath.item]
        selectedThemeId = theme.id
        AppGroupManager.shared.set(theme.id, forKey: AppConstants.UserDefaultsKeys.keyboardTheme)
        collectionView.reloadData()
    }
}

// MARK: - ThemeCell

private class ThemeCell: UICollectionViewCell {

    static let reuseId = "ThemeCell"

    private let previewContainer: UIView = {
        let v = UIView()
        v.layer.cornerRadius = 10
        v.clipsToBounds = true
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private let keyRow: UIStackView = {
        let sv = UIStackView()
        sv.axis = .horizontal
        sv.spacing = 4
        sv.distribution = .fillEqually
        sv.translatesAutoresizingMaskIntoConstraints = false
        return sv
    }()

    private let specialKeyView: UIView = {
        let v = UIView()
        v.layer.cornerRadius = 4
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private let nameLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 13, weight: .medium)
        l.textAlignment = .center
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let checkmark: UIImageView = {
        let config = UIImage.SymbolConfiguration(pointSize: 16, weight: .bold)
        let iv = UIImageView(image: UIImage(systemName: "checkmark.circle.fill", withConfiguration: config))
        iv.tintColor = .systemBlue
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.isHidden = true
        return iv
    }()

    private var keyViews: [UIView] = []

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        contentView.addSubview(previewContainer)
        contentView.addSubview(nameLabel)
        contentView.addSubview(checkmark)

        // Key row — 4 mini keys
        for _ in 0..<4 {
            let kv = UIView()
            kv.layer.cornerRadius = 4
            keyViews.append(kv)
            keyRow.addArrangedSubview(kv)
        }

        previewContainer.addSubview(keyRow)
        previewContainer.addSubview(specialKeyView)

        NSLayoutConstraint.activate([
            previewContainer.topAnchor.constraint(equalTo: contentView.topAnchor),
            previewContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            previewContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            previewContainer.bottomAnchor.constraint(equalTo: nameLabel.topAnchor, constant: -6),

            keyRow.topAnchor.constraint(equalTo: previewContainer.topAnchor, constant: 10),
            keyRow.leadingAnchor.constraint(equalTo: previewContainer.leadingAnchor, constant: 8),
            keyRow.trailingAnchor.constraint(equalTo: previewContainer.trailingAnchor, constant: -8),
            keyRow.heightAnchor.constraint(equalToConstant: 24),

            specialKeyView.topAnchor.constraint(equalTo: keyRow.bottomAnchor, constant: 6),
            specialKeyView.leadingAnchor.constraint(equalTo: previewContainer.leadingAnchor, constant: 8),
            specialKeyView.trailingAnchor.constraint(equalTo: previewContainer.trailingAnchor, constant: -8),
            specialKeyView.heightAnchor.constraint(equalToConstant: 20),

            nameLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            nameLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            nameLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            nameLabel.heightAnchor.constraint(equalToConstant: 22),

            checkmark.topAnchor.constraint(equalTo: previewContainer.topAnchor, constant: 4),
            checkmark.trailingAnchor.constraint(equalTo: previewContainer.trailingAnchor, constant: -4),
        ])

        previewContainer.layer.borderWidth = 2
        previewContainer.layer.borderColor = UIColor.clear.cgColor
    }

    func configure(theme: KeyboardTheme, isSelected: Bool) {
        previewContainer.backgroundColor = theme.keyboardBackground
        for kv in keyViews {
            kv.backgroundColor = theme.keyBackground
        }
        specialKeyView.backgroundColor = theme.specialKeyBackground
        nameLabel.text = theme.displayName
        nameLabel.textColor = .label

        checkmark.isHidden = !isSelected
        previewContainer.layer.borderColor = isSelected ? UIColor.systemBlue.cgColor : UIColor.clear.cgColor
    }
}
