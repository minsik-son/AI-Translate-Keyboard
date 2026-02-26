import UIKit

class LayoutSettingsViewController: UITableViewController {

    private lazy var numberRowSwitch: UISwitch = {
        let toggle = UISwitch()
        let defaults = UserDefaults(suiteName: AppConstants.appGroupIdentifier)
        toggle.isOn = defaults?.object(forKey: AppConstants.UserDefaultsKeys.showNumberRow) == nil ? true : AppGroupManager.shared.bool(forKey: AppConstants.UserDefaultsKeys.showNumberRow)
        toggle.addTarget(self, action: #selector(numberRowToggled(_:)), for: .valueChanged)
        return toggle
    }()

    private struct LanguageOption {
        let code: String
        let displayName: String
    }

    private let languageOptions: [LanguageOption] = [
        LanguageOption(code: "ko", displayName: "한국어"),
        LanguageOption(code: "es", displayName: "Español"),
        LanguageOption(code: "fr", displayName: "Français"),
        LanguageOption(code: "de", displayName: "Deutsch"),
        LanguageOption(code: "it", displayName: "Italiano"),
        LanguageOption(code: "ru", displayName: "Русский"),
    ]

    private var selectedLanguageCode: String = "ko"

    init() {
        super.init(style: .insetGrouped)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = L("settings.layout")
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "LayoutCell")
        selectedLanguageCode = AppGroupManager.shared.string(forKey: AppConstants.UserDefaultsKeys.primaryKeyboardLanguage) ?? "ko"
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        title = L("settings.layout")
        tableView.reloadData()
    }

    // MARK: - UITableViewDataSource

    override func numberOfSections(in tableView: UITableView) -> Int { 2 }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0: return 1
        case 1: return languageOptions.count
        default: return 0
        }
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 1: return L("settings.keyboard_language")
        default: return nil
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "LayoutCell", for: indexPath)
        cell.accessoryView = nil
        cell.accessoryType = .none

        var config = cell.defaultContentConfiguration()

        switch indexPath.section {
        case 0:
            config.text = L("settings.number_row")
            cell.contentConfiguration = config
            cell.accessoryView = numberRowSwitch
            cell.selectionStyle = .none
        case 1:
            let option = languageOptions[indexPath.row]
            config.text = option.displayName
            cell.contentConfiguration = config
            cell.accessoryType = (option.code == selectedLanguageCode) ? .checkmark : .none
            cell.selectionStyle = .default
        default:
            cell.contentConfiguration = config
        }

        return cell
    }

    // MARK: - UITableViewDelegate

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard indexPath.section == 1 else { return }

        let option = languageOptions[indexPath.row]
        selectedLanguageCode = option.code
        AppGroupManager.shared.set(option.code, forKey: AppConstants.UserDefaultsKeys.primaryKeyboardLanguage)

        // 앱 UI 언어도 함께 변경
        if let appLang = AppLanguage(rawValue: option.code) {
            LocalizationManager.shared.currentLanguage = appLang
        }

        tableView.reloadSections(IndexSet(integer: 1), with: .none)
    }

    // MARK: - Actions

    @objc private func numberRowToggled(_ sender: UISwitch) {
        AppGroupManager.shared.set(sender.isOn, forKey: AppConstants.UserDefaultsKeys.showNumberRow)
    }
}
