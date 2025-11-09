import Foundation
import SwiftData
@testable import SwiftUI_SotkaApp
import Testing

extension AllWorkoutPreviewViewModelTests {
    @Test("Должен инициализировать restTime из AppSettings при создании новой тренировки")
    @MainActor
    func initializesFromAppSettings() throws {
        let userDefaults = try MockUserDefaults.create()
        let appSettings = AppSettings(userDefaults: userDefaults)
        appSettings.restTime = 75

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
        viewModel.updateData(modelContext: context, day: 1, restTime: appSettings.restTime)

        #expect(viewModel.restTime == 75)
    }

    @Test("Должен устанавливать restTime для всех тренировок, включая пройденные")
    @MainActor
    func setsRestTimeForAllWorkouts() throws {
        let userDefaults = try MockUserDefaults.create()
        let appSettings = AppSettings(userDefaults: userDefaults)
        appSettings.restTime = 75

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
        viewModel.updateData(modelContext: context, day: 5, restTime: appSettings.restTime)

        #expect(viewModel.restTime == 75)
    }

    @Test("Должен сохранять restTime в ViewModel")
    @MainActor
    func savesRestTimeInViewModel() throws {
        let userDefaults = try MockUserDefaults.create()
        let appSettings = AppSettings(userDefaults: userDefaults)

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
        viewModel.updateData(modelContext: context, day: 1, restTime: appSettings.restTime)
        viewModel.restTime = 45

        #expect(viewModel.restTime == 45)
    }

    @Test("Должен включать restTime в DataSnapshot")
    @MainActor
    func includesInDataSnapshot() throws {
        let userDefaults = try MockUserDefaults.create()
        let appSettings = AppSettings(userDefaults: userDefaults)
        appSettings.restTime = 50

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
        viewModel.updateData(modelContext: context, day: 1, restTime: appSettings.restTime)
        viewModel.restTime = 60

        #expect(viewModel.hasChanges)
    }

    @Test("Должен обновлять restTime через updaterestTime")
    @MainActor
    func updatesRestTime() throws {
        let userDefaults = try MockUserDefaults.create()
        let appSettings = AppSettings(userDefaults: userDefaults)

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
        viewModel.updateData(modelContext: context, day: 1, restTime: appSettings.restTime)
        viewModel.updateRestTime(60)

        #expect(viewModel.restTime == 60)
    }
}
