import Foundation

enum TargetStyle: String, CaseIterable, Identifiable {
    case targetArchery
    case fieldArchery

    var id: String { rawValue }

    var title: String {
        switch self {
        case .targetArchery:
            return "Target Archery"
        case .fieldArchery:
            return "Field Archery"
        }
    }

    var detailLabel: String {
        switch self {
        case .targetArchery:
            return "10 rings / 5 colors"
        case .fieldArchery:
            return "6 rings / 2 colors"
        }
    }

    var ringCount: Int {
        switch self {
        case .targetArchery:
            return 10
        case .fieldArchery:
            return 6
        }
    }
}
