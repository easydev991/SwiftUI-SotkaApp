import Foundation
import SwiftData

/// Калькулятор для расчета статистики прогресса
struct ProgressCalculator {
    private let user: User
    private let activities: [DayActivityType]
    private let currentDay: Int

    init(user: User, activities: [DayActivityType], currentDay: Int) {
        self.user = user
        self.activities = activities
        self.currentDay = currentDay
    }

    /// Рассчитывает полный прогресс (дни с активностью И инфопостом)
    var fullProgressPercent: Int {
        let totalDays = min(100, currentDay)
        guard totalDays > 0 else { return 0 }

        var completedDays = 0

        for day in 1 ... totalDays {
            let hasActivity = activities.indices.contains(day - 1)
            let hasInfopost = user.readInfopostDays.contains(day)

            if hasActivity, hasInfopost {
                completedDays += 1
            }
        }

        return Int((Double(completedDays) / Double(totalDays)) * 100)
    }

    /// Рассчитывает прогресс по инфопостам
    var infoPostsPercent: Int {
        let totalDays = 100
        let readDays = user.readInfopostDays.count
        return Int((Double(readDays) / Double(totalDays)) * 100)
    }

    /// Рассчитывает прогресс по активностям
    var activityPercent: Int {
        let totalDays = 100
        let activityDays = activities.count
        return Int((Double(activityDays) / Double(totalDays)) * 100)
    }

    /// Статусы всех дней
    var dayStatuses: [DayProgressStatus] {
        (1 ... 100).map { day in
            getDayStatus(day: day)
        }
    }

    /// Определяет статус дня
    private func getDayStatus(day: Int) -> DayProgressStatus {
        // Текущий день - всегда синий
        if day == currentDay {
            return .currentDay
        }

        // Проверяем, что день в пределах программы
        guard day <= currentDay else {
            return .notStarted
        }

        let hasActivity = activities.indices.contains(day - 1)
        let hasInfopost = user.readInfopostDays.contains(day)

        // Зеленый: активность + инфопост
        if hasActivity && hasInfopost {
            return .completed
        }

        // Желтый: только активность ИЛИ только инфопост
        if hasActivity || hasInfopost {
            return .partial
        }

        // Красный: ничего нет
        return .skipped
    }
}
