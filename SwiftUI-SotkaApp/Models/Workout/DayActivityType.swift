import SwiftUI

/// Тип активности на день
enum DayActivityType: CaseIterable {
    /// Тренировка
    case workout
    /// Растяжка
    case stretch
    /// Отдых
    case rest
    /// Пропуск из-за болезни/травмы
    case sick

    var localizedTitle: LocalizedStringKey {
        switch self {
        case .workout: "WorkoutDay"
        case .stretch: "StretchDay"
        case .rest: "RestDay"
        case .sick: "SickDay"
        }
    }

    var color: Color {
        switch self {
        case .workout: .blue
        case .stretch: .purple
        case .rest: .green
        case .sick: .red
        }
    }

    var iconName: String {
        switch self {
        case .workout: "figure.play"
        case .stretch: "figure.flexibility"
        case .rest: "chair.lounge"
        case .sick: "medical.thermometer"
        }
    }
}
