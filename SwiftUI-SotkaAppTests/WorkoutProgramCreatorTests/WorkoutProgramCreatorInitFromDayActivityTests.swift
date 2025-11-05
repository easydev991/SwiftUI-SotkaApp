import Foundation
import SwiftData
@testable import SwiftUI_SotkaApp
import Testing

extension AllWorkoutProgramCreatorTests {
    // MARK: - init(from: DayActivity) Tests

    @Test("Должен создавать WorkoutProgramCreator из DayActivity с правильными данными")
    @MainActor
    func createsFromDayActivityWithCorrectData() throws {
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
        dayActivity.comment = "Test comment"
        context.insert(dayActivity)

        let training1 = DayActivityTraining(
            count: 5,
            typeId: ExerciseType.pullups.rawValue,
            sortOrder: 0,
            dayActivity: dayActivity
        )
        let training2 = DayActivityTraining(
            count: 10,
            typeId: ExerciseType.pushups.rawValue,
            sortOrder: 1,
            dayActivity: dayActivity
        )
        context.insert(training1)
        context.insert(training2)
        try context.save()

        let creator = WorkoutProgramCreator(from: dayActivity)

        #expect(creator.day == 5)
        #expect(creator.executionType == .cycles)
        let count = try #require(creator.count)
        #expect(count == 10)
        let plannedCount = try #require(creator.plannedCount)
        #expect(plannedCount == 8)
        let comment = try #require(creator.comment)
        #expect(comment == "Test comment")
        #expect(creator.trainings.count == 2)
    }

    @Test("Должен преобразовывать DayActivityTraining в WorkoutPreviewTraining")
    @MainActor
    func convertsDayActivityTrainingToWorkoutPreviewTraining() throws {
        let container = try ModelContainer(
            for: DayActivity.self,
            DayActivityTraining.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = container.mainContext

        let dayActivity = DayActivity(
            day: 1,
            createDate: Date(),
            modifyDate: Date()
        )
        context.insert(dayActivity)

        let training = DayActivityTraining(
            count: 15,
            typeId: ExerciseType.squats.rawValue,
            customTypeId: "custom-123",
            sortOrder: 2,
            dayActivity: dayActivity
        )
        context.insert(training)
        try context.save()

        let creator = WorkoutProgramCreator(from: dayActivity)

        #expect(creator.trainings.count == 1)
        let previewTraining = try #require(creator.trainings.first)
        let count = try #require(previewTraining.count)
        #expect(count == 15)
        let typeId = try #require(previewTraining.typeId)
        #expect(typeId == ExerciseType.squats.rawValue)
        let customTypeId = try #require(previewTraining.customTypeId)
        #expect(customTypeId == "custom-123")
        let sortOrder = try #require(previewTraining.sortOrder)
        #expect(sortOrder == 2)
    }

    @Test("Должен правильно маппить все поля из DayActivity")
    @MainActor
    func mapsAllFieldsFromDayActivity() throws {
        let container = try ModelContainer(
            for: DayActivity.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = container.mainContext

        let dayActivity = DayActivity(
            day: 50,
            activityTypeRaw: DayActivityType.workout.rawValue,
            count: nil,
            plannedCount: 6,
            executeTypeRaw: ExerciseExecutionType.sets.rawValue,
            createDate: Date(),
            modifyDate: Date()
        )
        dayActivity.comment = "My comment"
        context.insert(dayActivity)

        let creator = WorkoutProgramCreator(from: dayActivity)

        #expect(creator.day == 50)
        #expect(creator.executionType == .sets)
        #expect(creator.count == nil)
        let plannedCount = try #require(creator.plannedCount)
        #expect(plannedCount == 6)
        let comment = try #require(creator.comment)
        #expect(comment == "My comment")
        #expect(creator.trainings.isEmpty)
    }

    @Test("Должен использовать defaultExecutionType когда executeType равен nil")
    @MainActor
    func usesDefaultExecutionTypeWhenExecuteTypeIsNil() throws {
        let container = try ModelContainer(
            for: DayActivity.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = container.mainContext

        let dayActivity = DayActivity(
            day: 1,
            executeTypeRaw: nil,
            createDate: Date(),
            modifyDate: Date()
        )
        context.insert(dayActivity)

        let creator = WorkoutProgramCreator(from: dayActivity)

        #expect(creator.executionType == .cycles)
    }

    @Test("Должен использовать defaultExecutionType для дня 50 когда executeType равен nil")
    @MainActor
    func usesDefaultExecutionTypeForDay50WhenExecuteTypeIsNil() throws {
        let container = try ModelContainer(
            for: DayActivity.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = container.mainContext

        let dayActivity = DayActivity(
            day: 50,
            executeTypeRaw: nil,
            createDate: Date(),
            modifyDate: Date()
        )
        context.insert(dayActivity)

        let creator = WorkoutProgramCreator(from: dayActivity)

        #expect(creator.executionType == .cycles)
    }

    @Test("Должен вычислять plannedCount на основе day и executionType когда plannedCount равен nil")
    @MainActor
    func calculatesPlannedCountBasedOnDayAndExecutionTypeWhenPlannedCountIsNil() throws {
        let container = try ModelContainer(
            for: DayActivity.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = container.mainContext

        let dayActivity = DayActivity(
            day: 1,
            activityTypeRaw: DayActivityType.workout.rawValue,
            count: 10,
            plannedCount: nil,
            executeTypeRaw: ExerciseExecutionType.cycles.rawValue,
            createDate: Date(),
            modifyDate: Date()
        )
        context.insert(dayActivity)

        let creator = WorkoutProgramCreator(from: dayActivity)

        let plannedCount = try #require(creator.plannedCount)
        #expect(plannedCount == 4)
    }

    @Test("Должен использовать сохраненный plannedCount когда он не равен nil")
    @MainActor
    func usesSavedPlannedCountWhenItIsNotNil() throws {
        let container = try ModelContainer(
            for: DayActivity.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = container.mainContext

        let dayActivity = DayActivity(
            day: 1,
            activityTypeRaw: DayActivityType.workout.rawValue,
            count: 10,
            plannedCount: 8,
            executeTypeRaw: ExerciseExecutionType.cycles.rawValue,
            createDate: Date(),
            modifyDate: Date()
        )
        context.insert(dayActivity)

        let creator = WorkoutProgramCreator(from: dayActivity)

        let plannedCount = try #require(creator.plannedCount)
        #expect(plannedCount == 8)
    }

    @Test("Должен вычислять plannedCount для дня 50 с типом sets когда plannedCount равен nil")
    @MainActor
    func calculatesPlannedCountForDay50WithSetsTypeWhenPlannedCountIsNil() throws {
        let container = try ModelContainer(
            for: DayActivity.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = container.mainContext

        let dayActivity = DayActivity(
            day: 50,
            activityTypeRaw: DayActivityType.workout.rawValue,
            count: 10,
            plannedCount: nil,
            executeTypeRaw: ExerciseExecutionType.sets.rawValue,
            createDate: Date(),
            modifyDate: Date()
        )
        context.insert(dayActivity)

        let creator = WorkoutProgramCreator(from: dayActivity)

        let plannedCount = try #require(creator.plannedCount)
        #expect(plannedCount == 6)
    }
}
