import UIKit

class LanguageSettingsViewController: UITableViewController {

    private let languages = AppLanguage.allCases

    private var selectedLanguage: AppLanguage {
        return LocalizationManager.shared.currentLanguage
    }

    init() {
        super.init(style: .insetGrouped)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = L("settings.language")
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "LanguageCell")
    }

    // MARK: - UITableViewDataSource

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        languages.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "LanguageCell", for: indexPath)
        let lang = languages[indexPath.row]

        var config = cell.defaultContentConfiguration()
        config.text = lang.displayName
        cell.contentConfiguration = config
        cell.accessoryType = (lang == selectedLanguage) ? .checkmark : .none

        return cell
    }

    // MARK: - UITableViewDelegate

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let lang = languages[indexPath.row]
        guard lang != selectedLanguage else {
            tableView.deselectRow(at: indexPath, animated: true)
            return
        }
        LocalizationManager.shared.currentLanguage = lang
        AppGroupManager.shared.set(lang.translationLanguageCode, forKey: AppConstants.UserDefaultsKeys.sourceLanguage)
        title = L("settings.language")
        tableView.reloadData()
        tableView.deselectRow(at: indexPath, animated: true)
        showLoadingHUD()
    }

    private func showLoadingHUD() {
        let overlay = UIView(frame: view.bounds)
        overlay.backgroundColor = UIColor.black.withAlphaComponent(0.4)
        overlay.autoresizingMask = [.flexibleWidth, .flexibleHeight]

        let container = UIView()
        container.backgroundColor = UIColor.systemBackground.withAlphaComponent(0.95)
        container.layer.cornerRadius = 12
        container.translatesAutoresizingMaskIntoConstraints = false

        let spinner = UIActivityIndicatorView(style: .medium)
        spinner.startAnimating()
        spinner.translatesAutoresizingMaskIntoConstraints = false

        let label = UILabel()
        label.text = L("language.loading")
        label.font = .systemFont(ofSize: 14)
        label.textColor = .label
        label.translatesAutoresizingMaskIntoConstraints = false

        container.addSubview(spinner)
        container.addSubview(label)
        overlay.addSubview(container)
        view.addSubview(overlay)

        NSLayoutConstraint.activate([
            container.centerXAnchor.constraint(equalTo: overlay.centerXAnchor),
            container.centerYAnchor.constraint(equalTo: overlay.centerYAnchor),
            spinner.topAnchor.constraint(equalTo: container.topAnchor, constant: 20),
            spinner.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            label.topAnchor.constraint(equalTo: spinner.bottomAnchor, constant: 12),
            label.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            label.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -20),
            container.widthAnchor.constraint(greaterThanOrEqualToConstant: 120),
            label.leadingAnchor.constraint(greaterThanOrEqualTo: container.leadingAnchor, constant: 20),
            label.trailingAnchor.constraint(lessThanOrEqualTo: container.trailingAnchor, constant: -20),
        ])

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            overlay.removeFromSuperview()
        }
    }
}
