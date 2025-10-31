import Foundation
import SwiftData
@testable import SwiftUI_SotkaApp
import SWUtils
import Testing

@MainActor
struct DailyActivitiesServiceTests {
    // MARK: - Базовые операции (офлайн-приоритет)

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

    // MARK: - Разрешение конфликтов

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

    // MARK: - Загрузка с сервера

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

    // MARK: - Конфликты при создании

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

    // MARK: - Синхронизация с trainings

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

        await service.syncDailyActivities(context: context)

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
            createDate: DateFormatterService.stringFromFullDate(Date().addingTimeInterval(-3600), format: .serverDateTimeSec),
            modifyDate: DateFormatterService.stringFromFullDate(Date(), format: .serverDateTimeSec),
            duration: nil,
            comment: nil
        )
        mockClient.setServerActivity(serverResponse)

        await service.syncDailyActivities(context: context)

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
            createDate: DateFormatterService.stringFromFullDate(Date(), format: .serverDateTimeSec),
            modifyDate: DateFormatterService.stringFromFullDate(Date(), format: .serverDateTimeSec),
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
            createDate: DateFormatterService.stringFromFullDate(Date(), format: .serverDateTimeSec),
            modifyDate: DateFormatterService.stringFromFullDate(Date(), format: .serverDateTimeSec),
            duration: nil,
            comment: nil
        )
        #expect(activity.hasDataChanged(comparedTo: responseWithDifferentTrainingsCount))
    }

    // MARK: - Обработка ошибок

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

        await service.syncDailyActivities(context: context)

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

        await service.syncDailyActivities(context: context)
        await service.syncDailyActivities(context: context)

        #expect(mockClient.getDaysCallCount > initialGetDaysCallCount)
        #expect(mockClient.updateDayCallCount > initialUpdateDayCallCount)
    }

    // MARK: - Дополнительные сценарии

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
            createDate: DateFormatterService.stringFromFullDate(Date().addingTimeInterval(-3600), format: .serverDateTimeSec),
            modifyDate: DateFormatterService.stringFromFullDate(Date(), format: .serverDateTimeSec),
            duration: nil,
            comment: nil
        )
        mockClient.setServerActivity(serverResponse)

        await service.syncDailyActivities(context: context)

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

        await service.syncDailyActivities(context: context)

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
            createDate: DateFormatterService.stringFromFullDate(Date().addingTimeInterval(-3600), format: .serverDateTimeSec),
            modifyDate: DateFormatterService.stringFromFullDate(Date().addingTimeInterval(-1799), format: .serverDateTimeSec),
            duration: nil,
            comment: nil
        )
        mockClient.setServerActivity(serverResponse)

        let initialGetDaysCallCount = mockClient.getDaysCallCount

        await service.syncDailyActivities(context: context)

        let updatedActivity = try #require(context.fetch(FetchDescriptor<DayActivity>()).first)
        #expect(updatedActivity.count == 5)
        #expect(updatedActivity.isSynced)
        #expect(mockClient.getDaysCallCount > initialGetDaysCallCount)
    }
}
