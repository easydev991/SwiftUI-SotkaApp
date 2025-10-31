import Foundation
import SwiftData
@testable import SwiftUI_SotkaApp
import Testing

@Suite("Тесты для DayActivity и DayActivityTraining")
struct DayActivityTests {
    // MARK: - DayActivity Creation Tests

    @Test("DayActivity создается с базовыми полями")
    @MainActor
    func dayActivityCreation() throws {
        let container = try ModelContainer(
            for: DayActivity.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = container.mainContext

        let dayActivity = DayActivity(
            day: 1,
            activityTypeRaw: DayActivityType.workout.rawValue,
            count: 5,
            createDate: Date(),
            modifyDate: Date()
        )
        context.insert(dayActivity)
        try context.save()

        let fetched = try context.fetch(FetchDescriptor<DayActivity>())
        let activity = try #require(fetched.first)
        #expect(fetched.count == 1)
        #expect(activity.day == 1)
        #expect(activity.activityTypeRaw == 0)
        #expect(activity.count == 5)
    }

    // MARK: - Computed Properties Tests

    @Test("activityType возвращает workout для rawValue 0")
    @MainActor
    func activityTypeReturnsWorkout() throws {
        let container = try ModelContainer(
            for: DayActivity.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = container.mainContext

        let dayActivity = DayActivity(day: 1, createDate: Date(), modifyDate: Date())
        context.insert(dayActivity)

        dayActivity.activityTypeRaw = 0
        let activityType = try #require(dayActivity.activityType)
        #expect(activityType == .workout)
    }

    @Test("activityType устанавливает rawValue при установке workout")
    @MainActor
    func activityTypeSetsRawValueForWorkout() throws {
        let container = try ModelContainer(
            for: DayActivity.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = container.mainContext

        let dayActivity = DayActivity(day: 1, createDate: Date(), modifyDate: Date())
        context.insert(dayActivity)

        dayActivity.activityType = .workout
        #expect(dayActivity.activityTypeRaw == 0)
    }

    @Test("activityType возвращает nil для nil rawValue")
    @MainActor
    func activityTypeReturnsNilForNilRawValue() throws {
        let container = try ModelContainer(
            for: DayActivity.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = container.mainContext

        let dayActivity = DayActivity(day: 1, createDate: Date(), modifyDate: Date())
        context.insert(dayActivity)

        dayActivity.activityTypeRaw = nil
        #expect(dayActivity.activityType == nil)
    }

    @Test("executeType возвращает cycles для rawValue 0")
    @MainActor
    func executeTypeReturnsCycles() throws {
        let container = try ModelContainer(
            for: DayActivity.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = container.mainContext

        let dayActivity = DayActivity(day: 1, createDate: Date(), modifyDate: Date())
        context.insert(dayActivity)

        dayActivity.executeTypeRaw = 0
        let executeType = try #require(dayActivity.executeType)
        #expect(executeType == .cycles)
    }

    @Test("executeType устанавливает rawValue при установке sets")
    @MainActor
    func executeTypeSetsRawValueForSets() throws {
        let container = try ModelContainer(
            for: DayActivity.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = container.mainContext

        let dayActivity = DayActivity(day: 1, createDate: Date(), modifyDate: Date())
        context.insert(dayActivity)

        dayActivity.executeType = .sets
        #expect(dayActivity.executeTypeRaw == 1)
    }

    @Test("trainingType возвращает pullups для rawValue 0")
    @MainActor
    func trainingTypeReturnsPullups() throws {
        let container = try ModelContainer(
            for: DayActivity.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = container.mainContext

        let dayActivity = DayActivity(day: 1, createDate: Date(), modifyDate: Date())
        context.insert(dayActivity)

        dayActivity.trainingTypeRaw = 0
        let trainingType = try #require(dayActivity.trainingType)
        #expect(trainingType == .pullups)
    }

    @Test("trainingType устанавливает nil при установке nil")
    @MainActor
    func trainingTypeSetsNil() throws {
        let container = try ModelContainer(
            for: DayActivity.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = container.mainContext

        let dayActivity = DayActivity(day: 1, createDate: Date(), modifyDate: Date())
        context.insert(dayActivity)

        dayActivity.trainingType = nil
        #expect(dayActivity.trainingTypeRaw == nil)
        #expect(dayActivity.trainingType == nil)
    }

    @Test("exerciseType возвращает pullups для typeId 0")
    @MainActor
    func exerciseTypeReturnsPullups() throws {
        let container = try ModelContainer(
            for: DayActivityTraining.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = container.mainContext

        let training = DayActivityTraining(typeId: ExerciseType.pullups.rawValue)
        context.insert(training)

        let exerciseType = try #require(training.exerciseType)
        #expect(exerciseType == .pullups)
        #expect(training.typeId == 0)
    }

    @Test("exerciseType устанавливает typeId при установке pushups")
    @MainActor
    func exerciseTypeSetsTypeIdForPushups() throws {
        let container = try ModelContainer(
            for: DayActivityTraining.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = container.mainContext

        let training = DayActivityTraining()
        context.insert(training)

        training.exerciseType = .pushups
        #expect(training.typeId == 3)
    }

    @Test("exerciseType возвращает nil для nil typeId")
    @MainActor
    func exerciseTypeReturnsNilForNilTypeId() throws {
        let container = try ModelContainer(
            for: DayActivityTraining.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = container.mainContext

        let training = DayActivityTraining(typeId: nil)
        context.insert(training)

        #expect(training.exerciseType == nil)
    }

    // MARK: - Relationship Tests

    @Test("DayActivity связан с User через relationship")
    @MainActor
    func dayActivityUserRelationship() throws {
        let container = try ModelContainer(
            for: User.self,
            DayActivity.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = container.mainContext

        let user = User(id: 1)
        context.insert(user)

        let dayActivity = DayActivity(day: 1, createDate: Date(), modifyDate: Date(), user: user)
        context.insert(dayActivity)
        try context.save()

        let userFromActivity = try #require(dayActivity.user)
        #expect(userFromActivity.id == 1)
    }

    @Test("User содержит DayActivity в dayActivities")
    @MainActor
    func userContainsDayActivity() throws {
        let container = try ModelContainer(
            for: User.self,
            DayActivity.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = container.mainContext

        let user = User(id: 1)
        context.insert(user)

        let dayActivity = DayActivity(day: 1, createDate: Date(), modifyDate: Date(), user: user)
        context.insert(dayActivity)
        try context.save()

        #expect(user.dayActivities.contains { $0.day == 1 })
    }

    @Test("DayActivity содержит DayActivityTraining в trainings")
    @MainActor
    func dayActivityContainsTrainings() throws {
        let container = try ModelContainer(
            for: DayActivity.self,
            DayActivityTraining.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = container.mainContext

        let dayActivity = DayActivity(day: 1, createDate: Date(), modifyDate: Date())
        context.insert(dayActivity)

        let training1 = DayActivityTraining(count: 10, typeId: ExerciseType.pullups.rawValue, sortOrder: 0, dayActivity: dayActivity)
        let training2 = DayActivityTraining(count: 20, typeId: ExerciseType.pushups.rawValue, sortOrder: 1, dayActivity: dayActivity)
        context.insert(training1)
        context.insert(training2)
        try context.save()

        #expect(dayActivity.trainings.count == 2)
    }

    @Test("DayActivityTraining связан с DayActivity через relationship")
    @MainActor
    func dayActivityTrainingRelationship() throws {
        let container = try ModelContainer(
            for: DayActivity.self,
            DayActivityTraining.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = container.mainContext

        let dayActivity = DayActivity(day: 1, createDate: Date(), modifyDate: Date())
        context.insert(dayActivity)

        let training = DayActivityTraining(count: 10, dayActivity: dayActivity)
        context.insert(training)
        try context.save()

        let dayActivityFromTraining = try #require(training.dayActivity)
        #expect(dayActivityFromTraining.day == 1)
    }

    // MARK: - Cascade Delete Tests

    @Test("Удаление User каскадно удаляет DayActivity")
    @MainActor
    func cascadeDeleteDayActivityOnUserDelete() throws {
        let container = try ModelContainer(
            for: User.self,
            DayActivity.self,
            DayActivityTraining.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = container.mainContext

        let user = User(id: 1)
        context.insert(user)

        let dayActivity = DayActivity(day: 1, createDate: Date(), modifyDate: Date(), user: user)
        context.insert(dayActivity)

        let training = DayActivityTraining(count: 10, dayActivity: dayActivity)
        context.insert(training)
        try context.save()

        context.delete(user)
        try context.save()

        let users = try context.fetch(FetchDescriptor<User>())
        let activities = try context.fetch(FetchDescriptor<DayActivity>())
        let trainings = try context.fetch(FetchDescriptor<DayActivityTraining>())

        #expect(users.isEmpty)
        #expect(activities.isEmpty)
        #expect(trainings.isEmpty)
    }

    @Test("Удаление DayActivity каскадно удаляет DayActivityTraining")
    @MainActor
    func cascadeDeleteTrainingOnDayActivityDelete() throws {
        let container = try ModelContainer(
            for: DayActivity.self,
            DayActivityTraining.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = container.mainContext

        let dayActivity = DayActivity(day: 1, createDate: Date(), modifyDate: Date())
        context.insert(dayActivity)

        let training1 = DayActivityTraining(count: 10, dayActivity: dayActivity)
        let training2 = DayActivityTraining(count: 20, dayActivity: dayActivity)
        context.insert(training1)
        context.insert(training2)
        try context.save()

        context.delete(dayActivity)
        try context.save()

        let activities = try context.fetch(FetchDescriptor<DayActivity>())
        let trainings = try context.fetch(FetchDescriptor<DayActivityTraining>())

        #expect(activities.isEmpty)
        #expect(trainings.isEmpty)
    }

    // MARK: - Initializer from DayResponse Tests

    @Test("Инициализатор из DayResponse создает DayActivity с правильными полями")
    @MainActor
    func dayActivityFromResponse() throws {
        let response = DayResponse(
            id: 5,
            activityType: 0,
            count: 10,
            plannedCount: 8,
            executeType: 0,
            trainType: 3,
            trainings: [
                .init(typeId: 0, customTypeId: nil, count: 5, sortOrder: 0),
                .init(typeId: 3, customTypeId: nil, count: 10, sortOrder: 1)
            ],
            createDate: "2024-01-01T12:00:00+00:00",
            modifyDate: "2024-01-01T12:30:00+00:00",
            duration: 30,
            comment: "Test comment"
        )

        let dayActivity = DayActivity(from: response)

        #expect(dayActivity.day == 5)
        #expect(dayActivity.activityTypeRaw == 0)
        #expect(dayActivity.count == 10)
        #expect(dayActivity.plannedCount == 8)
        #expect(dayActivity.executeTypeRaw == 0)
        #expect(dayActivity.trainingTypeRaw == 3)
        #expect(dayActivity.duration == 30)
        #expect(dayActivity.comment == "Test comment")
    }

    @Test("Инициализатор из DayResponse устанавливает isSynced в true")
    @MainActor
    func dayActivityFromResponseSetsSynced() throws {
        let response = DayResponse(
            id: 1,
            activityType: 0,
            count: nil,
            plannedCount: nil,
            executeType: nil,
            trainType: nil,
            trainings: nil,
            createDate: "2024-01-01T12:00:00+00:00",
            modifyDate: "2024-01-01T12:00:00+00:00",
            duration: nil,
            comment: nil
        )

        let dayActivity = DayActivity(from: response)

        #expect(dayActivity.isSynced)
        #expect(!dayActivity.shouldDelete)
    }

    @Test("Инициализатор из DayResponse создает trainings из массива")
    @MainActor
    func dayActivityFromResponseCreatesTrainings() throws {
        let response = DayResponse(
            id: 1,
            activityType: 0,
            count: nil,
            plannedCount: nil,
            executeType: nil,
            trainType: nil,
            trainings: [
                .init(typeId: 0, customTypeId: nil, count: 5, sortOrder: 0),
                .init(typeId: 3, customTypeId: nil, count: 10, sortOrder: 1)
            ],
            createDate: "2024-01-01T12:00:00+00:00",
            modifyDate: "2024-01-01T12:00:00+00:00",
            duration: nil,
            comment: nil
        )

        let dayActivity = DayActivity(from: response)

        #expect(dayActivity.trainings.count == 2)
        let firstTraining = try #require(dayActivity.trainings.first)
        let lastTraining = try #require(dayActivity.trainings.last)
        #expect(firstTraining.count == 5)
        #expect(lastTraining.count == 10)
    }
}
