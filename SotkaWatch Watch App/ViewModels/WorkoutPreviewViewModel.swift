import Foundation
import Observation
import OSLog

/// ViewModel для экрана превью тренировки на Apple Watch
@MainActor
@Observable
final class WorkoutPreviewViewModel {
    @ObservationIgnored private let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "SotkaWatch",
        category: String(describing: WorkoutPreviewViewModel.self)
    )

    @ObservationIgnored private let connectivityService: any WatchConnectivityServiceProtocol
    @ObservationIgnored private let appGroupHelper: any WatchAppGroupHelperProtocol

    // MARK: - State

    @ObservationIgnored private var originalSnapshot: DataSnapshot?
    private(set) var isLoading = false
    var error: TrainingError?
    private(set) var wasOriginallyPassed = false
    var dayNumber = 1
    var selectedExecutionType: ExerciseExecutionType?
    var availableExecutionTypes: [ExerciseExecutionType] = []
    var trainings: [WorkoutPreviewTraining] = []
    var count: Int?
    var plannedCount: Int?
    var restTime = Constants.defaultRestTime
    var comment: String?
    var isWorkoutCompleted = false
    var workoutDuration: Int?

    /// Определяет, должен ли степпер для `plannedCount` быть отключен
    var isPlannedCountDisabled: Bool {
        selectedExecutionType == .turbo
    }

    /// Отображаемое количество кругов/подходов
    var displayedCount: Int? {
        count ?? plannedCount
    }

    /// Выбранный тип выполнения для Picker (неопциональное значение)
    ///
    /// Если selectedExecutionType == nil, возвращает первый доступный тип или .cycles по умолчанию
    var selectedExecutionTypeForPicker: ExerciseExecutionType {
        selectedExecutionType ?? availableExecutionTypes.first ?? .cycles
    }

    /// Определяет, нужно ли показывать кнопку редактирования упражнений
    var shouldShowEditButton: Bool {
        guard let executionType = selectedExecutionType else { return false }
        return executionType == .cycles || executionType == .sets
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

    // MARK: - Initialization

    /// Инициализатор
    /// - Parameters:
    ///   - connectivityService: Сервис связи с iPhone для получения данных тренировки
    ///   - appGroupHelper: Хелпер для чтения данных из App Group UserDefaults (по умолчанию создается новый экземпляр)
    init(
        connectivityService: any WatchConnectivityServiceProtocol,
        appGroupHelper: (any WatchAppGroupHelperProtocol)? = nil
    ) {
        self.connectivityService = connectivityService
        self.appGroupHelper = appGroupHelper ?? WatchAppGroupHelper()
    }

    // MARK: - Methods

    /// Загрузка данных тренировки и инициализация ViewModel
    /// - Parameter day: Номер дня программы
    func loadData(day: Int) async {
        isLoading = true
        error = nil

        defer {
            isLoading = false
        }

        do {
            let response = try await connectivityService.requestWorkoutData(day: day)
            let restTime = appGroupHelper.restTime
            updateData(workoutDataResponse: response, restTime: restTime)
            logger.info("Данные тренировки для дня \(day) загружены успешно")
        } catch {
            logger.error("Ошибка загрузки данных тренировки для дня \(day): \(error.localizedDescription)")
            // Для сетевых ошибок не устанавливаем error, так как TrainingError только для валидации
            // Можно добавить отдельный тип ошибки для сетевых ошибок если нужно
            self.error = nil
        }
    }

    /// Внутренний метод инициализации/обновления данных ViewModel
    /// - Parameters:
    ///   - workoutDataResponse: Ответ от connectivityService с данными тренировки
    ///   - restTime: Время отдыха между подходами/кругами (в секундах)
    func updateData(workoutDataResponse: WorkoutDataResponse, restTime: Int) {
        let workoutData = workoutDataResponse.workoutData
        dayNumber = workoutData.day
        selectedExecutionType = workoutData.exerciseExecutionType
        let creator = WorkoutProgramCreator(day: dayNumber)
        availableExecutionTypes = creator.availableExecutionTypes
        trainings = workoutData.trainings
        count = workoutDataResponse.executionCount
        plannedCount = workoutData.plannedCount
        self.restTime = restTime
        comment = workoutDataResponse.comment
        wasOriginallyPassed = count != nil

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
    func updateExecutionType(with newType: ExerciseExecutionType) {
        // Создать WorkoutProgramCreator из текущих данных ViewModel
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

    /// Обновляет количество повторений для конкретной тренировки или `plannedCount`
    /// - Parameters:
    ///   - id: Идентификатор тренировки или "plannedCount" для обновления `plannedCount`
    ///   - action: Действие (increment или decrement)
    func updatePlannedCount(id: String, action: TrainingRowAction) {
        if id == "plannedCount" {
            let currentCount = plannedCount ?? 0
            let newCount: Int = switch action {
            case .increment:
                currentCount + 1
            case .decrement:
                max(0, currentCount - 1)
            }
            plannedCount = newCount
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

    /// Обновляет плановое количество кругов/подходов
    /// - Parameter newValue: Новое значение планового количества
    func updatePlannedCount(for newValue: Int) {
        plannedCount = newValue
    }

    /// Обновляет количество повторений для конкретной тренировки
    ///
    /// Если новое значение равно 0, удаляет упражнение из списка (отличие для первой итерации часов)
    /// - Parameters:
    ///   - trainingId: Идентификатор тренировки
    ///   - newValue: Новое значение количества повторений
    func updateTrainingCount(for trainingId: String, newValue: Int) {
        let currentTraining = trainings.first { $0.id == trainingId }
        let currentCount = currentTraining?.count ?? 0

        guard newValue != currentCount else {
            return
        }

        if newValue == 0 {
            // Удаляем упражнение из списка (отличие для первой итерации часов)
            trainings.removeAll { $0.id == trainingId }
            logger.info("Упражнение \(trainingId) удалено из списка (count = 0)")
        } else {
            // Обновляем count для упражнения
            trainings = trainings.map { existingTraining in
                guard existingTraining.id == trainingId else { return existingTraining }
                return existingTraining.withCount(newValue)
            }
        }
    }

    /// Обновляет время отдыха между подходами/кругами
    /// - Parameter newValue: Новое значение времени отдыха в секундах
    func updateRestTime(_ newValue: Int) {
        restTime = newValue
    }

    /// Обновляет список упражнений тренировки
    ///
    /// Пересчитывает `sortOrder` на основе порядка в массиве
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

    /// Получить тип выполнения для отображения
    ///
    /// Для турбо-режима использует `getEffectiveExecutionType` для определения правильного типа
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

    /// Определяет, нужно ли показывать пикер типа выполнения
    /// - Parameters:
    ///   - day: Номер дня для проверки
    ///   - isPassed: Флаг, был ли день пройден
    /// - Returns: true если нужно показывать пикер, false иначе
    func shouldShowExecutionTypePicker(day: Int, isPassed: Bool) -> Bool {
        // Проверяем, что данные загружены (dayNumber установлен и trainings не пустой)
        guard dayNumber == day, !trainings.isEmpty else { return false }

        // Показываем только для не пройденных дней
        guard !isPassed else { return false }

        // Показываем только если доступно больше одного типа
        return availableExecutionTypes.count > 1
    }

    /// Создание результата тренировки из текущих значений
    /// - Returns: WorkoutResult для отправки на iPhone
    func buildWorkoutResult() -> WorkoutResult {
        let resultCount = count ?? plannedCount ?? 0
        return WorkoutResult(count: resultCount, duration: workoutDuration)
    }

    /// Получение обновленных данных тренировки
    /// - Returns: WorkoutData для передачи в WorkoutView
    func buildWorkoutData() -> WorkoutData {
        guard let executionType = selectedExecutionType else {
            // Если executionType не установлен, возвращаем дефолтные данные
            let creator = WorkoutProgramCreator(day: dayNumber)
            return WorkoutData(
                day: dayNumber,
                executionType: creator.executionType.rawValue,
                trainings: creator.trainings,
                plannedCount: creator.plannedCount
            )
        }

        return WorkoutData(
            day: dayNumber,
            executionType: executionType.rawValue,
            trainings: trainings,
            plannedCount: plannedCount
        )
    }

    /// Сохранение тренировки через WatchConnectivityService
    func saveTrainingAsPassed() async {
        error = nil

        // Проверить валидность данных
        guard selectedExecutionType != nil else {
            error = TrainingError.executionTypeNotSelected
            logger.error("Ошибка сохранения: тип выполнения не выбран")
            return
        }

        guard !trainings.isEmpty else {
            error = TrainingError.trainingsListEmpty
            logger.error("Ошибка сохранения: список упражнений пуст")
            return
        }

        // Установить count = plannedCount, если count == nil
        if count == nil, let plannedCount {
            count = plannedCount
        }

        // Построить результат тренировки
        let result = buildWorkoutResult()

        // Отправить через connectivityService
        guard let executionType = selectedExecutionType else {
            error = TrainingError.executionTypeNotSelected
            logger.error("Ошибка сохранения: тип выполнения не выбран")
            return
        }

        do {
            try await connectivityService.sendWorkoutResult(
                day: dayNumber,
                result: result,
                executionType: executionType
            )

            let dayNumber = dayNumber
            logger.info("Тренировка для дня \(dayNumber) сохранена")
        } catch {
            logger.error("Ошибка отправки результата тренировки на iPhone: \(error.localizedDescription)")
        }
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
