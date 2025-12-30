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

        @Test("Для прерванной тренировки с подходами handleWorkoutResult должен установить count = plannedCount из результата")
        @MainActor
        func handleWorkoutResultForInterruptedSetsWorkout() throws {
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
            viewModel.plannedCount = 6

            // Результат прерванной тренировки с подходами содержит plannedCount
            let result = WorkoutResult(count: 6, duration: 120)
            viewModel.handleWorkoutResult(result)

            let count = try #require(viewModel.count)
            #expect(count == 6)
            #expect(viewModel.isWorkoutCompleted)
        }

        @Test(
            "Для завершенной тренировки с подходами handleWorkoutResult должен установить count равным фактическому количеству из результата"
        )
        @MainActor
        func handleWorkoutResultForCompletedSetsWorkout() throws {
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
            viewModel.plannedCount = 6

            // Результат завершенной тренировки с подходами содержит фактическое количество (12 подходов = 6 подходов * 2 упражнения)
            let result = WorkoutResult(count: 12, duration: 300)
            viewModel.handleWorkoutResult(result)

            let count = try #require(viewModel.count)
            #expect(count == 12)
            #expect(viewModel.isWorkoutCompleted)
        }

        @Test(
            "Для прерванной тренировки с кругами handleWorkoutResult должен установить count равным количеству завершенных кругов из результата"
        )
        @MainActor
        func handleWorkoutResultForInterruptedCyclesWorkout() throws {
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
            viewModel.plannedCount = 4

            // Результат прерванной тренировки с кругами содержит количество завершенных кругов (прежняя логика)
            let result = WorkoutResult(count: 2, duration: 90)
            viewModel.handleWorkoutResult(result)

            let count = try #require(viewModel.count)
            #expect(count == 2)
            #expect(viewModel.isWorkoutCompleted)
        }
    }
}
