import Foundation
import SwiftData
@testable import SwiftUI_SotkaApp
import SWUtils
import Testing

// MARK: - Установка активности дня (set)

extension DailyActivitiesServiceTests {
    @Test("Создает новую активность для дня без существующей активности (stretch)")
    func setCreatesNewActivityForStretch() throws {
        let mockClient = MockDaysClient()
        let service = DailyActivitiesService(client: mockClient)
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

        service.set(.stretch, for: 1, context: context)

        let savedActivity = try #require(context.fetch(FetchDescriptor<DayActivity>()).first)
        #expect(savedActivity.day == 1)
        #expect(savedActivity.activityType == .stretch)
        #expect(!savedActivity.isSynced)
        #expect(savedActivity.shouldDelete == false)
        #expect(savedActivity.count == nil)
        #expect(savedActivity.trainings.isEmpty)
        #expect(savedActivity.executeTypeRaw == nil)
        #expect(savedActivity.trainingTypeRaw == nil)
    }

    @Test("Создает новую активность для дня без существующей активности (rest)")
    func setCreatesNewActivityForRest() throws {
        let mockClient = MockDaysClient()
        let service = DailyActivitiesService(client: mockClient)
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

        service.set(.rest, for: 2, context: context)

        let savedActivity = try #require(context.fetch(FetchDescriptor<DayActivity>()).first)
        #expect(savedActivity.day == 2)
        #expect(savedActivity.activityType == .rest)
        #expect(!savedActivity.isSynced)
        #expect(savedActivity.shouldDelete == false)
    }

    @Test("Создает новую активность для дня без существующей активности (sick)")
    func setCreatesNewActivityForSick() throws {
        let mockClient = MockDaysClient()
        let service = DailyActivitiesService(client: mockClient)
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

        service.set(.sick, for: 3, context: context)

        let savedActivity = try #require(context.fetch(FetchDescriptor<DayActivity>()).first)
        #expect(savedActivity.day == 3)
        #expect(savedActivity.activityType == .sick)
        #expect(!savedActivity.isSynced)
        #expect(savedActivity.shouldDelete == false)
    }

    @Test("Не обрабатывает тип workout")
    func setIgnoresWorkoutType() throws {
        let mockClient = MockDaysClient()
        let service = DailyActivitiesService(client: mockClient)
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

        service.set(.workout, for: 1, context: context)

        let activities = try context.fetch(FetchDescriptor<DayActivity>())
        #expect(activities.isEmpty)
    }

    @Test("Обновляет существующую активность с другим типом")
    func setUpdatesExistingActivityWithDifferentType() throws {
        let mockClient = MockDaysClient()
        let service = DailyActivitiesService(client: mockClient)
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
            activityTypeRaw: 1,
            count: 5,
            createDate: originalCreateDate,
            modifyDate: originalCreateDate,
            user: user
        )
        activity.isSynced = true
        let training = DayActivityTraining(count: 10, typeId: 1, dayActivity: activity)
        activity.trainings.append(training)
        context.insert(activity)
        try context.save()

        service.set(.stretch, for: 1, context: context)

        let updatedActivity = try #require(context.fetch(FetchDescriptor<DayActivity>()).first)
        #expect(updatedActivity.activityType == .stretch)
        #expect(updatedActivity.count == nil)
        #expect(updatedActivity.trainings.isEmpty)
        #expect(updatedActivity.executeTypeRaw == nil)
        #expect(updatedActivity.trainingTypeRaw == nil)
        #expect(!updatedActivity.isSynced)
        #expect(!updatedActivity.shouldDelete)
        #expect(updatedActivity.createDate == originalCreateDate)
    }

    @Test("Не изменяет активность при повторном выборе того же типа")
    func setDoesNotChangeActivityOnSameType() throws {
        let mockClient = MockDaysClient()
        let service = DailyActivitiesService(client: mockClient)
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
        let originalModifyDate = Date().addingTimeInterval(-1800)
        let activity = DayActivity(
            day: 1,
            activityTypeRaw: 2,
            createDate: originalCreateDate,
            modifyDate: originalModifyDate,
            user: user
        )
        context.insert(activity)
        try context.save()

        service.set(.stretch, for: 1, context: context)

        let unchangedActivity = try #require(context.fetch(FetchDescriptor<DayActivity>()).first)
        #expect(unchangedActivity.activityType == .stretch)
        let createDateDifference = abs(unchangedActivity.createDate.timeIntervalSince1970 - originalCreateDate.timeIntervalSince1970)
        let modifyDateDifference = abs(unchangedActivity.modifyDate.timeIntervalSince1970 - originalModifyDate.timeIntervalSince1970)
        #expect(createDateDifference < 1.0)
        #expect(modifyDateDifference < 1.0)
    }

    @Test("Создает активность только с типом (без тренировочных данных) для stretch/rest/sick")
    func setCreatesActivityOnlyWithTypeForStretchRestSick() throws {
        let mockClient = MockDaysClient()
        let service = DailyActivitiesService(client: mockClient)
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

        service.set(.rest, for: 5, context: context)

        let savedActivity = try #require(context.fetch(FetchDescriptor<DayActivity>()).first)
        #expect(savedActivity.count == nil)
        #expect(savedActivity.trainings.isEmpty)
        #expect(savedActivity.executeTypeRaw == nil)
        #expect(savedActivity.trainingTypeRaw == nil)
        #expect(savedActivity.activityTypeRaw == 1)
    }

    @Test("Очищает тренировочные данные при обновлении на stretch/rest/sick")
    func setClearsTrainingDataWhenUpdatingToStretchRestSick() throws {
        let mockClient = MockDaysClient()
        let service = DailyActivitiesService(client: mockClient)
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

        service.set(.sick, for: 1, context: context)

        let updatedActivity = try #require(context.fetch(FetchDescriptor<DayActivity>()).first)
        #expect(updatedActivity.activityType == .sick)
        #expect(updatedActivity.count == nil)
        #expect(updatedActivity.trainings.isEmpty)
        #expect(updatedActivity.executeTypeRaw == nil)
        #expect(updatedActivity.trainingTypeRaw == nil)
    }

    @Test("Не создает активность если пользователь не найден")
    func setDoesNotCreateActivityIfUserNotFound() throws {
        let mockClient = MockDaysClient()
        let service = DailyActivitiesService(client: mockClient)
        let container = try ModelContainer(
            for: DayActivity.self,
            DayActivityTraining.self,
            User.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = container.mainContext

        service.set(.stretch, for: 1, context: context)

        let activities = try context.fetch(FetchDescriptor<DayActivity>())
        #expect(activities.isEmpty)
    }

    @Test("Корректно работает с активностью помеченной на удаление")
    func setWorksWithActivityMarkedForDeletion() throws {
        let mockClient = MockDaysClient()
        let service = DailyActivitiesService(client: mockClient)
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
            activityTypeRaw: 1,
            count: 5,
            createDate: .now,
            modifyDate: .now,
            user: user
        )
        activity.shouldDelete = true
        activity.isSynced = true
        context.insert(activity)
        try context.save()

        service.set(.rest, for: 1, context: context)

        let updatedActivity = try #require(context.fetch(FetchDescriptor<DayActivity>()).first)
        #expect(updatedActivity.activityType == .rest)
        #expect(!updatedActivity.shouldDelete)
        #expect(!updatedActivity.isSynced)
    }

    @Test("Очищает дополнительные данные при обновлении типа (comment, duration)")
    func setClearsAdditionalDataWhenUpdatingType() throws {
        let mockClient = MockDaysClient()
        let service = DailyActivitiesService(client: mockClient)
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
            duration: 3600,
            comment: "Test comment",
            createDate: .now,
            modifyDate: .now,
            user: user
        )
        context.insert(activity)
        try context.save()

        service.set(.stretch, for: 1, context: context)

        let updatedActivity = try #require(context.fetch(FetchDescriptor<DayActivity>()).first)
        #expect(updatedActivity.activityType == .stretch)
        #expect(updatedActivity.comment == nil)
        #expect(updatedActivity.duration == nil)
    }

    @Test("Корректно обрабатывает множественные вызовы для одного дня")
    func setHandlesMultipleCallsForSameDay() throws {
        let mockClient = MockDaysClient()
        let service = DailyActivitiesService(client: mockClient)
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

        service.set(.stretch, for: 1, context: context)
        service.set(.rest, for: 1, context: context)
        service.set(.sick, for: 1, context: context)

        let activities = try context.fetch(FetchDescriptor<DayActivity>())
        #expect(activities.count == 1)
        let finalActivity = try #require(activities.first)
        #expect(finalActivity.activityType == .sick)
    }
}
