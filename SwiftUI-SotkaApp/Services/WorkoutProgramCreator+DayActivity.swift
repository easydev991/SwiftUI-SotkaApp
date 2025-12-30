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
            DayActivityTraining(
                from: training,
                dayActivity: activity
            )
        }
        activity.trainings = activityTrainings

        return activity
    }
}
