import Foundation
import SwiftData
@testable import SwiftUI_SotkaApp
import Testing

extension WorkoutPreviewViewModelTests {
    @Suite("Тесты для handleWorkoutResult")
    struct HandleWorkoutResultTests {
        @Test("Должен обновлять состояние ViewModel из результата тренировки")
        @MainActor
        func handleWorkoutResult() throws {
            let viewModel = WorkoutPreviewViewModel()
            let modelConfiguration = ModelConfiguration(isStoredInMemoryOnly: true)
            let modelContainer = try ModelContainer(
                for: User.self,
                DayActivity.self,
                DayActivityTraining.self,
                configurations: modelConfiguration
            )
            let context = modelContainer.mainContext

            viewModel.updateData(modelContext: context, day: 1, restTime: 60)

            let result = WorkoutResult(count: 4, duration: 180)
            viewModel.handleWorkoutResult(result)

            let count = try #require(viewModel.count)
            let workoutDuration = try #require(viewModel.workoutDuration)

            #expect(count == 4)
            #expect(workoutDuration == 180)
            #expect(viewModel.isWorkoutCompleted)
        }

        @Test("Должен обрабатывать результат с duration = nil")
        @MainActor
        func handleWorkoutResultWithNilDuration() throws {
            let viewModel = WorkoutPreviewViewModel()
            let modelConfiguration = ModelConfiguration(isStoredInMemoryOnly: true)
            let modelContainer = try ModelContainer(
                for: User.self,
                DayActivity.self,
                DayActivityTraining.self,
                configurations: modelConfiguration
            )
            let context = modelContainer.mainContext

            viewModel.updateData(modelContext: context, day: 1, restTime: 60)

            let result = WorkoutResult(count: 3, duration: nil)
            viewModel.handleWorkoutResult(result)

            let count = try #require(viewModel.count)
            #expect(count == 3)
            #expect(viewModel.workoutDuration == nil)
            #expect(viewModel.isWorkoutCompleted)
        }

        @Test("Должен не устанавливать isWorkoutCompleted при count == 0")
        @MainActor
        func handleWorkoutResultWithZeroCount() throws {
            let viewModel = WorkoutPreviewViewModel()
            let modelConfiguration = ModelConfiguration(isStoredInMemoryOnly: true)
            let modelContainer = try ModelContainer(
                for: User.self,
                DayActivity.self,
                DayActivityTraining.self,
                configurations: modelConfiguration
            )
            let context = modelContainer.mainContext

            viewModel.updateData(modelContext: context, day: 1, restTime: 60)

            let initialCount = viewModel.count
            let initialWorkoutDuration = viewModel.workoutDuration

            let result = WorkoutResult(count: 0, duration: 100)
            viewModel.handleWorkoutResult(result)

            #expect(!viewModel.isWorkoutCompleted)
            #expect(viewModel.count == initialCount)
            #expect(viewModel.workoutDuration == initialWorkoutDuration)
        }

        @Test("Должен устанавливать isWorkoutCompleted и обновлять count при count > 0")
        @MainActor
        func handleWorkoutResultWithPositiveCount() throws {
            let viewModel = WorkoutPreviewViewModel()
            let modelConfiguration = ModelConfiguration(isStoredInMemoryOnly: true)
            let modelContainer = try ModelContainer(
                for: User.self,
                DayActivity.self,
                DayActivityTraining.self,
                configurations: modelConfiguration
            )
            let context = modelContainer.mainContext

            viewModel.updateData(modelContext: context, day: 1, restTime: 60)

            let result = WorkoutResult(count: 5, duration: 200)
            viewModel.handleWorkoutResult(result)

            let count = try #require(viewModel.count)
            let workoutDuration = try #require(viewModel.workoutDuration)

            #expect(viewModel.isWorkoutCompleted)
            #expect(count == 5)
            #expect(workoutDuration == 200)
        }
    }
}
