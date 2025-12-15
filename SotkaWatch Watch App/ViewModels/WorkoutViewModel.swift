import Foundation
import Observation
import OSLog
import UserNotifications

/// ViewModel для экрана выполнения тренировки на Apple Watch
@MainActor
@Observable
final class WorkoutViewModel {
    @ObservationIgnored private let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "SotkaWatch",
        category: String(describing: WorkoutViewModel.self)
    )
    private let restTimerNotificationIdentifier = "restTimerNotification"

    @ObservationIgnored private let connectivityService: any WatchConnectivityServiceProtocol
    @ObservationIgnored private let appGroupHelper: any WatchAppGroupHelperProtocol

    private(set) var dayNumber = 1
    private(set) var executionType: ExerciseExecutionType = .cycles
    private(set) var trainings: [WorkoutPreviewTraining] = []
    private(set) var plannedCount: Int?
    private(set) var restTime: Int = Constants.defaultRestTime

    var stepStates: [WorkoutStepState] = []
    private(set) var currentStepIndex = 0

    var showTimer = false

    @ObservationIgnored private(set) var workoutStartTime: Date?
    @ObservationIgnored private(set) var totalRestTime = 0
    @ObservationIgnored private(set) var currentRestStartTime: Date?

    var currentStep: WorkoutStep? {
        guard currentStepIndex < stepStates.count else { return nil }
        return stepStates[currentStepIndex].step
    }

    var isWorkoutCompleted: Bool {
        stepStates.allSatisfy { $0.state == .completed }
    }

    /// Определяет, нужно ли показывать секцию со списком упражнений
    var shouldShowExercisesReminder: Bool {
        if executionType == .cycles {
            return true
        }
        if executionType == .turbo {
            return getEffectiveExecutionType() == .cycles
        }
        return false
    }

    /// Инициализатор
    /// - Parameters:
    ///   - connectivityService: Сервис связи с iPhone для сохранения результата тренировки
    ///   - appGroupHelper: Хелпер для чтения данных из App Group UserDefaults (по умолчанию создается новый экземпляр)
    init(
        connectivityService: any WatchConnectivityServiceProtocol,
        appGroupHelper: (any WatchAppGroupHelperProtocol)? = nil
    ) {
        self.connectivityService = connectivityService
        self.appGroupHelper = appGroupHelper ?? WatchAppGroupHelper()
    }

    /// Определяет фактический тип выполнения для турбо-дней
    /// - Returns: Фактический тип выполнения
    func getEffectiveExecutionType() -> ExerciseExecutionType {
        WorkoutProgramCreator.getEffectiveExecutionType(for: dayNumber, executionType: executionType)
    }

    /// Настройка данных тренировки
    /// - Parameters:
    ///   - dayNumber: Номер дня программы
    ///   - executionType: Тип выполнения тренировки
    ///   - trainings: Массив упражнений
    ///   - plannedCount: Плановое количество кругов/подходов
    ///   - restTime: Время отдыха между подходами/кругами (в секундах)
    func setupWorkoutData(
        dayNumber: Int,
        executionType: ExerciseExecutionType,
        trainings: [WorkoutPreviewTraining],
        plannedCount: Int?,
        restTime: Int
    ) {
        self.dayNumber = dayNumber
        self.executionType = executionType
        self.trainings = trainings
        self.plannedCount = plannedCount
        self.restTime = restTime

        initializeStepStates()

        if !stepStates.isEmpty {
            stepStates[0].state = .active
        }

        workoutStartTime = Date()
        totalRestTime = 0

        logger.info("Настройка данных тренировки: день \(dayNumber), тип выполнения \(executionType.rawValue)")
    }

    /// Инициализация этапов тренировки
    func initializeStepStates() {
        stepStates = []
        currentStepIndex = 0

        let effectiveType = getEffectiveExecutionType()

        switch effectiveType {
        case .cycles:
            stepStates.append(WorkoutStepState(step: .warmUp, state: .inactive))

            if let plannedCount {
                for i in 1 ... plannedCount {
                    stepStates.append(
                        WorkoutStepState(
                            step: .exercise(.cycles, number: i),
                            state: .inactive
                        )
                    )
                }
            }

            stepStates.append(WorkoutStepState(step: .coolDown, state: .inactive))

        case .sets:
            stepStates.append(WorkoutStepState(step: .warmUp, state: .inactive))

            let isTurboWithSets = WorkoutProgramCreator.isTurboWithSets(day: dayNumber, executionType: executionType)
            let setsPerExercise = isTurboWithSets ? 1 : (plannedCount ?? 0)

            if setsPerExercise > 0 {
                var setNumber = 1
                for _ in trainings {
                    for _ in 1 ... setsPerExercise {
                        stepStates.append(
                            WorkoutStepState(
                                step: .exercise(.sets, number: setNumber),
                                state: .inactive
                            )
                        )
                        setNumber += 1
                    }
                }
            }

            stepStates.append(WorkoutStepState(step: .coolDown, state: .inactive))

        case .turbo:
            break
        }

        let executionTypeValue = executionType.rawValue
        let plannedCountValue = plannedCount ?? 0
        logger.info("Инициализация этапов: тип выполнения \(executionTypeValue), количество \(plannedCountValue)")
    }

    /// Завершение текущего этапа
    func completeCurrentStep() {
        guard currentStepIndex < stepStates.count else { return }

        stepStates[currentStepIndex].state = .completed
        let completedStep = stepStates[currentStepIndex].step
        currentStepIndex += 1

        if currentStepIndex < stepStates.count {
            let nextStep = stepStates[currentStepIndex].step
            let isCompletedWarmUp = completedStep == .warmUp
            let isNextCoolDown = nextStep == .coolDown

            if isCompletedWarmUp || isNextCoolDown {
                stepStates[currentStepIndex].state = .active
                showTimer = false
            } else {
                showTimer = true
                currentRestStartTime = Date()
                scheduleRestTimerNotification()
            }
        }

        if case let .exercise(executionType, number) = completedStep {
            logger.info("Завершение этапа: тип выполнения \(executionType.rawValue), номер \(number)")
        } else {
            logger.info("Завершение этапа: \(completedStep.id)")
        }
    }

    /// Обработка завершения таймера отдыха
    /// - Parameter force: `true` для досрочного завершения, `false` для автоматического
    func handleRestTimerFinish(force _: Bool) {
        guard currentRestStartTime != nil else {
            logger.info("Таймер уже был обработан, пропускаем повторный вызов")
            return
        }

        cancelRestTimerNotification()
        showTimer = false

        if let restStartTime = currentRestStartTime {
            let actualRestTime = Int(Date().timeIntervalSince(restStartTime))
            totalRestTime += actualRestTime
            currentRestStartTime = nil
            logger.info("Завершение таймера отдыха: фактическое время \(actualRestTime) секунд")
        }

        if currentStepIndex < stepStates.count {
            stepStates[currentStepIndex].state = .active
        }
        logger.info("Продолжение тренировки после отдыха")
    }

    /// Планирование уведомления об окончании отдыха
    func scheduleRestTimerNotification() {
        cancelRestTimerNotification()

        let content = UNMutableNotificationContent()
        content.title = String(localized: .notificationDailyWorkoutTitle)
        content.body = String(localized: .restCompleted)
        content.sound = nil
        content.userInfo = ["type": "restTimer"]

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: TimeInterval(restTime), repeats: false)
        let request = UNNotificationRequest(
            identifier: restTimerNotificationIdentifier,
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request)
        let restTimeValue = restTime
        logger.info("Планирование уведомления о завершении отдыха через \(restTimeValue) секунд")
    }

    /// Отмена уведомления о завершении отдыха
    func cancelRestTimerNotification() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: [restTimerNotificationIdentifier]
        )
        logger.info("Отмена уведомления о завершении отдыха")
    }

    /// Проверка и обработка истекшего таймера отдыха при активации приложения
    func checkAndHandleExpiredRestTimer() {
        guard showTimer else { return }
        guard let restStartTime = currentRestStartTime else { return }

        let elapsedTime = Date().timeIntervalSince(restStartTime)
        guard elapsedTime >= TimeInterval(restTime) else { return }

        logger.info("Обнаружен истекший таймер отдыха при активации приложения, закрываем экран таймера")
        handleRestTimerFinish(force: true)
    }

    /// Завершение тренировки (формирование результата, отправка на iPhone)
    /// - Returns: Результат тренировки или `nil` если тренировка не завершена
    func finishWorkout() async -> WorkoutResult? {
        let effectiveExecutionType = getEffectiveExecutionType()

        guard let result = getWorkoutResult(interrupt: false) else {
            logger.error("Не удалось получить результат тренировки")
            error = WatchConnectivityError.invalidResponse
            return nil
        }

        logger.info("Тренировка завершена: количество кругов/подходов \(result.count), длительность \(result.duration ?? 0) секунд")

        do {
            try await connectivityService.sendWorkoutResult(
                day: dayNumber,
                result: result,
                executionType: effectiveExecutionType
            )
            logger.info("Результат тренировки успешно отправлен на iPhone")
        } catch {
            logger.error("Ошибка отправки результата тренировки на iPhone: \(error.localizedDescription)")
            self.error = error
            return nil
        }

        return result
    }

    /// Прерывание тренировки
    /// - Returns: Результат прерванной тренировки или `nil` если тренировка не была начата
    func cancelWorkout() -> WorkoutResult? {
        cancelRestTimerNotification()
        showTimer = false
        currentRestStartTime = nil
        logger.info("Тренировка прервана")

        return getWorkoutResult(interrupt: true)
    }

    /// Получение результата тренировки
    /// - Parameter interrupt: `true` для прерванной тренировки, `false` для завершенной
    /// - Returns: Результат тренировки или `nil` если тренировка не завершена и не прервана
    func getWorkoutResult(interrupt: Bool = false) -> WorkoutResult? {
        cancelRestTimerNotification()

        if !interrupt {
            guard isWorkoutCompleted else {
                logger.info("Тренировка не завершена, результат не может быть получен")
                return nil
            }
        }

        let exerciseSteps = stepStates.filter { stepState in
            if case .exercise = stepState.step {
                return true
            }
            return false
        }

        let count = if interrupt {
            exerciseSteps.count(where: { $0.state == .completed })
        } else {
            exerciseSteps.count
        }

        let duration: Int?
        if let startTime = workoutStartTime {
            let workoutTime = Int(Date().timeIntervalSince(startTime))
            duration = workoutTime + totalRestTime
        } else {
            duration = nil
        }

        let countValue = count
        let durationValue = duration ?? 0
        if interrupt {
            logger.info("Получение результата прерванной тренировки: количество \(countValue), длительность \(durationValue) секунд")
        } else {
            logger.info("Получение результата тренировки: количество \(countValue), длительность \(durationValue) секунд")
        }

        return WorkoutResult(count: count, duration: duration)
    }

    /// Получение состояния этапа
    /// - Parameter step: Этап тренировки
    /// - Returns: Состояние этапа
    func getStepState(for step: WorkoutStep) -> WorkoutState {
        guard let stepState = stepStates.first(where: { $0.step.id == step.id }) else {
            return .inactive
        }
        return stepState.state
    }

    /// Получение списка кругов (для типа .cycles)
    /// - Returns: Список этапов кругов
    func getCycleSteps() -> [WorkoutStepState] {
        let effectiveType = getEffectiveExecutionType()
        guard effectiveType == .cycles else {
            return []
        }
        return stepStates.filter { stepState in
            if case .exercise(.cycles, _) = stepState.step {
                return true
            }
            return false
        }
    }

    /// Получение списка подходов для упражнения (для типа .sets)
    /// - Parameter trainingId: Идентификатор упражнения
    /// - Returns: Список этапов подходов для упражнения
    func getExerciseSteps(for trainingId: String) -> [WorkoutStepState] {
        let effectiveType = getEffectiveExecutionType()
        guard effectiveType == .sets else {
            return []
        }

        guard let exerciseIndex = trainings.firstIndex(where: { $0.id == trainingId }) else {
            return []
        }

        let isTurboWithSets = WorkoutProgramCreator.isTurboWithSets(day: dayNumber, executionType: executionType)
        let setsPerExercise = isTurboWithSets ? 1 : (plannedCount ?? 0)

        guard setsPerExercise > 0 else {
            return []
        }

        let startIndex = 1 + exerciseIndex * setsPerExercise
        let endIndex = startIndex + setsPerExercise

        guard startIndex < stepStates.count, endIndex <= stepStates.count else {
            return []
        }

        let exerciseSteps = Array(stepStates[startIndex ..< endIndex])
        return exerciseSteps.filter { stepState in
            if case .exercise(.sets, _) = stepState.step {
                return true
            }
            return false
        }
    }

    /// Получение заголовка для навигации на основе текущего этапа тренировки
    /// - Returns: Локализованный заголовок для текущего этапа
    func getNavigationTitle() -> String {
        guard let currentStep else {
            return String(localized: .workoutScreenTitle)
        }

        switch currentStep {
        case .warmUp:
            return ""
        case let .exercise(executionType, globalNumber):
            let effectiveType = getEffectiveExecutionType()
            if effectiveType == .cycles {
                let totalCount = plannedCount ?? 0
                return String(localized: .workoutViewCycle(globalNumber, totalCount))
            } else {
                // Для типа .sets нужно вычислить номер подхода для конкретного упражнения
                let isTurboWithSets = WorkoutProgramCreator.isTurboWithSets(day: dayNumber, executionType: executionType)
                let setsPerExercise = isTurboWithSets ? 1 : (plannedCount ?? 0)

                guard setsPerExercise > 0 else {
                    return String(localized: .workoutViewSet(globalNumber, 0))
                }

                // Вычисляем номер подхода для конкретного упражнения
                // Формула: ((globalNumber - 1) % setsPerExercise) + 1
                let setNumberForExercise = ((globalNumber - 1) % setsPerExercise) + 1
                return String(localized: .workoutViewSet(setNumberForExercise, setsPerExercise))
            }
        case .coolDown:
            return ""
        }
    }

    var error: Error?
}
