import SwiftUI

/// Режимы отображения прогресса
enum ProgressDisplayMode: CaseIterable, Identifiable {
    var id: Self { self }

    case metrics
    case photos

    /// Локализованные названия режимов
    var title: LocalizedStringKey {
        switch self {
        case .metrics:
            "Progress.Metrics"
        case .photos:
            "Progress.Photos"
        }
    }
}
