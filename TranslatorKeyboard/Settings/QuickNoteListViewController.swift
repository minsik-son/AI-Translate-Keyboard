import UIKit

class QuickNoteListViewController: UITableViewController {

    private var notes: [QuickNote] = []

    init() {
        super.init(style: .insetGrouped)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = L("settings.quick_notes")
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .add,
            target: self,
            action: #selector(addNoteTapped)
        )
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "NoteCell")
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        reloadNotes()
    }

    private func reloadNotes() {
        notes = QuickNoteManager.shared.getAllNotes()
        tableView.reloadData()
    }

    @objc private func addNoteTapped() {
        let editVC = QuickNoteEditViewController(note: nil)
        navigationController?.pushViewController(editVC, animated: true)
    }

    // MARK: - DataSource

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        notes.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "NoteCell", for: indexPath)
        let note = notes[indexPath.row]

        var config = cell.defaultContentConfiguration()
        config.text = note.content
        config.textProperties.numberOfLines = 1
        config.secondaryText = relativeTimeString(from: note.updatedAt)
        config.secondaryTextProperties.color = .secondaryLabel
        config.secondaryTextProperties.font = .systemFont(ofSize: 12)
        cell.contentConfiguration = config
        cell.accessoryType = .disclosureIndicator

        return cell
    }

    // MARK: - Delegate

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let editVC = QuickNoteEditViewController(note: notes[indexPath.row])
        navigationController?.pushViewController(editVC, animated: true)
    }

    override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let delete = UIContextualAction(style: .destructive, title: L("quicknote.delete")) { [weak self] _, _, completion in
            guard let self = self else { completion(false); return }
            QuickNoteManager.shared.deleteNote(id: self.notes[indexPath.row].id)
            self.notes.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .automatic)
            completion(true)
        }
        return UISwipeActionsConfiguration(actions: [delete])
    }

    private func relativeTimeString(from date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}
