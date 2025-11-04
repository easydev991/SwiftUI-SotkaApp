import Foundation
import SwiftData
@testable import SwiftUI_SotkaApp
import SWUtils
import Testing

// MARK: - Разрешение конфликтов и загрузка с сервера

extension DailyActivitiesServiceTests {
    @Test("Пропускает обновление если данные не изменились и активность синхронизирована")
    func skipUpdateWhenDataNotChangedAndSynced() async throws {
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

        let localDate = Date().addingTimeInterval(-3600)
        let activity = DayActivity(
            day: 1,
            activityTypeRaw: 1,
            count: 5,
            createDate: localDate,
            modifyDate: localDate,
            user: user
        )
        activity.isSynced = true
        context.insert(activity)
        try context.save()

        let serverDate = Date().addingTimeInterval(-1800)
        let serverResponse = DayResponse(
            id: 1,
            activityType: 1,
            count: 5,
            plannedCount: nil,
            executeType: nil,
            trainType: nil,
            trainings: nil,
            createDate: DateFormatterService.stringFromFullDate(localDate, format: .serverDateTimeSec),
            modifyDate: DateFormatterService.stringFromFullDate(serverDate, format: .serverDateTimeSec),
            duration: nil,
            comment: nil
        )
        mockClient.setServerActivity(serverResponse)

        await service.syncDailyActivities(context: context)

        let updatedActivity = try #require(context.fetch(FetchDescriptor<DayActivity>()).first)
        #expect(updatedActivity.count == 5)
        #expect(updatedActivity.isSynced)
    }

    @Test("Обновляет локальную версию когда данные изменились и серверная версия новее или равна")
    func updateWhenDataChangedAndServerNewer() async throws {
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

        let localModifyDate = Date().addingTimeInterval(-3600)
        let activity = DayActivity(
            day: 1,
            activityTypeRaw: 1,
            count: 5,
            createDate: Date().addingTimeInterval(-7200),
            modifyDate: localModifyDate,
            user: user
        )
        activity.isSynced = true
        context.insert(activity)
        try context.save()

        let serverModifyDate = Date().addingTimeInterval(-1800)
        let serverResponse = DayResponse(
            id: 1,
            activityType: 1,
            count: 10,
            plannedCount: nil,
            executeType: nil,
            trainType: nil,
            trainings: nil,
            createDate: DateFormatterService.stringFromFullDate(Date().addingTimeInterval(-7200), format: .serverDateTimeSec),
            modifyDate: DateFormatterService.stringFromFullDate(serverModifyDate, format: .serverDateTimeSec),
            duration: nil,
            comment: nil
        )
        mockClient.setServerActivity(serverResponse)

        await service.syncDailyActivities(context: context)

        let updatedActivity = try #require(context.fetch(FetchDescriptor<DayActivity>()).first)
        #expect(updatedActivity.count == 10)
        #expect(updatedActivity.isSynced)
    }

    @Test("Пропускает обновление когда данные изменились но локальная версия новее серверной")
    func skipUpdateWhenDataChangedButLocalNewer() async throws {
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

        // Используем фиксированную дату для точного сравнения
        let baseDate = Date(timeIntervalSince1970: 1_700_000_000)
        // Серверная дата: 2 часа назад
        let serverModifyDate = baseDate.addingTimeInterval(-7200)
        // Локальная дата: 30 минут назад (новее серверной на 5400 секунд = 1.5 часа)
        let localModifyDate = baseDate.addingTimeInterval(-1800)

        // Проверяем, что локальная дата действительно новее серверной
        let initialDifference = localModifyDate.timeIntervalSince1970 - serverModifyDate.timeIntervalSince1970
        #expect(initialDifference > 0, "Локальная дата должна быть новее серверной изначально")

        let activity = DayActivity(
            day: 1,
            activityTypeRaw: 1,
            count: 5,
            createDate: baseDate.addingTimeInterval(-14400),
            modifyDate: localModifyDate,
            user: user
        )
        activity.isSynced = true
        context.insert(activity)
        try context.save()

        // Используем UTC для согласованности парсинга
        let utcTimeZone = TimeZone(secondsFromGMT: 0)
        let serverResponse = DayResponse(
            id: 1,
            activityType: 1,
            count: 10,
            plannedCount: nil,
            executeType: nil,
            trainType: nil,
            trainings: nil,
            createDate: DateFormatterService.stringFromFullDate(
                baseDate.addingTimeInterval(-14400),
                format: .serverDateTimeSec,
                timeZone: utcTimeZone,
                iso: false
            ),
            modifyDate: DateFormatterService.stringFromFullDate(
                serverModifyDate,
                format: .serverDateTimeSec,
                timeZone: utcTimeZone,
                iso: false
            ),
            duration: nil,
            comment: nil
        )
        mockClient.setServerActivity(serverResponse)

        await service.syncDailyActivities(context: context)

        let updatedActivity = try #require(context.fetch(FetchDescriptor<DayActivity>()).first)
        let parsedServerDate = DateFormatterService.dateFromString(
            serverResponse.modifyDate ?? "",
            format: .serverDateTimeSec
        )

        // Проверяем разницу дат после синхронизации
        // Используем исходную локальную дату для сравнения, чтобы избежать потери точности при сохранении/извлечении
        let expectedLocalDate = localModifyDate.timeIntervalSince1970
        let actualLocalDate = updatedActivity.modifyDate.timeIntervalSince1970
        let serverDate = parsedServerDate.timeIntervalSince1970

        // Проверяем, что локальная дата не была заменена серверной (должна остаться близкой к исходной)
        let localDatePreserved = abs(actualLocalDate - expectedLocalDate) < 1.0

        #expect(updatedActivity.count == 5)
        #expect(updatedActivity.isSynced)
        #expect(
            localDatePreserved || actualLocalDate > serverDate,
            "Локальная дата должна остаться новее серверной после синхронизации. Локальная: \(actualLocalDate), Серверная: \(serverDate), Исходная: \(expectedLocalDate)"
        )
    }

    @Test("Не перезаписывает несинхронизированные локальные изменения")
    func unsyncedLocalChangesNotOverwritten() async throws {
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

        let localModifyDate = Date()
        let activity = DayActivity(
            day: 1,
            activityTypeRaw: 1,
            count: 5,
            createDate: Date().addingTimeInterval(-7200),
            modifyDate: localModifyDate,
            user: user
        )
        activity.isSynced = false
        context.insert(activity)
        try context.save()

        let serverModifyDate = Date().addingTimeInterval(-1800)
        let serverResponse = DayResponse(
            id: 1,
            activityType: 1,
            count: 10,
            plannedCount: nil,
            executeType: nil,
            trainType: nil,
            trainings: nil,
            createDate: DateFormatterService.stringFromFullDate(Date().addingTimeInterval(-7200), format: .serverDateTimeSec),
            modifyDate: DateFormatterService.stringFromFullDate(serverModifyDate, format: .serverDateTimeSec),
            duration: nil,
            comment: nil
        )
        mockClient.setServerActivity(serverResponse)

        await service.syncDailyActivities(context: context)

        let updatedActivity = try #require(context.fetch(FetchDescriptor<DayActivity>()).first)
        #expect(updatedActivity.count == 5)
        #expect(!updatedActivity.isSynced)
    }

    @Test("Метод hasDataChanged корректно определяет изменения")
    func hasDataChangedWorksCorrectly() throws {
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

        let sameResponse = DayResponse(
            id: 1,
            activityType: 1,
            count: 5,
            plannedCount: nil,
            executeType: nil,
            trainType: nil,
            trainings: nil,
            createDate: DateFormatterService.stringFromFullDate(Date(), format: .serverDateTimeSec),
            modifyDate: DateFormatterService.stringFromFullDate(Date(), format: .serverDateTimeSec),
            duration: nil,
            comment: nil
        )
        #expect(!activity.hasDataChanged(comparedTo: sameResponse))

        let differentResponse = DayResponse(
            id: 1,
            activityType: 1,
            count: 10,
            plannedCount: nil,
            executeType: nil,
            trainType: nil,
            trainings: nil,
            createDate: DateFormatterService.stringFromFullDate(Date(), format: .serverDateTimeSec),
            modifyDate: DateFormatterService.stringFromFullDate(Date(), format: .serverDateTimeSec),
            duration: nil,
            comment: nil
        )
        #expect(activity.hasDataChanged(comparedTo: differentResponse))
    }

    @Test("Загружает новые активности с сервера")
    func downloadNewActivitiesFromServer() async throws {
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

        let serverResponse = DayResponse(
            id: 1,
            activityType: 1,
            count: 5,
            plannedCount: nil,
            executeType: nil,
            trainType: nil,
            trainings: nil,
            createDate: DateFormatterService.stringFromFullDate(Date().addingTimeInterval(-3600), format: .serverDateTimeSec),
            modifyDate: DateFormatterService.stringFromFullDate(Date().addingTimeInterval(-1800), format: .serverDateTimeSec),
            duration: nil,
            comment: nil
        )
        mockClient.setServerActivity(serverResponse)

        await service.syncDailyActivities(context: context)

        let activities = try context.fetch(FetchDescriptor<DayActivity>())
        #expect(activities.count == 1)
        let newActivity = try #require(activities.first)
        #expect(newActivity.day == 1)
        #expect(newActivity.count == 5)
        #expect(newActivity.isSynced)
    }

    @Test("Физически удаляет синхронизированные активности отсутствующие на сервере")
    func physicallyDeleteSyncedActivitiesMissingOnServer() async throws {
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

        await service.syncDailyActivities(context: context)

        let activities = try context.fetch(FetchDescriptor<DayActivity>())
        #expect(activities.isEmpty)
    }

    @Test("Обновляет существующую активность при конфликте дня")
    func updateExistingActivityOnDayConflict() throws {
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

        let existingActivity = DayActivity(
            day: 1,
            activityTypeRaw: 1,
            count: 5,
            createDate: .now,
            modifyDate: .now,
            user: user
        )
        context.insert(existingActivity)
        try context.save()

        let newActivity = DayActivity(
            day: 1,
            activityTypeRaw: 1,
            count: 10,
            createDate: .now,
            modifyDate: .now
        )

        service.createDailyActivity(newActivity, context: context)

        let activities = try context.fetch(FetchDescriptor<DayActivity>())
        #expect(activities.count == 1)
        let updatedActivity = try #require(activities.first)
        #expect(updatedActivity.count == 10)
        #expect(!updatedActivity.isSynced)
    }
}
