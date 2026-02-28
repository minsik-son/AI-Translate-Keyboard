import UIKit

class HistoryViewController: UIViewController {

    private var allItems: [HistoryItem] = []
    private var filteredItems: [HistoryItem] = []
    private var selectedFilter: HistoryType?

    private let filterStack = UIStackView()
    private let tableView = UITableView(frame: .zero, style: .plain)
    private let emptyLabel = UILabel()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = AppColors.bg
        title = L("history.title")
        setupNavigation()
        setupFilterBar()
        setupTableView()
        setupEmptyState()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        reloadData()
    }

    // MARK: - Setup

    private func setupNavigation() {
        navigationController?.navigationBar.prefersLargeTitles = true
        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.largeTitleTextAttributes = [.foregroundColor: AppColors.text]
        appearance.titleTextAttributes = [.foregroundColor: AppColors.text]
        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
    }

    private func setupFilterBar() {
        filterStack.axis = .horizontal
        filterStack.spacing = 8
        filterStack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(filterStack)
        NSLayoutConstraint.activate([
            filterStack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            filterStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
        ])

        let filters: [(String, HistoryType?)] = [
            (L("history.filter.all"), nil),
            (L("history.filter.translate"), .translation),
            (L("history.filter.correct"), .correction),
            (L("history.filter.clipboard"), .clipboard),
        ]

        for (i, filter) in filters.enumerated() {
            let btn = UIButton(type: .system)
            btn.setTitle(filter.0, for: .normal)
            btn.titleLabel?.font = .systemFont(ofSize: 13, weight: .medium)
            btn.layer.cornerRadius = 14
            btn.contentEdgeInsets = UIEdgeInsets(top: 6, left: 14, bottom: 6, right: 14)
            btn.tag = i
            btn.addTarget(self, action: #selector(filterTapped(_:)), for: .touchUpInside)
            filterStack.addArrangedSubview(btn)
        }

        updateFilterAppearance()
    }

    private func setupTableView() {
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(HistoryCell.self, forCellReuseIdentifier: "HistoryCell")
        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: filterStack.bottomAnchor, constant: 12),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }

    private func setupEmptyState() {
        emptyLabel.text = L("history.empty")
        emptyLabel.font = .systemFont(ofSize: 15)
        emptyLabel.textColor = AppColors.textMuted
        emptyLabel.textAlignment = .center
        emptyLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(emptyLabel)
        NSLayoutConstraint.activate([
            emptyLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor),
        ])
    }

    // MARK: - Actions

    @objc private func filterTapped(_ sender: UIButton) {
        let filters: [HistoryType?] = [nil, .translation, .correction, .clipboard]
        selectedFilter = filters[sender.tag]
        updateFilterAppearance()
        applyFilter()
    }

    private func updateFilterAppearance() {
        let filters: [HistoryType?] = [nil, .translation, .correction, .clipboard]
        for case let btn as UIButton in filterStack.arrangedSubviews {
            let isSelected = filters[btn.tag] == selectedFilter
            btn.backgroundColor = isSelected ? AppColors.accent : AppColors.card
            btn.setTitleColor(isSelected ? .white : AppColors.textMuted, for: .normal)
        }
    }

    private func reloadData() {
        allItems = HistoryManager.shared.loadItems()
        applyFilter()
    }

    private func applyFilter() {
        if let filter = selectedFilter {
            filteredItems = allItems.filter { $0.type == filter }
        } else {
            filteredItems = allItems
        }
        tableView.reloadData()
        emptyLabel.isHidden = !filteredItems.isEmpty
        tableView.isHidden = filteredItems.isEmpty
    }

    // MARK: - Relative Time

    private func relativeTime(from date: Date) -> String {
        let interval = Date().timeIntervalSince(date)
        if interval < 60 { return L("clipboard.time.now") }
        if interval < 3600 { return String(format: L("clipboard.time.minutes_ago"), Int(interval / 60)) }
        if interval < 86400 { return String(format: L("clipboard.time.hours_ago"), Int(interval / 3600)) }
        return String(format: L("clipboard.time.days_ago"), Int(interval / 86400))
    }
}

// MARK: - UITableViewDataSource & Delegate

extension HistoryViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        filteredItems.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "HistoryCell", for: indexPath) as! HistoryCell
        let item = filteredItems[indexPath.row]
        cell.configure(with: item, relativeTime: relativeTime(from: item.createdAt))
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let item = filteredItems[indexPath.row]
        let textToCopy = item.resultText ?? item.originalText
        UIPasteboard.general.string = textToCopy

        let toast = UILabel()
        toast.text = L("ai_writer.copied")
        toast.font = .systemFont(ofSize: 13, weight: .medium)
        toast.textColor = .white
        toast.backgroundColor = UIColor.black.withAlphaComponent(0.8)
        toast.textAlignment = .center
        toast.layer.cornerRadius = 8
        toast.clipsToBounds = true
        toast.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(toast)
        NSLayoutConstraint.activate([
            toast.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            toast.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            toast.widthAnchor.constraint(greaterThanOrEqualToConstant: 100),
            toast.heightAnchor.constraint(equalToConstant: 32),
        ])
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            toast.removeFromSuperview()
        }
    }

    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let delete = UIContextualAction(style: .destructive, title: nil) { [weak self] _, _, completion in
            guard let self else { completion(false); return }
            let item = self.filteredItems[indexPath.row]
            HistoryManager.shared.deleteItem(id: item.id)
            self.reloadData()
            completion(true)
        }
        delete.image = UIImage(systemName: "trash")
        return UISwipeActionsConfiguration(actions: [delete])
    }
}

// MARK: - HistoryCell

class HistoryCell: UITableViewCell {

    private let cardView = UIView()
    private let tagLabel = UILabel()
    private let timeLabel = UILabel()
    private let originalLabel = UILabel()
    private let separator = UIView()
    private let resultLabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupCell()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupCell() {
        backgroundColor = .clear
        selectionStyle = .none

        cardView.backgroundColor = AppColors.card
        cardView.layer.cornerRadius = 12
        cardView.layer.borderWidth = 1
        cardView.layer.borderColor = AppColors.border.cgColor
        cardView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(cardView)

        tagLabel.font = .systemFont(ofSize: 11, weight: .semibold)
        tagLabel.textColor = .white
        tagLabel.layer.cornerRadius = 4
        tagLabel.clipsToBounds = true
        tagLabel.textAlignment = .center
        tagLabel.translatesAutoresizingMaskIntoConstraints = false

        timeLabel.font = .systemFont(ofSize: 11)
        timeLabel.textColor = AppColors.textMuted
        timeLabel.translatesAutoresizingMaskIntoConstraints = false

        originalLabel.font = .systemFont(ofSize: 14)
        originalLabel.textColor = AppColors.text
        originalLabel.numberOfLines = 2
        originalLabel.translatesAutoresizingMaskIntoConstraints = false

        separator.backgroundColor = AppColors.border
        separator.translatesAutoresizingMaskIntoConstraints = false

        resultLabel.font = .systemFont(ofSize: 14)
        resultLabel.textColor = AppColors.accent
        resultLabel.numberOfLines = 2
        resultLabel.translatesAutoresizingMaskIntoConstraints = false

        cardView.addSubview(tagLabel)
        cardView.addSubview(timeLabel)
        cardView.addSubview(originalLabel)
        cardView.addSubview(separator)
        cardView.addSubview(resultLabel)

        NSLayoutConstraint.activate([
            cardView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 4),
            cardView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            cardView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            cardView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -4),

            tagLabel.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 12),
            tagLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 14),
            tagLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 40),
            tagLabel.heightAnchor.constraint(equalToConstant: 20),

            timeLabel.centerYAnchor.constraint(equalTo: tagLabel.centerYAnchor),
            timeLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -14),

            originalLabel.topAnchor.constraint(equalTo: tagLabel.bottomAnchor, constant: 10),
            originalLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 14),
            originalLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -14),

            separator.topAnchor.constraint(equalTo: originalLabel.bottomAnchor, constant: 8),
            separator.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 14),
            separator.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -14),
            separator.heightAnchor.constraint(equalToConstant: 0.5),

            resultLabel.topAnchor.constraint(equalTo: separator.bottomAnchor, constant: 8),
            resultLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 14),
            resultLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -14),
            resultLabel.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -12),
        ])
    }

    func configure(with item: HistoryItem, relativeTime: String) {
        timeLabel.text = relativeTime
        originalLabel.text = item.originalText

        switch item.type {
        case .translation:
            tagLabel.text = " \(item.metadata ?? "KO → EN") "
            tagLabel.backgroundColor = AppColors.blue
            resultLabel.text = item.resultText
            separator.isHidden = false
            resultLabel.isHidden = false
        case .correction:
            tagLabel.text = " \(item.metadata ?? L("home.stat.corrections")) "
            tagLabel.backgroundColor = AppColors.orange
            resultLabel.text = item.resultText
            separator.isHidden = false
            resultLabel.isHidden = false
        case .clipboard:
            tagLabel.text = " \(item.metadata ?? "Text") "
            tagLabel.backgroundColor = AppColors.green
            separator.isHidden = true
            resultLabel.isHidden = true
        }
    }
}
