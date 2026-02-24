import Foundation

/// Phase 2: Context buffer for improved translation quality
/// Will maintain conversation context to disambiguate:
/// - "맛있었어" (was delicious) vs "멋있었어" (was cool)
/// - Pronoun resolution across sentences
/// - Consistent terminology within a conversation
protocol ContextBuffering {
    /// Previous translated sentences for context
    var contextHistory: [ContextEntry] { get }

    /// Add a new entry to context
    func addEntry(_ entry: ContextEntry)

    /// Get context string for API prompt enhancement
    func contextPrompt() -> String?

    /// Clear all context
    func clearContext()

    /// Maximum number of context entries to maintain
    var maxEntries: Int { get }
}

struct ContextEntry {
    let sourceText: String
    let translatedText: String
    let sourceLang: String
    let targetLang: String
    let timestamp: Date
}
