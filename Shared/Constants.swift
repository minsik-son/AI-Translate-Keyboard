import Foundation

enum AppConstants {
    static let appGroupIdentifier = "group.com.translatorkeyboard.shared"
    static let mainBundleIdentifier = "com.translatorkeyboard.app"
    static let extensionBundleIdentifier = "com.translatorkeyboard.app.keyboard"

    enum UserDefaultsKeys {
        static let subscriptionTier = "subscription_tier"
        static let subscriptionExpiry = "subscription_expiry"
        static let selectedTheme = "selected_theme"
        static let dailySessionCount = "daily_session_count"
        static let lastSessionDate = "last_session_date"
        static let bonusSessions = "bonus_sessions"
        static let sourceLanguage = "source_language"
        static let targetLanguage = "target_language"
        static let autoComplete = "auto_complete"
        static let autoCapitalize = "auto_capitalize"
        static let hapticFeedback = "haptic_feedback"
        static let appLanguage = "app_language"
        static let keyboardLayout = "keyboard_layout"
        static let hasCompletedOnboarding = "has_completed_onboarding"
        static let savedPhrases = "saved_phrases"
        static let keyboardTheme = "keyboard_theme"
    }

    enum API {
        static let baseURL = "https://proxy-server-for-tk.vercel.app"
        static let translateEndpoint = "/api/translate"
        static let correctEndpoint = "/api/correct"
        static let timeout: TimeInterval = 10
    }

    enum Limits {
        static let maxCharacters = 200
        static let warningCharacters = 150
        static let freeSessionsPerDay = 30
        static let debounceDuration: TimeInterval = 0.3
        static let cacheMaxItems = 100
    }
}
