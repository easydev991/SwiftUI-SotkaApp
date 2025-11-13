import Foundation
@testable import SwiftUI_SotkaApp
import Testing

extension WorkoutPreviewViewModelTests {
    @Suite("Тесты для buildDayActivity")
    struct BuildDayActivityTests {
        @Test("Должен создавать WorkoutProgramCreator с полными данными из ViewModel")
        @MainActor
        func createsWorkoutProgramCreatorWithFullDataFromViewModel() throws {
            let viewModel = WorkoutPreviewViewModel()
            viewModel.dayNumber = 5
            viewModel.selectedExecutionType = .cycles
            viewModel.count = 10
            viewModel.plannedCount = 8
            viewModel.comment = "Test comment"
            viewModel.trainings = [
                WorkoutPreviewTraining(count: 5, typeId: ExerciseType.pullups.rawValue, sortOrder: 0)
            ]

            let dayActivity = viewModel.buildDayActivity()

            #expect(dayActivity.day == 5)
            let count = try #require(dayActivity.count)
            #expect(count == 10)
            let plannedCount = try #require(dayActivity.plannedCount)
            #expect(plannedCount == 8)
            let comment = try #require(dayActivity.comment)
            #expect(comment == "Test comment")
        }

        @Test("Должен получать DayActivity через computed property dayActivity")
        @MainActor
        func getsDayActivityThroughComputedProperty() throws {
            let viewModel = WorkoutPreviewViewModel()
            viewModel.dayNumber = 1
            viewModel.selectedExecutionType = .cycles
            viewModel.trainings = [
                WorkoutPreviewTraining(count: 1, typeId: ExerciseType.pullups.rawValue, sortOrder: 0)
            ]

            let dayActivity = viewModel.buildDayActivity()

            #expect(dayActivity.activityType == .workout)
            #expect(dayActivity.trainings.count == 1)
        }

        @Test("Должен создавать DayActivity с правильными параметрами")
        @MainActor
        func createsDayActivityWithCorrectParameters() throws {
            let viewModel = WorkoutPreviewViewModel()
            viewModel.dayNumber = 5
            viewModel.selectedExecutionType = .cycles
            viewModel.count = 10
            viewModel.plannedCount = 8
            viewModel.comment = "Test comment"
            viewModel.trainings = [
                WorkoutPreviewTraining(count: 5, typeId: ExerciseType.pullups.rawValue, sortOrder: 0),
                WorkoutPreviewTraining(count: 10, typeId: ExerciseType.pushups.rawValue, sortOrder: 1)
            ]

            let dayActivity = viewModel.buildDayActivity()

            #expect(dayActivity.day == 5)
            let count = try #require(dayActivity.count)
            #expect(count == 10)
            let plannedCount = try #require(dayActivity.plannedCount)
            #expect(plannedCount == 8)
            let comment = try #require(dayActivity.comment)
            #expect(comment == "Test comment")
            #expect(dayActivity.trainings.count == 2)
        }

        @Test("Должен преобразовывать WorkoutPreviewTraining в DayActivityTraining")
        @MainActor
        func convertsWorkoutPreviewTrainingToDayActivityTraining() throws {
            let viewModel = WorkoutPreviewViewModel()
            viewModel.dayNumber = 1
            viewModel.selectedExecutionType = .cycles
            viewModel.trainings = [
                WorkoutPreviewTraining(count: 15, typeId: ExerciseType.squats.rawValue, customTypeId: "custom-123", sortOrder: 2)
            ]

            let dayActivity = viewModel.buildDayActivity()

            #expect(dayActivity.trainings.count == 1)
            let training = try #require(dayActivity.trainings.first)
            let count = try #require(training.count)
            #expect(count == 15)
            let typeId = try #require(training.typeId)
            #expect(typeId == ExerciseType.squats.rawValue)
            let customTypeId = try #require(training.customTypeId)
            #expect(customTypeId == "custom-123")
            let sortOrder = try #require(training.sortOrder)
            #expect(sortOrder == 2)
        }

        @Test("Должен устанавливать правильные связи между DayActivity и DayActivityTraining")
        @MainActor
        func setsCorrectRelationshipsBetweenDayActivityAndDayActivityTraining() throws {
            let viewModel = WorkoutPreviewViewModel()
            viewModel.dayNumber = 1
            viewModel.selectedExecutionType = .cycles
            viewModel.trainings = [
                WorkoutPreviewTraining(count: 5, typeId: ExerciseType.pullups.rawValue, sortOrder: 0)
            ]

            let dayActivity = viewModel.buildDayActivity()

            #expect(dayActivity.trainings.count == 1)
            let training = try #require(dayActivity.trainings.first)
            #expect(training.dayActivity === dayActivity)
        }
    }
}
