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

    private let sections: [(title: String?, items: [SettingsItem])] = [
        (
            title: "키보드 설정",
            items: [
                SettingsItem(title: "키보드 테마", iconName: "paintbrush.fill", iconBackgroundColor: .purple, accessory: .chevron),
                SettingsItem(title: "언어", iconName: "globe", iconBackgroundColor: .systemBlue, accessory: .chevron),
                SettingsItem(title: "레이아웃", iconName: "keyboard", iconBackgroundColor: .systemTeal, accessory: .chevron),
                SettingsItem(title: "자동완성", iconName: "text.badge.checkmark", iconBackgroundColor: .systemGreen, accessory: .toggle(key: AppConstants.UserDefaultsKeys.autoComplete)),
                SettingsItem(title: "자동 대문자", iconName: "textformat.size.larger", iconBackgroundColor: .systemOrange, accessory: .toggle(key: AppConstants.UserDefaultsKeys.autoCapitalize)),
                SettingsItem(title: "햅틱", iconName: "hand.tap", iconBackgroundColor: .systemIndigo, accessory: .toggle(key: AppConstants.UserDefaultsKeys.hapticFeedback)),
            ]
        ),
        (
            title: "About & Support",
            items: [
                SettingsItem(title: "Rate Us", iconName: "star.fill", iconBackgroundColor: .systemYellow, accessory: .chevron),
                SettingsItem(title: "FAQ & Support", iconName: "questionmark.circle", iconBackgroundColor: .systemBlue, accessory: .chevron),
                SettingsItem(title: "Privacy Policy", iconName: "hand.raised.fill", iconBackgroundColor: .systemGreen, accessory: .chevron),
                SettingsItem(title: "Terms of Use", iconName: "doc.text", iconBackgroundColor: .systemGray, accessory: .chevron),
            ]
        ),
    ]

    // MARK: - Lifecycle

    init() {
        super.init(style: .insetGrouped)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "설정"
        navigationController?.navigationBar.prefersLargeTitles = true
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "SettingsCell")
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
            toggle.isOn = defaults?.object(forKey: key) == nil ? true : AppGroupManager.shared.bool(forKey: key)
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
        if indexPath.section == 0 {
            switch indexPath.row {
            case 0:
                navigationController?.pushViewController(ThemeSelectionViewController(), animated: true)
            case 1:
                navigationController?.pushViewController(LanguageSettingsViewController(), animated: true)
            case 2:
                navigationController?.pushViewController(LayoutSettingsViewController(), animated: true)
            default:
                break
            }
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }

    // MARK: - Actions

    @objc private func toggleChanged(_ sender: UISwitch) {
        let section = sender.tag / 100
        let row = sender.tag % 100
        let item = sections[section].items[row]
        if case .toggle(let key) = item.accessory {
            AppGroupManager.shared.set(sender.isOn, forKey: key)
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
