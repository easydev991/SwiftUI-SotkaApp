import SwiftUI

/// Размер шрифта для отображения инфопостов
enum FontSize: String, CaseIterable, Identifiable {
    var id: Self { self }

    case small
    case medium
    case large

    var title: LocalizedStringKey {
        switch self {
        case .small: "FontSize.Small"
        case .medium: "FontSize.Medium"
        case .large: "FontSize.Large"
        }
    }

    static let appStorageKey = "InfopostFontSize"
}
