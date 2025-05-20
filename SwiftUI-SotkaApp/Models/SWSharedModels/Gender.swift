import Foundation

enum Gender: CaseIterable, CustomStringConvertible, Codable {
    case unspecified
    case male
    case female

    init?(_ code: Int) {
        switch code {
        case -1:
            self = .unspecified
        case 0:
            self = .male
        case 1:
            self = .female
        default:
            return nil
        }
    }

    var code: Int {
        switch self {
        case .unspecified:
            -1
        case .male:
            0
        case .female:
            1
        }
    }

    var affiliation: String {
        switch self {
        case .unspecified: NSLocalizedString("Gender.NotSpecified.Afiliation", comment: "")
        case .male: NSLocalizedString("Gender.Male.Affiliation", comment: "")
        case .female: NSLocalizedString("Gender.Female.Affiliation", comment: "")
        }
    }

    var description: String {
        switch self {
        case .unspecified: ""
        case .male: NSLocalizedString("Gender.Male", comment: "")
        case .female: NSLocalizedString("Gender.Female", comment: "")
        }
    }
}
