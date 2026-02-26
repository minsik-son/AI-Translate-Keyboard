import UIKit

class PhraseInputHeaderView: UIView {

    var onCancel: (() -> Void)?
    var onSave: (() -> Void)?

    private let cancelButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle(L("phrase.cancel"), for: .normal)
        btn.titleLabel?.font = .systemFont(ofSize: 16)
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = L("phrase.add_title")
        label.font = .systemFont(ofSize: 16, weight: .medium)
        label.textColor = .label
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let saveButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle(L("phrase.save"), for: .normal)
        btn.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
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

        addSubview(cancelButton)
        addSubview(titleLabel)
        addSubview(saveButton)

        NSLayoutConstraint.activate([
            cancelButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            cancelButton.centerYAnchor.constraint(equalTo: centerYAnchor),

            titleLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: centerYAnchor),

            saveButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            saveButton.centerYAnchor.constraint(equalTo: centerYAnchor),
        ])

        cancelButton.addTarget(self, action: #selector(cancelTapped), for: .touchUpInside)
        saveButton.addTarget(self, action: #selector(saveTapped), for: .touchUpInside)
    }

    // MARK: - Actions

    @objc private func cancelTapped() { onCancel?() }
    @objc private func saveTapped() { onSave?() }

    // MARK: - Public

    func reloadLocalizedStrings() {
        cancelButton.setTitle(L("phrase.cancel"), for: .normal)
        titleLabel.text = L("phrase.add_title")
        saveButton.setTitle(L("phrase.save"), for: .normal)
    }

    private var customTheme: KeyboardTheme?

    func applyTheme(_ theme: KeyboardTheme?) {
        customTheme = theme
    }

    func updateAppearance(isDark: Bool) {
        if let theme = customTheme {
            backgroundColor = theme.toolbarBackground
            titleLabel.textColor = theme.keyTextColor
            cancelButton.tintColor = theme.keyTextColor.withAlphaComponent(0.8)
            saveButton.tintColor = theme.keyTextColor.withAlphaComponent(0.8)
        } else {
            backgroundColor = .clear
            titleLabel.textColor = isDark ? .white : .label
            cancelButton.tintColor = nil
            saveButton.tintColor = nil
        }
    }
}
