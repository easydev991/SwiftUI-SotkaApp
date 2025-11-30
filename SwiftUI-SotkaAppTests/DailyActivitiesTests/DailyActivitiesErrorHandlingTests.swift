import Foundation
import SwiftData
@testable import SwiftUI_SotkaApp
import SWUtils
import Testing

// MARK: - Обработка ошибок и дополнительные сценарии

extension DailyActivitiesServiceTests {
    @Test("Локальная работа продолжается при сетевой ошибке")
    func localWorkContinuesOnNetworkError() async throws {
        let mockClient = MockDaysClient()
        mockClient.shouldThrowError = true
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

        _ = try await service.syncDailyActivities(context: context)

        let savedActivity = try #require(context.fetch(FetchDescriptor<DayActivity>()).first)
        #expect(!savedActivity.isSynced)
        #expect(savedActivity.count == 5)
    }

    @Test("Предотвращает параллельную синхронизацию")
    func preventsConcurrentSync() async throws {
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

        let initialGetDaysCallCount = mockClient.getDaysCallCount
        let initialUpdateDayCallCount = mockClient.updateDayCallCount

        _ = try await service.syncDailyActivities(context: context)
        _ = try await service.syncDailyActivities(context: context)

        #expect(mockClient.getDaysCallCount > initialGetDaysCallCount)
        #expect(mockClient.updateDayCallCount > initialUpdateDayCallCount)
    }

    @Test("Элемент помечен на удаление но присутствует на сервере - не восстанавливается")
    func deletedItemPresentOnServerNotRestored() async throws {
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
        activity.isSynced = false
        context.insert(activity)
        try context.save()

        let serverResponse = DayResponse(
            id: 1,
            activityType: 1,
            count: 10,
            plannedCount: nil,
            executeType: nil,
            trainType: nil,
            trainings: nil,
            createDate: Date().addingTimeInterval(-3600),
            modifyDate: Date(),
            duration: nil,
            comment: nil
        )
        mockClient.setServerActivity(serverResponse)

        _ = try await service.syncDailyActivities(context: context)

        let activities = try context.fetch(FetchDescriptor<DayActivity>())
        let deletedActivity = try #require(activities.first)
        #expect(deletedActivity.shouldDelete)
        #expect(deletedActivity.count == 5)
    }

    @Test("Физически удаляет активность после синхронизации удаления")
    func physicallyDeleteAfterSyncDeletion() async throws {
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
        service.deleteDailyActivity(activity, context: context)

        _ = try await service.syncDailyActivities(context: context)

        let activities = try context.fetch(FetchDescriptor<DayActivity>())
        #expect(activities.isEmpty)
        #expect(mockClient.deleteDayCallCount == 1)
    }

    @Test("Пропускает обновление при повторной синхронизации без изменений данных")
    func skipUpdateOnRepeatedSyncWithoutDataChanges() async throws {
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
            createDate: Date().addingTimeInterval(-3600),
            modifyDate: Date().addingTimeInterval(-1800),
            user: user
        )
        activity.isSynced = true
        context.insert(activity)
        try context.save()

        let serverResponse = DayResponse(
            id: 1,
            activityType: 1,
            count: 5,
            plannedCount: nil,
            executeType: nil,
            trainType: nil,
            trainings: nil,
            createDate: Date().addingTimeInterval(-3600),
            modifyDate: Date().addingTimeInterval(-1799),
            duration: nil,
            comment: nil
        )
        mockClient.setServerActivity(serverResponse)

        let initialGetDaysCallCount = mockClient.getDaysCallCount

        _ = try await service.syncDailyActivities(context: context)

        let updatedActivity = try #require(context.fetch(FetchDescriptor<DayActivity>()).first)
        #expect(updatedActivity.count == 5)
        #expect(updatedActivity.isSynced)
        #expect(mockClient.getDaysCallCount > initialGetDaysCallCount)
    }
}
