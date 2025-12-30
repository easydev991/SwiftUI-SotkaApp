import Foundation
import Observation
import OSLog
import SwiftData

@MainActor
@Observable
final class WorkoutPreviewViewModel {
    @ObservationIgnored private let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "SotkaApp",
        category: String(describing: WorkoutPreviewViewModel.self)
    )

    // MARK: - State

    @ObservationIgnored private var originalSnapshot: DataSnapshot?
    private(set) var wasOriginallyPassed = false
    var dayNumber = 1
    var selectedExecutionType: ExerciseExecutionType?
    var availableExecutionTypes: [ExerciseExecutionType] = []
    var trainings: [WorkoutPreviewTraining] = []
    var count: Int?
    var plannedCount: Int?
    var restTime = Constants.defaultRestTime
    var comment: String?
    var error: TrainingError?
    var isWorkoutCompleted = false
    var workoutDuration: Int?
    /// Определяет, должен ли степпер для `plannedCount` быть отключен
    var isPlannedCountDisabled: Bool {
        selectedExecutionType == .turbo
    }

    /// Отображаемое количество кругов/подходов
    ///
    /// Для сохраненных тренировок (`count != nil`) возвращает фактическое значение `count`
    /// Для непройденных тренировок (`count == nil`) возвращает плановое значение `plannedCount`
    var displayedCount: Int? {
        count ?? plannedCount
    }

    /// Определяет, нужно ли показывать кнопку редактирования упражнений
    ///
    /// - Показывается только для типов выполнения `.cycles` и `.sets`
    /// - Скрывается для типа `.turbo`
    var shouldShowEditButton: Bool {
        guard let executionType = selectedExecutionType else { return false }
        return executionType == .cycles || executionType == .sets
    }

    var canEditComment: Bool {
        isWorkoutCompleted || wasOriginallyPassed
    }

    /// Определяет, были ли внесены изменения после первоначальной загрузки
    var hasChanges: Bool {
        guard let originalSnapshot else { return false }
        let currentSnapshot = DataSnapshot(
            selectedExecutionType: selectedExecutionType,
            trainings: trainings,
            count: count,
            plannedCount: plannedCount,
            restTime: restTime,
            comment: comment
        )
        return currentSnapshot != originalSnapshot
    }

    // MARK: - Methods

    /// Инициализация/обновление данных из базы
    /// - Parameters:
    ///   - modelContext: Контекст SwiftData
    ///   - day: Номер дня для загрузки
    ///   - restTime: Время отдыха между подходами/кругами (в секундах)
    func updateData(modelContext: ModelContext, day: Int, restTime: Int) {
        guard dayNumber != day || trainings.isEmpty else {
            logger.info("Нет необходимости обновлять вьюмодель")
            return
        }

        dayNumber = day

        // Запросить DayActivity для дня из ModelContext
        let descriptor = FetchDescriptor<DayActivity>(
            predicate: #Predicate { $0.day == day }
        )
        let activities = (try? modelContext.fetch(descriptor)) ?? []
        let dayActivity = activities.first(where: {
            !$0.shouldDelete && $0.activityType == .workout
        })

        let creator = if let dayActivity {
            // Создать WorkoutProgramCreator из DayActivity
            WorkoutProgramCreator(from: dayActivity)
        } else {
            // Создать WorkoutProgramCreator для нового дня
            WorkoutProgramCreator(day: dayNumber)
        }

        // Загрузить данные из WorkoutProgramCreator в ViewModel
        dayNumber = creator.day
        count = creator.count
        plannedCount = creator.plannedCount
        trainings = creator.trainings
        comment = creator.comment
        selectedExecutionType = creator.executionType
        availableExecutionTypes = creator.availableExecutionTypes
        wasOriginallyPassed = creator.count != nil
        self.restTime = restTime

        // Создать snapshot исходных данных для отслеживания изменений
        originalSnapshot = DataSnapshot(
            selectedExecutionType: selectedExecutionType,
            trainings: trainings,
            count: count,
            plannedCount: plannedCount,
            restTime: restTime,
            comment: comment
        )
    }

    /// Обновление типа выполнения и пересчет упражнений
    /// - Parameter newType: Новый тип выполнения
    func updateExecutionType(_ newType: ExerciseExecutionType) {
        // Создать WorkoutProgramCreator из текущих данных ViewModel
        // executionType будет автоматически вычислен если nil
        let creator = WorkoutProgramCreator(
            day: dayNumber,
            executionType: selectedExecutionType,
            count: count,
            plannedCount: plannedCount,
            trainings: trainings,
            comment: comment
        )

        // Обновить тип выполнения функционально
        let updatedCreator = creator.withExecutionType(newType)

        // Обновить данные ViewModel из обновленного экземпляра
        selectedExecutionType = updatedCreator.executionType
        trainings = updatedCreator.trainings
        plannedCount = updatedCreator.plannedCount
    }

    /// Создание модели DayActivity из простых данных ViewModel
    /// - Returns: DayActivity для сохранения
    func buildDayActivity() -> DayActivity {
        // Создать WorkoutProgramCreator - executionType и plannedCount вычислятся автоматически если nil
        let creator = WorkoutProgramCreator(
            day: dayNumber,
            executionType: selectedExecutionType,
            count: count,
            plannedCount: plannedCount,
            trainings: trainings,
            comment: comment
        )

        // Получить DayActivity через computed property
        let activity = creator.dayActivity

        // Если workoutDuration установлен, использовать его
        if let workoutDuration {
            activity.duration = workoutDuration
        }

        return activity
    }

    /// Сохранение тренировки через DailyActivitiesService
    /// - Parameters:
    ///   - activitiesService: Сервис для работы с активностями
    ///   - modelContext: Контекст SwiftData
    func saveTrainingAsPassed(activitiesService: DailyActivitiesService, modelContext: ModelContext) {
        // Проверить валидность данных
        guard selectedExecutionType != nil else {
            error = .executionTypeNotSelected
            logger.error("Ошибка сохранения: тип выполнения не выбран")
            return
        }

        guard !trainings.isEmpty else {
            error = .trainingsListEmpty
            logger.error("Ошибка сохранения: список упражнений пуст")
            return
        }

        // Установить count = plannedCount, если count == nil
        // Это соответствует логике Android приложения: actualCircles = getPlannedCircles(day) для непройденных дней
        if count == nil, let plannedCount {
            count = plannedCount
        }

        // Построить модель DayActivity из простых данных
        let dayActivity = buildDayActivity()

        // Сохранить через DailyActivitiesService
        activitiesService.createDailyActivity(dayActivity, context: modelContext)

        // Сбросить ошибку при успехе
        error = nil
        let dayNumber = dayNumber
        logger.info("Тренировка для дня \(dayNumber) сохранена")
    }

    /// Определяет, нужно ли показывать пикер типа выполнения
    /// - Parameters:
    ///   - modelContext: Контекст SwiftData
    ///   - day: Номер дня для проверки
    /// - Returns: true если нужно показывать пикер, false иначе
    func shouldShowExecutionTypePicker(modelContext: ModelContext, day: Int) -> Bool {
        // Проверяем, что данные загружены (dayNumber установлен и trainings не пустой)
        guard dayNumber == day, !trainings.isEmpty else { return false }

        // Получить dayActivity из базы для проверки пройденности
        let descriptor = FetchDescriptor<DayActivity>(
            predicate: #Predicate { $0.day == day }
        )
        guard let dayActivity = try? modelContext.fetch(descriptor).first(where: { !$0.shouldDelete }) else {
            // Если активность не найдена, показываем контрол если доступно больше одного типа
            return availableExecutionTypes.count > 1
        }

        // Показываем только для не пройденных дней
        guard !dayActivity.isPassed else { return false }

        // Показываем только если доступно больше одного типа
        return availableExecutionTypes.count > 1
    }

    /// Обновляет количество повторений для конкретной тренировки или `plannedCount`/`count`
    ///
    /// Для сохраненных тренировок (`count != nil`) обновляет фактическое значение `count`
    /// Для непройденных тренировок (`count == nil`) обновляет плановое значение `plannedCount`
    /// - Parameters:
    ///   - id: Идентификатор тренировки или "plannedCount" для обновления `plannedCount`/`count`
    ///   - action: Действие (increment или decrement)
    func updatePlannedCount(id: String, action: TrainingRowAction) {
        if id == "plannedCount" {
            if count != nil {
                let currentCount = count ?? 0
                let newCount: Int = switch action {
                case .increment:
                    currentCount + 1
                case .decrement:
                    max(0, currentCount - 1)
                }
                count = newCount
            } else {
                let currentCount = plannedCount ?? 0
                let newCount: Int = switch action {
                case .increment:
                    currentCount + 1
                case .decrement:
                    max(0, currentCount - 1)
                }
                plannedCount = newCount
            }
        } else {
            trainings = trainings.map { existingTraining in
                guard existingTraining.id == id else { return existingTraining }

                let currentCount = existingTraining.count ?? 0
                let newCount: Int = switch action {
                case .increment:
                    currentCount + 1
                case .decrement:
                    max(0, currentCount - 1)
                }

                return existingTraining.withCount(newCount)
            }
        }
    }

    /// Обновляет комментарий тренировки
    /// - Parameter newComment: Новый комментарий (`nil` для удаления)
    func updateComment(_ newComment: String?) {
        comment = newComment
    }

    /// Обновляет время отдыха между подходами/кругами
    /// - Parameter newValue: Новое значение времени отдыха в секундах
    func updateRestTime(_ newValue: Int) {
        restTime = newValue
    }

    /// Получить тип выполнения для отображения
    /// Для турбо-режима использует getEffectiveExecutionType для определения правильного типа
    /// - Parameter executionType: Тип выполнения упражнений
    /// - Returns: Тип выполнения для отображения
    func displayExecutionType(for executionType: ExerciseExecutionType) -> ExerciseExecutionType {
        WorkoutProgramCreator.getEffectiveExecutionType(for: dayNumber, executionType: executionType)
    }

    /// Обработка результата тренировки
    /// - Parameter result: Результат выполнения тренировки
    func handleWorkoutResult(_ result: WorkoutResult) {
        if result.count == 0 {
            logger.info("Результат тренировки с count = 0, не обновляем состояние")
            return
        }

        count = result.count
        workoutDuration = result.duration
        isWorkoutCompleted = true
        let countValue = result.count
        let durationValue = result.duration ?? 0
        logger.info("Обработка результата тренировки: количество \(countValue), длительность \(durationValue) секунд")
    }

    /// Обновляет список упражнений тренировки
    /// Пересчитывает sortOrder на основе порядка в массиве
    /// - Parameter newTrainings: Новый список упражнений
    func updateTrainings(_ newTrainings: [WorkoutPreviewTraining]) {
        let trainingsWithSortOrder = newTrainings.enumerated().map { index, training in
            WorkoutPreviewTraining(
                id: training.id,
                count: training.count,
                typeId: training.typeId,
                customTypeId: training.customTypeId,
                sortOrder: index
            )
        }
        trainings = trainingsWithSortOrder
        logger.info("Обновлен список упражнений: \(trainingsWithSortOrder.count) упражнений")
    }
}

extension WorkoutPreviewViewModel {
    /// Ошибки валидации при сохранении тренировки
    enum TrainingError: Error, LocalizedError, Equatable {
        case executionTypeNotSelected
        case trainingsListEmpty

        var errorDescription: String? {
            switch self {
            case .executionTypeNotSelected:
                String(localized: .errorTrainingExecutionTypeNotSelected)
            case .trainingsListEmpty:
                String(localized: .errorTrainingTrainingsListEmpty)
            }
        }
    }
}

private extension WorkoutPreviewViewModel {
    /// `Snapshot` для отслеживания изменений
    struct DataSnapshot: Equatable {
        let selectedExecutionType: ExerciseExecutionType?
        let trainings: [WorkoutPreviewTraining]
        let count: Int?
        let plannedCount: Int?
        let restTime: Int
        let comment: String?
    }
}
