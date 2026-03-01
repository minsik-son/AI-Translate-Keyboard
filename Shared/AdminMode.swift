import Foundation

final class AdminMode {
    static let shared = AdminMode()

    private let defaults: UserDefaults?
    private let adminKey = "admin_mode_enabled"
    private let adminCode = "tk2026admin"

    private init() {
        defaults = UserDefaults(suiteName: AppConstants.appGroupIdentifier)
    }

    var isEnabled: Bool {
        return defaults?.bool(forKey: adminKey) ?? false
    }

    func activate(code: String) -> Bool {
        if code == adminCode {
            defaults?.set(true, forKey: adminKey)
            return true
        }
        return false
    }

    func deactivate() {
        defaults?.set(false, forKey: adminKey)
    }
}
