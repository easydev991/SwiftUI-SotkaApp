import SwiftUI

/// Тип выполнения упражнений
enum ExerciseExecutionType: Int {
    /// Круги
    case cycles = 0
    /// Подходы
    case sets = 1

    var localizedTitle: String {
        switch self {
        case .cycles: String(localized: .cycles)
        case .sets: String(localized: .sets)
        }
    }
}
