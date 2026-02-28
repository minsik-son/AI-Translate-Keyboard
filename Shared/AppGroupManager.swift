import Foundation

final class AppGroupManager {
    static let shared = AppGroupManager()

    private let userDefaults: UserDefaults?

    private init() {
        userDefaults = UserDefaults(suiteName: AppConstants.appGroupIdentifier)
        userDefaults?.register(defaults: [
            AppConstants.UserDefaultsKeys.autoCapitalize: true,
            AppConstants.UserDefaultsKeys.hapticFeedback: true
        ])
    }

    func set(_ value: Any?, forKey key: String) {
        userDefaults?.set(value, forKey: key)
    }

    func string(forKey key: String) -> String? {
        return userDefaults?.string(forKey: key)
    }

    func integer(forKey key: String) -> Int {
        return userDefaults?.integer(forKey: key) ?? 0
    }

    func bool(forKey key: String) -> Bool {
        return userDefaults?.bool(forKey: key) ?? false
    }

    func date(forKey key: String) -> Date? {
        return userDefaults?.object(forKey: key) as? Date
    }

    func removeObject(forKey key: String) {
        userDefaults?.removeObject(forKey: key)
    }
}
