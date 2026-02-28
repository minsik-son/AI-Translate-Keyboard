import Foundation

final class SavedPhrasesManager {
    static let shared = SavedPhrasesManager()

    private init() {}

    func getPhrases() -> [String] {
        let defaults = UserDefaults(suiteName: AppConstants.appGroupIdentifier)
        return defaults?.stringArray(forKey: AppConstants.UserDefaultsKeys.savedPhrases) ?? []
    }

    func addPhrase(_ phrase: String) {
        var phrases = getPhrases()
        phrases.insert(phrase, at: 0)
        save(phrases)
    }

    func deletePhrase(at index: Int) {
        var phrases = getPhrases()
        guard index >= 0, index < phrases.count else { return }
        phrases.remove(at: index)
        save(phrases)
    }

    private func save(_ phrases: [String]) {
        let defaults = UserDefaults(suiteName: AppConstants.appGroupIdentifier)
        defaults?.set(phrases, forKey: AppConstants.UserDefaultsKeys.savedPhrases)
    }
}
