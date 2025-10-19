import SwiftUI

/// Размер шрифта для отображения инфопостов
enum FontSize: String, CaseIterable, Identifiable {
    var id: Self { self }

    case small
    case medium
    case large

    var title: String {
        switch self {
        case .small: String(localized: .fontSizeSmall)
        case .medium: String(localized: .fontSizeMedium)
        case .large: String(localized: .fontSizeLarge)
        }
    }

    static let appStorageKey = "InfopostFontSize"
}
