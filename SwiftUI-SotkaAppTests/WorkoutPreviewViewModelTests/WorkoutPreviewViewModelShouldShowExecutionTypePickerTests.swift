import Foundation
import SwiftData
@testable import SwiftUI_SotkaApp
import Testing

extension AllWorkoutPreviewViewModelTests {
    // MARK: - shouldShowExecutionTypePicker Tests

    @Test("Должен возвращать false если dayNumber не совпадает с day")
    @MainActor
    func returnsFalseIfDayNumberDoesNotMatchDay() throws {
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

        let viewModel = WorkoutPreviewViewModel()
        viewModel.dayNumber = 5
        viewModel.trainings = [
            WorkoutPreviewTraining(count: 1, typeId: ExerciseType.pullups.rawValue, sortOrder: 0)
        ]
        viewModel.availableExecutionTypes = [.cycles, .sets]

        let result = viewModel.shouldShowExecutionTypePicker(modelContext: context, day: 10)

        #expect(!result)
    }

    @Test("Должен возвращать false если trainings пустой")
    @MainActor
    func returnsFalseIfTrainingsIsEmpty() throws {
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

        let viewModel = WorkoutPreviewViewModel()
        viewModel.dayNumber = 5
        viewModel.trainings = []
        viewModel.availableExecutionTypes = [.cycles, .sets]

        let result = viewModel.shouldShowExecutionTypePicker(modelContext: context, day: 5)

        #expect(!result)
    }

    @Test("Должен возвращать false если активность найдена и пройдена")
    @MainActor
    func returnsFalseIfActivityFoundAndPassed() throws {
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

        let dayActivity = DayActivity(
            day: 5,
            activityTypeRaw: DayActivityType.workout.rawValue,
            count: 10,
            plannedCount: 8,
            executeTypeRaw: ExerciseExecutionType.cycles.rawValue,
            createDate: Date(),
            modifyDate: Date(),
            user: user
        )
        context.insert(dayActivity)
        try context.save()

        let viewModel = WorkoutPreviewViewModel()
        viewModel.dayNumber = 5
        viewModel.trainings = [
            WorkoutPreviewTraining(count: 1, typeId: ExerciseType.pullups.rawValue, sortOrder: 0)
        ]
        viewModel.availableExecutionTypes = [.cycles, .sets]

        let result = viewModel.shouldShowExecutionTypePicker(modelContext: context, day: 5)

        #expect(!result)
    }

    @Test("Должен возвращать false если доступно только один тип выполнения")
    @MainActor
    func returnsFalseIfOnlyOneExecutionTypeAvailable() throws {
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

        let viewModel = WorkoutPreviewViewModel()
        viewModel.dayNumber = 5
        viewModel.trainings = [
            WorkoutPreviewTraining(count: 1, typeId: ExerciseType.pullups.rawValue, sortOrder: 0)
        ]
        viewModel.availableExecutionTypes = [.cycles]

        let result = viewModel.shouldShowExecutionTypePicker(modelContext: context, day: 5)

        #expect(!result)
    }

    @Test("Должен возвращать true если активность не найдена и доступно больше одного типа")
    @MainActor
    func returnsTrueIfActivityNotFoundAndMultipleTypesAvailable() throws {
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

        let viewModel = WorkoutPreviewViewModel()
        viewModel.dayNumber = 5
        viewModel.trainings = [
            WorkoutPreviewTraining(count: 1, typeId: ExerciseType.pullups.rawValue, sortOrder: 0)
        ]
        viewModel.availableExecutionTypes = [.cycles, .sets]

        let result = viewModel.shouldShowExecutionTypePicker(modelContext: context, day: 5)

        #expect(result)
    }

    @Test("Должен возвращать true если активность найдена, не пройдена и доступно больше одного типа")
    @MainActor
    func returnsTrueIfActivityFoundNotPassedAndMultipleTypesAvailable() throws {
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

        let dayActivity = DayActivity(
            day: 5,
            activityTypeRaw: DayActivityType.workout.rawValue,
            count: nil,
            plannedCount: 8,
            executeTypeRaw: ExerciseExecutionType.cycles.rawValue,
            createDate: Date(),
            modifyDate: Date(),
            user: user
        )
        context.insert(dayActivity)
        try context.save()

        let viewModel = WorkoutPreviewViewModel()
        viewModel.dayNumber = 5
        viewModel.trainings = [
            WorkoutPreviewTraining(count: 1, typeId: ExerciseType.pullups.rawValue, sortOrder: 0)
        ]
        viewModel.availableExecutionTypes = [.cycles, .sets]

        let result = viewModel.shouldShowExecutionTypePicker(modelContext: context, day: 5)

        #expect(result)
    }

    @Test("Должен игнорировать активность с shouldDelete = true")
    @MainActor
    func ignoresActivityWithShouldDeleteTrue() throws {
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

        let dayActivity = DayActivity(
            day: 5,
            activityTypeRaw: DayActivityType.workout.rawValue,
            count: 10,
            plannedCount: 8,
            executeTypeRaw: ExerciseExecutionType.cycles.rawValue,
            createDate: Date(),
            modifyDate: Date(),
            user: user
        )
        dayActivity.shouldDelete = true
        context.insert(dayActivity)
        try context.save()

        let viewModel = WorkoutPreviewViewModel()
        viewModel.dayNumber = 5
        viewModel.trainings = [
            WorkoutPreviewTraining(count: 1, typeId: ExerciseType.pullups.rawValue, sortOrder: 0)
        ]
        viewModel.availableExecutionTypes = [.cycles, .sets]

        let result = viewModel.shouldShowExecutionTypePicker(modelContext: context, day: 5)

        #expect(result)
    }
}
