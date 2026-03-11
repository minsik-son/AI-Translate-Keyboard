import UIKit

struct KeyboardTheme {
    let id: String
    let displayName: String

    // 키보드 전체 배경
    let keyboardBackground: UIColor
    // 일반 키 배경
    let keyBackground: UIColor
    // 특수 키 배경 (shift, backspace, return 등)
    let specialKeyBackground: UIColor
    // 키 텍스트/아이콘
    let keyTextColor: UIColor
    // 툴바 배경
    let toolbarBackground: UIColor
}

// MARK: - Pastel Rainbow Presets

extension KeyboardTheme {

    static let pastelRed = KeyboardTheme(
        id: "pastel_red",
        displayName: L("theme.pastel_red"),
        keyboardBackground: UIColor(red: 0.98, green: 0.88, blue: 0.88, alpha: 1),
        keyBackground: UIColor(red: 1.0, green: 0.98, blue: 0.98, alpha: 1),
        specialKeyBackground: UIColor(red: 0.95, green: 0.82, blue: 0.82, alpha: 1),
        keyTextColor: UIColor(red: 0.35, green: 0.15, blue: 0.15, alpha: 1),
        toolbarBackground: .clear
    )

    static let pastelOrange = KeyboardTheme(
        id: "pastel_orange",
        displayName: L("theme.pastel_orange"),
        keyboardBackground: UIColor(red: 0.99, green: 0.92, blue: 0.85, alpha: 1),
        keyBackground: UIColor(red: 1.0, green: 0.98, blue: 0.96, alpha: 1),
        specialKeyBackground: UIColor(red: 0.96, green: 0.87, blue: 0.78, alpha: 1),
        keyTextColor: UIColor(red: 0.38, green: 0.22, blue: 0.10, alpha: 1),
        toolbarBackground: .clear
    )

    static let pastelYellow = KeyboardTheme(
        id: "pastel_yellow",
        displayName: L("theme.pastel_yellow"),
        keyboardBackground: UIColor(red: 0.99, green: 0.97, blue: 0.85, alpha: 1),
        keyBackground: UIColor(red: 1.0, green: 0.99, blue: 0.96, alpha: 1),
        specialKeyBackground: UIColor(red: 0.96, green: 0.93, blue: 0.78, alpha: 1),
        keyTextColor: UIColor(red: 0.35, green: 0.30, blue: 0.10, alpha: 1),
        toolbarBackground: .clear
    )

    static let pastelGreen = KeyboardTheme(
        id: "pastel_green",
        displayName: L("theme.pastel_green"),
        keyboardBackground: UIColor(red: 0.88, green: 0.96, blue: 0.88, alpha: 1),
        keyBackground: UIColor(red: 0.97, green: 1.0, blue: 0.97, alpha: 1),
        specialKeyBackground: UIColor(red: 0.82, green: 0.93, blue: 0.82, alpha: 1),
        keyTextColor: UIColor(red: 0.15, green: 0.32, blue: 0.15, alpha: 1),
        toolbarBackground: .clear
    )

    static let pastelBlue = KeyboardTheme(
        id: "pastel_blue",
        displayName: L("theme.pastel_blue"),
        keyboardBackground: UIColor(red: 0.87, green: 0.92, blue: 0.98, alpha: 1),
        keyBackground: UIColor(red: 0.97, green: 0.98, blue: 1.0, alpha: 1),
        specialKeyBackground: UIColor(red: 0.80, green: 0.87, blue: 0.95, alpha: 1),
        keyTextColor: UIColor(red: 0.14, green: 0.22, blue: 0.38, alpha: 1),
        toolbarBackground: .clear
    )

    static let pastelIndigo = KeyboardTheme(
        id: "pastel_indigo",
        displayName: L("theme.pastel_indigo"),
        keyboardBackground: UIColor(red: 0.90, green: 0.88, blue: 0.98, alpha: 1),
        keyBackground: UIColor(red: 0.97, green: 0.97, blue: 1.0, alpha: 1),
        specialKeyBackground: UIColor(red: 0.84, green: 0.82, blue: 0.95, alpha: 1),
        keyTextColor: UIColor(red: 0.22, green: 0.18, blue: 0.40, alpha: 1),
        toolbarBackground: .clear
    )

    static let pastelViolet = KeyboardTheme(
        id: "pastel_violet",
        displayName: L("theme.pastel_violet"),
        keyboardBackground: UIColor(red: 0.95, green: 0.88, blue: 0.96, alpha: 1),
        keyBackground: UIColor(red: 0.99, green: 0.97, blue: 1.0, alpha: 1),
        specialKeyBackground: UIColor(red: 0.92, green: 0.82, blue: 0.93, alpha: 1),
        keyTextColor: UIColor(red: 0.35, green: 0.15, blue: 0.36, alpha: 1),
        toolbarBackground: .clear
    )

    static let allPastelThemes: [KeyboardTheme] = [
        .pastelRed, .pastelOrange, .pastelYellow, .pastelGreen,
        .pastelBlue, .pastelIndigo, .pastelViolet
    ]

    static let defaultLight = KeyboardTheme(
        id: "default",
        displayName: L("theme.default"),
        keyboardBackground: UIColor(red: 0.82, green: 0.84, blue: 0.86, alpha: 1),
        keyBackground: .white,
        specialKeyBackground: UIColor(red: 0.76, green: 0.78, blue: 0.81, alpha: 1),
        keyTextColor: .black,
        toolbarBackground: .clear
    )

    // MARK: - Dark Presets

    static let darkNavy = KeyboardTheme(
        id: "dark_navy",
        displayName: L("theme.navy"),
        keyboardBackground: UIColor(red: 0.10, green: 0.12, blue: 0.20, alpha: 1),
        keyBackground: UIColor(red: 0.18, green: 0.21, blue: 0.30, alpha: 1),
        specialKeyBackground: UIColor(red: 0.13, green: 0.15, blue: 0.24, alpha: 1),
        keyTextColor: UIColor(red: 0.82, green: 0.85, blue: 0.92, alpha: 1),
        toolbarBackground: .clear
    )

    static let darkCharcoal = KeyboardTheme(
        id: "dark_charcoal",
        displayName: L("theme.charcoal"),
        keyboardBackground: UIColor(red: 0.13, green: 0.13, blue: 0.14, alpha: 1),
        keyBackground: UIColor(red: 0.22, green: 0.22, blue: 0.23, alpha: 1),
        specialKeyBackground: UIColor(red: 0.16, green: 0.16, blue: 0.17, alpha: 1),
        keyTextColor: UIColor(red: 0.88, green: 0.88, blue: 0.88, alpha: 1),
        toolbarBackground: .clear
    )

    static let darkForest = KeyboardTheme(
        id: "dark_forest",
        displayName: L("theme.dark_green"),
        keyboardBackground: UIColor(red: 0.08, green: 0.16, blue: 0.12, alpha: 1),
        keyBackground: UIColor(red: 0.16, green: 0.25, blue: 0.20, alpha: 1),
        specialKeyBackground: UIColor(red: 0.11, green: 0.19, blue: 0.15, alpha: 1),
        keyTextColor: UIColor(red: 0.78, green: 0.90, blue: 0.82, alpha: 1),
        toolbarBackground: .clear
    )

    static let darkBurgundy = KeyboardTheme(
        id: "dark_burgundy",
        displayName: L("theme.burgundy"),
        keyboardBackground: UIColor(red: 0.20, green: 0.08, blue: 0.10, alpha: 1),
        keyBackground: UIColor(red: 0.30, green: 0.16, blue: 0.18, alpha: 1),
        specialKeyBackground: UIColor(red: 0.24, green: 0.11, blue: 0.13, alpha: 1),
        keyTextColor: UIColor(red: 0.92, green: 0.82, blue: 0.84, alpha: 1),
        toolbarBackground: .clear
    )

    static let allDarkThemes: [KeyboardTheme] = [
        .darkNavy, .darkCharcoal, .darkForest, .darkBurgundy
    ]

    static let allThemes: [KeyboardTheme] = [defaultLight] + allPastelThemes + allDarkThemes

    // MARK: - Premium Presets

    static let premiumMidnightAurora = KeyboardTheme(
        id: "premium_midnight_aurora",
        displayName: L("theme.premium_midnight_aurora"),
        keyboardBackground: UIColor(red: 0.06, green: 0.08, blue: 0.18, alpha: 1),
        keyBackground: UIColor(red: 0.10, green: 0.16, blue: 0.30, alpha: 1),
        specialKeyBackground: UIColor(red: 0.00, green: 0.55, blue: 0.55, alpha: 1),
        keyTextColor: UIColor(red: 0.70, green: 0.92, blue: 0.90, alpha: 1),
        toolbarBackground: .clear
    )

    static let premiumRoseGold = KeyboardTheme(
        id: "premium_rose_gold",
        displayName: L("theme.premium_rose_gold"),
        keyboardBackground: UIColor(red: 0.95, green: 0.85, blue: 0.82, alpha: 1),
        keyBackground: UIColor(red: 1.0, green: 0.96, blue: 0.95, alpha: 1),
        specialKeyBackground: UIColor(red: 0.76, green: 0.57, blue: 0.50, alpha: 1),
        keyTextColor: UIColor(red: 0.35, green: 0.18, blue: 0.15, alpha: 1),
        toolbarBackground: .clear
    )

    static let premiumOceanAbyss = KeyboardTheme(
        id: "premium_ocean_abyss",
        displayName: L("theme.premium_ocean_abyss"),
        keyboardBackground: UIColor(red: 0.04, green: 0.15, blue: 0.25, alpha: 1),
        keyBackground: UIColor(red: 0.08, green: 0.22, blue: 0.35, alpha: 1),
        specialKeyBackground: UIColor(red: 0.10, green: 0.36, blue: 0.47, alpha: 1),
        keyTextColor: UIColor(red: 0.80, green: 0.94, blue: 1.0, alpha: 1),
        toolbarBackground: .clear
    )

    static let premiumSunsetEmber = KeyboardTheme(
        id: "premium_sunset_ember",
        displayName: L("theme.premium_sunset_ember"),
        keyboardBackground: UIColor(red: 0.18, green: 0.06, blue: 0.04, alpha: 1),
        keyBackground: UIColor(red: 0.30, green: 0.12, blue: 0.08, alpha: 1),
        specialKeyBackground: UIColor(red: 0.55, green: 0.33, blue: 0.13, alpha: 1),
        keyTextColor: UIColor(red: 1.0, green: 0.90, blue: 0.75, alpha: 1),
        toolbarBackground: .clear
    )

    static let premiumFrostCrystal = KeyboardTheme(
        id: "premium_frost_crystal",
        displayName: L("theme.premium_frost_crystal"),
        keyboardBackground: UIColor(red: 0.80, green: 0.85, blue: 0.89, alpha: 1),
        keyBackground: UIColor(red: 0.94, green: 0.96, blue: 0.98, alpha: 1),
        specialKeyBackground: UIColor(red: 0.62, green: 0.75, blue: 0.85, alpha: 1),
        keyTextColor: UIColor(red: 0.15, green: 0.22, blue: 0.32, alpha: 1),
        toolbarBackground: .clear
    )

    static let allPremiumThemes: [KeyboardTheme] = [
        .premiumMidnightAurora, .premiumRoseGold, .premiumOceanAbyss,
        .premiumSunsetEmber, .premiumFrostCrystal
    ]

    static let allThemesIncludingPremium: [KeyboardTheme] = allThemes + allPremiumThemes

    // MARK: - Properties

    var isPremium: Bool {
        return id.hasPrefix("premium_")
    }

    var localizedDisplayName: String {
        L("theme.\(id)")
    }

    /// Returns the currently selected custom theme, or nil if "default" (use isDark logic).
    static func currentTheme() -> KeyboardTheme? {
        let defaults = UserDefaults(suiteName: AppConstants.appGroupIdentifier)
        guard let themeId = defaults?.string(forKey: AppConstants.UserDefaultsKeys.keyboardTheme),
              themeId != "default" else {
            return nil
        }
        return allThemesIncludingPremium.first { $0.id == themeId }
    }
}
