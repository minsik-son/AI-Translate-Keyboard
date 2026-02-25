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
        displayName: "파스텔 레드",
        keyboardBackground: UIColor(red: 0.98, green: 0.88, blue: 0.88, alpha: 1),
        keyBackground: UIColor(red: 1.0, green: 0.95, blue: 0.95, alpha: 1),
        specialKeyBackground: UIColor(red: 0.95, green: 0.82, blue: 0.82, alpha: 1),
        keyTextColor: UIColor(red: 0.35, green: 0.15, blue: 0.15, alpha: 1),
        toolbarBackground: UIColor(red: 0.96, green: 0.85, blue: 0.85, alpha: 1)
    )

    static let pastelOrange = KeyboardTheme(
        id: "pastel_orange",
        displayName: "파스텔 오렌지",
        keyboardBackground: UIColor(red: 0.99, green: 0.92, blue: 0.85, alpha: 1),
        keyBackground: UIColor(red: 1.0, green: 0.96, blue: 0.92, alpha: 1),
        specialKeyBackground: UIColor(red: 0.96, green: 0.87, blue: 0.78, alpha: 1),
        keyTextColor: UIColor(red: 0.38, green: 0.22, blue: 0.10, alpha: 1),
        toolbarBackground: UIColor(red: 0.97, green: 0.90, blue: 0.82, alpha: 1)
    )

    static let pastelYellow = KeyboardTheme(
        id: "pastel_yellow",
        displayName: "파스텔 옐로우",
        keyboardBackground: UIColor(red: 0.99, green: 0.97, blue: 0.85, alpha: 1),
        keyBackground: UIColor(red: 1.0, green: 0.99, blue: 0.92, alpha: 1),
        specialKeyBackground: UIColor(red: 0.96, green: 0.93, blue: 0.78, alpha: 1),
        keyTextColor: UIColor(red: 0.35, green: 0.30, blue: 0.10, alpha: 1),
        toolbarBackground: UIColor(red: 0.97, green: 0.95, blue: 0.82, alpha: 1)
    )

    static let pastelGreen = KeyboardTheme(
        id: "pastel_green",
        displayName: "파스텔 그린",
        keyboardBackground: UIColor(red: 0.88, green: 0.96, blue: 0.88, alpha: 1),
        keyBackground: UIColor(red: 0.94, green: 0.99, blue: 0.94, alpha: 1),
        specialKeyBackground: UIColor(red: 0.82, green: 0.93, blue: 0.82, alpha: 1),
        keyTextColor: UIColor(red: 0.15, green: 0.32, blue: 0.15, alpha: 1),
        toolbarBackground: UIColor(red: 0.85, green: 0.94, blue: 0.85, alpha: 1)
    )

    static let pastelBlue = KeyboardTheme(
        id: "pastel_blue",
        displayName: "파스텔 블루",
        keyboardBackground: UIColor(red: 0.87, green: 0.92, blue: 0.98, alpha: 1),
        keyBackground: UIColor(red: 0.93, green: 0.96, blue: 1.0, alpha: 1),
        specialKeyBackground: UIColor(red: 0.80, green: 0.87, blue: 0.95, alpha: 1),
        keyTextColor: UIColor(red: 0.14, green: 0.22, blue: 0.38, alpha: 1),
        toolbarBackground: UIColor(red: 0.84, green: 0.90, blue: 0.96, alpha: 1)
    )

    static let pastelIndigo = KeyboardTheme(
        id: "pastel_indigo",
        displayName: "파스텔 인디고",
        keyboardBackground: UIColor(red: 0.90, green: 0.88, blue: 0.98, alpha: 1),
        keyBackground: UIColor(red: 0.95, green: 0.94, blue: 1.0, alpha: 1),
        specialKeyBackground: UIColor(red: 0.84, green: 0.82, blue: 0.95, alpha: 1),
        keyTextColor: UIColor(red: 0.22, green: 0.18, blue: 0.40, alpha: 1),
        toolbarBackground: UIColor(red: 0.88, green: 0.85, blue: 0.96, alpha: 1)
    )

    static let pastelViolet = KeyboardTheme(
        id: "pastel_violet",
        displayName: "파스텔 바이올렛",
        keyboardBackground: UIColor(red: 0.95, green: 0.88, blue: 0.96, alpha: 1),
        keyBackground: UIColor(red: 0.98, green: 0.94, blue: 0.99, alpha: 1),
        specialKeyBackground: UIColor(red: 0.92, green: 0.82, blue: 0.93, alpha: 1),
        keyTextColor: UIColor(red: 0.35, green: 0.15, blue: 0.36, alpha: 1),
        toolbarBackground: UIColor(red: 0.93, green: 0.85, blue: 0.94, alpha: 1)
    )

    static let allPastelThemes: [KeyboardTheme] = [
        .pastelRed, .pastelOrange, .pastelYellow, .pastelGreen,
        .pastelBlue, .pastelIndigo, .pastelViolet
    ]

    static let defaultLight = KeyboardTheme(
        id: "default",
        displayName: "기본",
        keyboardBackground: UIColor(red: 0.82, green: 0.84, blue: 0.86, alpha: 1),
        keyBackground: .white,
        specialKeyBackground: UIColor(red: 0.76, green: 0.78, blue: 0.81, alpha: 1),
        keyTextColor: .black,
        toolbarBackground: .clear
    )

    static let allThemes: [KeyboardTheme] = [defaultLight] + allPastelThemes

    /// Returns the currently selected custom theme, or nil if "default" (use isDark logic).
    static func currentTheme() -> KeyboardTheme? {
        let defaults = UserDefaults(suiteName: AppConstants.appGroupIdentifier)
        guard let themeId = defaults?.string(forKey: AppConstants.UserDefaultsKeys.keyboardTheme),
              themeId != "default" else {
            return nil
        }
        return allThemes.first { $0.id == themeId }
    }
}
