import Foundation

final class SuggestionManager {
    private let autocorrectEngine = AutocorrectEngine()
    private let predictionEngine = PredictionEngine()

    enum SuggestionMode {
        case autocorrect
        case prediction
        case none
    }

    struct SuggestionResult {
        let mode: SuggestionMode
        let suggestions: [String]
    }

    func getSuggestions(
        context: String?,
        currentWord: String?,
        isComposing: Bool,
        language: KeyboardLanguage
    ) -> SuggestionResult {
        // Korean composing → no suggestions
        if isComposing {
            return SuggestionResult(mode: .none, suggestions: [])
        }

        // Currently typing a word → autocorrect
        if let word = currentWord, !word.isEmpty {
            let suggestions = autocorrectEngine.suggestions(for: word, language: language)
            if suggestions.isEmpty {
                return SuggestionResult(mode: .none, suggestions: [])
            }
            return SuggestionResult(mode: .autocorrect, suggestions: suggestions)
        }

        // No current word (after space) → prediction
        let langCode = language.rawValue
        predictionEngine.loadModel(for: langCode)

        let words = extractContextWords(from: context)
        guard !words.isEmpty else {
            return SuggestionResult(mode: .none, suggestions: [])
        }

        let predictions = predictionEngine.predict(context: words)
        if predictions.isEmpty {
            return SuggestionResult(mode: .none, suggestions: [])
        }
        return SuggestionResult(mode: .prediction, suggestions: predictions)
    }

    private func extractContextWords(from context: String?) -> [String] {
        guard let context = context else { return [] }
        let words = context.components(separatedBy: CharacterSet.whitespacesAndNewlines)
            .filter { !$0.isEmpty }
        return Array(words.suffix(2))
    }
}
