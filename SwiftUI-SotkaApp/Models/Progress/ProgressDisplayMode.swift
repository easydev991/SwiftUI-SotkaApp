import SwiftUI

/// Режимы отображения прогресса
enum ProgressDisplayMode: CaseIterable, Identifiable {
    var id: Self { self }

    case metrics
    case photos

    /// Локализованные названия режимов
    var title: String {
        switch self {
        case .metrics:
            String(localized: "Progress.Metrics")
        case .photos:
            String(localized: "Progress.Photos")
        }
    }
}
