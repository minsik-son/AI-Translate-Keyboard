import UIKit

class LayoutSettingsViewController: UITableViewController {

    private lazy var numberRowSwitch: UISwitch = {
        let toggle = UISwitch()
        let defaults = UserDefaults(suiteName: AppConstants.appGroupIdentifier)
        toggle.isOn = defaults?.object(forKey: AppConstants.UserDefaultsKeys.showNumberRow) == nil ? true : AppGroupManager.shared.bool(forKey: AppConstants.UserDefaultsKeys.showNumberRow)
        toggle.addTarget(self, action: #selector(numberRowToggled(_:)), for: .valueChanged)
        return toggle
    }()

    init() {
        super.init(style: .insetGrouped)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "레이아웃"
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "LayoutCell")
    }

    // MARK: - UITableViewDataSource

    override func numberOfSections(in tableView: UITableView) -> Int { 1 }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { 1 }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "LayoutCell", for: indexPath)
        var config = cell.defaultContentConfiguration()
        config.text = "숫자 줄"
        cell.contentConfiguration = config
        cell.accessoryView = numberRowSwitch
        cell.selectionStyle = .none
        return cell
    }

    // MARK: - Actions

    @objc private func numberRowToggled(_ sender: UISwitch) {
        AppGroupManager.shared.set(sender.isOn, forKey: AppConstants.UserDefaultsKeys.showNumberRow)
    }
}
