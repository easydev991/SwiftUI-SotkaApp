#if DEBUG
import Foundation

extension [WorkoutPreviewTraining] {
    /// Превью для тренировки типа "Круги"
    static var previewCycles: [WorkoutPreviewTraining] {
        [
            WorkoutPreviewTraining(
                count: 5,
                typeId: ExerciseType.pullups.rawValue,
                sortOrder: 0
            ),
            WorkoutPreviewTraining(
                count: 10,
                typeId: ExerciseType.pushups.rawValue,
                sortOrder: 1
            ),
            WorkoutPreviewTraining(
                count: 15,
                typeId: ExerciseType.squats.rawValue,
                sortOrder: 2
            ),
            WorkoutPreviewTraining(
                count: 8,
                typeId: ExerciseType.austrPullups.rawValue,
                sortOrder: 3
            )
        ]
    }

    /// Превью для тренировки типа "Подходы"
    static var previewSets: [WorkoutPreviewTraining] {
        [
            WorkoutPreviewTraining(
                count: 5,
                typeId: ExerciseType.pullups.rawValue,
                sortOrder: 0
            ),
            WorkoutPreviewTraining(
                count: 10,
                typeId: ExerciseType.pushups.rawValue,
                sortOrder: 1
            ),
            WorkoutPreviewTraining(
                count: 15,
                typeId: ExerciseType.squats.rawValue,
                sortOrder: 2
            )
        ]
    }

    /// Превью для тренировки типа "Турбо"
    static var previewTurbo: [WorkoutPreviewTraining] {
        [
            WorkoutPreviewTraining(
                count: 20,
                typeId: ExerciseType.turbo93_1.rawValue,
                sortOrder: 0
            ),
            WorkoutPreviewTraining(
                count: 15,
                typeId: ExerciseType.turbo94Pushups.rawValue,
                sortOrder: 1
            ),
            WorkoutPreviewTraining(
                count: 25,
                typeId: ExerciseType.turbo94Squats.rawValue,
                sortOrder: 2
            )
        ]
    }
}
#endif
