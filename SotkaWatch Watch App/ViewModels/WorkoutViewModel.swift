import Foundation
import Observation
import OSLog

/// ViewModel для экрана выполнения тренировки на Apple Watch
@MainActor
@Observable
final class WorkoutViewModel {
    @ObservationIgnored private let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "SotkaWatch",
        category: String(describing: WorkoutViewModel.self)
    )

    @ObservationIgnored private let workoutService: WatchWorkoutService
    @ObservationIgnored private let connectivityService: any WatchConnectivityServiceProtocol

    var currentRound: Int {
        workoutService.currentRound
    }

    var completedRounds: Int {
        workoutService.completedRounds
    }

    var duration: TimeInterval {
        guard let startTime = workoutService.workoutStartTime else {
            return 0
        }
        return Date.now.timeIntervalSince(startTime)
    }

    var isFinished = false
    var error: Error?
    var showRestTimer = false
    var restTime = 0
    var restTimerStartTime: Date?

    /// Инициализатор из WorkoutData
    /// - Parameters:
    ///   - workoutData: Данные тренировки
    ///   - connectivityService: Сервис связи с iPhone
    ///   - appGroupHelper: Хелпер для чтения данных из App Group UserDefaults (по умолчанию создается новый экземпляр)
    init(
        workoutData: WorkoutData,
        connectivityService: any WatchConnectivityServiceProtocol,
        appGroupHelper: (any WatchAppGroupHelperProtocol)? = nil
    ) {
        self.workoutService = WatchWorkoutService(workoutData: workoutData, appGroupHelper: appGroupHelper)
        self.connectivityService = connectivityService
        self.restTime = workoutService.getRestTime()
        logger.info("Инициализирован WorkoutViewModel для дня \(workoutData.day)")
    }

    /// Инициализатор из WatchWorkoutService (для тестирования)
    /// - Parameters:
    ///   - workoutService: Сервис тренировки
    ///   - connectivityService: Сервис связи с iPhone
    init(
        workoutService: WatchWorkoutService,
        connectivityService: any WatchConnectivityServiceProtocol
    ) {
        self.workoutService = workoutService
        self.connectivityService = connectivityService
        self.restTime = workoutService.getRestTime()
        logger.info("Инициализирован WorkoutViewModel с существующим workoutService")
    }

    /// Завершение круга/подхода (запускает таймер отдыха, если есть время отдыха)
    func completeRound() {
        guard !isFinished else {
            logger.warning("Попытка завершить круг в завершенной тренировке")
            return
        }

        workoutService.completeRound()
        let completedRoundsValue = completedRounds
        let currentRoundValue = currentRound
        logger.info("Завершен круг/подход \(completedRoundsValue), текущий круг: \(currentRoundValue)")

        if restTime > 0 {
            startRestTimer()
        }
    }

    /// Запуск таймера отдыха
    private func startRestTimer() {
        showRestTimer = true
        restTimerStartTime = Date.now
        let restTimeValue = restTime
        logger.info("Запущен таймер отдыха: \(restTimeValue) секунд")
    }

    /// Обработка завершения таймера отдыха
    /// - Parameter force: `true` для досрочного завершения, `false` для автоматического
    func handleRestTimerFinish(force: Bool) {
        guard showRestTimer else {
            logger.warning("Попытка завершить таймер отдыха, который не запущен")
            return
        }

        if let startTime = restTimerStartTime {
            let actualRestTime = Int(Date().timeIntervalSince(startTime))
            logger.info("Завершение таймера отдыха: фактическое время \(actualRestTime) секунд (досрочно: \(force))")
        }

        showRestTimer = false
        restTimerStartTime = nil
        logger.info("Таймер отдыха завершен, продолжение тренировки")
    }

    /// Проверка и обработка истекшего таймера при активации приложения
    func checkAndHandleExpiredRestTimer() {
        guard showRestTimer else {
            return
        }

        guard let startTime = restTimerStartTime else {
            return
        }

        let elapsedTime = Date().timeIntervalSince(startTime)
        let restTimeValue = restTime
        guard elapsedTime >= TimeInterval(restTimeValue) else {
            return
        }

        logger.info("Обнаружен истекший таймер отдыха при активации приложения, закрываем экран таймера")
        handleRestTimerFinish(force: true)
    }

    /// Завершение тренировки (формирование результата, отправка на iPhone)
    func finishWorkout() async {
        guard !isFinished else {
            logger.warning("Попытка завершить уже завершенную тренировку")
            return
        }

        isFinished = true

        guard let executionType = workoutService.workoutData.exerciseExecutionType else {
            logger.error("Не удалось определить тип выполнения упражнений")
            error = WatchConnectivityError.invalidResponse
            return
        }

        let result = workoutService.finishWorkout()
        logger.info("Тренировка завершена: количество кругов/подходов \(result.count), длительность \(result.duration ?? 0) секунд")

        do {
            try await connectivityService.sendWorkoutResult(
                day: workoutService.workoutData.day,
                result: result,
                executionType: executionType
            )
            logger.info("Результат тренировки успешно отправлен на iPhone")
        } catch {
            logger.error("Ошибка отправки результата тренировки на iPhone: \(error.localizedDescription)")
            self.error = error
        }
    }

    /// Прерывание тренировки
    func cancelWorkout() {
        guard !isFinished else {
            logger.warning("Попытка прервать уже завершенную тренировку")
            return
        }

        workoutService.cancelWorkout()
        isFinished = true
        showRestTimer = false
        restTimerStartTime = nil
        let completedRoundsValue = completedRounds
        logger.info("Тренировка прервана на круге/подходе \(completedRoundsValue)")
    }
}
