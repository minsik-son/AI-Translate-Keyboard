import UIKit

class SettingsViewController: UITableViewController {

    // MARK: - Data Model

    private enum AccessoryType {
        case chevron
        case toggle(key: String)
    }

    private struct SettingsItem {
        let title: String
        let iconName: String
        let iconBackgroundColor: UIColor
        let accessory: AccessoryType
    }

    private var sections: [(title: String?, items: [SettingsItem])] {
        [
            (
                title: L("settings.section.appearance"),
                items: [
                    SettingsItem(title: L("settings.dark_mode"), iconName: "moon.fill", iconBackgroundColor: .systemIndigo, accessory: .toggle(key: AppConstants.UserDefaultsKeys.appDarkMode)),
                ]
            ),
            (
                title: L("settings.section.keyboard"),
                items: [
                    SettingsItem(title: L("settings.language"), iconName: "globe", iconBackgroundColor: .systemBlue, accessory: .chevron),
                    SettingsItem(title: L("settings.layout"), iconName: "keyboard", iconBackgroundColor: .systemTeal, accessory: .chevron),
                    SettingsItem(title: L("settings.autocomplete"), iconName: "text.badge.checkmark", iconBackgroundColor: .systemGreen, accessory: .toggle(key: AppConstants.UserDefaultsKeys.autoComplete)),
                    SettingsItem(title: L("settings.auto_capitalize"), iconName: "textformat.size.larger", iconBackgroundColor: .systemOrange, accessory: .toggle(key: AppConstants.UserDefaultsKeys.autoCapitalize)),
                    SettingsItem(title: L("settings.haptic"), iconName: "hand.tap", iconBackgroundColor: .systemIndigo, accessory: .toggle(key: AppConstants.UserDefaultsKeys.hapticFeedback)),
                    SettingsItem(title: L("settings.paste_guide"), iconName: "doc.on.clipboard", iconBackgroundColor: .systemTeal, accessory: .chevron),
                ]
            ),
            (
                title: L("settings.section.ai"),
                items: [
                    SettingsItem(title: L("settings.ai_correction"), iconName: "checkmark.circle", iconBackgroundColor: AppColors.orange, accessory: .chevron),
                    SettingsItem(title: L("settings.ai_translation"), iconName: "globe", iconBackgroundColor: AppColors.blue, accessory: .chevron),
                ]
            ),
            (
                title: L("settings.section.privacy"),
                items: [
                    SettingsItem(title: L("settings.privacy_dashboard"), iconName: "shield.checkered", iconBackgroundColor: AppColors.green, accessory: .chevron),
                    SettingsItem(title: L("settings.full_access_explain"), iconName: "lock.open", iconBackgroundColor: AppColors.accent, accessory: .chevron),
                ]
            ),
            (
                title: L("settings.section.about"),
                items: [
                    SettingsItem(title: L("settings.redo_onboarding"), iconName: "arrow.counterclockwise", iconBackgroundColor: .systemBlue, accessory: .chevron),
                    SettingsItem(title: L("settings.rate_us"), iconName: "star.fill", iconBackgroundColor: .systemYellow, accessory: .chevron),
                    SettingsItem(title: L("settings.faq"), iconName: "questionmark.circle", iconBackgroundColor: .systemBlue, accessory: .chevron),
                    SettingsItem(title: L("settings.privacy"), iconName: "hand.raised.fill", iconBackgroundColor: .systemGreen, accessory: .chevron),
                    SettingsItem(title: L("settings.terms"), iconName: "doc.text", iconBackgroundColor: .systemGray, accessory: .chevron),
                ]
            ),
        ]
    }

    // MARK: - Lifecycle

    init() {
        super.init(style: .insetGrouped)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = L("settings.title")
        navigationController?.navigationBar.prefersLargeTitles = true
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "SettingsCell")
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        title = L("settings.title")
        tableView.reloadData()
    }

    // MARK: - UITableViewDataSource

    override func numberOfSections(in tableView: UITableView) -> Int {
        sections.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        sections[section].items.count
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        sections[section].title
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SettingsCell", for: indexPath)
        let item = sections[indexPath.section].items[indexPath.row]

        var config = cell.defaultContentConfiguration()
        config.text = item.title
        config.image = makeIcon(symbolName: item.iconName, backgroundColor: item.iconBackgroundColor)
        cell.contentConfiguration = config

        switch item.accessory {
        case .chevron:
            cell.accessoryType = .disclosureIndicator
            cell.accessoryView = nil
            cell.selectionStyle = .default
        case .toggle(let key):
            let toggle = UISwitch()
            let defaults = UserDefaults(suiteName: AppConstants.appGroupIdentifier)
            let defaultValue = key != AppConstants.UserDefaultsKeys.appDarkMode
            toggle.isOn = defaults?.object(forKey: key) == nil ? defaultValue : AppGroupManager.shared.bool(forKey: key)
            toggle.tag = indexPath.section * 100 + indexPath.row
            toggle.addTarget(self, action: #selector(toggleChanged(_:)), for: .valueChanged)
            cell.accessoryType = .none
            cell.accessoryView = toggle
            cell.selectionStyle = .none
        }

        return cell
    }

    // MARK: - UITableViewDelegate

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        var vc: UIViewController?

        switch (indexPath.section, indexPath.row) {
        // Keyboard section
        case (1, 0): vc = LanguageSettingsViewController()
        case (1, 1): vc = LayoutSettingsViewController()
        case (1, 5): vc = PasteGuideViewController()
        // AI section
        case (2, 0): vc = AICorrectionInfoViewController()
        case (2, 1): vc = AITranslationInfoViewController()
        // Privacy section
        case (3, 0): vc = PrivacyDashboardViewController()
        case (3, 1): vc = FullAccessExplainViewController()
        // About section
        case (4, 0):
            let defaults = UserDefaults(suiteName: AppConstants.appGroupIdentifier) ?? UserDefaults.standard
            defaults.set(false, forKey: AppConstants.UserDefaultsKeys.hasCompletedOnboarding)
            let onboarding = OnboardingViewController()
            onboarding.modalPresentationStyle = .fullScreen
            present(onboarding, animated: true)
        default: break
        }

        if let vc = vc {
            navigationController?.pushViewController(vc, animated: true)
        }
    }

    // MARK: - Actions

    @objc private func toggleChanged(_ sender: UISwitch) {
        let section = sender.tag / 100
        let row = sender.tag % 100
        let item = sections[section].items[row]
        if case .toggle(let key) = item.accessory {
            AppGroupManager.shared.set(sender.isOn, forKey: key)
            if key == AppConstants.UserDefaultsKeys.appDarkMode {
                view.window?.overrideUserInterfaceStyle = sender.isOn ? .dark : .light
            }
        }
    }

    // MARK: - Icon Helper

    private func makeIcon(symbolName: String, backgroundColor: UIColor) -> UIImage? {
        let size: CGFloat = 30
        let cornerRadius: CGFloat = 6
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: size, height: size))
        return renderer.image { context in
            let rect = CGRect(origin: .zero, size: CGSize(width: size, height: size))
            let path = UIBezierPath(roundedRect: rect, cornerRadius: cornerRadius)
            backgroundColor.setFill()
            path.fill()

            let symbolConfig = UIImage.SymbolConfiguration(pointSize: 15, weight: .medium)
            if let symbol = UIImage(systemName: symbolName, withConfiguration: symbolConfig)?.withTintColor(.white, renderingMode: .alwaysOriginal) {
                let symbolSize = symbol.size
                let symbolOrigin = CGPoint(
                    x: (size - symbolSize.width) / 2,
                    y: (size - symbolSize.height) / 2
                )
                symbol.draw(at: symbolOrigin)
            }
        }
    }
}
