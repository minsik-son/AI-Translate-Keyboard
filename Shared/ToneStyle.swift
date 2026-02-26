import Foundation

enum ToneStyle: String, CaseIterable {
    case none = "none"
    case formal = "formal"
    case casual = "casual"
    case business = "business"
    case friendly = "friendly"

    var displayName: String {
        switch self {
        case .none: return "기본"
        case .formal: return "존댓말"
        case .casual: return "반말"
        case .business: return "비즈니스"
        case .friendly: return "친근한"
        }
    }

    var displayNameEN: String {
        switch self {
        case .none: return "Default"
        case .formal: return "Formal"
        case .casual: return "Casual"
        case .business: return "Business"
        case .friendly: return "Friendly"
        }
    }
}
