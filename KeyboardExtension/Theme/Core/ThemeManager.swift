import UIKit

enum AppTheme: String {
    case light = "light"
    case dark = "dark"
    case system = "system"
}

final class ThemeManager {
    static let shared = ThemeManager()

    private let appGroup = AppGroupManager.shared

    private init() {}

    var currentTheme: AppTheme {
        guard let themeString = appGroup.string(forKey: AppConstants.UserDefaultsKeys.selectedTheme),
              let theme = AppTheme(rawValue: themeString) else {
            return .system
        }
        return theme
    }

    func setTheme(_ theme: AppTheme) {
        appGroup.set(theme.rawValue, forKey: AppConstants.UserDefaultsKeys.selectedTheme)
    }

    var keyBackgroundColor: UIColor {
        switch effectiveTheme {
        case .light: return .white
        case .dark: return UIColor(white: 0.45, alpha: 1)
        case .system: return .white
        }
    }

    var keyTextColor: UIColor {
        switch effectiveTheme {
        case .light: return .black
        case .dark: return .white
        case .system: return .black
        }
    }

    var keyboardBackgroundColor: UIColor {
        switch effectiveTheme {
        case .light: return UIColor(white: 0.85, alpha: 1)
        case .dark: return UIColor(white: 0.08, alpha: 1)
        case .system: return UIColor(white: 0.85, alpha: 1)
        }
    }

    var toolbarBackgroundColor: UIColor {
        switch effectiveTheme {
        case .light: return .secondarySystemBackground
        case .dark: return UIColor(white: 0.12, alpha: 1)
        case .system: return .secondarySystemBackground
        }
    }

    private var effectiveTheme: AppTheme {
        let theme = currentTheme
        if theme == .system {
            // Will be determined by traitCollection at usage site
            return .light
        }
        return theme
    }
}
