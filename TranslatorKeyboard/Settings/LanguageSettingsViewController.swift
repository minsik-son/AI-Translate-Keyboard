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
        title = "언어"
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
        LocalizationManager.shared.currentLanguage = lang
        tableView.reloadData()
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
