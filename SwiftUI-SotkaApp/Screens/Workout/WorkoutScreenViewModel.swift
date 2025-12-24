import Foundation
import Observation
import OSLog
import SwiftData
import SWUtils
import UserNotifications

@MainActor
@Observable
final class WorkoutScreenViewModel {
    @ObservationIgnored private let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "SotkaApp",
        category: String(describing: WorkoutScreenViewModel.self)
    )
    private let restTimerNotificationIdentifier = "restTimerNotification"
    private let audioPlayer = AudioPlayerManager()

    var dayNumber = 1
    var executionType: ExerciseExecutionType = .cycles
    var trainings: [WorkoutPreviewTraining] = []
    var plannedCount: Int?
    var restTime: Int = Constants.defaultRestTime

    var stepStates: [WorkoutStepState] = []
    var currentStepIndex = 0

    var showTimer = false

    @ObservationIgnored var workoutStartTime: Date?
    @ObservationIgnored var totalRestTime = 0
    @ObservationIgnored var currentRestStartTime: Date?

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

    /// Определяет фактический тип выполнения для турбо-дней
    /// - Returns: Фактический тип выполнения
    func getEffectiveExecutionType() -> ExerciseExecutionType {
        WorkoutProgramCreator.getEffectiveExecutionType(for: dayNumber, executionType: executionType)
    }

    /// Определяет, является ли текущая тренировка турбо-днем с подходами
    var isTurboWithSets: Bool {
        WorkoutProgramCreator.isTurboWithSets(day: dayNumber, executionType: executionType)
    }

    // Методы инициализации
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

    func initializeStepStates() {
        stepStates = []
        currentStepIndex = 0

        stepStates.append(WorkoutStepState(step: .warmUp, state: .inactive))
        let effectiveType = getEffectiveExecutionType()
        switch effectiveType {
        case .cycles:
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
        case .sets:
            let setsPerExercise = isTurboWithSets ? 1 : (plannedCount ?? 0)
            if setsPerExercise > 0 {
                for _ in trainings {
                    for setNumber in 1 ... setsPerExercise {
                        stepStates.append(
                            WorkoutStepState(
                                step: .exercise(.sets, number: setNumber),
                                state: .inactive
                            )
                        )
                    }
                }
            }
        case .turbo:
            assertionFailure("Кейс .turbo недостижим: getEffectiveExecutionType() всегда преобразует .turbo в .cycles или .sets")
        }
        stepStates.append(WorkoutStepState(step: .coolDown, state: .inactive))
        let executionTypeValue = executionType.rawValue
        let plannedCountValue = plannedCount ?? 0
        logger.info("Инициализация этапов: тип выполнения \(executionTypeValue), количество \(plannedCountValue)")
    }

    // Методы управления тренировкой
    func completeCurrentStep(appSettings: AppSettings) {
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
                scheduleRestTimerNotification(appSettings: appSettings)
            }
        }

        if case let .exercise(executionType, number) = completedStep {
            logger.info("Завершение этапа: тип выполнения \(executionType.rawValue), номер \(number)")
        } else {
            logger.info("Завершение этапа: \(completedStep.id)")
        }
    }

    func handleTimerFinish(force: Bool, appSettings: AppSettings) {
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
        guard !force else {
            return
        }
        if appSettings.playTimerSound {
            logger.info("Воспроизведение звука после таймера отдыха: \(appSettings.timerSound.rawValue)")
            if audioPlayer.setupSound(appSettings.timerSound) {
                audioPlayer.play()
            } else {
                logger.error("Не удалось настроить звук")
            }
        } else {
            logger.debug("Звук отключен в настройках")
        }
        if appSettings.vibrate {
            logger.info("Выполнение вибрации после таймера отдыха")
            VibrationService.perform()
        } else {
            logger.debug("Вибрация отключена в настройках")
        }
    }

    func scheduleRestTimerNotification(appSettings: AppSettings) {
        cancelRestTimerNotification()

        let content = UNMutableNotificationContent()
        content.title = String(localized: .notificationDailyWorkoutTitle)
        content.body = String(localized: .restCompleted)
        content.sound = appSettings.playTimerSound ? .default : nil
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

    func cancelRestTimerNotification() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: [restTimerNotificationIdentifier]
        )
        logger.info("Отмена уведомления о завершении отдыха")
    }

    func checkAndHandleExpiredRestTimer(appSettings: AppSettings) {
        guard showTimer else { return }
        guard let restStartTime = currentRestStartTime else { return }

        let elapsedTime = Date().timeIntervalSince(restStartTime)
        guard elapsedTime >= TimeInterval(restTime) else { return }

        logger.info("Обнаружен истекший таймер отдыха при активации приложения, закрываем экран таймера")
        handleTimerFinish(force: true, appSettings: appSettings)
    }

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

    func getStepState(for step: WorkoutStep) -> WorkoutState {
        guard let stepState = stepStates.first(where: { $0.step.id == step.id }) else {
            return .inactive
        }
        return stepState.state
    }

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

    func getExerciseSteps(for trainingId: String) -> [WorkoutStepState] {
        let effectiveType = getEffectiveExecutionType()
        guard effectiveType == .sets else {
            return []
        }

        guard let exerciseIndex = trainings.firstIndex(where: { $0.id == trainingId }) else {
            return []
        }

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

    func getExerciseTitle(for training: WorkoutPreviewTraining, modelContext: ModelContext) -> String {
        let exerciseName: String? = if let typeId = training.typeId {
            ExerciseType(rawValue: typeId)?.localizedTitle
        } else if let customTypeId = training.customTypeId {
            CustomExercise.fetch(by: customTypeId, in: modelContext)?.name
        } else {
            nil
        }
        guard let name = exerciseName, !name.isEmpty else {
            return ""
        }
        return name
    }

    func getExerciseTitleWithCount(for training: WorkoutPreviewTraining, modelContext: ModelContext) -> String {
        let exerciseName: String? = if let typeId = training.typeId {
            ExerciseType(rawValue: typeId)?.localizedTitle
        } else if let customTypeId = training.customTypeId {
            CustomExercise.fetch(by: customTypeId, in: modelContext)?.name
        } else {
            nil
        }
        guard let name = exerciseName, !name.isEmpty else {
            return ""
        }
        if let count = training.count {
            return "\(name) x \(count)"
        } else {
            return name
        }
    }
}
