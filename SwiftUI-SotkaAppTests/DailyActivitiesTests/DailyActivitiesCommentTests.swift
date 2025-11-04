import Foundation
import SwiftData
@testable import SwiftUI_SotkaApp
import SWUtils
import Testing

// MARK: - Обновление комментария

extension DailyActivitiesServiceTests {
    @Test("Создает комментарий для существующей активности")
    func updateCommentForExistingActivity() throws {
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

        let comment = "Отличная тренировка!"
        service.updateComment(day: 1, comment: comment, context: context)

        let updatedActivity = try #require(context.fetch(FetchDescriptor<DayActivity>()).first)
        let updatedComment = try #require(updatedActivity.comment)
        #expect(updatedComment == comment)
    }

    @Test("Обновляет существующий комментарий")
    func updateExistingComment() throws {
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
            comment: "Старый комментарий",
            createDate: .now,
            modifyDate: .now,
            user: user
        )
        activity.isSynced = true
        context.insert(activity)
        try context.save()

        let newComment = "Новый комментарий"
        service.updateComment(day: 1, comment: newComment, context: context)

        let updatedActivity = try #require(context.fetch(FetchDescriptor<DayActivity>()).first)
        let updatedComment = try #require(updatedActivity.comment)
        #expect(updatedComment == newComment)
    }

    @Test("Удаляет комментарий при установке nil")
    func deleteCommentWithNil() throws {
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
            comment: "Комментарий для удаления",
            createDate: .now,
            modifyDate: .now,
            user: user
        )
        activity.isSynced = true
        context.insert(activity)
        try context.save()

        service.updateComment(day: 1, comment: nil, context: context)

        let updatedActivity = try #require(context.fetch(FetchDescriptor<DayActivity>()).first)
        #expect(updatedActivity.comment == nil)
    }

    @Test("Устанавливает isSynced = false при обновлении комментария")
    func updateCommentSetsIsSyncedFalse() throws {
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

        service.updateComment(day: 1, comment: "Новый комментарий", context: context)

        let updatedActivity = try #require(context.fetch(FetchDescriptor<DayActivity>()).first)
        #expect(!updatedActivity.isSynced)
    }

    @Test("Обновляет modifyDate при изменении комментария")
    func updateCommentUpdatesModifyDate() async throws {
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

        let oldDate = Date(timeIntervalSinceNow: -3600)
        let activity = DayActivity(
            day: 1,
            activityTypeRaw: 1,
            count: 5,
            createDate: oldDate,
            modifyDate: oldDate,
            user: user
        )
        activity.isSynced = true
        context.insert(activity)
        try context.save()

        try await Task.sleep(nanoseconds: 100_000_000)

        service.updateComment(day: 1, comment: "Новый комментарий", context: context)

        let updatedActivity = try #require(context.fetch(FetchDescriptor<DayActivity>()).first)
        #expect(updatedActivity.modifyDate > oldDate)
    }

    @Test("Создает активность для несуществующего дня при обновлении комментария")
    func updateCommentCreatesActivityForNonExistentDay() throws {
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

        let comment = "Комментарий для нового дня"
        service.updateComment(day: 5, comment: comment, context: context)

        let activities = try context.fetch(FetchDescriptor<DayActivity>())
        #expect(activities.count == 1)
        let createdActivity = try #require(activities.first)
        #expect(createdActivity.day == 5)
        let createdComment = try #require(createdActivity.comment)
        #expect(createdComment == comment)
        #expect(!createdActivity.isSynced)
    }
}
