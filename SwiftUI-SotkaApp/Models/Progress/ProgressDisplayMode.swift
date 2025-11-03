import SwiftUI

/// Режимы отображения прогресса
enum ProgressDisplayMode: CaseIterable, Identifiable {
    var id: Self { self }

    case metrics
    case photos

    /// Локализованные названия режимов
    var localizedTitle: String {
        switch self {
        case .metrics:
            String(localized: .progressMetrics)
        case .photos:
            String(localized: .progressPhotos)
        }
    }
}
