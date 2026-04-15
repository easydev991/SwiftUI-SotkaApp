import Foundation

enum Gender: CaseIterable, CustomStringConvertible, Codable {
    case male
    case female
    case unspecified

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
        case .unspecified: String(localized: .genderNotSpecifiedAfiliation)
        case .male: String(localized: .genderMaleAffiliation)
        case .female: String(localized: .genderFemaleAffiliation)
        }
    }

    var description: String {
        switch self {
        case .unspecified: String(localized: .genderNotSpecified)
        case .male: String(localized: .genderMale)
        case .female: String(localized: .genderFemale)
        }
    }
}
