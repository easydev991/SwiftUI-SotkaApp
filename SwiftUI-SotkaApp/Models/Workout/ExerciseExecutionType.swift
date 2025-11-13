import SwiftUI

/// Тип выполнения упражнений
enum ExerciseExecutionType: Int {
    /// Круги
    case cycles = 0
    /// Подходы
    case sets = 1
    /// Турбо
    case turbo = 2

    /// Локализованное название во множественном числе
    var localizedTitle: String {
        switch self {
        case .cycles: String(localized: .cycles)
        case .sets: String(localized: .sets)
        case .turbo: String(localized: .turbo)
        }
    }

    /// Локализованное название в единственном числе
    var localizedShortTitle: String {
        switch self {
        case .cycles: String(localized: .cycle)
        case .sets: String(localized: .set)
        case .turbo: localizedTitle
        }
    }

    var image: Image {
        switch self {
        case .cycles, .sets:
            .init(systemName: "arrow.2.squarepath")
        case .turbo:
            .init(systemName: "bolt.fill")
        }
    }
}
