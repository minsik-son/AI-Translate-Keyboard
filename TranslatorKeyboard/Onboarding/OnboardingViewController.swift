import UIKit

class OnboardingViewController: UIViewController {

    private let scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.isPagingEnabled = true
        sv.showsHorizontalScrollIndicator = false
        sv.translatesAutoresizingMaskIntoConstraints = false
        return sv
    }()

    private let pageControl: UIPageControl = {
        let pc = UIPageControl()
        pc.numberOfPages = 3
        pc.currentPageIndicatorTintColor = .systemBlue
        pc.pageIndicatorTintColor = .systemGray4
        pc.translatesAutoresizingMaskIntoConstraints = false
        return pc
    }()

    private let continueButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("다음", for: .normal)
        btn.titleLabel?.font = .systemFont(ofSize: 18, weight: .semibold)
        btn.backgroundColor = .systemBlue
        btn.setTitleColor(.white, for: .normal)
        btn.layer.cornerRadius = 12
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }()

    private let pages: [(icon: String, title: String, description: String)] = [
        (
            icon: "keyboard",
            title: "키보드 설정하기",
            description: "설정 → 일반 → 키보드 → 키보드 추가에서\nTranslator Keyboard를 추가해주세요"
        ),
        (
            icon: "lock.open",
            title: "전체 접근 허용",
            description: "번역 기능을 사용하려면\n'전체 접근 허용'을 켜주세요\n(네트워크 접근에 필요합니다)"
        ),
        (
            icon: "checkmark.circle",
            title: "준비 완료!",
            description: "아무 앱에서 키보드를 전환하고\n번역 버튼을 눌러 시작하세요"
        )
    ]

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setupUI()
    }

    private func setupUI() {
        view.addSubview(scrollView)
        view.addSubview(pageControl)
        view.addSubview(continueButton)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: pageControl.topAnchor, constant: -20),

            pageControl.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            pageControl.bottomAnchor.constraint(equalTo: continueButton.topAnchor, constant: -20),

            continueButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            continueButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            continueButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            continueButton.heightAnchor.constraint(equalToConstant: 52),
        ])

        scrollView.delegate = self
        continueButton.addTarget(self, action: #selector(continueTapped), for: .touchUpInside)

        setupPages()
    }

    private func setupPages() {
        let contentView = UIView()
        contentView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentView)

        NSLayoutConstraint.activate([
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.heightAnchor.constraint(equalTo: scrollView.heightAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor, multiplier: CGFloat(pages.count)),
        ])

        var previousView: UIView?

        for (index, page) in pages.enumerated() {
            let pageView = createPageView(icon: page.icon, title: page.title, description: page.description)
            pageView.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview(pageView)

            NSLayoutConstraint.activate([
                pageView.topAnchor.constraint(equalTo: contentView.topAnchor),
                pageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
                pageView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            ])

            if let prev = previousView {
                pageView.leadingAnchor.constraint(equalTo: prev.trailingAnchor).isActive = true
            } else {
                pageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor).isActive = true
            }

            if index == pages.count - 1 {
                pageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor).isActive = true
            }

            previousView = pageView
        }
    }

    private func createPageView(icon: String, title: String, description: String) -> UIView {
        let container = UIView()

        let iconView = UIImageView()
        iconView.image = UIImage(systemName: icon)
        iconView.tintColor = .systemBlue
        iconView.contentMode = .scaleAspectFit
        iconView.translatesAutoresizingMaskIntoConstraints = false

        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .systemFont(ofSize: 28, weight: .bold)
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        let descLabel = UILabel()
        descLabel.text = description
        descLabel.font = .systemFont(ofSize: 16)
        descLabel.textColor = .secondaryLabel
        descLabel.textAlignment = .center
        descLabel.numberOfLines = 0
        descLabel.translatesAutoresizingMaskIntoConstraints = false

        container.addSubview(iconView)
        container.addSubview(titleLabel)
        container.addSubview(descLabel)

        NSLayoutConstraint.activate([
            iconView.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            iconView.centerYAnchor.constraint(equalTo: container.centerYAnchor, constant: -80),
            iconView.widthAnchor.constraint(equalToConstant: 80),
            iconView.heightAnchor.constraint(equalToConstant: 80),

            titleLabel.topAnchor.constraint(equalTo: iconView.bottomAnchor, constant: 24),
            titleLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 24),
            titleLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -24),

            descLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 12),
            descLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 24),
            descLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -24),
        ])

        return container
    }

    @objc private func continueTapped() {
        let currentPage = pageControl.currentPage

        if currentPage < pages.count - 1 {
            let nextPage = currentPage + 1
            let offset = CGFloat(nextPage) * scrollView.frame.width
            scrollView.setContentOffset(CGPoint(x: offset, y: 0), animated: true)
            pageControl.currentPage = nextPage

            if nextPage == pages.count - 1 {
                continueButton.setTitle("시작하기", for: .normal)
            }
        } else {
            // Open Settings for keyboard activation
            if currentPage == 0 {
                openKeyboardSettings()
            }
            dismiss(animated: true)
        }
    }

    private func openKeyboardSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
}

extension OnboardingViewController: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let page = Int(round(scrollView.contentOffset.x / scrollView.frame.width))
        pageControl.currentPage = page

        if page == pages.count - 1 {
            continueButton.setTitle("시작하기", for: .normal)
        } else {
            continueButton.setTitle("다음", for: .normal)
        }
    }
}
