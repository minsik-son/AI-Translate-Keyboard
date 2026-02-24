import Foundation

enum AppLanguage: String, CaseIterable {
    case en = "en"
    case ko = "ko"
    case ja = "ja"
    case zhHans = "zh-Hans"
    case es = "es"

    var displayName: String {
        switch self {
        case .en: return "English"
        case .ko: return "한국어"
        case .ja: return "日本語"
        case .zhHans: return "简体中文"
        case .es: return "Español"
        }
    }
}

final class LocalizationManager {
    static let shared = LocalizationManager()
    private var bundle: Bundle = .main

    private init() { loadBundle() }

    var currentLanguage: AppLanguage {
        get {
            guard let code = AppGroupManager.shared.string(forKey: AppConstants.UserDefaultsKeys.appLanguage),
                  let lang = AppLanguage(rawValue: code) else { return .ko }
            return lang
        }
        set {
            AppGroupManager.shared.set(newValue.rawValue, forKey: AppConstants.UserDefaultsKeys.appLanguage)
            loadBundle()
        }
    }

    func localized(_ key: String) -> String {
        bundle.localizedString(forKey: key, value: nil, table: "Localizable")
    }

    private func loadBundle() {
        let langCode = currentLanguage.rawValue
        if let path = Bundle.main.path(forResource: langCode, ofType: "lproj"),
           let langBundle = Bundle(path: path) {
            bundle = langBundle
        } else {
            bundle = .main
        }
    }

    func reload() { loadBundle() }
}

func L(_ key: String) -> String {
    LocalizationManager.shared.localized(key)
}
