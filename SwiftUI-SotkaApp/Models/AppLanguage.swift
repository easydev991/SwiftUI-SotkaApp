import SwiftUI

enum AppLanguage: CaseIterable, Identifiable {
    var id: Self { self }
    case russian
    case english

    var localizedTitle: String {
        switch self {
        case .russian: String(localized: .russian)
        case .english: String(localized: .english)
        }
    }

    static func makeCurrentValue(_ localeIdentifier: String) -> AppLanguage {
        let isRussian = localeIdentifier.split(separator: "_").first == "ru"
        return isRussian ? .russian : .english
    }
}
