import Foundation
import SwiftData
@testable import SwiftUI_SotkaApp
import Testing

extension AllWorkoutPreviewViewModelTests {
    // MARK: - saveTrainingAsPassed Tests

    @Test("Должен вызывать createDailyActivity с правильной моделью")
    @MainActor
    func callsCreateDailyActivityWithCorrectModel() throws {
        let container = try ModelContainer(
            for: DayActivity.self,
            DayActivityTraining.self,
            User.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = container.mainContext
        let user = User(id: 1)
        context.insert(user)
        try context.save()

        let mockClient = MockDaysClient()
        let activitiesService = DailyActivitiesService(client: mockClient)
        let viewModel = WorkoutPreviewViewModel()

        viewModel.dayNumber = 5
        viewModel.selectedExecutionType = .cycles
        viewModel.count = 10
        viewModel.plannedCount = 8
        viewModel.comment = "Test comment"
        viewModel.trainings = [
            WorkoutPreviewTraining(count: 5, typeId: ExerciseType.pullups.rawValue, sortOrder: 0)
        ]

        viewModel.saveTrainingAsPassed(activitiesService: activitiesService, modelContext: context)

        let savedActivity = try #require(context.fetch(FetchDescriptor<DayActivity>()).first)
        #expect(savedActivity.day == 5)
        let count = try #require(savedActivity.count)
        #expect(count == 10)
        let plannedCount = try #require(savedActivity.plannedCount)
        #expect(plannedCount == 8)
        let comment = try #require(savedActivity.comment)
        #expect(comment == "Test comment")
    }

    @Test("Должен обрабатывать ошибку если тип выполнения не выбран")
    @MainActor
    func handlesErrorIfExecutionTypeNotSelected() throws {
        let container = try ModelContainer(
            for: DayActivity.self,
            DayActivityTraining.self,
            User.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = container.mainContext
        let user = User(id: 1)
        context.insert(user)
        try context.save()

        let mockClient = MockDaysClient()
        let activitiesService = DailyActivitiesService(client: mockClient)
        let viewModel = WorkoutPreviewViewModel()

        viewModel.dayNumber = 5
        viewModel.selectedExecutionType = nil
        viewModel.trainings = []

        viewModel.saveTrainingAsPassed(activitiesService: activitiesService, modelContext: context)

        let error = try #require(viewModel.error)
        #expect(error == .executionTypeNotSelected)
    }

    @Test("Должен обрабатывать ошибку если список упражнений пуст")
    @MainActor
    func handlesErrorIfTrainingsListIsEmpty() throws {
        let container = try ModelContainer(
            for: DayActivity.self,
            DayActivityTraining.self,
            User.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = container.mainContext
        let user = User(id: 1)
        context.insert(user)
        try context.save()

        let mockClient = MockDaysClient()
        let activitiesService = DailyActivitiesService(client: mockClient)
        let viewModel = WorkoutPreviewViewModel()

        viewModel.dayNumber = 5
        viewModel.selectedExecutionType = .cycles
        viewModel.trainings = []

        viewModel.saveTrainingAsPassed(activitiesService: activitiesService, modelContext: context)

        let error = try #require(viewModel.error)
        #expect(error == .trainingsListEmpty)
    }

    @Test("Должен устанавливать count = plannedCount при сохранении с count == nil")
    @MainActor
    func setsCountToPlannedCountWhenCountIsNil() throws {
        let container = try ModelContainer(
            for: DayActivity.self,
            DayActivityTraining.self,
            User.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = container.mainContext
        let user = User(id: 1)
        context.insert(user)
        try context.save()

        let mockClient = MockDaysClient()
        let activitiesService = DailyActivitiesService(client: mockClient)
        let viewModel = WorkoutPreviewViewModel()

        viewModel.dayNumber = 5
        viewModel.selectedExecutionType = .cycles
        viewModel.count = nil
        viewModel.plannedCount = 8
        viewModel.trainings = [
            WorkoutPreviewTraining(count: 5, typeId: ExerciseType.pullups.rawValue, sortOrder: 0)
        ]

        viewModel.saveTrainingAsPassed(activitiesService: activitiesService, modelContext: context)

        let savedActivity = try #require(context.fetch(FetchDescriptor<DayActivity>()).first)
        let count = try #require(savedActivity.count)
        #expect(count == 8)
    }

    @Test("Должен сохранять существующий count при сохранении с count != nil")
    @MainActor
    func preservesExistingCountWhenCountIsNotNil() throws {
        let container = try ModelContainer(
            for: DayActivity.self,
            DayActivityTraining.self,
            User.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = container.mainContext
        let user = User(id: 1)
        context.insert(user)
        try context.save()

        let mockClient = MockDaysClient()
        let activitiesService = DailyActivitiesService(client: mockClient)
        let viewModel = WorkoutPreviewViewModel()

        viewModel.dayNumber = 5
        viewModel.selectedExecutionType = .cycles
        viewModel.count = 10
        viewModel.plannedCount = 8
        viewModel.trainings = [
            WorkoutPreviewTraining(count: 5, typeId: ExerciseType.pullups.rawValue, sortOrder: 0)
        ]

        viewModel.saveTrainingAsPassed(activitiesService: activitiesService, modelContext: context)

        let savedActivity = try #require(context.fetch(FetchDescriptor<DayActivity>()).first)
        let count = try #require(savedActivity.count)
        #expect(count == 10)
    }

    @Test("Должен устанавливать wasOriginallyPassed = true после сохранения и перезагрузки")
    @MainActor
    func setsWasOriginallyPassedToTrueAfterSaveAndReload() throws {
        let container = try ModelContainer(
            for: DayActivity.self,
            DayActivityTraining.self,
            User.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = container.mainContext
        let user = User(id: 1)
        context.insert(user)
        try context.save()

        let mockClient = MockDaysClient()
        let activitiesService = DailyActivitiesService(client: mockClient)
        let viewModel = WorkoutPreviewViewModel()

        viewModel.dayNumber = 5
        viewModel.selectedExecutionType = .cycles
        viewModel.count = nil
        viewModel.plannedCount = 8
        viewModel.trainings = [
            WorkoutPreviewTraining(count: 5, typeId: ExerciseType.pullups.rawValue, sortOrder: 0)
        ]

        viewModel.saveTrainingAsPassed(activitiesService: activitiesService, modelContext: context)

        let reloadedViewModel = WorkoutPreviewViewModel()
        let appSettings = AppSettings()
        reloadedViewModel.updateData(modelContext: context, day: 5, restTime: appSettings.restTime)

        #expect(reloadedViewModel.wasOriginallyPassed)
    }
}
