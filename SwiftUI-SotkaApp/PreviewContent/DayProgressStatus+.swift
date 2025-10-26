#if DEBUG
import Foundation

extension [DayProgressStatus] {
    /// Пустой прогресс - программа еще не начата
    static let emptyProgress: [DayProgressStatus] = Array(repeating: .notStarted, count: 100)

    /// Общий алгоритм для создания прогресса с текущим днем
    private static func makeDemoProgress(currentDay: Int) -> [DayProgressStatus] {
        let completedCount = currentDay / 3
        let partialCount = currentDay / 3

        return (1 ... 100).map { day in
            if day == currentDay {
                .currentDay
            } else if day < currentDay {
                if day <= completedCount {
                    .completed
                } else if day <= completedCount + partialCount {
                    .partial
                } else {
                    .skipped
                }
            } else {
                .notStarted
            }
        }
    }

    /// Текущий день 25 - треть пройдена, треть пропущена, остальные частично
    static let currentDay25 = makeDemoProgress(currentDay: 25)

    /// Текущий день 50 - треть пройдена, треть пропущена, остальные частично
    static let currentDay50 = makeDemoProgress(currentDay: 50)

    /// Текущий день 100 - треть пройдена, треть пропущена, остальные частично
    static let currentDay100 = makeDemoProgress(currentDay: 100)

    /// Текущий день 100 с полностью выполненным прогрессом
    static var currentDay100Completed: [DayProgressStatus] {
        (1 ... 100).map { day in
            if day == 100 {
                .currentDay
            } else {
                .completed
            }
        }
    }
}
#endif
