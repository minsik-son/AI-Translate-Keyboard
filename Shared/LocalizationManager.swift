import Foundation

extension Notification.Name {
    static let languageDidChange = Notification.Name("languageDidChange")
}

enum AppLanguage: String, CaseIterable {
    case en = "en"
    case ko = "ko"
    case ja = "ja"
    case zhHans = "zh-Hans"
    case ru = "ru"
    case es = "es"
    case fr = "fr"
    case de = "de"
    case it = "it"

    var translationLanguageCode: String {
        switch self {
        case .zhHans: return "zh-CN"
        default: return rawValue
        }
    }

    var displayName: String {
        switch self {
        case .en: return "English"
        case .ko: return "한국어"
        case .ja: return "日本語"
        case .zhHans: return "中文(简体)"
        case .ru: return "Русский"
        case .es: return "Español"
        case .fr: return "Français"
        case .de: return "Deutsch"
        case .it: return "Italiano"
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
            NotificationCenter.default.post(name: .languageDidChange, object: nil)
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
