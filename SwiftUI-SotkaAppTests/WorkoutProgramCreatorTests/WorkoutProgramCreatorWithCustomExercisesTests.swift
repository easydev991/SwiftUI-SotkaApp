import Foundation
@testable import SwiftUI_SotkaApp
import Testing

extension AllWorkoutProgramCreatorTests {
    // MARK: - withCustomExercises Tests

    @Test("Должен обновлять упражнения с сохранением остальных данных")
    func updatesExercisesWhilePreservingOtherData() throws {
        let creator = WorkoutProgramCreator(
            day: 5,
            executionType: .cycles,
            count: 10,
            plannedCount: 8,
            trainings: [
                WorkoutPreviewTraining(count: 5, typeId: ExerciseType.pullups.rawValue, sortOrder: 0)
            ],
            comment: "Test comment"
        )

        let newExercises = [
            WorkoutPreviewTraining(count: 10, typeId: ExerciseType.pushups.rawValue, sortOrder: 0),
            WorkoutPreviewTraining(count: 15, typeId: ExerciseType.squats.rawValue, sortOrder: 1)
        ]

        let updatedCreator = creator.withCustomExercises(newExercises)

        #expect(updatedCreator.day == 5)
        #expect(updatedCreator.executionType == .cycles)
        let count = try #require(updatedCreator.count)
        #expect(count == 10)
        let plannedCount = try #require(updatedCreator.plannedCount)
        #expect(plannedCount == 8)
        let comment = try #require(updatedCreator.comment)
        #expect(comment == "Test comment")
        #expect(updatedCreator.trainings.count == 2)
    }

    @Test("Должен сохранять day при обновлении упражнений")
    func preservesDayWhenUpdatingExercises() {
        let creator = WorkoutProgramCreator(day: 50, executionType: .sets)

        let newExercises = [
            WorkoutPreviewTraining(count: 10, typeId: ExerciseType.pushups.rawValue, sortOrder: 0)
        ]

        let updatedCreator = creator.withCustomExercises(newExercises)

        #expect(updatedCreator.day == 50)
    }

    @Test("Должен сохранять executionType при обновлении упражнений")
    func preservesExecutionTypeWhenUpdatingExercises() {
        let creator = WorkoutProgramCreator(day: 50, executionType: .sets)

        let newExercises = [
            WorkoutPreviewTraining(count: 10, typeId: ExerciseType.pushups.rawValue, sortOrder: 0)
        ]

        let updatedCreator = creator.withCustomExercises(newExercises)

        #expect(updatedCreator.executionType == .sets)
    }

    @Test("Должен сохранять count при обновлении упражнений")
    func preservesCountWhenUpdatingExercises() throws {
        let creator = WorkoutProgramCreator(
            day: 5,
            executionType: .cycles,
            count: 15,
            plannedCount: nil,
            trainings: [],
            comment: nil
        )

        let newExercises = [
            WorkoutPreviewTraining(count: 10, typeId: ExerciseType.pushups.rawValue, sortOrder: 0)
        ]

        let updatedCreator = creator.withCustomExercises(newExercises)

        let count = try #require(updatedCreator.count)
        #expect(count == 15)
    }

    @Test("Должен сохранять plannedCount при обновлении упражнений")
    func preservesPlannedCountWhenUpdatingExercises() throws {
        let creator = WorkoutProgramCreator(
            day: 5,
            executionType: .cycles,
            count: nil,
            plannedCount: 12,
            trainings: [],
            comment: nil
        )

        let newExercises = [
            WorkoutPreviewTraining(count: 10, typeId: ExerciseType.pushups.rawValue, sortOrder: 0)
        ]

        let updatedCreator = creator.withCustomExercises(newExercises)

        let plannedCount = try #require(updatedCreator.plannedCount)
        #expect(plannedCount == 12)
    }

    @Test("Должен сохранять comment при обновлении упражнений")
    func preservesCommentWhenUpdatingExercises() throws {
        let creator = WorkoutProgramCreator(
            day: 5,
            executionType: .cycles,
            count: nil,
            plannedCount: nil,
            trainings: [],
            comment: "Original comment"
        )

        let newExercises = [
            WorkoutPreviewTraining(count: 10, typeId: ExerciseType.pushups.rawValue, sortOrder: 0)
        ]

        let updatedCreator = creator.withCustomExercises(newExercises)

        let comment = try #require(updatedCreator.comment)
        #expect(comment == "Original comment")
    }

    @Test("Должен обновлять список упражнений")
    func updatesTrainingsList() {
        let creator = WorkoutProgramCreator(day: 1, executionType: .cycles)

        let newExercises = [
            WorkoutPreviewTraining(count: 10, typeId: ExerciseType.pushups.rawValue, sortOrder: 0),
            WorkoutPreviewTraining(count: 15, typeId: ExerciseType.squats.rawValue, sortOrder: 1),
            WorkoutPreviewTraining(count: 20, typeId: ExerciseType.lunges.rawValue, sortOrder: 2)
        ]

        let updatedCreator = creator.withCustomExercises(newExercises)

        #expect(updatedCreator.trainings.count == 3)
        #expect(updatedCreator.trainings[0].count == 10)
        #expect(updatedCreator.trainings[1].count == 15)
        #expect(updatedCreator.trainings[2].count == 20)
    }

    @Test("Должен обрабатывать пустой список упражнений")
    func handlesEmptyExercisesList() {
        let creator = WorkoutProgramCreator(day: 1, executionType: .cycles)

        let updatedCreator = creator.withCustomExercises([])

        #expect(updatedCreator.trainings.isEmpty)
    }
}
