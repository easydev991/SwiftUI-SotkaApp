import Foundation
import SwiftData
@testable import SwiftUI_SotkaApp
import SWUtils
import Testing

// MARK: - Базовые операции (офлайн-приоритет)

extension DailyActivitiesServiceTests {
    @Test("Создает активность локально с isSynced = false")
    func createDailyActivityOffline() throws {
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

        service.createDailyActivity(activity, context: context)

        let savedActivity = try #require(context.fetch(FetchDescriptor<DayActivity>()).first)
        #expect(!savedActivity.isSynced)
        #expect(savedActivity.shouldDelete == false)
        #expect(savedActivity.day == 1)
        #expect(savedActivity.count == 5)
    }

    @Test("Создает активность с последующей синхронизацией")
    func createDailyActivityWithSync() async throws {
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
        service.createDailyActivity(activity, context: context)

        await service.syncDailyActivities(context: context)

        let savedActivity = try #require(context.fetch(FetchDescriptor<DayActivity>()).first)
        #expect(savedActivity.isSynced)
        #expect(mockClient.updateDayCallCount > 0)
    }

    @Test("Изменяет активность и синхронизирует")
    func markDailyActivityAsModifiedAndSync() async throws {
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
        activity.isSynced = true
        context.insert(activity)
        try context.save()

        activity.count = 10
        try service.markDailyActivityAsModified(activity, context: context)

        await service.syncDailyActivities(context: context)

        let updatedActivity = try #require(context.fetch(FetchDescriptor<DayActivity>()).first)
        #expect(updatedActivity.isSynced)
        #expect(updatedActivity.count == 10)
    }

    @Test("Мягко удаляет активность")
    func deleteDailyActivitySoftDelete() throws {
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
        context.insert(activity)
        try context.save()

        service.deleteDailyActivity(activity, context: context)

        let deletedActivity = try #require(context.fetch(FetchDescriptor<DayActivity>()).first)
        #expect(deletedActivity.shouldDelete)
        #expect(!deletedActivity.isSynced)
    }

    @Test("Удаляет активность и синхронизирует удаление")
    func deleteDailyActivityWithSync() async throws {
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
        context.insert(activity)
        try context.save()

        service.deleteDailyActivity(activity, context: context)
        await service.syncDailyActivities(context: context)

        let activities = try context.fetch(FetchDescriptor<DayActivity>())
        #expect(activities.isEmpty)
        #expect(mockClient.deleteDayCallCount == 1)
    }
}
