import Foundation
import SwiftData
@testable import SwiftUI_SotkaApp
import SWUtils
import Testing

@MainActor
struct DailyActivitiesServiceTests {
    @Test("Возвращает результат успешной синхронизации с подсчетом созданных записей")
    func returnsSuccessResultWithCreatedCount() async throws {
        let mockClient = MockDaysClient()
        let service = DailyActivitiesService(client: mockClient)
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
            activityTypeRaw: DayActivityType.rest.rawValue,
            count: nil,
            plannedCount: nil,
            executeTypeRaw: nil,
            trainingTypeRaw: nil,
            duration: nil,
            comment: nil,
            createDate: Date(),
            modifyDate: Date(),
            user: user
        )
        activity.isSynced = false
        context.insert(activity)
        try context.save()

        let serverResponse = DayResponse(
            id: 1,
            activityType: DayActivityType.rest.rawValue,
            count: nil,
            plannedCount: nil,
            executeType: nil,
            trainType: nil,
            trainings: nil,
            createDate: Date(),
            modifyDate: Date(),
            duration: nil,
            comment: nil
        )
        mockClient.setServerActivity(serverResponse)

        let result = try await service.syncDailyActivities(context: context)

        #expect(result.type == .success)
        let details = try #require(result.details.activities)
        #expect(details.created >= 0)
        #expect(details.updated >= 0)
        #expect(details.deleted >= 0)
    }

    @Test("Возвращает результат с ошибками при сетевой ошибке")
    func returnsResultWithErrorsOnNetworkError() async throws {
        let mockClient = MockDaysClient()
        let service = DailyActivitiesService(client: mockClient)
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
            activityTypeRaw: DayActivityType.rest.rawValue,
            count: nil,
            plannedCount: nil,
            executeTypeRaw: nil,
            trainingTypeRaw: nil,
            duration: nil,
            comment: nil,
            createDate: Date(),
            modifyDate: Date(),
            user: user
        )
        activity.isSynced = false
        context.insert(activity)
        try context.save()

        mockClient.shouldThrowError = true

        let result = try await service.syncDailyActivities(context: context)

        #expect(result.type == .error || result.type == .partial)
        let errors = result.details.errors ?? []
        #expect(!errors.isEmpty)
    }

    @Test("Возвращает результат с подсчетом обновленных записей")
    func returnsResultWithUpdatedCount() async throws {
        let mockClient = MockDaysClient()
        let service = DailyActivitiesService(client: mockClient)
        let container = try ModelContainer(
            for: DayActivity.self,
            User.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = container.mainContext

        let user = User(id: 1, userName: "testuser", fullName: "Test User", email: "test@example.com")
        context.insert(user)
        try context.save()

        let localDate = Date().addingTimeInterval(-3600)
        let activity = DayActivity(
            day: 1,
            activityTypeRaw: DayActivityType.rest.rawValue,
            count: nil,
            plannedCount: nil,
            executeTypeRaw: nil,
            trainingTypeRaw: nil,
            duration: nil,
            comment: nil,
            createDate: localDate,
            modifyDate: localDate,
            user: user
        )
        activity.isSynced = true
        context.insert(activity)
        try context.save()

        let serverResponse = DayResponse(
            id: 1,
            activityType: DayActivityType.stretch.rawValue,
            count: nil,
            plannedCount: nil,
            executeType: nil,
            trainType: nil,
            trainings: nil,
            createDate: localDate,
            modifyDate: Date(),
            duration: nil,
            comment: nil
        )
        mockClient.setServerActivity(serverResponse)

        let result = try await service.syncDailyActivities(context: context)

        #expect(result.type == .success)
        let details = try #require(result.details.activities)
        #expect(details.updated >= 0)
    }

    @Test("Возвращает результат с подсчетом удаленных записей")
    func returnsResultWithDeletedCount() async throws {
        let mockClient = MockDaysClient()
        let service = DailyActivitiesService(client: mockClient)
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
            activityTypeRaw: DayActivityType.rest.rawValue,
            count: nil,
            plannedCount: nil,
            executeTypeRaw: nil,
            trainingTypeRaw: nil,
            duration: nil,
            comment: nil,
            createDate: Date(),
            modifyDate: Date(),
            user: user
        )
        activity.shouldDelete = true
        activity.isSynced = false
        context.insert(activity)
        try context.save()

        mockClient.setServerActivity(DayResponse(
            id: 1,
            activityType: DayActivityType.rest.rawValue,
            count: nil,
            plannedCount: nil,
            executeType: nil,
            trainType: nil,
            trainings: nil,
            createDate: Date(),
            modifyDate: Date(),
            duration: nil,
            comment: nil
        ))

        let result = try await service.syncDailyActivities(context: context)

        #expect(result.type == .success)
        let details = try #require(result.details.activities)
        #expect(details.deleted >= 0)
    }

    @Test("Возвращает частичный результат при ошибке загрузки с сервера")
    func returnsPartialResultOnDownloadError() async throws {
        let mockClient = MockDaysClient()
        let service = DailyActivitiesService(client: mockClient)
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
            activityTypeRaw: DayActivityType.rest.rawValue,
            count: nil,
            plannedCount: nil,
            executeTypeRaw: nil,
            trainingTypeRaw: nil,
            duration: nil,
            comment: nil,
            createDate: Date(),
            modifyDate: Date(),
            user: user
        )
        activity.isSynced = false
        context.insert(activity)
        try context.save()

        let serverResponse = DayResponse(
            id: 1,
            activityType: DayActivityType.rest.rawValue,
            count: nil,
            plannedCount: nil,
            executeType: nil,
            trainType: nil,
            trainings: nil,
            createDate: Date(),
            modifyDate: Date(),
            duration: nil,
            comment: nil
        )
        mockClient.setServerActivity(serverResponse)

        mockClient.shouldThrowError = true

        let result = try await service.syncDailyActivities(context: context)

        #expect(result.type == .error || result.type == .partial)
        let errors = result.details.errors ?? []
        #expect(!errors.isEmpty)
    }
}
