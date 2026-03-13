import UIKit

enum GradientDirection {
    case topToBottom
    case topLeadingToBottomTrailing
    case leftToRight

    var startPoint: CGPoint {
        switch self {
        case .topToBottom: return CGPoint(x: 0.5, y: 0)
        case .topLeadingToBottomTrailing: return CGPoint(x: 0, y: 0)
        case .leftToRight: return CGPoint(x: 0, y: 0.5)
        }
    }

    var endPoint: CGPoint {
        switch self {
        case .topToBottom: return CGPoint(x: 0.5, y: 1)
        case .topLeadingToBottomTrailing: return CGPoint(x: 1, y: 1)
        case .leftToRight: return CGPoint(x: 1, y: 0.5)
        }
    }
}

enum PatternStyle {
    case none
    case stars
    case noise
    case aurora
    case metalLines
    case petals
    case bubbles
    case woodGrain
    case matrixRain
}

enum KeyVisualStyle {
    case solid
    case translucent(alpha: CGFloat, tint: UIColor)
    case woodBlock(borderColor: UIColor, shadowColor: UIColor, highlightAlpha: CGFloat)
}

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

    // 그라데이션 (nil이면 기존 단색 모드)
    let gradientColors: [UIColor]?
    let gradientLocations: [NSNumber]?
    let gradientDirection: GradientDirection

    // 패턴 오버레이
    let patternStyle: PatternStyle
    let patternOpacity: CGFloat
    let patternTint: UIColor

    // 키 비주얼 스타일
    let keyVisualStyle: KeyVisualStyle
    let specialKeyVisualStyle: KeyVisualStyle

    // 텍스트 효과 (Wood theme)
    let textShadowColor: UIColor
    let textShadowOffset: CGSize
    let textHighlightColor: UIColor
    let textHighlightOffset: CGSize

    // 나무 텍스처 타일
    let woodTileImageName: String?

    // 웨이브 애니메이션 (Matrix Pulse)
    let hasWaveAnimation: Bool

    // 레인 애니메이션 (Digital Rain)
    let hasRainAnimation: Bool

    // 엔터키 Accent (returnKeyIsBlue 시 사용)
    let returnKeyAccentColor: UIColor
    let returnKeyAccentTextColor: UIColor

    var hasWoodTexture: Bool { woodTileImageName != nil }
    var needsWaveAnimation: Bool { hasWaveAnimation }
    var needsRainAnimation: Bool {
        assert(!(hasWaveAnimation && hasRainAnimation),
               "Theme cannot enable both wave and rain animation")
        return hasRainAnimation
    }

    var hasGradient: Bool {
        guard let colors = gradientColors else { return false }
        return !colors.isEmpty
    }
    var hasPattern: Bool { patternStyle != .none }
}

// MARK: - Backward-Compatible Init

extension KeyboardTheme {
    init(id: String, displayName: String,
         keyboardBackground: UIColor, keyBackground: UIColor,
         specialKeyBackground: UIColor, keyTextColor: UIColor,
         toolbarBackground: UIColor) {
        self.id = id
        self.displayName = displayName
        self.keyboardBackground = keyboardBackground
        self.keyBackground = keyBackground
        self.specialKeyBackground = specialKeyBackground
        self.keyTextColor = keyTextColor
        self.toolbarBackground = toolbarBackground
        self.gradientColors = nil
        self.gradientLocations = nil
        self.gradientDirection = .topToBottom
        self.patternStyle = .none
        self.patternOpacity = 0
        self.patternTint = .white
        self.keyVisualStyle = .solid
        self.specialKeyVisualStyle = .solid
        self.textShadowColor = .clear
        self.textShadowOffset = .zero
        self.textHighlightColor = .clear
        self.textHighlightOffset = .zero
        self.woodTileImageName = nil
        self.hasWaveAnimation = false
        self.hasRainAnimation = false
        self.returnKeyAccentColor = .systemBlue
        self.returnKeyAccentTextColor = .white
    }
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
        toolbarBackground: .clear,
        gradientColors: nil, gradientLocations: nil, gradientDirection: .topToBottom,
        patternStyle: .none, patternOpacity: 0, patternTint: .white,
        keyVisualStyle: .solid, specialKeyVisualStyle: .solid,
        textShadowColor: .clear, textShadowOffset: .zero,
        textHighlightColor: .clear, textHighlightOffset: .zero,
        woodTileImageName: nil, hasWaveAnimation: false, hasRainAnimation: false,
        returnKeyAccentColor: UIColor(red: 0.00, green: 0.65, blue: 0.65, alpha: 1),
        returnKeyAccentTextColor: .white
    )

    static let premiumRoseGold = KeyboardTheme(
        id: "premium_rose_gold",
        displayName: L("theme.premium_rose_gold"),
        keyboardBackground: UIColor(red: 0.95, green: 0.85, blue: 0.82, alpha: 1),
        keyBackground: UIColor(red: 1.0, green: 0.96, blue: 0.95, alpha: 1),
        specialKeyBackground: UIColor(red: 0.76, green: 0.57, blue: 0.50, alpha: 1),
        keyTextColor: UIColor(red: 0.35, green: 0.18, blue: 0.15, alpha: 1),
        toolbarBackground: .clear,
        gradientColors: nil, gradientLocations: nil, gradientDirection: .topToBottom,
        patternStyle: .none, patternOpacity: 0, patternTint: .white,
        keyVisualStyle: .solid, specialKeyVisualStyle: .solid,
        textShadowColor: .clear, textShadowOffset: .zero,
        textHighlightColor: .clear, textHighlightOffset: .zero,
        woodTileImageName: nil, hasWaveAnimation: false, hasRainAnimation: false,
        returnKeyAccentColor: UIColor(red: 0.70, green: 0.45, blue: 0.38, alpha: 1),
        returnKeyAccentTextColor: .white
    )

    static let premiumOceanAbyss = KeyboardTheme(
        id: "premium_ocean_abyss",
        displayName: L("theme.premium_ocean_abyss"),
        keyboardBackground: UIColor(red: 0.04, green: 0.15, blue: 0.25, alpha: 1),
        keyBackground: UIColor(red: 0.08, green: 0.22, blue: 0.35, alpha: 1),
        specialKeyBackground: UIColor(red: 0.10, green: 0.36, blue: 0.47, alpha: 1),
        keyTextColor: UIColor(red: 0.80, green: 0.94, blue: 1.0, alpha: 1),
        toolbarBackground: .clear,
        gradientColors: nil, gradientLocations: nil, gradientDirection: .topToBottom,
        patternStyle: .none, patternOpacity: 0, patternTint: .white,
        keyVisualStyle: .solid, specialKeyVisualStyle: .solid,
        textShadowColor: .clear, textShadowOffset: .zero,
        textHighlightColor: .clear, textHighlightOffset: .zero,
        woodTileImageName: nil, hasWaveAnimation: false, hasRainAnimation: false,
        returnKeyAccentColor: UIColor(red: 0.10, green: 0.45, blue: 0.60, alpha: 1),
        returnKeyAccentTextColor: .white
    )

    static let premiumSunsetEmber = KeyboardTheme(
        id: "premium_sunset_ember",
        displayName: L("theme.premium_sunset_ember"),
        keyboardBackground: UIColor(red: 0.18, green: 0.06, blue: 0.04, alpha: 1),
        keyBackground: UIColor(red: 0.30, green: 0.12, blue: 0.08, alpha: 1),
        specialKeyBackground: UIColor(red: 0.55, green: 0.33, blue: 0.13, alpha: 1),
        keyTextColor: UIColor(red: 1.0, green: 0.90, blue: 0.75, alpha: 1),
        toolbarBackground: .clear,
        gradientColors: nil, gradientLocations: nil, gradientDirection: .topToBottom,
        patternStyle: .none, patternOpacity: 0, patternTint: .white,
        keyVisualStyle: .solid, specialKeyVisualStyle: .solid,
        textShadowColor: .clear, textShadowOffset: .zero,
        textHighlightColor: .clear, textHighlightOffset: .zero,
        woodTileImageName: nil, hasWaveAnimation: false, hasRainAnimation: false,
        returnKeyAccentColor: UIColor(red: 0.70, green: 0.42, blue: 0.15, alpha: 1),
        returnKeyAccentTextColor: .white
    )

    static let premiumFrostCrystal = KeyboardTheme(
        id: "premium_frost_crystal",
        displayName: L("theme.premium_frost_crystal"),
        keyboardBackground: UIColor(red: 0.80, green: 0.85, blue: 0.89, alpha: 1),
        keyBackground: UIColor(red: 0.94, green: 0.96, blue: 0.98, alpha: 1),
        specialKeyBackground: UIColor(red: 0.62, green: 0.75, blue: 0.85, alpha: 1),
        keyTextColor: UIColor(red: 0.15, green: 0.22, blue: 0.32, alpha: 1),
        toolbarBackground: .clear,
        gradientColors: nil, gradientLocations: nil, gradientDirection: .topToBottom,
        patternStyle: .none, patternOpacity: 0, patternTint: .white,
        keyVisualStyle: .solid, specialKeyVisualStyle: .solid,
        textShadowColor: .clear, textShadowOffset: .zero,
        textHighlightColor: .clear, textHighlightOffset: .zero,
        woodTileImageName: nil, hasWaveAnimation: false, hasRainAnimation: false,
        returnKeyAccentColor: UIColor(red: 0.45, green: 0.60, blue: 0.75, alpha: 1),
        returnKeyAccentTextColor: .white
    )

    // MARK: - Visual Premium Presets

    static let premiumStarlitNight = KeyboardTheme(
        id: "premium_starlit_night",
        displayName: L("theme.premium_starlit_night"),
        keyboardBackground: UIColor(hex: "#0B0E2A"),
        keyBackground: UIColor(hex: "#50468C").withAlphaComponent(0.45),
        specialKeyBackground: UIColor(hex: "#6450B4").withAlphaComponent(0.6),
        keyTextColor: UIColor(hex: "#D4D0F0"),
        toolbarBackground: .clear,
        gradientColors: [UIColor(hex: "#0B0E2A"), UIColor(hex: "#1A1040"), UIColor(hex: "#0D1B3C")],
        gradientLocations: [0, 0.4, 1.0],
        gradientDirection: .topLeadingToBottomTrailing,
        patternStyle: .stars,
        patternOpacity: 0.7,
        patternTint: .white,
        keyVisualStyle: .translucent(alpha: 0.45, tint: UIColor(hex: "#50468C")),
        specialKeyVisualStyle: .translucent(alpha: 0.6, tint: UIColor(hex: "#6450B4")),
        textShadowColor: .clear,
        textShadowOffset: .zero,
        textHighlightColor: .clear,
        textHighlightOffset: .zero,
        woodTileImageName: nil,
        hasWaveAnimation: false,
        hasRainAnimation: false,
        returnKeyAccentColor: UIColor(hex: "#7B64D0"),
        returnKeyAccentTextColor: .white
    )

    static let premiumVolcanicEmber = KeyboardTheme(
        id: "premium_volcanic_ember",
        displayName: L("theme.premium_volcanic_ember"),
        keyboardBackground: UIColor(hex: "#1A0A08"),
        keyBackground: UIColor(hex: "#A03214").withAlphaComponent(0.4),
        specialKeyBackground: UIColor(hex: "#C86414").withAlphaComponent(0.55),
        keyTextColor: UIColor(hex: "#FFD4A8"),
        toolbarBackground: .clear,
        gradientColors: [UIColor(hex: "#1A0A08"), UIColor(hex: "#2E0E06"), UIColor(hex: "#3D1208"), UIColor(hex: "#1A0A08")],
        gradientLocations: [0, 0.35, 0.7, 1.0],
        gradientDirection: .topToBottom,
        patternStyle: .noise,
        patternOpacity: 0.06,
        patternTint: .white,
        keyVisualStyle: .translucent(alpha: 0.4, tint: UIColor(hex: "#A03214")),
        specialKeyVisualStyle: .translucent(alpha: 0.55, tint: UIColor(hex: "#C86414")),
        textShadowColor: .clear,
        textShadowOffset: .zero,
        textHighlightColor: .clear,
        textHighlightOffset: .zero,
        woodTileImageName: nil,
        hasWaveAnimation: false,
        hasRainAnimation: false,
        returnKeyAccentColor: UIColor(hex: "#E07818"),
        returnKeyAccentTextColor: .white
    )

    static let premiumNorthernLights = KeyboardTheme(
        id: "premium_northern_lights",
        displayName: L("theme.premium_northern_lights"),
        keyboardBackground: UIColor(hex: "#040E1A"),
        keyBackground: UIColor(hex: "#145050").withAlphaComponent(0.45),
        specialKeyBackground: UIColor(hex: "#00A064").withAlphaComponent(0.4),
        keyTextColor: UIColor(hex: "#B0FFE0"),
        toolbarBackground: .clear,
        gradientColors: [UIColor(hex: "#040E1A"), UIColor(hex: "#0A2038"), UIColor(hex: "#0C3030"), UIColor(hex: "#082818")],
        gradientLocations: [0, 0.3, 0.6, 1.0],
        gradientDirection: .topLeadingToBottomTrailing,
        patternStyle: .aurora,
        patternOpacity: 0.25,
        patternTint: UIColor(hex: "#00FF88"),
        keyVisualStyle: .translucent(alpha: 0.45, tint: UIColor(hex: "#145050")),
        specialKeyVisualStyle: .translucent(alpha: 0.4, tint: UIColor(hex: "#00A064")),
        textShadowColor: .clear,
        textShadowOffset: .zero,
        textHighlightColor: .clear,
        textHighlightOffset: .zero,
        woodTileImageName: nil,
        hasWaveAnimation: false,
        hasRainAnimation: false,
        returnKeyAccentColor: UIColor(hex: "#00C878"),
        returnKeyAccentTextColor: .white
    )

    static let premiumBrushedSteel = KeyboardTheme(
        id: "premium_brushed_steel",
        displayName: L("theme.premium_brushed_steel"),
        keyboardBackground: UIColor(hex: "#2A2D32"),
        keyBackground: UIColor(hex: "#B4B9C3").withAlphaComponent(0.25),
        specialKeyBackground: UIColor(hex: "#8C919B").withAlphaComponent(0.35),
        keyTextColor: UIColor(hex: "#D0D4DC"),
        toolbarBackground: .clear,
        gradientColors: [UIColor(hex: "#2A2D32"), UIColor(hex: "#3A3E45"), UIColor(hex: "#32363C")],
        gradientLocations: [0, 0.4, 1.0],
        gradientDirection: .topToBottom,
        patternStyle: .metalLines,
        patternOpacity: 0.08,
        patternTint: .white,
        keyVisualStyle: .translucent(alpha: 0.25, tint: UIColor(hex: "#B4B9C3")),
        specialKeyVisualStyle: .translucent(alpha: 0.35, tint: UIColor(hex: "#8C919B")),
        textShadowColor: .clear,
        textShadowOffset: .zero,
        textHighlightColor: .clear,
        textHighlightOffset: .zero,
        woodTileImageName: nil,
        hasWaveAnimation: false,
        hasRainAnimation: false,
        returnKeyAccentColor: UIColor(hex: "#6E7480"),
        returnKeyAccentTextColor: .white
    )

    static let premiumSakuraBreeze = KeyboardTheme(
        id: "premium_sakura_breeze",
        displayName: L("theme.premium_sakura_breeze"),
        keyboardBackground: UIColor(hex: "#FFE0E8"),
        keyBackground: UIColor.white.withAlphaComponent(0.75),
        specialKeyBackground: UIColor(hex: "#DC8CAA").withAlphaComponent(0.45),
        keyTextColor: UIColor(hex: "#8C3050"),
        toolbarBackground: .clear,
        gradientColors: [UIColor(hex: "#FFF0F3"), UIColor(hex: "#FFE0E8"), UIColor(hex: "#F8D4DE"), UIColor(hex: "#FFE8EE")],
        gradientLocations: [0, 0.4, 0.7, 1.0],
        gradientDirection: .topLeadingToBottomTrailing,
        patternStyle: .petals,
        patternOpacity: 0.35,
        patternTint: UIColor(hex: "#FF8CAA"),
        keyVisualStyle: .translucent(alpha: 0.75, tint: .white),
        specialKeyVisualStyle: .translucent(alpha: 0.45, tint: UIColor(hex: "#DC8CAA")),
        textShadowColor: .clear,
        textShadowOffset: .zero,
        textHighlightColor: .clear,
        textHighlightOffset: .zero,
        woodTileImageName: nil,
        hasWaveAnimation: false,
        hasRainAnimation: false,
        returnKeyAccentColor: UIColor(hex: "#C8648A"),
        returnKeyAccentTextColor: .white
    )

    static let premiumDeepOcean = KeyboardTheme(
        id: "premium_deep_ocean",
        displayName: L("theme.premium_deep_ocean"),
        keyboardBackground: UIColor(hex: "#061828"),
        keyBackground: UIColor(hex: "#14466E").withAlphaComponent(0.45),
        specialKeyBackground: UIColor(hex: "#00648C").withAlphaComponent(0.5),
        keyTextColor: UIColor(hex: "#A0D8F0"),
        toolbarBackground: .clear,
        gradientColors: [UIColor(hex: "#061828"), UIColor(hex: "#0A2844"), UIColor(hex: "#08203C"), UIColor(hex: "#041420")],
        gradientLocations: [0, 0.35, 0.65, 1.0],
        gradientDirection: .topToBottom,
        patternStyle: .bubbles,
        patternOpacity: 0.3,
        patternTint: UIColor(hex: "#40A0D0"),
        keyVisualStyle: .translucent(alpha: 0.45, tint: UIColor(hex: "#14466E")),
        specialKeyVisualStyle: .translucent(alpha: 0.5, tint: UIColor(hex: "#00648C")),
        textShadowColor: .clear,
        textShadowOffset: .zero,
        textHighlightColor: .clear,
        textHighlightOffset: .zero,
        woodTileImageName: nil,
        hasWaveAnimation: false,
        hasRainAnimation: false,
        returnKeyAccentColor: UIColor(hex: "#0082B4"),
        returnKeyAccentTextColor: .white
    )

    // MARK: - Animated Premium Themes

    static let premiumMatrixPulse = KeyboardTheme(
        id: "premium_matrix_pulse",
        displayName: L("theme.premium_matrix_pulse"),
        keyboardBackground: UIColor(hex: "#000000"),
        keyBackground: UIColor(hex: "#00FF41").withAlphaComponent(0.08),
        specialKeyBackground: UIColor(hex: "#00FF41").withAlphaComponent(0.15),
        keyTextColor: UIColor(hex: "#00FF41"),
        toolbarBackground: .clear,
        gradientColors: [UIColor(hex: "#000000"), UIColor(hex: "#001A00"), UIColor(hex: "#000000")],
        gradientLocations: [0, 0.5, 1.0],
        gradientDirection: .topToBottom,
        patternStyle: .matrixRain,
        patternOpacity: 0.12,
        patternTint: UIColor(hex: "#00FF41"),
        keyVisualStyle: .translucent(alpha: 0.08, tint: UIColor(hex: "#00FF41")),
        specialKeyVisualStyle: .translucent(alpha: 0.15, tint: UIColor(hex: "#00FF41")),
        textShadowColor: .clear,
        textShadowOffset: .zero,
        textHighlightColor: .clear,
        textHighlightOffset: .zero,
        woodTileImageName: nil,
        hasWaveAnimation: true,
        hasRainAnimation: false,
        returnKeyAccentColor: UIColor(hex: "#00FF41").withAlphaComponent(0.30),
        returnKeyAccentTextColor: .white
    )

    static let premiumDigitalRain = KeyboardTheme(
        id: "premium_digital_rain",
        displayName: L("theme.premium_digital_rain"),
        keyboardBackground: UIColor(hex: "#000000"),
        keyBackground: UIColor(hex: "#00FF41").withAlphaComponent(0.04),
        specialKeyBackground: UIColor(hex: "#00FF41").withAlphaComponent(0.08),
        keyTextColor: UIColor(hex: "#00FF41"),
        toolbarBackground: .clear,
        gradientColors: [UIColor(hex: "#000000"), UIColor(hex: "#000D00"), UIColor(hex: "#000000")],
        gradientLocations: [0.0, 0.5, 1.0],
        gradientDirection: .topToBottom,
        patternStyle: .matrixRain,
        patternOpacity: 0.08,
        patternTint: UIColor(hex: "#00AA28"),
        keyVisualStyle: .translucent(alpha: 0.04, tint: UIColor(hex: "#00FF41")),
        specialKeyVisualStyle: .translucent(alpha: 0.08, tint: UIColor(hex: "#00FF41")),
        textShadowColor: .clear,
        textShadowOffset: .zero,
        textHighlightColor: .clear,
        textHighlightOffset: .zero,
        woodTileImageName: nil,
        hasWaveAnimation: false,
        hasRainAnimation: true,
        returnKeyAccentColor: UIColor(hex: "#00FF41").withAlphaComponent(0.08),
        returnKeyAccentTextColor: .white
    )

    // MARK: - Wood Premium Themes

    static let premiumDarkWalnut = KeyboardTheme(
        id: "premium_dark_walnut",
        displayName: L("theme.premium_dark_walnut"),
        keyboardBackground: UIColor(red: 0.22, green: 0.15, blue: 0.10, alpha: 1),
        keyBackground: UIColor(red: 0.28, green: 0.20, blue: 0.14, alpha: 1),
        specialKeyBackground: UIColor(red: 0.22, green: 0.15, blue: 0.10, alpha: 1),
        keyTextColor: UIColor(white: 1.0, alpha: 0.75),
        toolbarBackground: .clear,
        gradientColors: [
            UIColor(red: 0.25, green: 0.17, blue: 0.11, alpha: 1),
            UIColor(red: 0.18, green: 0.12, blue: 0.08, alpha: 1),
        ],
        gradientLocations: [0.0, 1.0],
        gradientDirection: .topToBottom,
        patternStyle: .woodGrain,
        patternOpacity: 0.45,
        patternTint: UIColor(red: 0.35, green: 0.24, blue: 0.16, alpha: 1),
        keyVisualStyle: .woodBlock(
            borderColor: UIColor(white: 0, alpha: 0.2),
            shadowColor: UIColor(red: 0.12, green: 0.07, blue: 0.04, alpha: 0.65),
            highlightAlpha: 0.08
        ),
        specialKeyVisualStyle: .woodBlock(
            borderColor: UIColor(white: 0, alpha: 0.3),
            shadowColor: UIColor(red: 0.12, green: 0.07, blue: 0.04, alpha: 0.65),
            highlightAlpha: 0.04
        ),
        textShadowColor: UIColor(white: 0, alpha: 0.7),
        textShadowOffset: CGSize(width: 0, height: -1),
        textHighlightColor: UIColor(white: 1.0, alpha: 0.25),
        textHighlightOffset: CGSize(width: 0, height: 1),
        woodTileImageName: "wood_tile_dark",
        hasWaveAnimation: false,
        hasRainAnimation: false,
        returnKeyAccentColor: UIColor(red: 0.22, green: 0.15, blue: 0.10, alpha: 1),
        returnKeyAccentTextColor: UIColor(white: 1.0, alpha: 0.75)
    )

    static let premiumNaturalOak = KeyboardTheme(
        id: "premium_natural_oak",
        displayName: L("theme.premium_natural_oak"),
        keyboardBackground: UIColor(red: 0.72, green: 0.60, blue: 0.45, alpha: 1),
        keyBackground: UIColor(red: 0.78, green: 0.67, blue: 0.52, alpha: 1),
        specialKeyBackground: UIColor(red: 0.68, green: 0.56, blue: 0.42, alpha: 1),
        keyTextColor: UIColor(red: 0.16, green: 0.10, blue: 0.04, alpha: 0.70),
        toolbarBackground: .clear,
        gradientColors: [
            UIColor(red: 0.76, green: 0.64, blue: 0.49, alpha: 1),
            UIColor(red: 0.68, green: 0.55, blue: 0.40, alpha: 1),
        ],
        gradientLocations: [0.0, 1.0],
        gradientDirection: .topToBottom,
        patternStyle: .woodGrain,
        patternOpacity: 0.35,
        patternTint: UIColor(red: 0.55, green: 0.42, blue: 0.28, alpha: 1),
        keyVisualStyle: .woodBlock(
            borderColor: UIColor(red: 0.40, green: 0.28, blue: 0.12, alpha: 0.2),
            shadowColor: UIColor(red: 0.47, green: 0.35, blue: 0.20, alpha: 0.35),
            highlightAlpha: 0.06
        ),
        specialKeyVisualStyle: .woodBlock(
            borderColor: UIColor(red: 0.40, green: 0.28, blue: 0.12, alpha: 0.3),
            shadowColor: UIColor(red: 0.47, green: 0.35, blue: 0.20, alpha: 0.35),
            highlightAlpha: 0.04
        ),
        textShadowColor: UIColor(white: 0, alpha: 0.25),
        textShadowOffset: CGSize(width: 0, height: -1),
        textHighlightColor: UIColor(white: 1.0, alpha: 0.45),
        textHighlightOffset: CGSize(width: 0, height: 1),
        woodTileImageName: "wood_tile_light",
        hasWaveAnimation: false,
        hasRainAnimation: false,
        returnKeyAccentColor: UIColor(red: 0.68, green: 0.56, blue: 0.42, alpha: 1),
        returnKeyAccentTextColor: UIColor(red: 0.16, green: 0.10, blue: 0.04, alpha: 0.70)
    )

    static let allPremiumThemes: [KeyboardTheme] = [
        .premiumMidnightAurora, .premiumRoseGold, .premiumOceanAbyss,
        .premiumSunsetEmber, .premiumFrostCrystal,
        .premiumStarlitNight, .premiumVolcanicEmber, .premiumNorthernLights,
        .premiumBrushedSteel, .premiumSakuraBreeze, .premiumDeepOcean,
        .premiumDarkWalnut, .premiumNaturalOak,
        .premiumMatrixPulse, .premiumDigitalRain
    ]

    static let allThemesIncludingPremium: [KeyboardTheme] = allThemes + allPremiumThemes

    var isPremium: Bool {
        id.hasPrefix("premium_")
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
