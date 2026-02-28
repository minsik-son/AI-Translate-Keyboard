import Foundation

class SessionManager {
    static let shared = SessionManager()

    private let appGroup = AppGroupManager.shared

    private init() {}

    var remainingSessions: Int {
        return CompositionSessionManager.shared.remainingSessions()
    }

    var canTranslate: Bool {
        return CompositionSessionManager.shared.canStartSession()
    }

    func useSession() {
        // No-op: session counting is now handled by CompositionSessionManager.startSession()
    }

    func addBonusSessions(_ count: Int) {
        let current = appGroup.integer(forKey: AppConstants.UserDefaultsKeys.bonusSessions)
        appGroup.set(current + count, forKey: AppConstants.UserDefaultsKeys.bonusSessions)
    }
}
