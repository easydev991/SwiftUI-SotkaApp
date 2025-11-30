import Foundation
import SwiftData
@testable import SwiftUI_SotkaApp
import SWUtils
import Testing

// MARK: - Синхронизация с trainings

extension DailyActivitiesServiceTests {
    @Test("Синхронизирует активности с trainings")
    func syncActivitiesWithTrainings() async throws {
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
        let training1 = DayActivityTraining(count: 10, typeId: 1, dayActivity: activity)
        let training2 = DayActivityTraining(count: 15, typeId: 2, dayActivity: activity)
        activity.trainings.append(training1)
        activity.trainings.append(training2)
        context.insert(activity)
        try context.save()

        _ = try await service.syncDailyActivities(context: context)

        let savedActivity = try #require(context.fetch(FetchDescriptor<DayActivity>()).first)
        #expect(savedActivity.trainings.count == 2)
        #expect(savedActivity.isSynced)
        #expect(mockClient.updateDayCallCount > 0)
    }

    @Test("Обновляет trainings при синхронизации с сервера")
    func updateTrainingsFromServer() async throws {
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
        let training = DayActivityTraining(count: 10, typeId: 1, dayActivity: activity)
        activity.trainings.append(training)
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
            trainings: [
                DayResponse.Training(typeId: 2, customTypeId: nil, count: 20, sortOrder: 0),
                DayResponse.Training(typeId: 3, customTypeId: nil, count: 25, sortOrder: 1)
            ],
            createDate: Date().addingTimeInterval(-3600),
            modifyDate: Date(),
            duration: nil,
            comment: nil
        )
        mockClient.setServerActivity(serverResponse)

        _ = try await service.syncDailyActivities(context: context)

        let updatedActivity = try #require(context.fetch(FetchDescriptor<DayActivity>()).first)
        #expect(updatedActivity.trainings.count == 2)
        #expect(updatedActivity.trainings.allSatisfy { $0.typeId != 1 })
        #expect(updatedActivity.trainings.contains { $0.typeId == 2 && $0.count == 20 })
        #expect(updatedActivity.trainings.contains { $0.typeId == 3 && $0.count == 25 })
    }

    @Test("Метод hasDataChanged проверяет изменения в trainings")
    func hasDataChangedChecksTrainings() throws {
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
        let training = DayActivityTraining(count: 10, typeId: 1, dayActivity: activity)
        activity.trainings.append(training)
        context.insert(activity)
        try context.save()

        let responseWithSameTrainings = DayResponse(
            id: 1,
            activityType: 1,
            count: 5,
            plannedCount: nil,
            executeType: nil,
            trainType: nil,
            trainings: [DayResponse.Training(typeId: 1, customTypeId: nil, count: 10, sortOrder: 0)],
            createDate: Date(),
            modifyDate: Date(),
            duration: nil,
            comment: nil
        )
        #expect(!activity.hasDataChanged(comparedTo: responseWithSameTrainings))

        let responseWithDifferentTrainingsCount = DayResponse(
            id: 1,
            activityType: 1,
            count: 5,
            plannedCount: nil,
            executeType: nil,
            trainType: nil,
            trainings: [
                DayResponse.Training(typeId: 1, customTypeId: nil, count: 10, sortOrder: 0),
                DayResponse.Training(typeId: 2, customTypeId: nil, count: 15, sortOrder: 1)
            ],
            createDate: Date(),
            modifyDate: Date(),
            duration: nil,
            comment: nil
        )
        #expect(activity.hasDataChanged(comparedTo: responseWithDifferentTrainingsCount))
    }
}
