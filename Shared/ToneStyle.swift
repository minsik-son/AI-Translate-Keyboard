import Foundation

enum ToneStyle: String, CaseIterable {
    case none = "none"
    case formal = "formal"
    case casual = "casual"
    case business = "business"
    case friendly = "friendly"

    var displayName: String {
        switch self {
        case .none: return L("tone.none")
        case .formal: return L("tone.formal")
        case .casual: return L("tone.casual")
        case .business: return L("tone.business")
        case .friendly: return L("tone.friendly")
        }
    }
}
