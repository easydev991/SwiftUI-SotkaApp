import Foundation
import OSLog

/// Сервис для логики выполнения тренировки на Apple Watch
final class WatchWorkoutService {
    private let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "SotkaWatch",
        category: String(describing: WatchWorkoutService.self)
    )

    let workoutData: WorkoutData
    private(set) var currentRound = 1
    private(set) var completedRounds = 0
    private(set) var workoutStartTime: Date?
    private(set) var isCancelled = false
    private let appGroupHelper: any WatchAppGroupHelperProtocol

    /// Инициализация из WorkoutData
    /// - Parameters:
    ///   - workoutData: Данные тренировки
    ///   - appGroupHelper: Хелпер для чтения данных из App Group UserDefaults (по умолчанию создается новый экземпляр)
    init(workoutData: WorkoutData, appGroupHelper: (any WatchAppGroupHelperProtocol)? = nil) {
        self.workoutData = workoutData
        self.appGroupHelper = appGroupHelper ?? WatchAppGroupHelper()
        self.workoutStartTime = Date()
        logger.info("Инициализирована тренировка дня \(workoutData.day)")
    }

    /// Завершение круга/подхода
    func completeRound() {
        guard !isCancelled else {
            logger.warning("Попытка завершить круг в прерванной тренировке")
            return
        }

        completedRounds += 1
        currentRound = completedRounds + 1

        let completedRoundsValue = completedRounds
        let currentRoundValue = currentRound
        logger.info("Завершен круг/подход \(completedRoundsValue), текущий круг: \(currentRoundValue)")
    }

    /// Получение времени отдыха между кругами/подходами
    /// - Returns: Время отдыха в секундах или значение по умолчанию если время отдыха не установлено
    func getRestTime() -> Int {
        appGroupHelper.restTime
    }

    /// Завершение тренировки и формирование результата
    /// - Returns: Результат тренировки
    func finishWorkout() -> WorkoutResult {
        guard !isCancelled else {
            logger.warning("Попытка завершить прерванную тренировку")
            return WorkoutResult(count: completedRounds, duration: nil)
        }

        let duration: Int?
        if let startTime = workoutStartTime {
            let workoutTime = Int(Date().timeIntervalSince(startTime))
            duration = workoutTime
        } else {
            duration = nil
        }

        let result = WorkoutResult(count: completedRounds, duration: duration)
        logger.info("Тренировка завершена: количество кругов/подходов \(result.count), длительность \(duration ?? 0) секунд")

        return result
    }

    /// Прерывание тренировки
    func cancelWorkout() {
        guard !isCancelled else {
            return
        }

        isCancelled = true
        let completedRoundsValue = completedRounds
        logger.info("Тренировка прервана на круге/подходе \(completedRoundsValue)")
    }
}
