import SwiftUI

/// Тип выполнения упражнений
enum ExerciseExecutionType {
    /// Круги
    case cycles
    /// Подходы
    case sets

    var localizedTitle: String {
        switch self {
        case .cycles: String(localized: .cycles)
        case .sets: String(localized: .sets)
        }
    }
}
