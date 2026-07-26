import SwiftUI

enum AppLanguage: CaseIterable, Identifiable {
    var id: Self {
        self
    }

    case russian
    case english

    var localizedTitle: String {
        switch self {
        case .russian: String(localized: .russian)
        case .english: String(localized: .english)
        }
    }
}
