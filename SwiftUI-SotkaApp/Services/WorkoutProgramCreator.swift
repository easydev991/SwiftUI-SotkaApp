import Foundation

/// Модель для работы с данными тренировки
struct WorkoutProgramCreator {
    // MARK: Основные данные для ViewModel
    let day: Int
    let executionType: ExerciseExecutionType
    let count: Int?
    let plannedCount: Int?
    let trainings: [WorkoutPreviewTraining]
    let comment: String?

    var availableExecutionTypes: [ExerciseExecutionType] {
        Self.availableExecutionTypes(for: day)
    }

    var defaultExecutionType: ExerciseExecutionType {
        Self.defaultExecutionType(for: day)
    }

    /// Инициализатор для нового дня (создает данные с дефолтными значениями)
    init(day: Int, executionType: ExerciseExecutionType? = nil) {
        self.day = day
        let defaultType = executionType ?? Self.defaultExecutionType(for: day)
        self.executionType = defaultType
        self.count = nil
        self.plannedCount = Self.calculatePlannedCircles(for: day, executionType: defaultType)
        self.trainings = Self.generateExercises(for: day, executionType: defaultType)
        self.comment = nil
    }

    /// Инициализатор с полными данными (для buildDayActivity)
    ///
    /// - Если executionType == nil, используется дефолтный тип для дня
    /// - Если plannedCount == nil, вычисляется автоматически на основе day и executionType
    init(
        day: Int,
        executionType: ExerciseExecutionType? = nil,
        count: Int?,
        plannedCount: Int?,
        trainings: [WorkoutPreviewTraining],
        comment: String?
    ) {
        self.day = day
        let defaultType = executionType ?? Self.defaultExecutionType(for: day)
        self.executionType = defaultType
        self.count = count
        self.plannedCount = plannedCount ?? Self.calculatePlannedCircles(for: day, executionType: defaultType)
        self.trainings = trainings
        self.comment = comment
    }

    /// Метод для обновления упражнений с сохранением остальных данных
    /// - Parameter exercises: Новый список упражнений
    /// - Returns: Новый экземпляр WorkoutProgramCreator с обновленными упражнениями
    func withCustomExercises(_ exercises: [WorkoutPreviewTraining]) -> WorkoutProgramCreator {
        Self(
            day: day,
            executionType: executionType,
            count: count,
            plannedCount: plannedCount,
            trainings: exercises,
            comment: comment
        )
    }

    /// Метод для обновления планового количества повторений
    /// - Parameter newPlannedCount: Новое плановое количество
    /// - Returns: Новый экземпляр WorkoutProgramCreator с обновленным plannedCount
    func withPlannedCount(_ newPlannedCount: Int) -> WorkoutProgramCreator {
        Self(
            day: day,
            executionType: executionType,
            count: count,
            plannedCount: newPlannedCount,
            trainings: trainings,
            comment: comment
        )
    }

    /// Метод для обновления типа выполнения
    /// Сохраняет пользовательские изменения: plannedCount и count упражнений
    func withExecutionType(_ newType: ExerciseExecutionType) -> WorkoutProgramCreator {
        let defaultPlannedCountForNewType = Self.calculatePlannedCircles(for: day, executionType: newType)
        let defaultPlannedCountForCurrentType = Self.calculatePlannedCircles(for: day, executionType: executionType)

        let preservedPlannedCount: Int? = if newType == .turbo {
            defaultPlannedCountForNewType
        } else if let currentPlannedCount = plannedCount, currentPlannedCount != defaultPlannedCountForCurrentType {
            currentPlannedCount
        } else {
            defaultPlannedCountForNewType
        }

        let defaultTrainingsForCurrentType = Self.generateExercises(for: day, executionType: executionType)
        let newTrainings = Self.generateExercises(for: day, executionType: newType)
        let preservedTrainings = Self.preserveTrainingCounts(
            currentTrainings: trainings,
            defaultTrainingsForCurrentType: defaultTrainingsForCurrentType,
            newTrainings: newTrainings
        )
        let extraTrainings = Self.trainingsNotInProgram(
            currentTrainings: trainings,
            programTemplate: defaultTrainingsForCurrentType
        )
        // Сохраняем исходный sortOrder у доп. упражнений — порядок не должен зависеть от типа (стандартное/кастомное)
        let allTrainings = (preservedTrainings + extraTrainings).sorted

        return Self(
            day: day,
            executionType: newType,
            count: count,
            plannedCount: preservedPlannedCount,
            trainings: allTrainings,
            comment: comment
        )
    }

    // MARK: - Приватные статические методы для генерации (используются внутри структуры)
    private static func generateExercises(for day: Int, executionType: ExerciseExecutionType) -> [WorkoutPreviewTraining] {
        if executionType == .turbo {
            return generateTurboExercises(for: day)
        }

        var exercises: [WorkoutPreviewTraining] = [
            WorkoutPreviewTraining(count: 1, typeId: ExerciseType.pullups.rawValue, sortOrder: 0),
            WorkoutPreviewTraining(count: 2, typeId: ExerciseType.squats.rawValue, sortOrder: 1),
            WorkoutPreviewTraining(count: 2, typeId: ExerciseType.pushups.rawValue, sortOrder: 2)
        ]

        if day < 29 {
            exercises.append(WorkoutPreviewTraining(count: 2, typeId: ExerciseType.squats.rawValue, sortOrder: 3))
        } else {
            exercises.append(WorkoutPreviewTraining(count: 2, typeId: ExerciseType.lunges.rawValue, sortOrder: 3))
        }

        return exercises
    }

    private static func generateTurboExercises(for day: Int) -> [WorkoutPreviewTraining] {
        let freeStyle = (day == 93 || day == 95 || day == 97)
        if freeStyle {
            return generateFreeStyleTurboExercises(for: day)
        }

        switch day {
        case 92:
            return [
                WorkoutPreviewTraining(count: 4, typeId: ExerciseType.pushups.rawValue, sortOrder: 0),
                WorkoutPreviewTraining(count: 2, typeId: ExerciseType.lunges.rawValue, sortOrder: 1),
                WorkoutPreviewTraining(count: 1, typeId: ExerciseType.pullups.rawValue, sortOrder: 2)
            ]
        case 94:
            return [
                WorkoutPreviewTraining(count: 5, typeId: ExerciseType.turbo94Pushups.rawValue, sortOrder: 0),
                WorkoutPreviewTraining(count: 5, typeId: ExerciseType.turbo94Squats.rawValue, sortOrder: 1),
                WorkoutPreviewTraining(count: 5, typeId: ExerciseType.turbo94Pullups.rawValue, sortOrder: 2)
            ]
        case 96:
            return [
                WorkoutPreviewTraining(count: 5, typeId: ExerciseType.turbo96Pushups.rawValue, sortOrder: 0),
                WorkoutPreviewTraining(count: 10, typeId: ExerciseType.turbo96Squats.rawValue, sortOrder: 1),
                WorkoutPreviewTraining(count: 2, typeId: ExerciseType.turbo96Pullups.rawValue, sortOrder: 2)
            ]
        case 98:
            return [
                WorkoutPreviewTraining(count: 10, typeId: ExerciseType.turbo98Pullups.rawValue, sortOrder: 0),
                WorkoutPreviewTraining(count: 20, typeId: ExerciseType.turbo98Pushups.rawValue, sortOrder: 1),
                WorkoutPreviewTraining(count: 30, typeId: ExerciseType.turbo98Squats.rawValue, sortOrder: 2)
            ]
        default:
            return []
        }
    }

    private static func generateFreeStyleTurboExercises(for day: Int) -> [WorkoutPreviewTraining] {
        switch day {
        case 93:
            [
                WorkoutPreviewTraining(count: 3, typeId: ExerciseType.turbo93_1.rawValue, sortOrder: 0),
                WorkoutPreviewTraining(count: 3, typeId: ExerciseType.turbo93_2.rawValue, sortOrder: 1),
                WorkoutPreviewTraining(count: 2, typeId: ExerciseType.turbo93_3.rawValue, sortOrder: 2),
                WorkoutPreviewTraining(count: 3, typeId: ExerciseType.turbo93_4.rawValue, sortOrder: 3),
                WorkoutPreviewTraining(count: 10, typeId: ExerciseType.turbo93_5.rawValue, sortOrder: 4)
            ]
        case 95:
            [
                WorkoutPreviewTraining(count: 3, typeId: ExerciseType.turbo95_1.rawValue, sortOrder: 0),
                WorkoutPreviewTraining(count: 2, typeId: ExerciseType.turbo95_2.rawValue, sortOrder: 1),
                WorkoutPreviewTraining(count: 1, typeId: ExerciseType.turbo95_3.rawValue, sortOrder: 2),
                WorkoutPreviewTraining(count: 2, typeId: ExerciseType.turbo95_4.rawValue, sortOrder: 3),
                WorkoutPreviewTraining(count: 3, typeId: ExerciseType.turbo95_5.rawValue, sortOrder: 4)
            ]
        case 97:
            [
                WorkoutPreviewTraining(count: 5, typeId: ExerciseType.turbo97PushupsHigh.rawValue, sortOrder: 0),
                WorkoutPreviewTraining(count: 5, typeId: ExerciseType.pushups.rawValue, sortOrder: 1),
                WorkoutPreviewTraining(count: 5, typeId: ExerciseType.turbo97PushupsHighArms.rawValue, sortOrder: 2),
                WorkoutPreviewTraining(count: 5, typeId: ExerciseType.pushups.rawValue, sortOrder: 3),
                WorkoutPreviewTraining(count: 5, typeId: ExerciseType.turbo97PushupsHigh.rawValue, sortOrder: 4)
            ]
        default:
            []
        }
    }

    /// Определяет фактический тип выполнения упражнений
    /// - Parameters:
    ///   - day: Номер дня
    ///   - executionType: Выбранный тип выполнения упражнений
    /// - Returns: Либо подходы, либо круги, в зависимости от вводных данных
    static func getEffectiveExecutionType(for day: Int, executionType: ExerciseExecutionType) -> ExerciseExecutionType {
        if executionType == .turbo {
            let setsDays = [93, 95, 98]
            if setsDays.contains(day) {
                return .sets
            }
            return .cycles
        }
        return executionType
    }

    /// Проверяет, является ли комбинация дня и типа выполнения турбо с подходами
    /// - Parameters:
    ///   - day: Номер дня
    ///   - executionType: Тип выполнения упражнений
    /// - Returns: `true`, если это турбо режим с подходами (дни 93, 95, 98)
    static func isTurboWithSets(day: Int, executionType: ExerciseExecutionType) -> Bool {
        executionType == .turbo && getEffectiveExecutionType(for: day, executionType: executionType) == .sets
    }

    static func calculatePlannedCircles(for day: Int, executionType: ExerciseExecutionType) -> Int {
        let effectiveType = getEffectiveExecutionType(for: day, executionType: executionType)

        if effectiveType == .sets {
            if executionType == .turbo {
                switch day {
                case 93, 95: return 5
                case 98: return 3
                default: return 6
                }
            }
            return 6
        }

        if executionType == .turbo, effectiveType == .cycles {
            return calculateTurboCircles(for: day)
        }

        var result = 4
        for i in 1 ... day {
            if i == 22 || i == 43 {
                result += 1
            }
        }
        return result
    }

    static func defaultExecutionType(for day: Int) -> ExerciseExecutionType {
        (92 ... 98).contains(day)
            ? .turbo
            : .cycles
    }

    static func preserveTrainingCounts(
        currentTrainings: [WorkoutPreviewTraining],
        defaultTrainingsForCurrentType: [WorkoutPreviewTraining],
        newTrainings: [WorkoutPreviewTraining]
    ) -> [WorkoutPreviewTraining] {
        let existingTrainingsByKey = makeTrainingsByMatchKey(currentTrainings)
        let defaultTrainingsByKey = makeTrainingsByMatchKey(defaultTrainingsForCurrentType)
        var occurrenceByKey: [TrainingMatchKey: Int] = [:]

        return newTrainings.map { newTraining in
            let matchKey = makeTrainingMatchKey(for: newTraining)
            let occurrence = occurrenceByKey[matchKey, default: 0]
            occurrenceByKey[matchKey] = occurrence + 1
            let matchingTraining = training(
                at: occurrence,
                for: matchKey,
                in: existingTrainingsByKey
            )

            let resultWithCount: WorkoutPreviewTraining
            if let matchingTraining, let preservedCount = matchingTraining.count {
                let defaultTrainingForCurrentType = training(
                    at: occurrence,
                    for: matchKey,
                    in: defaultTrainingsByKey
                )

                // Если сохраненное значение совпадает с дефолтным для текущего режима,
                // значит это дефолтное значение, и при переключении используем дефолтное для нового режима
                if let defaultCountForCurrentType = defaultTrainingForCurrentType?.count,
                   preservedCount == defaultCountForCurrentType {
                    resultWithCount = newTraining
                } else {
                    // Если сохраненное значение отличается от дефолтного для текущего режима,
                    // значит пользователь изменил его вручную, сохраняем пользовательское значение
                    resultWithCount = newTraining.withCount(preservedCount)
                }
            } else {
                resultWithCount = newTraining
            }

            // Сохраняем sortOrder из текущего списка, чтобы порядок упражнений не сбрасывался
            if let matchingTraining, let preservedSortOrder = matchingTraining.sortOrder {
                return resultWithCount.withSortOrder(preservedSortOrder)
            }
            return resultWithCount
        }
    }

    /// Применяет count из предыдущих тренировок к новым, сопоставляя по типу и порядку появления
    static func applyCountsFrom(
        previousTrainings: [WorkoutPreviewTraining],
        to newTrainings: [WorkoutPreviewTraining]
    ) -> [WorkoutPreviewTraining] {
        let previousByKey = makeTrainingsByMatchKey(previousTrainings)
        var occurrenceByKey: [TrainingMatchKey: Int] = [:]

        return newTrainings.map { newTraining in
            let matchKey = makeTrainingMatchKey(for: newTraining)
            let occurrence = occurrenceByKey[matchKey, default: 0]
            occurrenceByKey[matchKey] = occurrence + 1
            let previousTraining = training(at: occurrence, for: matchKey, in: previousByKey)
            if let previousTraining, let previousCount = previousTraining.count {
                return newTraining.withCount(previousCount)
            }
            return newTraining
        }
    }
}

private extension WorkoutProgramCreator {
    typealias TrainingMatchKey = String

    static func calculateTurboCircles(for day: Int) -> Int {
        switch day {
        case 92: 40
        case 94, 96, 97: 5
        default: 5
        }
    }

    static func availableExecutionTypes(for day: Int) -> [ExerciseExecutionType] {
        (92 ... 98).contains(day)
            ? [.cycles, .sets, .turbo]
            : [.cycles, .sets]
    }

    static func makeTrainingsByMatchKey(
        _ trainings: [WorkoutPreviewTraining]
    ) -> [TrainingMatchKey: [WorkoutPreviewTraining]] {
        Dictionary(grouping: trainings.sorted, by: makeTrainingMatchKey(for:))
    }

    static func training(
        at occurrence: Int,
        for key: TrainingMatchKey,
        in trainingsByKey: [TrainingMatchKey: [WorkoutPreviewTraining]]
    ) -> WorkoutPreviewTraining? {
        guard let trainings = trainingsByKey[key], trainings.indices.contains(occurrence) else {
            return nil
        }

        return trainings[occurrence]
    }

    nonisolated static func makeTrainingMatchKey(for training: WorkoutPreviewTraining) -> TrainingMatchKey {
        if let customTypeId = training.customTypeId {
            return "custom:\(customTypeId)"
        }

        if let typeId = training.typeId {
            return "type:\(typeId)"
        }

        return "id:\(training.id)"
    }

    /// Тренировки из currentTrainings, которые не входят в шаблон программы (добавленные в редакторе)
    static func trainingsNotInProgram(
        currentTrainings: [WorkoutPreviewTraining],
        programTemplate: [WorkoutPreviewTraining]
    ) -> [WorkoutPreviewTraining] {
        let currentByKey = makeTrainingsByMatchKey(currentTrainings)
        var occurrenceByKey: [TrainingMatchKey: Int] = [:]
        var usedIds: Set<String> = []
        for templateTraining in programTemplate.sorted {
            let key = makeTrainingMatchKey(for: templateTraining)
            let occurrence = occurrenceByKey[key, default: 0]
            occurrenceByKey[key] = occurrence + 1
            if let t = training(at: occurrence, for: key, in: currentByKey) {
                usedIds.insert(t.id)
            }
        }
        return currentTrainings.filter { !usedIds.contains($0.id) }
    }
}
