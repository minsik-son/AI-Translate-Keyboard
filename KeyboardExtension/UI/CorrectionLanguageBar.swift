import UIKit

class CorrectionLanguageBar: UIView {

    var onLanguageTap: (() -> Void)?

    private let languagePill: UIButton = {
        let btn = UIButton(type: .custom)
        btn.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        btn.setTitleColor(.label, for: .normal)
        btn.backgroundColor = .white
        btn.clipsToBounds = true
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }()

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup

    private func setupViews() {
        backgroundColor = .clear

        addSubview(languagePill)

        let pillHeight: CGFloat = 36

        NSLayoutConstraint.activate([
            languagePill.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            languagePill.centerYAnchor.constraint(equalTo: centerYAnchor),
            languagePill.heightAnchor.constraint(equalToConstant: pillHeight),
            languagePill.widthAnchor.constraint(greaterThanOrEqualToConstant: 80),
        ])

        languagePill.layer.cornerRadius = pillHeight / 2
        languagePill.contentEdgeInsets = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)

        languagePill.addTarget(self, action: #selector(pillTapped), for: .touchUpInside)
    }

    // MARK: - Actions

    @objc private func pillTapped() { onLanguageTap?() }

    // MARK: - Public

    func updateLanguageName(_ name: String) {
        languagePill.setTitle(name, for: .normal)
    }

    func updateAppearance(isDark: Bool) {
        languagePill.backgroundColor = isDark ? UIColor(white: 0.25, alpha: 1) : .white
        languagePill.setTitleColor(isDark ? .white : .label, for: .normal)
    }
}
