import UIKit

enum AppColors {
    static let bg = UIColor { $0.userInterfaceStyle == .dark
        ? UIColor(red: 0.039, green: 0.039, blue: 0.047, alpha: 1)       // dark: #0A0A0C
        : UIColor(red: 0.965, green: 0.965, blue: 0.975, alpha: 1)       // light: #F6F6F9
    }
    static let surface = UIColor { $0.userInterfaceStyle == .dark
        ? UIColor(red: 0.075, green: 0.075, blue: 0.086, alpha: 1)       // dark: #131316
        : UIColor(red: 0.945, green: 0.945, blue: 0.953, alpha: 1)       // light: #F1F1F3
    }
    static let card = UIColor { $0.userInterfaceStyle == .dark
        ? UIColor(red: 0.086, green: 0.086, blue: 0.102, alpha: 1)       // dark: #16161A
        : .white                                                          // light: #FFFFFF
    }
    static let cardHover = UIColor { $0.userInterfaceStyle == .dark
        ? UIColor(red: 0.110, green: 0.110, blue: 0.133, alpha: 1)       // dark: #1C1C22
        : UIColor(red: 0.949, green: 0.949, blue: 0.957, alpha: 1)       // light: #F2F2F4
    }
    static let border = UIColor { $0.userInterfaceStyle == .dark
        ? UIColor.white.withAlphaComponent(0.06)
        : UIColor.black.withAlphaComponent(0.08)
    }
    static let borderActive = UIColor { $0.userInterfaceStyle == .dark
        ? UIColor.white.withAlphaComponent(0.12)
        : UIColor.black.withAlphaComponent(0.15)
    }
    static let text = UIColor { $0.userInterfaceStyle == .dark
        ? UIColor(red: 0.941, green: 0.941, blue: 0.949, alpha: 1)       // dark: #F0F0F2
        : UIColor(red: 0.102, green: 0.102, blue: 0.118, alpha: 1)       // light: #1A1A1E
    }
    static let textSub = UIColor { $0.userInterfaceStyle == .dark
        ? UIColor(red: 0.541, green: 0.541, blue: 0.588, alpha: 1)       // dark: #8A8A96
        : UIColor(red: 0.420, green: 0.420, blue: 0.471, alpha: 1)       // light: #6B6B78
    }
    static let textMuted = UIColor { $0.userInterfaceStyle == .dark
        ? UIColor(red: 0.333, green: 0.333, blue: 0.373, alpha: 1)       // dark: #55555F
        : UIColor(red: 0.608, green: 0.608, blue: 0.647, alpha: 1)       // light: #9B9BA5
    }
    static let accent = UIColor(red: 0.424, green: 0.361, blue: 0.906, alpha: 1)          // #6C5CE7
    static let accentSoft = UIColor(red: 0.424, green: 0.361, blue: 0.906, alpha: 0.12)
    static let green = UIColor(red: 0.0, green: 0.839, blue: 0.561, alpha: 1)             // #00D68F
    static let orange = UIColor(red: 1.0, green: 0.624, blue: 0.263, alpha: 1)            // #FF9F43
    static let blue = UIColor(red: 0.329, green: 0.627, blue: 1.0, alpha: 1)              // #54A0FF
    static let pink = UIColor(red: 1.0, green: 0.420, blue: 0.616, alpha: 1)              // #FF6B9D
}
