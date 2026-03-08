import Foundation

extension WorkoutProgramCreator {
    /// Инициализатор из DayActivity (для загрузки существующей активности)
    init(from dayActivity: DayActivity) {
        self.day = dayActivity.day
        let executionType = dayActivity.executeType ?? Self.defaultExecutionType(for: dayActivity.day)
        self.executionType = executionType
        self.count = dayActivity.count
        self.plannedCount = dayActivity.plannedCount ?? Self.calculatePlannedCircles(for: dayActivity.day, executionType: executionType)
        self.trainings = dayActivity.trainings.map(\.workoutPreviewTraining)
        self.comment = dayActivity.comment
    }

    var dayActivity: DayActivity {
        let activity = DayActivity(
            day: day,
            activityTypeRaw: DayActivityType.workout.rawValue,
            count: count,
            plannedCount: plannedCount,
            executeTypeRaw: executionType.rawValue,
            createDate: Date.now,
            modifyDate: Date.now
        )
        activity.isSynced = false
        activity.shouldDelete = false
        activity.comment = comment

        let activityTrainings = trainings.enumerated().map { _, training in
            DayActivityTraining(from: training, dayActivity: nil)
        }
        activity.trainings = activityTrainings

        return activity
    }

    /// Создает новый WorkoutProgramCreator с данными из предыдущей тренировки
    /// - Parameter previousActivity: Предыдущая пройденная тренировка (non-turbo)
    /// - Returns: Новый экземпляр с подставленными данными: plannedCount, executionType, повторы упражнений
    func withData(from previousActivity: DayActivity) -> WorkoutProgramCreator {
        // Подставить plannedCount (приоритет count над plannedCount)
        let newPlannedCount = previousActivity.count ?? previousActivity.plannedCount ?? plannedCount

        // Подставить executionType из предыдущей тренировки (если есть)
        let newExecutionType = previousActivity.executeType ?? executionType

        // Подставить повторы для каждого упражнения (сопоставление по типу и порядку появления)
        let previousTrainings = previousActivity.trainings.workoutPreviewTrainingsSorted
        let newTrainings = Self.applyCountsFrom(previousTrainings: previousTrainings, to: trainings)

        return Self(
            day: day,
            executionType: newExecutionType,
            count: count,
            plannedCount: newPlannedCount,
            trainings: newTrainings,
            comment: comment
        )
    }
}
