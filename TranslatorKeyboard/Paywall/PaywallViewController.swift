import UIKit

class PaywallViewController: UIViewController {

    private let storeKitManager = StoreKitManager.shared

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Pro로 업그레이드"
        label.font = .systemFont(ofSize: 28, weight: .bold)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let featuresLabel: UILabel = {
        let label = UILabel()
        label.text = "✓ 무제한 번역\n✓ DeepL 고품질 번역\n✓ 광고 없음\n✓ 프리미엄 테마"
        label.font = .systemFont(ofSize: 16)
        label.textColor = .secondaryLabel
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let monthlyButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("월간 구독", for: .normal)
        btn.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        btn.backgroundColor = .systemBlue
        btn.setTitleColor(.white, for: .normal)
        btn.layer.cornerRadius = 12
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }()

    private let yearlyButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("연간 구독 (할인)", for: .normal)
        btn.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        btn.backgroundColor = .systemGreen
        btn.setTitleColor(.white, for: .normal)
        btn.layer.cornerRadius = 12
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }()

    private let restoreButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("구매 복원", for: .normal)
        btn.titleLabel?.font = .systemFont(ofSize: 14)
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }()

    private let closeButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setImage(UIImage(systemName: "xmark"), for: .normal)
        btn.tintColor = .label
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setupUI()
        loadProducts()
    }

    private func setupUI() {
        view.addSubview(closeButton)
        view.addSubview(titleLabel)
        view.addSubview(featuresLabel)
        view.addSubview(monthlyButton)
        view.addSubview(yearlyButton)
        view.addSubview(restoreButton)

        NSLayoutConstraint.activate([
            closeButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            closeButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            closeButton.widthAnchor.constraint(equalToConstant: 30),
            closeButton.heightAnchor.constraint(equalToConstant: 30),

            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 60),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),

            featuresLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 24),
            featuresLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
            featuresLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32),

            monthlyButton.bottomAnchor.constraint(equalTo: yearlyButton.topAnchor, constant: -12),
            monthlyButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            monthlyButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            monthlyButton.heightAnchor.constraint(equalToConstant: 52),

            yearlyButton.bottomAnchor.constraint(equalTo: restoreButton.topAnchor, constant: -16),
            yearlyButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            yearlyButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            yearlyButton.heightAnchor.constraint(equalToConstant: 52),

            restoreButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            restoreButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
        ])

        closeButton.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
        monthlyButton.addTarget(self, action: #selector(monthlyTapped), for: .touchUpInside)
        yearlyButton.addTarget(self, action: #selector(yearlyTapped), for: .touchUpInside)
        restoreButton.addTarget(self, action: #selector(restoreTapped), for: .touchUpInside)
    }

    private func loadProducts() {
        Task {
            do {
                try await storeKitManager.loadProducts()
                updatePriceLabels()
            } catch {
                // Handle error
            }
        }
    }

    private func updatePriceLabels() {
        for product in storeKitManager.products {
            if product.id == StoreKitManager.ProductID.monthlyPro.rawValue {
                monthlyButton.setTitle("월간 \(product.displayPrice)/월", for: .normal)
            } else if product.id == StoreKitManager.ProductID.yearlyPro.rawValue {
                yearlyButton.setTitle("연간 \(product.displayPrice)/년", for: .normal)
            }
        }
    }

    @objc private func closeTapped() {
        dismiss(animated: true)
    }

    @objc private func monthlyTapped() {
        purchaseProduct(id: .monthlyPro)
    }

    @objc private func yearlyTapped() {
        purchaseProduct(id: .yearlyPro)
    }

    private func purchaseProduct(id: StoreKitManager.ProductID) {
        guard let product = storeKitManager.products.first(where: { $0.id == id.rawValue }) else { return }
        Task {
            do {
                _ = try await storeKitManager.purchase(product)
                dismiss(animated: true)
            } catch {
                // Show error alert
            }
        }
    }

    @objc private func restoreTapped() {
        Task {
            do {
                try await storeKitManager.restorePurchases()
                if SubscriptionStatus.shared.isPro {
                    dismiss(animated: true)
                }
            } catch {
                // Show error alert
            }
        }
    }
}
