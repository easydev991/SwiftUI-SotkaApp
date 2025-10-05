import Foundation
import SwiftUI

/// Режимы отображения инфопостов
enum InfopostsDisplayMode: CaseIterable, Identifiable {
    var id: Self { self }

    case all
    case favorites

    /// Локализованные названия режимов
    var title: LocalizedStringKey {
        switch self {
        case .all:
            "Infoposts.All"
        case .favorites:
            "Infoposts.Favorites"
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
