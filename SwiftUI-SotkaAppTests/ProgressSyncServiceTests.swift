import Foundation
import SwiftData
@testable import SwiftUI_SotkaApp
import SWUtils
import Testing

@MainActor
struct ProgressSyncServiceTests {
    @Test("Синхронизация нового прогресса - создание")
    func syncNewProgressCreation() async throws {
        // Arrange
        let mockClient = MockProgressClient()
        let service = ProgressSyncService(client: mockClient)
        let container = try ModelContainer(
            for: Progress.self,
            User.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = container.mainContext

        // Создаем пользователя
        let user = User(id: 1, userName: "testuser", fullName: "Test User", email: "test@example.com")
        context.insert(user)
        try context.save()

        // Создаем локальный прогресс (несинхронизированный)
        let progress = Progress(id: 1, pullUps: 10, pushUps: 20, squats: 30, weight: 70.0)
        progress.user = user
        progress.isSynced = false
        progress.lastModified = Date()
        context.insert(progress)
        try context.save()

        // Мокаем успешный ответ сервера
        let serverResponse = ProgressResponse(
            id: 1,
            pullups: 10,
            pushups: 20,
            squats: 30,
            weight: 70.0,
            createDate: DateFormatterService.stringFromFullDate(Date(), format: .serverDateTimeSec),
            modifyDate: DateFormatterService.stringFromFullDate(Date(), format: .serverDateTimeSec)
        )
        mockClient.mockedProgressResponses = [serverResponse]

        // Act
        await service.syncProgress(context: context)

        // Assert
        let syncedProgress = try #require(context.fetch(FetchDescriptor<SwiftUI_SotkaApp.Progress>()).first)
        #expect(syncedProgress.isSynced)
        #expect(!syncedProgress.shouldDelete)
        #expect(syncedProgress.pullUps == 10)
        #expect(syncedProgress.pushUps == 20)
        #expect(syncedProgress.squats == 30)
        #expect(syncedProgress.weight == 70.0)
    }

    @Test("Синхронизация обновления существующего прогресса")
    func syncExistingProgressUpdate() async throws {
        // Arrange
        let mockClient = MockProgressClient()
        let service = ProgressSyncService(client: mockClient)
        let container = try ModelContainer(
            for: Progress.self,
            User.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = container.mainContext

        // Создаем пользователя
        let user = User(id: 1, userName: "testuser", fullName: "Test User", email: "test@example.com")
        context.insert(user)
        try context.save()

        // Создаем локальный синхронизированный прогресс
        let progress = Progress(id: 1, pullUps: 10, pushUps: 20, squats: 30, weight: 70.0)
        progress.user = user
        progress.isSynced = true
        progress.lastModified = Date().addingTimeInterval(-3600) // 1 час назад
        context.insert(progress)
        try context.save()

        // Мокаем обновленные данные с сервера
        let serverResponse = ProgressResponse(
            id: 1,
            pullups: 15, // Изменено
            pushups: 25, // Изменено
            squats: 35, // Изменено
            weight: 72.0, // Изменено
            createDate: DateFormatterService.stringFromFullDate(Date().addingTimeInterval(-7200), format: .serverDateTimeSec),
            modifyDate: DateFormatterService.stringFromFullDate(Date(), format: .serverDateTimeSec) // Новее локального
        )
        mockClient.mockedProgressResponses = [serverResponse]

        // Act
        await service.syncProgress(context: context)

        // Assert
        let updatedProgress = try #require(context.fetch(FetchDescriptor<SwiftUI_SotkaApp.Progress>()).first)
        #expect(updatedProgress.pullUps == 15)
        #expect(updatedProgress.pushUps == 25)
        #expect(updatedProgress.squats == 35)
        #expect(updatedProgress.weight == 72.0)
        #expect(updatedProgress.isSynced)
    }

    @Test("LWW конфликт-резолюшн - локальная версия новее")
    func conflictResolutionLocalNewer() async throws {
        // Arrange
        let mockClient = MockProgressClient()
        let service = ProgressSyncService(client: mockClient)
        let container = try ModelContainer(
            for: Progress.self,
            User.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = container.mainContext

        // Создаем пользователя
        let user = User(id: 1, userName: "testuser", fullName: "Test User", email: "test@example.com")
        context.insert(user)
        try context.save()

        // Создаем локальный прогресс с более новой датой
        let localModifyDate = Date()
        let progress = Progress(id: 1, pullUps: 10, pushUps: 20, squats: 30, weight: 70.0)
        progress.user = user
        progress.isSynced = true // Синхронизированный прогресс (не отправляется на сервер)
        progress.lastModified = localModifyDate
        context.insert(progress)
        try context.save()

        // Мокаем серверные данные с более старой датой
        let serverModifyDate = localModifyDate.addingTimeInterval(-3600) // 1 час назад
        let serverResponse = ProgressResponse(
            id: 1,
            pullups: 99, // Другие данные
            pushups: 99,
            squats: 99,
            weight: 99.0,
            createDate: DateFormatterService.stringFromFullDate(Date().addingTimeInterval(-7200), format: .serverDateTimeSec, iso: false),
            modifyDate: DateFormatterService.stringFromFullDate(serverModifyDate, format: .serverDateTimeSec, iso: false)
        )
        mockClient.mockedProgressResponses = [serverResponse]

        // Act
        await service.syncProgress(context: context)

        // Assert - локальные данные должны сохраниться
        let updatedProgress = try #require(context.fetch(FetchDescriptor<SwiftUI_SotkaApp.Progress>()).first)
        #expect(updatedProgress.pullUps == 10, "Локальные данные должны сохраниться")
        #expect(updatedProgress.pushUps == 20)
        #expect(updatedProgress.squats == 30)
        #expect(updatedProgress.weight == 70.0)
    }

    @Test("LWW конфликт-резолюшн - серверная версия новее")
    func conflictResolutionServerNewer() async throws {
        // Arrange
        let mockClient = MockProgressClient()
        let service = ProgressSyncService(client: mockClient)
        let container = try ModelContainer(
            for: Progress.self,
            User.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = container.mainContext

        // Создаем пользователя
        let user = User(id: 1, userName: "testuser", fullName: "Test User", email: "test@example.com")
        context.insert(user)
        try context.save()

        // Создаем локальный прогресс со старой датой
        let progress = Progress(id: 1, pullUps: 10, pushUps: 20, squats: 30, weight: 70.0)
        progress.user = user
        progress.isSynced = true
        progress.lastModified = Date().addingTimeInterval(-3600) // 1 час назад
        context.insert(progress)
        try context.save()

        // Мокаем серверные данные с более новой датой
        let serverModifyDate = Date() // Текущее время, новее локального
        let serverResponse = ProgressResponse(
            id: 1,
            pullups: 15, // Новые данные
            pushups: 25,
            squats: 35,
            weight: 72.0,
            createDate: DateFormatterService.stringFromFullDate(Date().addingTimeInterval(-7200), format: .serverDateTimeSec),
            modifyDate: DateFormatterService.stringFromFullDate(serverModifyDate, format: .serverDateTimeSec)
        )
        mockClient.mockedProgressResponses = [serverResponse]

        // Act
        await service.syncProgress(context: context)

        // Assert - серверные данные должны быть применены
        let updatedProgress = try #require(context.fetch(FetchDescriptor<SwiftUI_SotkaApp.Progress>()).first)
        #expect(updatedProgress.pullUps == 15, "Серверные данные должны быть применены")
        #expect(updatedProgress.pushUps == 25)
        #expect(updatedProgress.squats == 35)
        #expect(updatedProgress.weight == 72.0)
    }

    @Test("Удаление прогресса помеченного для удаления")
    func deleteMarkedForDeletionProgress() async throws {
        // Arrange
        let mockClient = MockProgressClient()
        let service = ProgressSyncService(client: mockClient)
        let container = try ModelContainer(
            for: Progress.self,
            User.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = container.mainContext

        // Создаем пользователя
        let user = User(id: 1, userName: "testuser", fullName: "Test User", email: "test@example.com")
        context.insert(user)
        try context.save()

        // Создаем локальный прогресс, помеченный для удаления
        let progress = Progress(id: 1, pullUps: 10, pushUps: 20, squats: 30, weight: 70.0)
        progress.user = user
        progress.shouldDelete = true
        progress.isSynced = false
        context.insert(progress)
        try context.save()

        // Act
        await service.syncProgress(context: context)

        // Assert
        let allProgress = try context.fetch(FetchDescriptor<SwiftUI_SotkaApp.Progress>())
        #expect(allProgress.isEmpty, "Прогресс должен быть удален")
    }

    @Test("Создание нового прогресса с сервера")
    func createNewProgressFromServer() async throws {
        // Arrange
        let mockClient = MockProgressClient()
        let service = ProgressSyncService(client: mockClient)
        let container = try ModelContainer(
            for: Progress.self,
            User.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = container.mainContext

        // Создаем пользователя
        let user = User(id: 1, userName: "testuser", fullName: "Test User", email: "test@example.com")
        context.insert(user)
        try context.save()

        // Мокаем серверный ответ с новым прогрессом (локально отсутствует)
        let serverResponse = ProgressResponse(
            id: 50, // Новый день
            pullups: 15,
            pushups: 25,
            squats: 35,
            weight: 72.0,
            createDate: DateFormatterService.stringFromFullDate(Date(), format: .serverDateTimeSec),
            modifyDate: DateFormatterService.stringFromFullDate(Date(), format: .serverDateTimeSec)
        )
        mockClient.mockedProgressResponses = [serverResponse]

        // Act
        await service.syncProgress(context: context)

        // Assert
        let allProgress = try context.fetch(FetchDescriptor<SwiftUI_SotkaApp.Progress>())
        #expect(allProgress.count == 1)
        let newProgress = try #require(allProgress.first)
        #expect(newProgress.id == 50)
        #expect(newProgress.pullUps == 15)
        #expect(newProgress.pushUps == 25)
        #expect(newProgress.squats == 35)
        #expect(newProgress.weight == 72.0)
        #expect(newProgress.isSynced)
        #expect(!newProgress.shouldDelete)
    }

    @Test("Обработка удаленного на сервере прогресса")
    func handleServerDeletedProgress() async throws {
        // Arrange
        let mockClient = MockProgressClient()
        let service = ProgressSyncService(client: mockClient)
        let container = try ModelContainer(
            for: Progress.self,
            User.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = container.mainContext

        // Создаем пользователя
        let user = User(id: 1, userName: "testuser", fullName: "Test User", email: "test@example.com")
        context.insert(user)
        try context.save()

        // Создаем локальный синхронизированный прогресс
        let progress = Progress(id: 1, pullUps: 10, pushUps: 20, squats: 30, weight: 70.0)
        progress.user = user
        progress.isSynced = true
        context.insert(progress)
        try context.save()

        // Мокаем пустой ответ сервера (прогресс удален на сервере)
        mockClient.mockedProgressResponses = []

        // Act
        await service.syncProgress(context: context)

        // Assert
        let allProgress = try context.fetch(FetchDescriptor<SwiftUI_SotkaApp.Progress>())
        #expect(allProgress.count == 1)
        let updatedProgress = try #require(allProgress.first)
        #expect(updatedProgress.shouldDelete, "Должен быть помечен для удаления")
        #expect(!updatedProgress.isSynced, "Должен быть несинхронизированным")
    }

    @Test("Обработка ошибок сети при синхронизации")
    func handleNetworkErrors() async throws {
        // Arrange
        let mockClient = MockProgressClient()
        let service = ProgressSyncService(client: mockClient)
        let container = try ModelContainer(
            for: Progress.self,
            User.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = container.mainContext

        // Создаем пользователя
        let user = User(id: 1, userName: "testuser", fullName: "Test User", email: "test@example.com")
        context.insert(user)
        try context.save()

        // Создаем локальный несинхронизированный прогресс
        let progress = Progress(id: 1, pullUps: 10, pushUps: 20, squats: 30, weight: 70.0)
        progress.user = user
        progress.isSynced = false
        context.insert(progress)
        try context.save()

        // Мокаем ошибку сети
        mockClient.shouldThrowError = true

        // Act
        await service.syncProgress(context: context)

        // Assert - локальный прогресс должен остаться без изменений
        let unchangedProgress = try #require(context.fetch(FetchDescriptor<SwiftUI_SotkaApp.Progress>()).first)
        #expect(!unchangedProgress.isSynced, "Должен остаться несинхронизированным")
        #expect(!unchangedProgress.shouldDelete)
        #expect(unchangedProgress.pullUps == 10)
    }
}

// MARK: - Mock клиенты

@MainActor
private class MockProgressClient: ProgressClient {
    var mockedProgressResponses: [ProgressResponse] = []
    var shouldThrowError = false

    func getProgress() async throws -> [ProgressResponse] {
        if shouldThrowError {
            throw NSError(domain: "TestError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Test error"])
        }
        return mockedProgressResponses
    }

    func createProgress(progress: ProgressRequest) async throws -> ProgressResponse {
        if shouldThrowError {
            throw NSError(domain: "TestError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Test error"])
        }
        return ProgressResponse(
            id: progress.id,
            pullups: progress.pullups,
            pushups: progress.pushups,
            squats: progress.squats,
            weight: progress.weight,
            createDate: DateFormatterService.stringFromFullDate(Date(), format: .serverDateTimeSec),
            modifyDate: progress.modifyDate
        )
    }

    func updateProgress(day _: Int, progress: ProgressRequest) async throws -> ProgressResponse {
        if shouldThrowError {
            throw NSError(domain: "TestError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Test error"])
        }
        return ProgressResponse(
            id: progress.id,
            pullups: progress.pullups,
            pushups: progress.pushups,
            squats: progress.squats,
            weight: progress.weight,
            createDate: DateFormatterService.stringFromFullDate(Date(), format: .serverDateTimeSec),
            modifyDate: progress.modifyDate
        )
    }

    func deleteProgress(day _: Int) async throws {
        if shouldThrowError {
            throw NSError(domain: "TestError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Test error"])
        }
    }
}
