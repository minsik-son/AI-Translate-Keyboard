import Foundation

enum ToneStyle: String, CaseIterable {
    case none = "none"
    case casual = "casual"
    case formal = "formal"
    case polished = "polished"

    var displayName: String {
        switch self {
        case .none: return L("tone.none")
        case .casual: return L("tone.casual")
        case .formal: return L("tone.formal")
        case .polished: return L("tone.polished")
        }
    }
}
