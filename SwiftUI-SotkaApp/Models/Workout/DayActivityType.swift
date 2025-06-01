import SwiftUI

/// Тип активности на день
enum DayActivityType {
    /// Тренировка
    case workout
    /// Отдых
    case rest
    /// Растяжка
    case stretch
    /// Пропуск из-за болезни/травмы
    case sick

    var localizedTitle: LocalizedStringKey {
        switch self {
        case .workout: "WorkoutDay"
        case .rest: "RestDay"
        case .stretch: "StretchDay"
        case .sick: "SickDay"
        }
    }
}
