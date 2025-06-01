import SwiftUI

enum AppLanguage: CaseIterable, Identifiable {
    var id: Self { self }
    case russian
    case english

    var title: LocalizedStringKey {
        self == .russian ? "Russian" : "English"
    }

    static func makeCurrentValue(_ localeIdentifier: String) -> AppLanguage {
        let isRussian = localeIdentifier.split(separator: "_").first == "ru"
        return isRussian ? .russian : .english
    }
}
