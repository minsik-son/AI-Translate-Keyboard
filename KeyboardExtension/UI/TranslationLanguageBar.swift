import UIKit

class TranslationLanguageBar: UIView {

    var onSourceTap: (() -> Void)?
    var onTargetTap: (() -> Void)?
    var onSwapTap: (() -> Void)?
    var onCloseTap: (() -> Void)?

    // 통합 캡슐 컨테이너 (흰색/다크그레이 배경)
    private let capsuleContainer: UIView = {
        let v = UIView()
        v.backgroundColor = .white  // 초기값 설정 (updateAppearance 전에도 흰색 보장)
        v.layer.cornerRadius = 18
        v.clipsToBounds = true
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    // 소스 언어 버튼 — 고정 너비, 우측 정렬 텍스트
    private let sourceButton: UIButton = {
        let btn = UIButton(type: .custom)
        btn.titleLabel?.font = .systemFont(ofSize: 15, weight: .semibold)
        btn.titleLabel?.textAlignment = .right
        btn.contentHorizontalAlignment = .right
        btn.contentEdgeInsets = UIEdgeInsets(top: 0, left: 8, bottom: 0, right: 8)
        btn.setTitleColor(.label, for: .normal)
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }()

    // 타겟 언어 버튼 — 고정 너비, 좌측 정렬 텍스트
    private let targetButton: UIButton = {
        let btn = UIButton(type: .custom)
        btn.titleLabel?.font = .systemFont(ofSize: 15, weight: .semibold)
        btn.titleLabel?.textAlignment = .left
        btn.contentHorizontalAlignment = .left
        btn.contentEdgeInsets = UIEdgeInsets(top: 0, left: 8, bottom: 0, right: 8)
        btn.setTitleColor(.label, for: .normal)
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }()

    // 회전 화살표 — 화면 정중앙 고정
    private let swapButton: UIButton = {
        let btn = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 14, weight: .semibold)
        btn.setImage(UIImage(systemName: "arrow.triangle.2.circlepath", withConfiguration: config), for: .normal)
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }()

    // Close X 버튼 — 오른쪽 상단
    private let closeButton: UIButton = {
        let btn = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 13, weight: .semibold)
        btn.setImage(UIImage(systemName: "xmark", withConfiguration: config), for: .normal)
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }()

    // 양쪽 언어 버튼 고정 너비 (언어명 길이 무관하게 동일)
    private let languageButtonWidth: CGFloat = 80

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

        addSubview(capsuleContainer)
        addSubview(closeButton)
        capsuleContainer.addSubview(sourceButton)
        capsuleContainer.addSubview(swapButton)
        capsuleContainer.addSubview(targetButton)

        let capsuleHeight: CGFloat = 36

        NSLayoutConstraint.activate([
            // ──────────────────────────────────────────
            // 캡슐 컨테이너 — 화면 중앙 기준
            // ──────────────────────────────────────────
            capsuleContainer.centerXAnchor.constraint(equalTo: centerXAnchor),
            capsuleContainer.centerYAnchor.constraint(equalTo: centerYAnchor),
            capsuleContainer.heightAnchor.constraint(equalToConstant: capsuleHeight),

            // ──────────────────────────────────────────
            // Swap 버튼 — 캡슐 내부 정중앙 (= 화면 정중앙)
            // ──────────────────────────────────────────
            swapButton.centerXAnchor.constraint(equalTo: capsuleContainer.centerXAnchor),
            swapButton.centerYAnchor.constraint(equalTo: capsuleContainer.centerYAnchor),
            swapButton.widthAnchor.constraint(equalToConstant: 30),
            swapButton.heightAnchor.constraint(equalToConstant: 30),

            // ──────────────────────────────────────────
            // Source 버튼 — Swap 왼쪽, 고정 너비
            // ──────────────────────────────────────────
            sourceButton.trailingAnchor.constraint(equalTo: swapButton.leadingAnchor, constant: -2),
            sourceButton.topAnchor.constraint(equalTo: capsuleContainer.topAnchor),
            sourceButton.bottomAnchor.constraint(equalTo: capsuleContainer.bottomAnchor),
            sourceButton.leadingAnchor.constraint(equalTo: capsuleContainer.leadingAnchor),
            sourceButton.widthAnchor.constraint(equalToConstant: languageButtonWidth),

            // ──────────────────────────────────────────
            // Target 버튼 — Swap 오른쪽, 고정 너비
            // ──────────────────────────────────────────
            targetButton.leadingAnchor.constraint(equalTo: swapButton.trailingAnchor, constant: 2),
            targetButton.topAnchor.constraint(equalTo: capsuleContainer.topAnchor),
            targetButton.bottomAnchor.constraint(equalTo: capsuleContainer.bottomAnchor),
            targetButton.trailingAnchor.constraint(equalTo: capsuleContainer.trailingAnchor),
            targetButton.widthAnchor.constraint(equalToConstant: languageButtonWidth),

            // ──────────────────────────────────────────
            // Close X 버튼 — 오른쪽 상단
            // ──────────────────────────────────────────
            closeButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12),
            closeButton.centerYAnchor.constraint(equalTo: centerYAnchor),
            closeButton.widthAnchor.constraint(equalToConstant: 28),
            closeButton.heightAnchor.constraint(equalToConstant: 28),
        ])

        sourceButton.addTarget(self, action: #selector(sourceTapped), for: .touchUpInside)
        targetButton.addTarget(self, action: #selector(targetTapped), for: .touchUpInside)
        swapButton.addTarget(self, action: #selector(swapTapped), for: .touchUpInside)
        closeButton.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)

        // 누름 효과 등록
        addWoodPressEffect(to: sourceButton)
        addWoodPressEffect(to: targetButton)
        addWoodPressEffect(to: swapButton)
        addWoodPressEffect(to: closeButton)
    }

    // MARK: - Actions

    @objc private func sourceTapped() { onSourceTap?() }
    @objc private func targetTapped() { onTargetTap?() }
    @objc private func swapTapped() {
        // 회전 애니메이션
        UIView.animate(withDuration: 0.3) {
            self.swapButton.transform = self.swapButton.transform.rotated(by: .pi)
        }
        onSwapTap?()
    }
    @objc private func closeTapped() { onCloseTap?() }

    // MARK: - Public

    private var customTheme: KeyboardTheme?

    func applyTheme(_ theme: KeyboardTheme?) {
        customTheme = theme
    }

    func updateLanguageNames(source: String, target: String) {
        sourceButton.setTitle(source, for: .normal)
        targetButton.setTitle(target, for: .normal)
    }

    func updateAppearance(isDark: Bool) {
        if let theme = customTheme {
            backgroundColor = theme.toolbarBackground

            if theme.hasWoodTexture {
                // 나무 테마: 나무 블록 스타일 적용
                capsuleContainer.backgroundColor = theme.keyBackground
                capsuleContainer.layer.cornerRadius = 10
                capsuleContainer.layer.borderWidth = 1
                capsuleContainer.layer.borderColor = UIColor(white: 0, alpha: 0.15).cgColor
                capsuleContainer.layer.shadowColor = UIColor.black.cgColor
                capsuleContainer.layer.shadowOffset = CGSize(width: 0, height: 2)
                capsuleContainer.layer.shadowRadius = 3
                capsuleContainer.layer.shadowOpacity = 0.3
                capsuleContainer.clipsToBounds = false

                sourceButton.setTitleColor(theme.keyTextColor, for: .normal)
                targetButton.setTitleColor(theme.keyTextColor, for: .normal)
                swapButton.tintColor = theme.keyTextColor.withAlphaComponent(0.7)
                closeButton.tintColor = theme.keyTextColor.withAlphaComponent(0.7)
            } else {
                // 다른 프리미엄 테마: 기존 스타일
                capsuleContainer.backgroundColor = theme.keyBackground
                capsuleContainer.layer.borderWidth = 0
                capsuleContainer.layer.shadowOpacity = 0
                capsuleContainer.clipsToBounds = true
                capsuleContainer.layer.cornerRadius = 18

                sourceButton.setTitleColor(theme.keyTextColor, for: .normal)
                targetButton.setTitleColor(theme.keyTextColor, for: .normal)
                swapButton.tintColor = theme.keyTextColor.withAlphaComponent(0.6)
                closeButton.tintColor = theme.keyTextColor.withAlphaComponent(0.6)
            }
        } else {
            backgroundColor = .clear
            capsuleContainer.backgroundColor = isDark ? UIColor(white: 0.25, alpha: 1) : .white
            capsuleContainer.layer.borderWidth = 0
            capsuleContainer.layer.shadowOpacity = 0
            capsuleContainer.clipsToBounds = true
            capsuleContainer.layer.cornerRadius = 18
            let textColor: UIColor = isDark ? .white : .label
            sourceButton.setTitleColor(textColor, for: .normal)
            targetButton.setTitleColor(textColor, for: .normal)
            swapButton.tintColor = isDark ? UIColor(white: 0.55, alpha: 1) : .secondaryLabel
            closeButton.tintColor = isDark ? UIColor(white: 0.55, alpha: 1) : .secondaryLabel
        }
    }

    // MARK: - Wood Press Effect

    private func addWoodPressEffect(to button: UIButton) {
        button.addTarget(self, action: #selector(woodButtonDown(_:)), for: .touchDown)
        button.addTarget(self, action: #selector(woodButtonUp(_:)), for: [.touchUpInside, .touchUpOutside, .touchCancel])
    }

    @objc private func woodButtonDown(_ sender: UIButton) {
        UIView.animate(withDuration: 0.08) {
            sender.alpha = 0.6
        }
    }

    @objc private func woodButtonUp(_ sender: UIButton) {
        UIView.animate(withDuration: 0.15) {
            sender.alpha = 1.0
        }
    }
}
