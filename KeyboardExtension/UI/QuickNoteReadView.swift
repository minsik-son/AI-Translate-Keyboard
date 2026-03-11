import UIKit

class QuickNoteReadView: UIView {

    // MARK: - Callbacks

    var onBack: (() -> Void)?
    var onEdit: ((QuickNote) -> Void)?
    var onPaste: ((String) -> Void)?
    var onCopy: ((String) -> Void)?

    // MARK: - Data

    private var note: QuickNote?

    // MARK: - UI

    private let headerView: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private let backButton: UIButton = {
        let btn = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 18, weight: .medium)
        btn.setImage(UIImage(systemName: "chevron.left", withConfiguration: config), for: .normal)
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }()

    private let editButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle(L("quicknote.edit_button"), for: .normal)
        btn.titleLabel?.font = .systemFont(ofSize: 15, weight: .semibold)
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }()

    private let scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.translatesAutoresizingMaskIntoConstraints = false
        sv.showsVerticalScrollIndicator = true
        return sv
    }()

    private let contentLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 15)
        l.numberOfLines = 0
        l.lineBreakMode = .byWordWrapping
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let actionBar: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private let pasteButton: UIButton = {
        let btn = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 13, weight: .medium)
        btn.setImage(UIImage(systemName: "doc.on.clipboard", withConfiguration: config), for: .normal)
        btn.setTitle(" " + L("quicknote.paste"), for: .normal)
        btn.titleLabel?.font = .systemFont(ofSize: 13, weight: .medium)
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }()

    private let copyButton: UIButton = {
        let btn = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 13, weight: .medium)
        btn.setImage(UIImage(systemName: "doc.on.doc", withConfiguration: config), for: .normal)
        btn.setTitle(" " + L("quicknote.copy"), for: .normal)
        btn.titleLabel?.font = .systemFont(ofSize: 13, weight: .medium)
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }()

    // MARK: - Theme

    private var customTheme: KeyboardTheme?
    private var isDark = false

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
        addSubview(headerView)
        headerView.addSubview(backButton)
        headerView.addSubview(editButton)
        addSubview(scrollView)
        scrollView.addSubview(contentLabel)
        addSubview(actionBar)
        actionBar.addSubview(pasteButton)
        actionBar.addSubview(copyButton)

        backButton.addTarget(self, action: #selector(backTapped), for: .touchUpInside)
        editButton.addTarget(self, action: #selector(editTapped), for: .touchUpInside)
        pasteButton.addTarget(self, action: #selector(pasteTapped), for: .touchUpInside)
        copyButton.addTarget(self, action: #selector(copyTapped), for: .touchUpInside)

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(editTapped))
        scrollView.addGestureRecognizer(tapGesture)

        NSLayoutConstraint.activate([
            headerView.topAnchor.constraint(equalTo: topAnchor),
            headerView.leadingAnchor.constraint(equalTo: leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: trailingAnchor),
            headerView.heightAnchor.constraint(equalToConstant: 44),

            backButton.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 8),
            backButton.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            backButton.widthAnchor.constraint(equalToConstant: 36),
            backButton.heightAnchor.constraint(equalToConstant: 34),

            editButton.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -12),
            editButton.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),

            scrollView.topAnchor.constraint(equalTo: headerView.bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: actionBar.topAnchor),

            contentLabel.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 8),
            contentLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            contentLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            contentLabel.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -16),

            actionBar.leadingAnchor.constraint(equalTo: leadingAnchor),
            actionBar.trailingAnchor.constraint(equalTo: trailingAnchor),
            actionBar.bottomAnchor.constraint(equalTo: bottomAnchor),
            actionBar.heightAnchor.constraint(equalToConstant: 40),

            pasteButton.leadingAnchor.constraint(equalTo: actionBar.leadingAnchor, constant: 12),
            pasteButton.centerYAnchor.constraint(equalTo: actionBar.centerYAnchor),

            copyButton.trailingAnchor.constraint(equalTo: actionBar.trailingAnchor, constant: -12),
            copyButton.centerYAnchor.constraint(equalTo: actionBar.centerYAnchor),
        ])
    }

    // MARK: - Public

    func configure(with note: QuickNote) {
        self.note = note
        contentLabel.text = note.content
    }

    func applyTheme(_ theme: KeyboardTheme?) {
        customTheme = theme
    }

    func updateAppearance(isDark: Bool) {
        self.isDark = isDark
        let textColor: UIColor
        let accentColor: UIColor

        if let theme = customTheme {
            backgroundColor = theme.keyboardBackground
            textColor = theme.keyTextColor
            accentColor = theme.keyTextColor
        } else {
            backgroundColor = isDark ? UIColor(white: 0.12, alpha: 1) : UIColor(white: 0.95, alpha: 1)
            textColor = isDark ? .white : .label
            accentColor = .systemBlue
        }

        contentLabel.textColor = textColor
        backButton.tintColor = accentColor
        editButton.tintColor = accentColor
        pasteButton.tintColor = accentColor
        copyButton.tintColor = accentColor
    }

    // MARK: - Actions

    @objc private func backTapped() {
        onBack?()
    }

    @objc private func editTapped() {
        guard let note = note else { return }
        onEdit?(note)
    }

    @objc private func pasteTapped() {
        guard let content = note?.content, !content.isEmpty else { return }
        onPaste?(content)
    }

    @objc private func copyTapped() {
        guard let content = note?.content, !content.isEmpty else { return }
        onCopy?(content)
    }
}
