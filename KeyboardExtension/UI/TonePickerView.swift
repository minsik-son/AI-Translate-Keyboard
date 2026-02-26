import UIKit

class TonePickerView: UIView {

    var onToneSelected: ((ToneStyle) -> Void)?

    private var selectedTone: ToneStyle = .none
    private var pillButtons: [UIButton] = []
    private var customTheme: KeyboardTheme?

    private let stackView: UIStackView = {
        let sv = UIStackView()
        sv.axis = .horizontal
        sv.spacing = 6
        sv.alignment = .center
        sv.translatesAutoresizingMaskIntoConstraints = false
        return sv
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
        alpha = 0
        isHidden = true

        addSubview(stackView)
        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            stackView.centerYAnchor.constraint(equalTo: centerYAnchor),
        ])

        for tone in ToneStyle.allCases {
            let btn = UIButton(type: .custom)
            btn.titleLabel?.font = .systemFont(ofSize: 13, weight: .medium)
            btn.setTitle(tone.displayName, for: .normal)
            btn.tag = ToneStyle.allCases.firstIndex(of: tone) ?? 0
            btn.layer.cornerRadius = 15
            btn.clipsToBounds = true
            btn.contentEdgeInsets = UIEdgeInsets(top: 0, left: 12, bottom: 0, right: 12)
            btn.translatesAutoresizingMaskIntoConstraints = false
            btn.heightAnchor.constraint(equalToConstant: 30).isActive = true
            btn.addTarget(self, action: #selector(toneTapped(_:)), for: .touchUpInside)
            stackView.addArrangedSubview(btn)
            pillButtons.append(btn)
        }

        updateSelection()
    }

    // MARK: - Actions

    @objc private func toneTapped(_ sender: UIButton) {
        let allCases = ToneStyle.allCases
        guard sender.tag < allCases.count else { return }
        let tone = allCases[sender.tag]
        selectedTone = tone
        updateSelection()
        onToneSelected?(tone)
    }

    // MARK: - Public

    func selectTone(_ tone: ToneStyle) {
        selectedTone = tone
        updateSelection()
    }

    func show() {
        isHidden = false
        UIView.animate(withDuration: 0.2) {
            self.alpha = 1
        }
    }

    func hide() {
        UIView.animate(withDuration: 0.2, animations: {
            self.alpha = 0
        }) { _ in
            self.isHidden = true
        }
    }

    func applyTheme(_ theme: KeyboardTheme?) {
        customTheme = theme
    }

    func updateAppearance(isDark: Bool) {
        updateSelection()
    }

    // MARK: - Private

    private func updateSelection() {
        let allCases = ToneStyle.allCases
        for (index, btn) in pillButtons.enumerated() {
            let tone = allCases[index]
            if tone == selectedTone {
                btn.backgroundColor = .systemBlue
                btn.setTitleColor(.white, for: .normal)
            } else {
                if let theme = customTheme {
                    btn.backgroundColor = theme.keyBackground
                    btn.setTitleColor(theme.keyTextColor, for: .normal)
                } else {
                    btn.backgroundColor = .systemGray5
                    btn.setTitleColor(.label, for: .normal)
                }
            }
        }
    }
}
