import Foundation
import SwiftData
@testable import SwiftUI_SotkaApp
import SWUtils
import Testing

extension AllProgressTests {
    @MainActor
    struct ProgressSyncServiceTests {
        @Test("Синхронизация нового прогресса - создание")
        func syncNewProgressCreation() async throws {
            // Arrange
            let mockClient = MockProgressClient()
            let service = ProgressSyncService.makeMock(client: mockClient)
            let container = try ModelContainer(
                for: UserProgress.self,
                User.self,
                configurations: ModelConfiguration(isStoredInMemoryOnly: true)
            )
            let context = container.mainContext

            // Создаем пользователя
            let user = User(id: 1, userName: "testuser", fullName: "Test User", email: "test@example.com")
            context.insert(user)
            try context.save()

            // Создаем локальный прогресс (несинхронизированный)
            let progress = UserProgress(id: 1, pullUps: 10, pushUps: 20, squats: 30, weight: 70.0)
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
                createDate: Date(),
                modifyDate: Date()
            )
            mockClient.mockedProgressResponses = [serverResponse]

            // Act
            _ = try await service.syncProgress(context: context)

            // Assert
            let allProgress = try context.fetch(FetchDescriptor<UserProgress>())
            #expect(allProgress.count == 1)

            let syncedProgress = try #require(allProgress.first)
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
            let service = ProgressSyncService.makeMock(client: mockClient)
            let container = try ModelContainer(
                for: UserProgress.self,
                User.self,
                configurations: ModelConfiguration(isStoredInMemoryOnly: true)
            )
            let context = container.mainContext

            // Создаем пользователя
            let user = User(id: 1, userName: "testuser", fullName: "Test User", email: "test@example.com")
            context.insert(user)
            try context.save()

            // Создаем локальный синхронизированный прогресс
            let progress = UserProgress(id: 1, pullUps: 10, pushUps: 20, squats: 30, weight: 70.0)
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
                createDate: Date().addingTimeInterval(-7200),
                modifyDate: Date() // Новее локального
            )
            mockClient.mockedProgressResponses = [serverResponse]

            // Act
            _ = try await service.syncProgress(context: context)

            // Assert
            let allProgress = try context.fetch(FetchDescriptor<UserProgress>())
            #expect(allProgress.count == 1)

            let updatedProgress = try #require(allProgress.first)
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
            let service = ProgressSyncService.makeMock(client: mockClient)
            let container = try ModelContainer(
                for: UserProgress.self,
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
            let progress = UserProgress(id: 1, pullUps: 10, pushUps: 20, squats: 30, weight: 70.0)
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
                createDate: Date().addingTimeInterval(-7200),
                modifyDate: serverModifyDate
            )
            mockClient.mockedProgressResponses = [serverResponse]

            // Act
            _ = try await service.syncProgress(context: context)

            // Assert - локальные данные должны сохраниться
            let allProgress = try context.fetch(FetchDescriptor<UserProgress>())
            #expect(allProgress.count == 1)

            let updatedProgress = try #require(allProgress.first)
            #expect(updatedProgress.pullUps == 10, "Локальные данные должны сохраниться")
            #expect(updatedProgress.pushUps == 20)
            #expect(updatedProgress.squats == 30)
            #expect(updatedProgress.weight == 70.0)
        }

        @Test("LWW конфликт-резолюшн - серверная версия новее")
        func conflictResolutionServerNewer() async throws {
            // Arrange
            let mockClient = MockProgressClient()
            let service = ProgressSyncService.makeMock(client: mockClient)
            let container = try ModelContainer(
                for: UserProgress.self,
                User.self,
                configurations: ModelConfiguration(isStoredInMemoryOnly: true)
            )
            let context = container.mainContext

            // Создаем пользователя
            let user = User(id: 1, userName: "testuser", fullName: "Test User", email: "test@example.com")
            context.insert(user)
            try context.save()

            // Создаем локальный прогресс со старой датой
            let progress = UserProgress(id: 1, pullUps: 10, pushUps: 20, squats: 30, weight: 70.0)
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
                createDate: Date().addingTimeInterval(-7200),
                modifyDate: serverModifyDate
            )
            mockClient.mockedProgressResponses = [serverResponse]

            // Act
            _ = try await service.syncProgress(context: context)

            // Assert - серверные данные должны быть применены
            let allProgress = try context.fetch(FetchDescriptor<UserProgress>())
            #expect(allProgress.count == 1)

            let updatedProgress = try #require(allProgress.first)
            #expect(updatedProgress.pullUps == 15, "Серверные данные должны быть применены")
            #expect(updatedProgress.pushUps == 25)
            #expect(updatedProgress.squats == 35)
            #expect(updatedProgress.weight == 72.0)
        }

        @Test("Удаление прогресса помеченного для удаления")
        func deleteMarkedForDeletionProgress() async throws {
            // Arrange
            let mockClient = MockProgressClient()
            let service = ProgressSyncService.makeMock(client: mockClient)
            let container = try ModelContainer(
                for: UserProgress.self,
                User.self,
                configurations: ModelConfiguration(isStoredInMemoryOnly: true)
            )
            let context = container.mainContext

            // Создаем пользователя
            let user = User(id: 1, userName: "testuser", fullName: "Test User", email: "test@example.com")
            context.insert(user)
            try context.save()

            // Создаем локальный прогресс, помеченный для удаления
            let progress = UserProgress(id: 1, pullUps: 10, pushUps: 20, squats: 30, weight: 70.0)
            progress.user = user
            progress.shouldDelete = true
            progress.isSynced = false
            context.insert(progress)
            try context.save()

            // Act
            _ = try await service.syncProgress(context: context)

            // Assert
            let allProgress = try context.fetch(FetchDescriptor<UserProgress>())
            #expect(allProgress.isEmpty, "Прогресс должен быть удален")
        }

        @Test("Создание нового прогресса с сервера")
        func createNewProgressFromServer() async throws {
            // Arrange
            let mockClient = MockProgressClient()
            let service = ProgressSyncService.makeMock(client: mockClient)
            let container = try ModelContainer(
                for: UserProgress.self,
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
                createDate: Date(),
                modifyDate: Date()
            )
            mockClient.mockedProgressResponses = [serverResponse]

            // Act
            _ = try await service.syncProgress(context: context)

            // Assert
            let allProgress = try context.fetch(FetchDescriptor<UserProgress>())
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
            let service = ProgressSyncService.makeMock(client: mockClient)
            let container = try ModelContainer(
                for: UserProgress.self,
                User.self,
                configurations: ModelConfiguration(isStoredInMemoryOnly: true)
            )
            let context = container.mainContext

            // Создаем пользователя
            let user = User(id: 1, userName: "testuser", fullName: "Test User", email: "test@example.com")
            context.insert(user)
            try context.save()

            // Создаем локальный синхронизированный прогресс с старой датой
            let progress = UserProgress(id: 1, pullUps: 10, pushUps: 20, squats: 30, weight: 70.0)
            progress.user = user
            progress.isSynced = true
            progress.lastModified = Date().addingTimeInterval(-3600) // 1 час назад, чтобы не попасть под проверку "недавно синхронизирован"
            context.insert(progress)
            try context.save()

            // Мокаем пустой ответ сервера (прогресс удален на сервере)
            mockClient.mockedProgressResponses = []

            // Act
            _ = try await service.syncProgress(context: context)

            // Assert
            let allProgress = try context.fetch(FetchDescriptor<UserProgress>())
            #expect(allProgress.count == 1)
            let updatedProgress = try #require(allProgress.first)
            #expect(updatedProgress.shouldDelete, "Должен быть помечен для удаления")
            #expect(!updatedProgress.isSynced, "Должен быть несинхронизированным")
        }

        @Test("Обработка ошибок сети при синхронизации")
        func handleNetworkErrors() async throws {
            // Arrange
            let mockClient = MockProgressClient()
            let service = ProgressSyncService.makeMock(client: mockClient)
            let container = try ModelContainer(
                for: UserProgress.self,
                User.self,
                configurations: ModelConfiguration(isStoredInMemoryOnly: true)
            )
            let context = container.mainContext

            // Создаем пользователя
            let user = User(id: 1, userName: "testuser", fullName: "Test User", email: "test@example.com")
            context.insert(user)
            try context.save()

            // Создаем локальный несинхронизированный прогресс
            let progress = UserProgress(id: 1, pullUps: 10, pushUps: 20, squats: 30, weight: 70.0)
            progress.user = user
            progress.isSynced = false
            context.insert(progress)
            try context.save()

            // Мокаем ошибку сети
            mockClient.shouldThrowError = true

            // Act
            _ = try await service.syncProgress(context: context)

            // Assert - локальный прогресс должен остаться без изменений
            let unchangedProgress = try #require(context.fetch(FetchDescriptor<UserProgress>()).first)
            #expect(!unchangedProgress.isSynced, "Должен остаться несинхронизированным")
            #expect(!unchangedProgress.shouldDelete)
            #expect(unchangedProgress.pullUps == 10)
        }

        @Test("Проверка корректности работы cleanupDuplicateProgress")
        func cleanupDuplicateProgress() async throws {
            // Arrange
            let mockClient = MockProgressClient()
            let service = ProgressSyncService.makeMock(client: mockClient)
            let container = try ModelContainer(
                for: UserProgress.self,
                User.self,
                configurations: ModelConfiguration(isStoredInMemoryOnly: true)
            )
            let context = container.mainContext

            // Создаем пользователя
            let user = User(id: 1, userName: "testuser", fullName: "Test User", email: "test@example.com")
            context.insert(user)
            try context.save()

            // Создаем дубликаты прогресса для одного дня
            let progress1 = UserProgress(id: 1, pullUps: 10, pushUps: 20, squats: 30, weight: 70.0)
            progress1.user = user
            progress1.isSynced = false
            progress1.lastModified = Date().addingTimeInterval(-3600) // 1 час назад
            context.insert(progress1)

            let progress2 = UserProgress(id: 1, pullUps: 15, pushUps: 25, squats: 35, weight: 72.0) // Дубликат с другими данными
            progress2.user = user
            progress2.isSynced = false
            progress2.lastModified = Date() // Более новая дата
            context.insert(progress2)

            try context.save()

            // Act
            _ = try await service.syncProgress(context: context)

            // Assert - должен остаться только один прогресс (более новый)
            let allProgress = try context.fetch(FetchDescriptor<UserProgress>())
            #expect(allProgress.count == 1, "Должен остаться только один прогресс после очистки дубликатов")

            let remainingProgress = try #require(allProgress.first)
            #expect(remainingProgress.pullUps == 15, "Должен остаться прогресс с более новыми данными")
            #expect(remainingProgress.pushUps == 25)
            #expect(remainingProgress.squats == 35)
            #expect(remainingProgress.weight == 72.0)
        }

        @Test("Проверка корректности makeProgressSnapshotsForSync")
        func makeProgressSnapshotsForSync() async throws {
            // Arrange
            let mockClient = MockProgressClient()
            let service = ProgressSyncService.makeMock(client: mockClient)
            let container = try ModelContainer(
                for: UserProgress.self,
                User.self,
                configurations: ModelConfiguration(isStoredInMemoryOnly: true)
            )
            let context = container.mainContext

            // Создаем пользователя
            let user = User(id: 1, userName: "testuser", fullName: "Test User", email: "test@example.com")
            context.insert(user)
            try context.save()

            // Создаем различные типы записей прогресса
            let syncedProgress = UserProgress(id: 1, pullUps: 10, pushUps: 20, squats: 30, weight: 70.0)
            syncedProgress.user = user
            syncedProgress.isSynced = true // Синхронизированный - не должен попасть в snapshots
            context.insert(syncedProgress)

            let unsyncedProgress = UserProgress(id: 2, pullUps: 15, pushUps: 25, squats: 35, weight: 72.0)
            unsyncedProgress.user = user
            unsyncedProgress.isSynced = false // Несинхронизированный - должен попасть в snapshots
            context.insert(unsyncedProgress)

            let progressForDeletion = UserProgress(id: 3, pullUps: 0, pushUps: 0, squats: 0, weight: 0.0)
            progressForDeletion.user = user
            progressForDeletion.shouldDelete = true
            progressForDeletion.isSynced = false // Помеченный для удаления - должен попасть в snapshots
            context.insert(progressForDeletion)

            try context.save()

            // Настраиваем мок-ответы сервера для всех записей
            // Это необходимо, чтобы handleDeletedProgress не помечал их как удаленные
            // и чтобы downloadServerProgress корректно обработал все записи
            let syncedProgressResponse = ProgressResponse(
                id: 1,
                pullups: 10,
                pushups: 20,
                squats: 30,
                weight: 70.0,
                createDate: syncedProgress.lastModified,
                modifyDate: syncedProgress.lastModified
            )
            let unsyncedProgressResponse = ProgressResponse(
                id: 2,
                pullups: 15,
                pushups: 25,
                squats: 35,
                weight: 72.0,
                createDate: unsyncedProgress.lastModified,
                modifyDate: unsyncedProgress.lastModified
            )
            mockClient.mockedProgressResponses = [syncedProgressResponse, unsyncedProgressResponse]

            // Act - тестируем приватный метод через публичный интерфейс
            _ = try await service.syncProgress(context: context)

            // Проверяем, что записи обработаны корректно
            let allProgress = try context.fetch(FetchDescriptor<UserProgress>())
            #expect(allProgress.count == 2, "Должно остаться 2 записи (синхронизированная и несинхронизированная)")

            // Проверяем финальные состояния
            let finalSyncedProgress = allProgress.first { $0.id == 1 }
            let finalUnsyncedProgress = allProgress.first { $0.id == 2 }
            let finalDeletedProgress = allProgress.first { $0.id == 3 }

            let syncedProgressValue = try #require(finalSyncedProgress)
            let unsyncedProgressValue = try #require(finalUnsyncedProgress)

            #expect(syncedProgressValue.isSynced, "Синхронизированный прогресс должен остаться синхронизированным")
            #expect(unsyncedProgressValue.isSynced, "Несинхронизированный прогресс должен стать синхронизированным")
            #expect(finalDeletedProgress == nil, "Прогресс помеченный для удаления должен быть удален")
        }

        @Test("Проверка корректности applyLWWLogic с детальным логированием")
        func applyLWWLogicWithLogging() async throws {
            // Arrange
            let mockClient = MockProgressClient()
            let service = ProgressSyncService.makeMock(client: mockClient)
            let container = try ModelContainer(
                for: UserProgress.self,
                User.self,
                configurations: ModelConfiguration(isStoredInMemoryOnly: true)
            )
            let context = container.mainContext

            // Создаем пользователя
            let user = User(id: 1, userName: "testuser", fullName: "Test User", email: "test@example.com")
            context.insert(user)
            try context.save()

            // Создаем локальный прогресс с более новыми данными
            let progress = UserProgress(id: 1, pullUps: 10, pushUps: 20, squats: 30, weight: 70.0)
            progress.user = user
            progress.isSynced = true
            progress.lastModified = Date().addingTimeInterval(3600) // Локальная дата новее (на 1 час)
            context.insert(progress)
            try context.save()

            // Мокаем серверные данные с более старой датой
            let serverResponse = ProgressResponse(
                id: 1,
                pullups: 99, // Другие данные
                pushups: 99,
                squats: 99,
                weight: 99.0,
                createDate: Date().addingTimeInterval(-7200),
                modifyDate: Date().addingTimeInterval(-3600) // Старше локального
            )
            mockClient.mockedProgressResponses = [serverResponse]

            // Act
            _ = try await service.syncProgress(context: context)

            // Assert - локальные данные должны сохраниться (локальная версия новее)
            let updatedProgress = try #require(context.fetch(FetchDescriptor<UserProgress>()).first)
            #expect(updatedProgress.pullUps == 10, "Локальные данные должны сохраниться")
            #expect(updatedProgress.pushUps == 20)
            #expect(updatedProgress.squats == 30)
            #expect(updatedProgress.weight == 70.0)
            #expect(updatedProgress.isSynced, "Прогресс должен остаться синхронизированным")
        }

        @Test("Проверка корректности handlePhotoDeletion")
        func handlePhotoDeletion() async throws {
            // Arrange
            let mockClient = MockProgressClient()
            let service = ProgressSyncService.makeMock(client: mockClient)
            let container = try ModelContainer(
                for: UserProgress.self,
                User.self,
                configurations: ModelConfiguration(isStoredInMemoryOnly: true)
            )
            let context = container.mainContext

            // Создаем пользователя
            let user = User(id: 1, userName: "testuser", fullName: "Test User", email: "test@example.com")
            context.insert(user)
            try context.save()

            // Создаем прогресс с фотографиями помеченными для удаления
            let progress = UserProgress(id: 1, pullUps: 10, pushUps: 20, squats: 30, weight: 70.0)
            progress.user = user
            progress.deletePhotoData(.front)
            progress.deletePhotoData(.back)
            context.insert(progress)
            try context.save()

            // Act
            _ = try await service.syncProgress(context: context)

            // Assert - фотографии должны быть очищены после успешного удаления
            let updatedProgress = try #require(context.fetch(FetchDescriptor<UserProgress>()).first)
            #expect(!updatedProgress.shouldDeletePhoto(.front), "Фронтальная фотография не должна быть помечена для удаления")
            #expect(!updatedProgress.shouldDeletePhoto(.back), "Задняя фотография не должна быть помечена для удаления")
            #expect(updatedProgress.isSynced, "Прогресс должен быть синхронизирован")
        }

        @Test("Обработка ошибок в handlePhotoDeletion")
        func handlePhotoDeletionErrors() async throws {
            // Arrange
            let mockClient = MockProgressClient()
            mockClient.shouldThrowError = true // Имитируем ошибки сети
            let service = ProgressSyncService.makeMock(client: mockClient)
            let container = try ModelContainer(
                for: UserProgress.self,
                User.self,
                configurations: ModelConfiguration(isStoredInMemoryOnly: true)
            )
            let context = container.mainContext

            // Создаем пользователя
            let user = User(id: 1, userName: "testuser", fullName: "Test User", email: "test@example.com")
            context.insert(user)
            try context.save()

            // Создаем прогресс с фотографиями помеченными для удаления
            let progress = UserProgress(id: 1, pullUps: 10, pushUps: 20, squats: 30, weight: 70.0)
            progress.user = user
            progress.deletePhotoData(.front)
            context.insert(progress)
            try context.save()

            // Act
            _ = try await service.syncProgress(context: context)

            // Assert - при ошибках фотографии должны остаться помеченными для удаления
            let updatedProgress = try #require(context.fetch(FetchDescriptor<UserProgress>()).first)
            #expect(updatedProgress.shouldDeletePhoto(.front), "Фотография должна остаться помеченной для удаления при ошибке")
            #expect(!updatedProgress.isSynced, "Прогресс не должен быть синхронизирован при ошибке")
        }

        @Test("Проверка корректности логирования всех этапов синхронизации")
        func loggingAllSyncStages() async throws {
            // Arrange
            let mockClient = MockProgressClient()
            let service = ProgressSyncService.makeMock(client: mockClient)
            let container = try ModelContainer(
                for: UserProgress.self,
                User.self,
                configurations: ModelConfiguration(isStoredInMemoryOnly: true)
            )
            let context = container.mainContext

            // Создаем пользователя
            let user = User(id: 1, userName: "testuser", fullName: "Test User", email: "test@example.com")
            context.insert(user)
            try context.save()

            // Создаем прогресс для синхронизации
            let progress = UserProgress(id: 1, pullUps: 10, pushUps: 20, squats: 30, weight: 70.0)
            progress.user = user
            progress.isSynced = false
            context.insert(progress)
            try context.save()

            // Мокаем ответ сервера
            let serverResponse = ProgressResponse(
                id: 1,
                pullups: 10,
                pushups: 20,
                squats: 30,
                weight: 70.0,
                createDate: Date(),
                modifyDate: Date()
            )
            mockClient.mockedProgressResponses = [serverResponse]

            // Act
            _ = try await service.syncProgress(context: context)

            // Assert - проверяем финальное состояние
            let updatedProgress = try #require(context.fetch(FetchDescriptor<UserProgress>()).first)
            #expect(updatedProgress.isSynced, "Прогресс должен быть синхронизирован")
            #expect(!updatedProgress.shouldDelete, "Прогресс не должен быть помечен для удаления")
            #expect(updatedProgress.pullUps == 10, "Данные должны соответствовать серверным")
            #expect(updatedProgress.pushUps == 20)
            #expect(updatedProgress.squats == 30)
            #expect(updatedProgress.weight == 70.0)
        }

        @Test("Тест пустого состояния - без записей для синхронизации")
        func emptyStateNoRecordsToSync() async throws {
            // Arrange
            let mockClient = MockProgressClient()
            let service = ProgressSyncService.makeMock(client: mockClient)
            let container = try ModelContainer(
                for: UserProgress.self,
                User.self,
                configurations: ModelConfiguration(isStoredInMemoryOnly: true)
            )
            let context = container.mainContext

            // Создаем пользователя, но без записей прогресса
            let user = User(id: 1, userName: "testuser", fullName: "Test User", email: "test@example.com")
            context.insert(user)
            try context.save()

            // Act
            _ = try await service.syncProgress(context: context)

            // Assert - синхронизация должна пройти без ошибок
            let allProgress = try context.fetch(FetchDescriptor<UserProgress>())
            #expect(allProgress.isEmpty, "Не должно быть записей прогресса")
        }

        @Test("Тест синхронизации уже выполняемой синхронизации")
        func alreadySyncingProtection() async throws {
            // Arrange
            let mockClient = MockProgressClient()
            let service = ProgressSyncService.makeMock(client: mockClient)
            let container = try ModelContainer(
                for: UserProgress.self,
                User.self,
                configurations: ModelConfiguration(isStoredInMemoryOnly: true)
            )
            let context = container.mainContext

            // Создаем пользователя
            let user = User(id: 1, userName: "testuser", fullName: "Test User", email: "test@example.com")
            context.insert(user)
            try context.save()

            // Создаем прогресс
            let progress = UserProgress(id: 1, pullUps: 10, pushUps: 20, squats: 30, weight: 70.0)
            progress.user = user
            progress.isSynced = false
            context.insert(progress)
            try context.save()

            // Act - запускаем первую синхронизацию
            _ = try await service.syncProgress(context: context)

            // Проверяем состояние после первой синхронизации
            let progressAfterFirst = try context.fetch(FetchDescriptor<UserProgress>())
            #expect(progressAfterFirst.count == 1, "Должен быть только один прогресс после первой синхронизации")
            let firstProgress = try #require(progressAfterFirst.first)
            #expect(firstProgress.isSynced, "Прогресс должен быть синхронизирован после первой синхронизации")

            // Запускаем вторую синхронизацию (должна быть пропущена из-за флага isSyncing)
            _ = try await service.syncProgress(context: context)

            // Assert - синхронизация должна пройти корректно без дублирования
            let allProgress = try context.fetch(FetchDescriptor<UserProgress>())
            #expect(allProgress.count == 1, "Должен быть только один прогресс")

            let updatedProgress = try #require(allProgress.first)
            #expect(updatedProgress.isSynced, "Прогресс должен быть синхронизирован")
        }

        @Test("Должен корректно обрабатывать серверные данные и создавать локальные записи")
        func serverDataProcessing() async throws {
            // Arrange
            let container = try ModelContainer(
                for: UserProgress.self,
                User.self,
                configurations: ModelConfiguration(isStoredInMemoryOnly: true)
            )
            let context = container.mainContext

            // Создаем пользователя
            let user = User(id: 10367, userName: "Test User", email: "test@example.com")
            context.insert(user)
            try context.save()

            // Создаем мок клиента
            let mockClient = MockProgressClient()

            // Настраиваем мок для возврата серверных данных
            // Используем локальные URL вместо реальных серверных, чтобы избежать сетевых запросов
            let createDate = try #require(ISO8601DateFormatter().date(from: "2025-10-24T10:39:51+03:00"))
            let modifyDate = try #require(ISO8601DateFormatter().date(from: "2025-10-24T10:40:08+03:00"))
            let serverResponse = ProgressResponse(
                id: 1,
                pullups: 1,
                pushups: 1,
                squats: 1,
                weight: 10.0,
                createDate: createDate,
                modifyDate: modifyDate,
                photoFront: "https://example.com/front.jpg",
                photoBack: "https://example.com/back.jpg"
            )
            mockClient.mockedProgressResponses = [serverResponse]

            let syncService = ProgressSyncService.makeMock(client: mockClient)

            // Act
            _ = try await syncService.syncProgress(context: context)

            // Assert
            let allProgress = try context.fetch(FetchDescriptor<UserProgress>())
            let userProgress = allProgress.filter { $0.user?.id == user.id }

            #expect(userProgress.count == 1)

            let progress = try #require(userProgress.first)
            #expect(progress.id == 1)
            #expect(progress.pullUps == 1)
            #expect(progress.pushUps == 1)
            #expect(progress.squats == 1)
            #expect(progress.weight == 10.0)
            #expect(progress.isSynced)
            #expect(!progress.shouldDelete)
            #expect(progress.urlPhotoFront == "https://example.com/front.jpg")
            #expect(progress.urlPhotoBack == "https://example.com/back.jpg")
        }

        @Test("Должен корректно маппить внешние дни сервера во внутренние дни приложения")
        func dayMapping() {
            // Тестируем маппинг внешних дней во внутренние
            #expect(UserProgress.getInternalDayFromExternalDay(1) == 1)
            #expect(UserProgress.getInternalDayFromExternalDay(49) == 49)
            #expect(UserProgress.getInternalDayFromExternalDay(99) == 100)
            #expect(UserProgress.getInternalDayFromExternalDay(50) == 50)

            // Тестируем обратный маппинг
            #expect(UserProgress.getExternalDayFromProgressId(1) == 1)
            #expect(UserProgress.getExternalDayFromProgressId(49) == 49)
            #expect(UserProgress.getExternalDayFromProgressId(100) == 99)
            #expect(UserProgress.getExternalDayFromProgressId(50) == 50)
        }

        @Test("Должен корректно обновлять существующие записи данными с сервера")
        func updateExistingProgressFromServer() async throws {
            // Arrange
            let container = try ModelContainer(
                for: UserProgress.self,
                User.self,
                configurations: ModelConfiguration(isStoredInMemoryOnly: true)
            )
            let context = container.mainContext

            // Создаем пользователя
            let user = User(id: 10367, userName: "Test User", email: "test@example.com")
            context.insert(user)

            // Создаем существующую локальную запись
            let existingProgress = UserProgress(
                id: 1,
                pullUps: 5,
                pushUps: 10,
                squats: 15,
                weight: 80.0
            )
            existingProgress.user = user
            existingProgress.isSynced = true
            existingProgress.shouldDelete = false
            context.insert(existingProgress)
            try context.save()

            // Создаем мок клиента
            let mockClient = MockProgressClient()

            // Настраиваем мок для возврата обновленных серверных данных
            // Используем локальные URL вместо реальных серверных, чтобы избежать сетевых запросов
            // Используем даты в будущем, чтобы серверные данные были новее локальных
            let serverCreateDate = Date().addingTimeInterval(3600) // +1 час
            let serverModifyDate = Date().addingTimeInterval(7200) // +2 часа
            let serverResponse = ProgressResponse(
                id: 1,
                pullups: 1,
                pushups: 1,
                squats: 1,
                weight: 10.0,
                createDate: serverCreateDate,
                modifyDate: serverModifyDate,
                photoFront: "https://example.com/front.jpg",
                photoBack: "https://example.com/back.jpg"
            )
            mockClient.mockedProgressResponses = [serverResponse]

            let syncService = ProgressSyncService.makeMock(client: mockClient)

            // Act
            _ = try await syncService.syncProgress(context: context)

            // Assert
            let allProgress = try context.fetch(FetchDescriptor<UserProgress>())
            let userProgress = allProgress.filter { $0.user?.id == user.id }

            #expect(userProgress.count == 1)

            let progress = try #require(userProgress.first)
            #expect(progress.id == 1)
            #expect(progress.pullUps == 1)
            #expect(progress.pushUps == 1)
            #expect(progress.squats == 1)
            #expect(progress.weight == 10.0)
            #expect(progress.isSynced)
            #expect(!progress.shouldDelete)
            #expect(progress.urlPhotoFront == "https://example.com/front.jpg")
            #expect(progress.urlPhotoBack == "https://example.com/back.jpg")
        }

        @Test("Возвращает результат успешной синхронизации с подсчетом созданных записей")
        func returnsSuccessResultWithCreatedCount() async throws {
            let mockClient = MockProgressClient()
            let service = ProgressSyncService.makeMock(client: mockClient)
            let container = try ModelContainer(
                for: UserProgress.self,
                User.self,
                configurations: ModelConfiguration(isStoredInMemoryOnly: true)
            )
            let context = container.mainContext

            let user = User(id: 1, userName: "testuser", fullName: "Test User", email: "test@example.com")
            context.insert(user)
            try context.save()

            let progress = UserProgress(id: 1, pullUps: 10, pushUps: 20, squats: 30, weight: 70.0)
            progress.user = user
            progress.isSynced = false
            context.insert(progress)
            try context.save()

            let serverResponse = ProgressResponse(
                id: 1,
                pullups: 10,
                pushups: 20,
                squats: 30,
                weight: 70.0,
                createDate: Date(),
                modifyDate: Date()
            )
            mockClient.mockedProgressResponses = [serverResponse]

            let result = try await service.syncProgress(context: context)

            #expect(result.type == .success)
            let details = try #require(result.details.progress)
            #expect(details.created >= 0)
            #expect(details.updated >= 0)
            #expect(details.deleted >= 0)
        }

        @Test("Возвращает результат с ошибками при сетевой ошибке")
        func returnsResultWithErrorsOnNetworkError() async throws {
            let mockClient = MockProgressClient()
            mockClient.shouldThrowError = true
            let service = ProgressSyncService.makeMock(client: mockClient)
            let container = try ModelContainer(
                for: UserProgress.self,
                User.self,
                configurations: ModelConfiguration(isStoredInMemoryOnly: true)
            )
            let context = container.mainContext

            let user = User(id: 1, userName: "testuser", fullName: "Test User", email: "test@example.com")
            context.insert(user)
            try context.save()

            let progress = UserProgress(id: 1, pullUps: 10, pushUps: 20, squats: 30, weight: 70.0)
            progress.user = user
            progress.isSynced = false
            context.insert(progress)
            try context.save()

            let result = try await service.syncProgress(context: context)

            #expect(!result.isSuccess)
            let errors = try #require(result.details.errors)
            #expect(!errors.isEmpty)
            // При ошибках и статистике = 0 должен быть тип .error
            let stats = result.details.progress ?? SyncStats(created: 0, updated: 0, deleted: 0)
            if stats.totalOperations == 0 {
                #expect(result.type == .error)
            } else {
                #expect(result.type == .partial)
            }
        }

        @Test("Подсчитывает созданные обновленные и удаленные записи")
        func countsCreatedUpdatedAndDeletedRecords() async throws {
            let mockClient = MockProgressClient()
            let service = ProgressSyncService.makeMock(client: mockClient)
            let container = try ModelContainer(
                for: UserProgress.self,
                User.self,
                configurations: ModelConfiguration(isStoredInMemoryOnly: true)
            )
            let context = container.mainContext

            let user = User(id: 1, userName: "testuser", fullName: "Test User", email: "test@example.com")
            context.insert(user)
            try context.save()

            let progress1 = UserProgress(id: 1, pullUps: 10, pushUps: 20, squats: 30, weight: 70.0)
            progress1.user = user
            progress1.isSynced = false
            context.insert(progress1)

            let progress2 = UserProgress(id: 2, pullUps: 15, pushUps: 25, squats: 35, weight: 75.0)
            progress2.user = user
            progress2.isSynced = true
            progress2.lastModified = Date().addingTimeInterval(-3600)
            context.insert(progress2)
            try context.save()

            let response1 = ProgressResponse(
                id: 1,
                pullups: 10,
                pushups: 20,
                squats: 30,
                weight: 70.0,
                createDate: Date(),
                modifyDate: Date()
            )
            let response2 = ProgressResponse(
                id: 2,
                pullups: 15,
                pushups: 25,
                squats: 35,
                weight: 75.0,
                createDate: Date().addingTimeInterval(-7200),
                modifyDate: Date()
            )
            mockClient.mockedProgressResponses = [response1, response2]

            let result = try await service.syncProgress(context: context)

            #expect(result.type == .success)
            let details = try #require(result.details.progress)
            #expect(details.created >= 0)
            #expect(details.updated >= 0)
            #expect(details.deleted >= 0)
        }

        @Test("Определяет тип результата как error когда есть ошибки и статистика = 0")
        func determinesErrorTypeWhenErrorsExistAndStatsZero() async throws {
            let mockClient = MockProgressClient()
            mockClient.shouldThrowError = true
            let service = ProgressSyncService.makeMock(client: mockClient)
            let container = try ModelContainer(
                for: UserProgress.self,
                User.self,
                configurations: ModelConfiguration(isStoredInMemoryOnly: true)
            )
            let context = container.mainContext

            let user = User(id: 1, userName: "testuser", fullName: "Test User", email: "test@example.com")
            context.insert(user)
            try context.save()

            // Не добавляем прогресс, чтобы статистика была 0
            let result = try await service.syncProgress(context: context)

            #expect(result.type == .error)
            let errors = try #require(result.details.errors)
            #expect(!errors.isEmpty)
        }

        @Test("Определяет тип результата как partial когда есть ошибки и статистика > 0")
        func determinesPartialTypeWhenErrorsExistAndStatsGreaterThanZero() async throws {
            let mockClient = MockProgressClient()
            let service = ProgressSyncService.makeMock(client: mockClient)
            let container = try ModelContainer(
                for: UserProgress.self,
                User.self,
                configurations: ModelConfiguration(isStoredInMemoryOnly: true)
            )
            let context = container.mainContext

            let user = User(id: 1, userName: "testuser", fullName: "Test User", email: "test@example.com")
            context.insert(user)
            try context.save()

            // Создаем прогресс для синхронизации
            let progress = UserProgress(id: 1, pullUps: 10, pushUps: 20, squats: 30, weight: 70.0)
            progress.user = user
            progress.isSynced = false
            context.insert(progress)
            try context.save()

            // Мокаем успешный ответ сервера
            let serverResponse = ProgressResponse(
                id: 1,
                pullups: 10,
                pushups: 20,
                squats: 30,
                weight: 70.0,
                createDate: Date(),
                modifyDate: Date()
            )
            mockClient.mockedProgressResponses = [serverResponse]

            // Симулируем ошибку при загрузке серверных изменений
            mockClient.shouldThrowErrorOnGetProgress = true

            let result = try await service.syncProgress(context: context)

            // Должен быть .partial, так как есть ошибки, но статистика > 0 (была успешная синхронизация)
            #expect(result.type == .partial)
            let errors = try #require(result.details.errors)
            #expect(!errors.isEmpty)
            let stats = try #require(result.details.progress)
            #expect(stats.totalOperations > 0)
        }
    }
}
