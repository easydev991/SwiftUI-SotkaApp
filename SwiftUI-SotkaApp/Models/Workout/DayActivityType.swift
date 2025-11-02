import SwiftUI

/// Тип активности на день
enum DayActivityType: Int, CaseIterable, Identifiable {
    var id: Int { rawValue }
    /// Тренировка
    case workout = 0
    /// Растяжка
    case stretch = 2
    /// Отдых
    case rest = 1
    /// Пропуск из-за болезни/травмы
    case sick = 3

    var localizedTitle: String {
        switch self {
        case .workout: String(localized: .workoutDay)
        case .stretch: String(localized: .stretchDay)
        case .rest: String(localized: .restDay)
        case .sick: String(localized: .sickDay)
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

    var image: Image {
        switch self {
        case .workout: Image(systemName: "figure.play")
        case .stretch: Image(systemName: "figure.flexibility")
        case .rest: Image(systemName: "chair.lounge")
        case .sick: Image(systemName: "medical.thermometer")
        }
    }
}
