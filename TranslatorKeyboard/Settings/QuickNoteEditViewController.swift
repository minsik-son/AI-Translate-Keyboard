import UIKit

class QuickNoteEditViewController: UIViewController {

    private var note: QuickNote?
    private var isNewNote: Bool

    private let textView: UITextView = {
        let tv = UITextView()
        tv.font = .systemFont(ofSize: 16)
        tv.translatesAutoresizingMaskIntoConstraints = false
        tv.textContainerInset = UIEdgeInsets(top: 16, left: 12, bottom: 16, right: 12)
        return tv
    }()

    private let charCountLabel: UILabel = {
        let l = UILabel()
        l.font = .monospacedDigitSystemFont(ofSize: 12, weight: .regular)
        l.textColor = .secondaryLabel
        l.textAlignment = .right
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    init(note: QuickNote?) {
        self.note = note
        self.isNewNote = (note == nil)
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = AppColors.bg
        navigationItem.title = isNewNote ? L("quicknote.new") : L("quicknote.edit")
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: L("quicknote.done"),
            style: .done,
            target: self,
            action: #selector(saveTapped)
        )

        view.addSubview(textView)
        view.addSubview(charCountLabel)

        textView.delegate = self

        NSLayoutConstraint.activate([
            textView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            textView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            textView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            textView.bottomAnchor.constraint(equalTo: charCountLabel.topAnchor, constant: -4),

            charCountLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            charCountLabel.bottomAnchor.constraint(equalTo: view.keyboardLayoutGuide.topAnchor, constant: -8),
        ])

        if let note = note {
            textView.text = note.content
        }
        updateCharCount()
        textView.becomeFirstResponder()
    }

    @objc private func saveTapped() {
        let content = textView.text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !content.isEmpty else {
            navigationController?.popViewController(animated: true)
            return
        }

        if let note = note {
            QuickNoteManager.shared.updateNote(id: note.id, content: content)
        } else {
            QuickNoteManager.shared.addNote(content)
        }
        navigationController?.popViewController(animated: true)
    }

    private func updateCharCount() {
        let count = textView.text.count
        let max = AppConstants.Limits.quickNoteMaxLength
        charCountLabel.text = "\(count)/\(max)"
        charCountLabel.textColor = count >= max ? .systemRed : .secondaryLabel
    }
}

extension QuickNoteEditViewController: UITextViewDelegate {
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        let currentText = textView.text ?? ""
        let newLength = currentText.count - range.length + text.count
        return newLength <= AppConstants.Limits.quickNoteMaxLength
    }

    func textViewDidChange(_ textView: UITextView) {
        updateCharCount()
    }
}
