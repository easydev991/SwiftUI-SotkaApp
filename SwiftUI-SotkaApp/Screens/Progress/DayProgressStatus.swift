import SwiftUI

/// Статус дня в прогрессе тренировки
enum DayProgressStatus: Identifiable, CaseIterable {
    var id: Self {
        self
    }

    case notStarted
    case skipped
    case partial
    case completed
    case currentDay

    var color: Color {
        switch self {
        case .currentDay:
            Color.blue
        case .completed:
            Color.green
        case .partial:
            Color.yellow
        case .skipped:
            Color.red
        case .notStarted:
            Color.gray.opacity(0.3)
        }
    }

    var localizedTitle: String {
        switch self {
        case .notStarted:
            String(localized: .progressStatusNotStarted)
        case .skipped:
            String(localized: .progressStatusSkipped)
        case .partial:
            String(localized: .progressStatusPartial)
        case .completed:
            String(localized: .progressStatusCompleted)
        case .currentDay:
            String(localized: .progressStatusCurrentDay)
        }
    }
}
