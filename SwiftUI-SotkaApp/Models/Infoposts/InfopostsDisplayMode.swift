import Foundation
import SwiftUI

/// Режимы отображения инфопостов
enum InfopostsDisplayMode: CaseIterable, Identifiable {
    var id: Self {
        self
    }

    case all
    case favorites

    /// Локализованные названия режимов
    var localizedTitle: String {
        switch self {
        case .all:
            String(localized: .infopostsAll)
        case .favorites:
            String(localized: .infopostsFavorites)
        }
    }

    /// Показывать только избранные посты
    var showsOnlyFavorites: Bool {
        switch self {
        case .all:
            false
        case .favorites:
            true
        }
    }
}
