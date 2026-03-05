import Foundation

struct DailyUsageData: Codable {
    var lastResetDate: Date
    var correctionCount: Int
    var translationCount: Int
    var bonusCorrection: Int
    var bonusTranslation: Int
    var rewardedAdCorrection: Int
    var rewardedAdTranslation: Int

    static let empty = DailyUsageData(
        lastResetDate: Date(),
        correctionCount: 0,
        translationCount: 0,
        bonusCorrection: 0,
        bonusTranslation: 0,
        rewardedAdCorrection: 0,
        rewardedAdTranslation: 0
    )
}
