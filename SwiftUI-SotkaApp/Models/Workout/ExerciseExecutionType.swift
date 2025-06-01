import SwiftUI

/// Тип выполнения упражнений
enum ExerciseExecutionType {
    /// Круги
    case cycles
    /// Подходы
    case sets

    var localizedTitle: LocalizedStringKey {
        switch self {
        case .cycles: "Cycles"
        case .sets: "Sets"
        }
    }
}
