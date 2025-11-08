import Foundation
@testable import SwiftUI_SotkaApp
import Testing

extension AllWorkoutPreviewViewModelTests {
    // MARK: - updateTrainings Tests

    @Test("Должен обновлять список упражнений")
    @MainActor
    func updatesTrainingsList() {
        let viewModel = WorkoutPreviewViewModel()
        viewModel.trainings = [
            WorkoutPreviewTraining(count: 5, typeId: ExerciseType.pullups.rawValue, sortOrder: 0)
        ]

        let newTrainings = [
            WorkoutPreviewTraining(count: 10, typeId: ExerciseType.pushups.rawValue, sortOrder: nil),
            WorkoutPreviewTraining(count: 15, typeId: ExerciseType.squats.rawValue, sortOrder: nil)
        ]

        viewModel.updateTrainings(newTrainings)

        #expect(viewModel.trainings.count == 2)
    }

    @Test("Должен пересчитывать sortOrder на основе порядка в массиве")
    @MainActor
    func recalculatesSortOrderBasedOnArrayOrder() throws {
        let viewModel = WorkoutPreviewViewModel()

        let newTrainings = [
            WorkoutPreviewTraining(count: 10, typeId: ExerciseType.pushups.rawValue, sortOrder: 99),
            WorkoutPreviewTraining(count: 15, typeId: ExerciseType.squats.rawValue, sortOrder: 50),
            WorkoutPreviewTraining(count: 20, typeId: ExerciseType.lunges.rawValue, sortOrder: 0)
        ]

        viewModel.updateTrainings(newTrainings)

        let firstSortOrder = try #require(viewModel.trainings[0].sortOrder)
        let secondSortOrder = try #require(viewModel.trainings[1].sortOrder)
        let thirdSortOrder = try #require(viewModel.trainings[2].sortOrder)

        #expect(firstSortOrder == 0)
        #expect(secondSortOrder == 1)
        #expect(thirdSortOrder == 2)
    }

    @Test("Должен сохранять id упражнений при обновлении")
    @MainActor
    func preservesExerciseIdsWhenUpdating() {
        let viewModel = WorkoutPreviewViewModel()

        let training1 = WorkoutPreviewTraining(count: 10, typeId: ExerciseType.pushups.rawValue)
        let training2 = WorkoutPreviewTraining(count: 15, typeId: ExerciseType.squats.rawValue)
        let newTrainings = [training1, training2]

        viewModel.updateTrainings(newTrainings)

        #expect(viewModel.trainings[0].id == training1.id)
        #expect(viewModel.trainings[1].id == training2.id)
    }

    @Test("Должен сохранять count упражнений при обновлении")
    @MainActor
    func preservesExerciseCountsWhenUpdating() throws {
        let viewModel = WorkoutPreviewViewModel()

        let newTrainings = [
            WorkoutPreviewTraining(count: 10, typeId: ExerciseType.pushups.rawValue),
            WorkoutPreviewTraining(count: 15, typeId: ExerciseType.squats.rawValue)
        ]

        viewModel.updateTrainings(newTrainings)

        let firstCount = try #require(viewModel.trainings[0].count)
        let secondCount = try #require(viewModel.trainings[1].count)

        #expect(firstCount == 10)
        #expect(secondCount == 15)
    }

    @Test("Должен обрабатывать пустой список упражнений")
    @MainActor
    func handlesEmptyTrainingsList() {
        let viewModel = WorkoutPreviewViewModel()
        viewModel.trainings = [
            WorkoutPreviewTraining(count: 5, typeId: ExerciseType.pullups.rawValue, sortOrder: 0)
        ]

        viewModel.updateTrainings([])

        #expect(viewModel.trainings.isEmpty)
    }
}
