import Foundation
import SwiftData

/// Калькулятор для расчета статистики прогресса
struct ProgressCalculator {
    private let user: User
    private let currentDay: Int

    init(user: User, currentDay: Int) {
        self.user = user
        self.currentDay = currentDay
    }

    /// Рассчитывает полный прогресс (дни с активностью И инфопостом)
    var fullProgressPercent: Int {
        let totalDays = min(100, currentDay)
        guard totalDays > 0 else { return 0 }

        var completedDays = 0

        for day in 1 ... totalDays {
            let hasActivityForDay = hasActivity(for: day)
            let hasInfopost = user.readInfopostDays.contains(day)

            if hasActivityForDay, hasInfopost {
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
        let activityDays = user.dayActivities.count(where: { !$0.shouldDelete })
        return Int((Double(activityDays) / Double(totalDays)) * 100)
    }

    /// Статусы всех дней
    var dayStatuses: [DayProgressStatus] {
        (1 ... 100).map { day in
            getDayStatus(day: day)
        }
    }
}

private extension ProgressCalculator {
    /// Проверяет наличие активности для конкретного дня
    func hasActivity(for day: Int) -> Bool {
        user.activitiesByDay[day] != nil
    }

    /// Определяет статус дня
    func getDayStatus(day: Int) -> DayProgressStatus {
        // Текущий день - всегда синий
        if day == currentDay {
            return .currentDay
        }

        // Проверяем, что день в пределах программы
        guard day <= currentDay else {
            return .notStarted
        }

        let hasActivityForDay = hasActivity(for: day)
        let hasInfopost = user.readInfopostDays.contains(day)

        // Зеленый: активность + инфопост
        if hasActivityForDay && hasInfopost {
            return .completed
        }

        // Желтый: только активность ИЛИ только инфопост
        if hasActivityForDay || hasInfopost {
            return .partial
        }

        // Красный: ничего нет
        return .skipped
    }
}
