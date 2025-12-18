import Foundation
@testable import SotkaWatch_Watch_App
import Testing

extension WorkoutPreviewViewModelTests {
    @Suite("Тесты для методов редактирования упражнений")
    @MainActor
    struct EditMethodsTests {
        @Test("canRemoveExercise должен возвращать true если упражнений больше 1")
        func canRemoveExerciseReturnsTrueWhenMoreThanOneExercise() {
            let connectivityService = MockWatchConnectivityService()
            let viewModel = WorkoutPreviewViewModel(
                connectivityService: connectivityService
            )

            viewModel.trainings = [
                WorkoutPreviewTraining(count: 5, typeId: ExerciseType.pullups.rawValue, sortOrder: 0),
                WorkoutPreviewTraining(count: 10, typeId: ExerciseType.pushups.rawValue, sortOrder: 1)
            ]

            #expect(viewModel.canRemoveExercise)
        }

        @Test("canRemoveExercise должен возвращать false если упражнений 1")
        func canRemoveExerciseReturnsFalseWhenOnlyOneExercise() {
            let connectivityService = MockWatchConnectivityService()
            let viewModel = WorkoutPreviewViewModel(
                connectivityService: connectivityService
            )

            viewModel.trainings = [
                WorkoutPreviewTraining(count: 5, typeId: ExerciseType.pullups.rawValue, sortOrder: 0)
            ]

            #expect(!viewModel.canRemoveExercise)
        }

        @Test("editableTrainings должен фильтровать турбо-упражнения")
        func editableTrainingsFiltersTurboExercises() {
            let connectivityService = MockWatchConnectivityService()
            let viewModel = WorkoutPreviewViewModel(
                connectivityService: connectivityService
            )

            viewModel.trainings = [
                WorkoutPreviewTraining(count: 5, typeId: ExerciseType.pullups.rawValue, sortOrder: 0),
                WorkoutPreviewTraining(count: 10, typeId: ExerciseType.turbo93_1.rawValue, sortOrder: 1),
                WorkoutPreviewTraining(count: 15, typeId: ExerciseType.pushups.rawValue, sortOrder: 2)
            ]

            let editableTrainings = viewModel.editableTrainings
            #expect(editableTrainings.count == 2)
            #expect(editableTrainings.allSatisfy { !$0.isTurboExercise })
        }

        @Test("addStandardExercise должен добавлять стандартное упражнение")
        func addStandardExerciseAddsStandardExercise() throws {
            let connectivityService = MockWatchConnectivityService()
            let viewModel = WorkoutPreviewViewModel(
                connectivityService: connectivityService
            )

            viewModel.trainings = [
                WorkoutPreviewTraining(count: 5, typeId: ExerciseType.pullups.rawValue, sortOrder: 0)
            ]

            viewModel.addStandardExercise(.pushups)

            #expect(viewModel.trainings.count == 2)
            let addedExercise = viewModel.trainings.first { $0.typeId == ExerciseType.pushups.rawValue }
            let addedExerciseTypeId = try #require(addedExercise?.typeId)
            #expect(addedExerciseTypeId == ExerciseType.pushups.rawValue)
            let addedExerciseCount = try #require(addedExercise?.count)
            #expect(addedExerciseCount == 5)
        }

        @Test("updateTrainingCount должен увеличивать количество повторений")
        func updateTrainingCountIncrementsCount() throws {
            let connectivityService = MockWatchConnectivityService()
            let viewModel = WorkoutPreviewViewModel(
                connectivityService: connectivityService
            )

            let exercise = WorkoutPreviewTraining(count: 5, typeId: ExerciseType.pullups.rawValue, sortOrder: 0)
            viewModel.trainings = [exercise]

            viewModel.updateTrainingCount(at: 0, amount: 1)

            let updatedCount = try #require(viewModel.trainings[0].count)
            #expect(updatedCount == 6)
        }

        @Test("updateTrainingCount должен уменьшать количество повторений")
        func updateTrainingCountDecrementsCount() throws {
            let connectivityService = MockWatchConnectivityService()
            let viewModel = WorkoutPreviewViewModel(
                connectivityService: connectivityService
            )

            let exercise = WorkoutPreviewTraining(count: 5, typeId: ExerciseType.pullups.rawValue, sortOrder: 0)
            viewModel.trainings = [exercise]

            viewModel.updateTrainingCount(at: 0, amount: -1)

            let updatedCount = try #require(viewModel.trainings[0].count)
            #expect(updatedCount == 4)
        }

        @Test("updateTrainingCount должен удалять упражнение если количество становится 0")
        func updateTrainingCountRemovesExerciseWhenCountBecomesZero() throws {
            let connectivityService = MockWatchConnectivityService()
            let viewModel = WorkoutPreviewViewModel(
                connectivityService: connectivityService
            )

            let exercise1 = WorkoutPreviewTraining(count: 1, typeId: ExerciseType.pullups.rawValue, sortOrder: 0)
            let exercise2 = WorkoutPreviewTraining(count: 5, typeId: ExerciseType.pushups.rawValue, sortOrder: 1)
            viewModel.trainings = [exercise1, exercise2]

            viewModel.updateTrainingCount(at: 0, amount: -1)

            #expect(viewModel.trainings.count == 1)
            let remainingExercise = try #require(viewModel.trainings.first)
            #expect(remainingExercise.id == exercise2.id)
        }

        @Test("initializeEditableExercises должен инициализировать редактируемый список без турбо-упражнений")
        func initializeEditableExercisesInitializesListWithoutTurboExercises() {
            let connectivityService = MockWatchConnectivityService()
            let viewModel = WorkoutPreviewViewModel(
                connectivityService: connectivityService
            )

            viewModel.trainings = [
                WorkoutPreviewTraining(count: 5, typeId: ExerciseType.pullups.rawValue, sortOrder: 0),
                WorkoutPreviewTraining(count: 10, typeId: ExerciseType.turbo93_1.rawValue, sortOrder: 1),
                WorkoutPreviewTraining(count: 15, typeId: ExerciseType.pushups.rawValue, sortOrder: 2)
            ]

            let editableExercises = viewModel.initializeEditableExercises()

            #expect(editableExercises.count == 2)
            #expect(editableExercises.allSatisfy { !$0.isTurboExercise })
        }
    }
}
