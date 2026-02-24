import Foundation

/// Phase 2: Advanced Hangul composition engine
/// Will handle:
/// - Context-aware composition (ㅇ→오→온→오늘)
/// - Prediction of likely next character
/// - Compound vowel/consonant suggestions
protocol HangulComposing {
    /// Current composition state
    var composingText: String { get }

    /// Process a single jamo input
    func processJamo(_ jamo: Character) -> CompositionResult

    /// Delete the last input unit
    func deleteBackward() -> CompositionResult

    /// Commit current composition to buffer
    func commit() -> String

    /// Reset composition state
    func reset()
}

enum CompositionResult {
    case composing(String)      // Still composing, display this
    case committed(String, composing: String) // Committed text + new composing
    case deleted(String)        // After deletion, display this
    case empty                  // Nothing to display
}
