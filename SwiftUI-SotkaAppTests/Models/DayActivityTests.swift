import Foundation
import SwiftData
@testable import SwiftUI_SotkaApp
import SWUtils
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
    func dayActivityFromResponse() {
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
            createDate: DateFormatterService.dateFromString("2024-01-01T12:00:00", format: .serverDateTimeSec),
            modifyDate: DateFormatterService.dateFromString("2024-01-01T12:30:00", format: .serverDateTimeSec),
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
    func dayActivityFromResponseSetsSynced() {
        let response = DayResponse(
            id: 1,
            activityType: 0,
            count: nil,
            plannedCount: nil,
            executeType: nil,
            trainType: nil,
            trainings: nil,
            createDate: DateFormatterService.dateFromString("2024-01-01T12:00:00", format: .serverDateTimeSec),
            modifyDate: DateFormatterService.dateFromString("2024-01-01T12:00:00", format: .serverDateTimeSec),
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
            createDate: DateFormatterService.dateFromString("2024-01-01T12:00:00", format: .serverDateTimeSec),
            modifyDate: DateFormatterService.dateFromString("2024-01-01T12:00:00", format: .serverDateTimeSec),
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

    // MARK: - DayActivityTraining sorted Tests

    @Test("sorted возвращает пустой массив для пустого массива тренировок")
    func sortedWithEmptyArray() {
        let trainings: [DayActivityTraining] = []
        let sorted = trainings.sorted
        #expect(sorted.isEmpty)
    }

    @Test("sorted возвращает отсортированный массив тренировок по sortOrder")
    @MainActor
    func sortedWithMultipleTrainings() throws {
        let container = try ModelContainer(
            for: DayActivityTraining.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = container.mainContext

        let training1 = DayActivityTraining(count: 10, sortOrder: 2)
        let training2 = DayActivityTraining(count: 20, sortOrder: 0)
        let training3 = DayActivityTraining(count: 30, sortOrder: 1)
        context.insert(training1)
        context.insert(training2)
        context.insert(training3)
        try context.save()

        let trainings = [training1, training2, training3]
        let sorted = trainings.sorted

        #expect(sorted.count == 3)
        let first = try #require(sorted.first)
        let last = try #require(sorted.last)
        let firstSortOrder = try #require(first.sortOrder)
        let lastSortOrder = try #require(last.sortOrder)
        #expect(firstSortOrder == 0)
        #expect(lastSortOrder == 2)
        #expect(first.count == 20)
        #expect(last.count == 10)
    }

    @Test("sorted обрабатывает тренировки с nil sortOrder")
    @MainActor
    func sortedWithNilSortOrder() throws {
        let container = try ModelContainer(
            for: DayActivityTraining.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = container.mainContext

        let training1 = DayActivityTraining(count: 10, sortOrder: 5)
        let training2 = DayActivityTraining(count: 20, sortOrder: nil)
        let training3 = DayActivityTraining(count: 30, sortOrder: 2)
        context.insert(training1)
        context.insert(training2)
        context.insert(training3)
        try context.save()

        let trainings = [training1, training2, training3]
        let sorted = trainings.sorted

        #expect(sorted.count == 3)
        let first = try #require(sorted.first)
        let last = try #require(sorted.last)
        #expect(first.sortOrder == nil || first.sortOrder == 2)
        #expect(last.sortOrder == 5)
        #expect(first.count == 20 || first.count == 30)
        #expect(last.count == 10)
    }

    @Test("sorted обрабатывает тренировки с одинаковым sortOrder")
    @MainActor
    func sortedWithSameSortOrder() throws {
        let container = try ModelContainer(
            for: DayActivityTraining.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = container.mainContext

        let training1 = DayActivityTraining(count: 10, sortOrder: 1)
        let training2 = DayActivityTraining(count: 20, sortOrder: 1)
        let training3 = DayActivityTraining(count: 30, sortOrder: 0)
        context.insert(training1)
        context.insert(training2)
        context.insert(training3)
        try context.save()

        let trainings = [training1, training2, training3]
        let sorted = trainings.sorted

        #expect(sorted.count == 3)
        let first = try #require(sorted.first)
        let firstSortOrder = try #require(first.sortOrder)
        #expect(firstSortOrder == 0)
        #expect(first.count == 30)
    }

    @Test("sorted сохраняет исходный массив без изменений")
    @MainActor
    func sortedPreservesOriginalArray() throws {
        let container = try ModelContainer(
            for: DayActivityTraining.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = container.mainContext

        let training1 = DayActivityTraining(count: 10, sortOrder: 2)
        let training2 = DayActivityTraining(count: 20, sortOrder: 0)
        context.insert(training1)
        context.insert(training2)
        try context.save()

        let trainings = [training1, training2]
        let sorted = trainings.sorted

        #expect(trainings.count == sorted.count)
        let originalFirst = try #require(trainings.first)
        let sortedFirst = try #require(sorted.first)
        let originalFirstSortOrder = try #require(originalFirst.sortOrder)
        let sortedFirstSortOrder = try #require(sortedFirst.sortOrder)
        #expect(originalFirstSortOrder == 2)
        #expect(sortedFirstSortOrder == 0)
    }

    // MARK: - setNonWorkoutType Tests

    @Test("setNonWorkoutType устанавливает тип активности stretch")
    @MainActor
    func setNonWorkoutTypeSetsStretch() throws {
        let container = try ModelContainer(
            for: DayActivity.self,
            DayActivityTraining.self,
            User.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = container.mainContext

        let user = User(id: 1, userName: "testuser", fullName: "Test User", email: "test@example.com")
        context.insert(user)
        try context.save()

        let originalCreateDate = Date().addingTimeInterval(-3600)
        let activity = DayActivity(
            day: 1,
            activityTypeRaw: 0,
            count: 5,
            createDate: originalCreateDate,
            modifyDate: originalCreateDate,
            user: user
        )
        let training = DayActivityTraining(count: 10, typeId: 1, dayActivity: activity)
        activity.trainings.append(training)
        context.insert(activity)
        try context.save()

        activity.setNonWorkoutType(.stretch, user: user)

        #expect(activity.activityType == .stretch)
        #expect(activity.count == nil)
        #expect(activity.trainings.isEmpty)
        #expect(activity.executeTypeRaw == nil)
        #expect(activity.trainingTypeRaw == nil)
        #expect(activity.comment == nil)
        #expect(activity.duration == nil)
        #expect(!activity.isSynced)
        #expect(!activity.shouldDelete)
        #expect(activity.createDate == originalCreateDate)
        let userFromActivity = try #require(activity.user)
        #expect(userFromActivity.id == user.id)
    }

    @Test("setNonWorkoutType устанавливает тип активности rest")
    @MainActor
    func setNonWorkoutTypeSetsRest() throws {
        let container = try ModelContainer(
            for: DayActivity.self,
            User.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = container.mainContext

        let user = User(id: 1, userName: "testuser", fullName: "Test User", email: "test@example.com")
        context.insert(user)
        try context.save()

        let originalCreateDate = Date().addingTimeInterval(-3600)
        let activity = DayActivity(
            day: 2,
            activityTypeRaw: 2,
            count: nil,
            createDate: originalCreateDate,
            modifyDate: originalCreateDate,
            user: user
        )
        context.insert(activity)
        try context.save()

        activity.setNonWorkoutType(.rest, user: user)

        #expect(activity.activityType == .rest)
        #expect(activity.createDate == originalCreateDate)
    }

    @Test("setNonWorkoutType устанавливает тип активности sick")
    @MainActor
    func setNonWorkoutTypeSetsSick() throws {
        let container = try ModelContainer(
            for: DayActivity.self,
            User.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = container.mainContext

        let user = User(id: 1, userName: "testuser", fullName: "Test User", email: "test@example.com")
        context.insert(user)
        try context.save()

        let originalCreateDate = Date().addingTimeInterval(-3600)
        let activity = DayActivity(
            day: 3,
            activityTypeRaw: 1,
            duration: 3600,
            comment: "Test comment",
            createDate: originalCreateDate,
            modifyDate: originalCreateDate,
            user: user
        )
        context.insert(activity)
        try context.save()

        activity.setNonWorkoutType(.sick, user: user)

        #expect(activity.activityType == .sick)
        #expect(activity.comment == nil)
        #expect(activity.duration == nil)
        #expect(activity.createDate == originalCreateDate)
    }

    @Test("setNonWorkoutType обновляет modifyDate на текущее время")
    @MainActor
    func setNonWorkoutTypeUpdatesModifyDate() throws {
        let container = try ModelContainer(
            for: DayActivity.self,
            User.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = container.mainContext

        let user = User(id: 1, userName: "testuser", fullName: "Test User", email: "test@example.com")
        context.insert(user)
        try context.save()

        let oldModifyDate = Date().addingTimeInterval(-3600)
        let activity = DayActivity(
            day: 1,
            activityTypeRaw: 0,
            createDate: Date().addingTimeInterval(-7200),
            modifyDate: oldModifyDate,
            user: user
        )
        context.insert(activity)
        try context.save()

        let beforeUpdate = Date()
        activity.setNonWorkoutType(.stretch, user: user)
        let afterUpdate = Date()

        #expect(activity.modifyDate >= beforeUpdate)
        #expect(activity.modifyDate <= afterUpdate)
    }

    @Test("setNonWorkoutType очищает все тренировочные данные")
    @MainActor
    func setNonWorkoutTypeClearsTrainingData() throws {
        let container = try ModelContainer(
            for: DayActivity.self,
            DayActivityTraining.self,
            User.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = container.mainContext

        let user = User(id: 1, userName: "testuser", fullName: "Test User", email: "test@example.com")
        context.insert(user)
        try context.save()

        let activity = DayActivity(
            day: 1,
            activityTypeRaw: 0,
            count: 10,
            executeTypeRaw: 1,
            trainingTypeRaw: 2,
            createDate: .now,
            modifyDate: .now,
            user: user
        )
        let training1 = DayActivityTraining(count: 5, typeId: 1, dayActivity: activity)
        let training2 = DayActivityTraining(count: 8, typeId: 2, dayActivity: activity)
        activity.trainings.append(training1)
        activity.trainings.append(training2)
        context.insert(activity)
        try context.save()

        activity.setNonWorkoutType(.rest, user: user)

        #expect(activity.count == nil)
        #expect(activity.trainings.isEmpty)
        #expect(activity.executeTypeRaw == nil)
        #expect(activity.trainingTypeRaw == nil)
    }

    @Test("setNonWorkoutType снимает флаг shouldDelete")
    @MainActor
    func setNonWorkoutTypeRemovesShouldDeleteFlag() throws {
        let container = try ModelContainer(
            for: DayActivity.self,
            User.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = container.mainContext

        let user = User(id: 1, userName: "testuser", fullName: "Test User", email: "test@example.com")
        context.insert(user)
        try context.save()

        let activity = DayActivity(
            day: 1,
            activityTypeRaw: 1,
            createDate: .now,
            modifyDate: .now,
            user: user
        )
        activity.shouldDelete = true
        activity.isSynced = true
        context.insert(activity)
        try context.save()

        activity.setNonWorkoutType(.stretch, user: user)

        #expect(!activity.shouldDelete)
        #expect(!activity.isSynced)
    }

    // MARK: - createNonWorkoutActivity Tests

    @Test("createNonWorkoutActivity создает активность с типом stretch")
    @MainActor
    func createNonWorkoutActivityCreatesStretch() throws {
        let container = try ModelContainer(
            for: DayActivity.self,
            User.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = container.mainContext

        let user = User(id: 1, userName: "testuser", fullName: "Test User", email: "test@example.com")
        context.insert(user)
        try context.save()

        let activity = DayActivity.createNonWorkoutActivity(day: 1, activityType: .stretch, user: user)

        #expect(activity.day == 1)
        #expect(activity.activityType == .stretch)
        #expect(activity.count == nil)
        #expect(activity.trainings.isEmpty)
        #expect(activity.executeTypeRaw == nil)
        #expect(activity.trainingTypeRaw == nil)
        #expect(activity.comment == nil)
        #expect(activity.duration == nil)
        #expect(!activity.isSynced)
        #expect(!activity.shouldDelete)
        let userFromActivity = try #require(activity.user)
        #expect(userFromActivity.id == user.id)
    }

    @Test("createNonWorkoutActivity создает активность с типом rest")
    @MainActor
    func createNonWorkoutActivityCreatesRest() {
        let user = User(id: 1, userName: "testuser", fullName: "Test User", email: "test@example.com")

        let activity = DayActivity.createNonWorkoutActivity(day: 2, activityType: .rest, user: user)

        #expect(activity.day == 2)
        #expect(activity.activityType == .rest)
        #expect(activity.activityTypeRaw == 1)
    }

    @Test("createNonWorkoutActivity создает активность с типом sick")
    @MainActor
    func createNonWorkoutActivityCreatesSick() {
        let user = User(id: 1, userName: "testuser", fullName: "Test User", email: "test@example.com")

        let activity = DayActivity.createNonWorkoutActivity(day: 3, activityType: .sick, user: user)

        #expect(activity.day == 3)
        #expect(activity.activityType == .sick)
        #expect(activity.activityTypeRaw == 3)
    }

    @Test("createNonWorkoutActivity устанавливает правильные флаги синхронизации")
    @MainActor
    func createNonWorkoutActivitySetsSyncFlags() {
        let user = User(id: 1, userName: "testuser", fullName: "Test User", email: "test@example.com")

        let activity = DayActivity.createNonWorkoutActivity(day: 1, activityType: .stretch, user: user)

        #expect(!activity.isSynced)
        #expect(!activity.shouldDelete)
    }

    @Test("createNonWorkoutActivity устанавливает текущие даты")
    @MainActor
    func createNonWorkoutActivitySetsCurrentDates() {
        let user = User(id: 1, userName: "testuser", fullName: "Test User", email: "test@example.com")

        let beforeCreation = Date()
        let activity = DayActivity.createNonWorkoutActivity(day: 1, activityType: .stretch, user: user)
        let afterCreation = Date()

        #expect(activity.createDate >= beforeCreation)
        #expect(activity.createDate <= afterCreation)
        #expect(activity.modifyDate >= beforeCreation)
        #expect(activity.modifyDate <= afterCreation)
    }

    @Test("createNonWorkoutActivity привязывает активность к пользователю")
    @MainActor
    func createNonWorkoutActivityBindsToUser() throws {
        let container = try ModelContainer(
            for: DayActivity.self,
            User.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = container.mainContext

        let user = User(id: 1, userName: "testuser", fullName: "Test User", email: "test@example.com")
        context.insert(user)
        try context.save()

        let activity = DayActivity.createNonWorkoutActivity(day: 1, activityType: .stretch, user: user)

        let userFromActivity = try #require(activity.user)
        #expect(userFromActivity.id == user.id)
    }

    // MARK: - isPassed Tests

    @Test("Должен возвращать true когда count не nil")
    @MainActor
    func isPassedReturnsTrueWhenCountIsNotNil() throws {
        let container = try ModelContainer(
            for: DayActivity.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = container.mainContext

        let dayActivity = DayActivity(
            day: 1,
            count: 5,
            createDate: Date(),
            modifyDate: Date()
        )
        context.insert(dayActivity)

        #expect(dayActivity.isPassed)
    }

    @Test("Должен возвращать false когда count равен nil")
    @MainActor
    func isPassedReturnsFalseWhenCountIsNil() throws {
        let container = try ModelContainer(
            for: DayActivity.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = container.mainContext

        let dayActivity = DayActivity(
            day: 1,
            count: nil,
            createDate: Date(),
            modifyDate: Date()
        )
        context.insert(dayActivity)

        #expect(!dayActivity.isPassed)
    }

    // MARK: - workoutData Tests

    @Test("workoutData возвращает nil для активности типа stretch")
    @MainActor
    func workoutDataReturnsNilForStretch() throws {
        let container = try ModelContainer(
            for: DayActivity.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = container.mainContext

        let dayActivity = DayActivity(
            day: 1,
            activityTypeRaw: DayActivityType.stretch.rawValue,
            createDate: Date(),
            modifyDate: Date()
        )
        context.insert(dayActivity)

        #expect(dayActivity.workoutData == nil)
    }

    @Test("workoutData возвращает nil для активности типа rest")
    @MainActor
    func workoutDataReturnsNilForRest() throws {
        let container = try ModelContainer(
            for: DayActivity.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = container.mainContext

        let dayActivity = DayActivity(
            day: 1,
            activityTypeRaw: DayActivityType.rest.rawValue,
            createDate: Date(),
            modifyDate: Date()
        )
        context.insert(dayActivity)

        #expect(dayActivity.workoutData == nil)
    }

    @Test("workoutData возвращает nil для активности типа sick")
    @MainActor
    func workoutDataReturnsNilForSick() throws {
        let container = try ModelContainer(
            for: DayActivity.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = container.mainContext

        let dayActivity = DayActivity(
            day: 1,
            activityTypeRaw: DayActivityType.sick.rawValue,
            createDate: Date(),
            modifyDate: Date()
        )
        context.insert(dayActivity)

        #expect(dayActivity.workoutData == nil)
    }

    @Test("workoutData возвращает WorkoutData для тренировочной активности")
    @MainActor
    func workoutDataReturnsWorkoutDataForWorkout() throws {
        let container = try ModelContainer(
            for: DayActivity.self,
            DayActivityTraining.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = container.mainContext

        let dayActivity = DayActivity(
            day: 5,
            activityTypeRaw: DayActivityType.workout.rawValue,
            plannedCount: 4,
            executeTypeRaw: ExerciseExecutionType.sets.rawValue,
            createDate: Date(),
            modifyDate: Date()
        )
        let training1 = DayActivityTraining(
            count: 10,
            typeId: 0,
            customTypeId: nil,
            sortOrder: 0,
            dayActivity: dayActivity
        )
        let training2 = DayActivityTraining(
            count: 15,
            typeId: 1,
            customTypeId: nil,
            sortOrder: 1,
            dayActivity: dayActivity
        )
        dayActivity.trainings.append(training1)
        dayActivity.trainings.append(training2)
        context.insert(dayActivity)
        try context.save()

        let workoutData = try #require(dayActivity.workoutData)

        #expect(workoutData.day == 5)
        #expect(workoutData.executionType == ExerciseExecutionType.sets.rawValue)
        let plannedCount = try #require(workoutData.plannedCount)
        #expect(plannedCount == 4)
        #expect(workoutData.trainings.count == 2)
    }

    @Test("workoutData использует значение по умолчанию для executionType если оно nil")
    @MainActor
    func workoutDataUsesDefaultExecutionTypeWhenNil() throws {
        let container = try ModelContainer(
            for: DayActivity.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = container.mainContext

        let dayActivity = DayActivity(
            day: 1,
            activityTypeRaw: DayActivityType.workout.rawValue,
            executeTypeRaw: nil,
            createDate: Date(),
            modifyDate: Date()
        )
        context.insert(dayActivity)

        let workoutData = try #require(dayActivity.workoutData)

        #expect(workoutData.executionType == ExerciseExecutionType.cycles.rawValue)
    }

    @Test("workoutData правильно преобразует trainings в WorkoutPreviewTraining")
    @MainActor
    func workoutDataConvertsTrainingsCorrectly() throws {
        let container = try ModelContainer(
            for: DayActivity.self,
            DayActivityTraining.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = container.mainContext

        let dayActivity = DayActivity(
            day: 10,
            activityTypeRaw: DayActivityType.workout.rawValue,
            executeTypeRaw: ExerciseExecutionType.cycles.rawValue,
            createDate: Date(),
            modifyDate: Date()
        )
        let training = DayActivityTraining(
            count: 20,
            typeId: 3,
            customTypeId: "custom-123",
            sortOrder: 5,
            dayActivity: dayActivity
        )
        dayActivity.trainings.append(training)
        context.insert(dayActivity)
        try context.save()

        let workoutData = try #require(dayActivity.workoutData)

        #expect(workoutData.trainings.count == 1)
        let previewTraining = workoutData.trainings[0]
        let count = try #require(previewTraining.count)
        #expect(count == 20)
        let typeId = try #require(previewTraining.typeId)
        #expect(typeId == 3)
        let customTypeId = try #require(previewTraining.customTypeId)
        #expect(customTypeId == "custom-123")
        let sortOrder = try #require(previewTraining.sortOrder)
        #expect(sortOrder == 5)
    }

    @Test("workoutData возвращает nil для plannedCount если оно nil")
    @MainActor
    func workoutDataReturnsNilPlannedCountWhenNil() throws {
        let container = try ModelContainer(
            for: DayActivity.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = container.mainContext

        let dayActivity = DayActivity(
            day: 1,
            activityTypeRaw: DayActivityType.workout.rawValue,
            plannedCount: nil,
            executeTypeRaw: ExerciseExecutionType.cycles.rawValue,
            createDate: Date(),
            modifyDate: Date()
        )
        context.insert(dayActivity)

        let workoutData = try #require(dayActivity.workoutData)

        #expect(workoutData.plannedCount == nil)
    }

    @Test("workoutData обрабатывает пустой массив trainings")
    @MainActor
    func workoutDataHandlesEmptyTrainingsArray() throws {
        let container = try ModelContainer(
            for: DayActivity.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = container.mainContext

        let dayActivity = DayActivity(
            day: 1,
            activityTypeRaw: DayActivityType.workout.rawValue,
            executeTypeRaw: ExerciseExecutionType.cycles.rawValue,
            createDate: Date(),
            modifyDate: Date()
        )
        context.insert(dayActivity)

        let workoutData = try #require(dayActivity.workoutData)

        #expect(workoutData.trainings.isEmpty)
    }
}
