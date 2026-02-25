import UIKit

class TextProxyManager {

    private weak var textDocumentProxy: UITextDocumentProxy?
    private var previousInsertedLength: Int = 0

    var hasPendingText: Bool {
        return previousInsertedLength > 0
    }

    init(textDocumentProxy: UITextDocumentProxy) {
        self.textDocumentProxy = textDocumentProxy
    }

    func updateProxy(_ proxy: UITextDocumentProxy) {
        self.textDocumentProxy = proxy
    }

    func replaceText(with newText: String) {
        guard let proxy = textDocumentProxy else { return }

        // Delete previous inserted text
        for _ in 0..<previousInsertedLength {
            proxy.deleteBackward()
        }

        // Insert new text
        proxy.insertText(newText)
        previousInsertedLength = newText.count
    }

    func clearPreviousText() {
        guard let proxy = textDocumentProxy else { return }

        for _ in 0..<previousInsertedLength {
            proxy.deleteBackward()
        }
        previousInsertedLength = 0
    }

    func insertText(_ text: String) {
        textDocumentProxy?.insertText(text)
    }

    func deleteBackward() {
        textDocumentProxy?.deleteBackward()
    }

    func reset() {
        previousInsertedLength = 0
    }
}
