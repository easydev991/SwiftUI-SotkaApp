import Foundation
import SwiftData
@testable import SwiftUI_SotkaApp
import SWUtils
import Testing
import UIKit

@MainActor
struct ProgressSyncServicePhotoTests {
    // MARK: - Test Data

    private var testImageData: Data {
        let testImage = UIImage(systemName: "photo") ?? UIImage()
        return testImage.pngData() ?? Data()
    }

    // MARK: - Mock Client

    private final class MockProgressClient: ProgressClient, @unchecked Sendable {
        var mockedProgressResponses: [ProgressResponse]
        var shouldThrowError = false
        var errorToThrow: Error = NSError(domain: "TestError", code: 1, userInfo: nil)

        init(mockedProgressResponses: [ProgressResponse] = []) {
            self.mockedProgressResponses = mockedProgressResponses
        }

        func getProgress() async throws -> [ProgressResponse] {
            if shouldThrowError {
                throw errorToThrow
            }
            return mockedProgressResponses
        }

        func createProgress(progress: ProgressRequest) async throws -> ProgressResponse {
            if shouldThrowError {
                throw errorToThrow
            }
            return mockedProgressResponses.first ?? ProgressResponse(
                id: progress.id,
                pullups: progress.pullups,
                pushups: progress.pushups,
                squats: progress.squats,
                weight: progress.weight,
                createDate: DateFormatterService.stringFromFullDate(Date(), format: .serverDateTimeSec),
                modifyDate: progress.modifyDate
            )
        }

        func updateProgress(day: Int, progress: ProgressRequest) async throws -> ProgressResponse {
            if shouldThrowError {
                throw errorToThrow
            }
            return mockedProgressResponses.first ?? ProgressResponse(
                id: day,
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
                throw errorToThrow
            }
        }

        func deletePhoto(day _: Int, type _: String) async throws {
            if shouldThrowError {
                throw errorToThrow
            }
            // Имитируем успешное удаление фотографии
        }

        func getProgress(day: Int) async throws -> ProgressResponse {
            if shouldThrowError {
                throw errorToThrow
            }
            return mockedProgressResponses.first ?? ProgressResponse(
                id: day,
                pullups: 10,
                pushups: 20,
                squats: 30,
                weight: 70.0,
                createDate: DateFormatterService.stringFromFullDate(Date(), format: .serverDateTimeSec),
                modifyDate: DateFormatterService.stringFromFullDate(Date(), format: .serverDateTimeSec)
            )
        }
    }

    // MARK: - Progress Model Photo Tests

    @Test("Создание прогресса из ответа сервера с фотографиями")
    func createProgressFromServerResponseWithPhotos() {
        let user = User(id: 1, userName: "test", email: "test@test.com", cityID: nil)

        let serverResponse = ProgressResponse(
            id: 1,
            pullups: 10,
            pushups: 20,
            squats: 30,
            weight: 70.0,
            createDate: DateFormatterService.stringFromFullDate(Date(), format: .serverDateTimeSec),
            modifyDate: DateFormatterService.stringFromFullDate(Date(), format: .serverDateTimeSec),
            photoFront: "https://example.com/photo_front.jpg",
            photoBack: "https://example.com/photo_back.jpg",
            photoSide: "https://example.com/photo_side.jpg"
        )

        let progress = Progress(from: serverResponse, user: user)

        #expect(progress.urlPhotoFront == "https://example.com/photo_front.jpg")
        #expect(progress.urlPhotoBack == "https://example.com/photo_back.jpg")
        #expect(progress.urlPhotoSide == "https://example.com/photo_side.jpg")
        #expect(progress.isSynced)
    }

    @Test("Создание прогресса из ответа сервера с одной фотографией")
    func createProgressFromServerResponseWithSinglePhoto() {
        let user = User(id: 1, userName: "test", email: "test@test.com", cityID: nil)

        let serverResponse = ProgressResponse(
            id: 1,
            pullups: 10,
            pushups: 20,
            squats: 30,
            weight: 70.0,
            createDate: DateFormatterService.stringFromFullDate(Date(), format: .serverDateTimeSec),
            modifyDate: DateFormatterService.stringFromFullDate(Date(), format: .serverDateTimeSec),
            photoFront: "https://example.com/photo_front.jpg"
        )

        let progress = Progress(from: serverResponse, user: user)

        #expect(progress.urlPhotoFront == "https://example.com/photo_front.jpg")
        #expect(progress.urlPhotoBack == nil)
        #expect(progress.urlPhotoSide == nil)
        #expect(progress.isSynced)
    }

    @Test("Создание прогресса из ответа сервера без фотографий")
    func createProgressFromServerResponseWithoutPhotos() {
        let user = User(id: 1, userName: "test", email: "test@test.com", cityID: nil)

        let serverResponse = ProgressResponse(
            id: 1,
            pullups: 10,
            pushups: 20,
            squats: 30,
            weight: 70.0,
            createDate: DateFormatterService.stringFromFullDate(Date(), format: .serverDateTimeSec),
            modifyDate: DateFormatterService.stringFromFullDate(Date(), format: .serverDateTimeSec)
        )

        let progress = Progress(from: serverResponse, user: user)

        #expect(progress.urlPhotoFront == nil)
        #expect(progress.urlPhotoBack == nil)
        #expect(progress.urlPhotoSide == nil)
        #expect(progress.isSynced)
    }

    @Test("Создание прогресса из ответа сервера с обновлением lastModified")
    func createProgressFromServerResponseUpdatesLastModified() {
        let user = User(id: 1, userName: "test", email: "test@test.com", cityID: nil)
        let originalDate = Date()

        let serverResponse = ProgressResponse(
            id: 1,
            pullups: 10,
            pushups: 20,
            squats: 30,
            weight: 70.0,
            createDate: DateFormatterService.stringFromFullDate(originalDate, format: .serverDateTimeSec),
            modifyDate: DateFormatterService.stringFromFullDate(originalDate, format: .serverDateTimeSec),
            photoFront: "https://example.com/photo_front.jpg"
        )

        let progress = Progress(from: serverResponse, user: user)

        #expect(progress.lastModified >= originalDate)
        #expect(progress.isSynced)
    }

    // MARK: - Progress Data Tests

    @Test("Проверка работы с локальными данными фотографий")
    func progressPhotoDataHandling() {
        let progress = Progress(id: 1, pullUps: 10, pushUps: 20, squats: 30, weight: 70.0)

        progress.setPhotoData(.front, data: testImageData)
        progress.setPhotoData(.back, data: testImageData)
        progress.setPhotoData(.side, data: testImageData)

        #expect(progress.hasPhotoData(.front))
        #expect(progress.hasPhotoData(.back))
        #expect(progress.hasPhotoData(.side))
        #expect(progress.hasAnyPhotoData)
    }

    // MARK: - Integration Tests

    @Test("Полная интеграция создания прогресса с фотографиями")
    func fullProgressCreationIntegration() {
        let user = User(id: 1, userName: "test", email: "test@test.com", cityID: nil)

        let serverResponse = ProgressResponse(
            id: 1,
            pullups: 10,
            pushups: 20,
            squats: 30,
            weight: 70.0,
            createDate: DateFormatterService.stringFromFullDate(Date(), format: .serverDateTimeSec),
            modifyDate: DateFormatterService.stringFromFullDate(Date(), format: .serverDateTimeSec),
            photoFront: "https://example.com/photo_front.jpg",
            photoBack: "https://example.com/photo_back.jpg",
            photoSide: "https://example.com/photo_side.jpg"
        )

        let progress = Progress(from: serverResponse, user: user)

        #expect(progress.urlPhotoFront == "https://example.com/photo_front.jpg")
        #expect(progress.urlPhotoBack == "https://example.com/photo_back.jpg")
        #expect(progress.urlPhotoSide == "https://example.com/photo_side.jpg")
        #expect(progress.isSynced)
    }

    @Test("Создание прогресса с внутренним днем")
    func createProgressWithInternalDay() {
        let user = User(id: 1, userName: "test", email: "test@test.com", cityID: nil)

        let serverResponse = ProgressResponse(
            id: 1,
            pullups: 10,
            pushups: 20,
            squats: 30,
            weight: 70.0,
            createDate: DateFormatterService.stringFromFullDate(Date(), format: .serverDateTimeSec),
            modifyDate: DateFormatterService.stringFromFullDate(Date(), format: .serverDateTimeSec),
            photoFront: "https://example.com/photo_front.jpg"
        )

        let progress = Progress(from: serverResponse, user: user, internalDay: 100)

        #expect(progress.id == 100)
        #expect(progress.urlPhotoFront == "https://example.com/photo_front.jpg")
        #expect(progress.isSynced)
    }

    @Test("Параметризированный тест создания прогресса", arguments: [1, 49, 100])
    func parameterizedProgressCreation(dayId: Int) {
        let user = User(id: 1, userName: "test", email: "test@test.com", cityID: nil)

        let serverResponse = ProgressResponse(
            id: dayId,
            pullups: 10,
            pushups: 20,
            squats: 30,
            weight: 70.0,
            createDate: DateFormatterService.stringFromFullDate(Date(), format: .serverDateTimeSec),
            modifyDate: DateFormatterService.stringFromFullDate(Date(), format: .serverDateTimeSec),
            photoFront: "https://example.com/photo_front.jpg"
        )

        let progress = Progress(from: serverResponse, user: user)

        #expect(progress.id == dayId)
        #expect(progress.isSynced)
        #expect(progress.urlPhotoFront == "https://example.com/photo_front.jpg")
    }

    // MARK: - Photo Deletion Sync Tests

    @Test("Синхронизация прогресса с фотографиями для удаления возвращает needsPhotoDeletion")
    func syncProgressWithPhotosToDeleteReturnsNeedsPhotoDeletion() async throws {
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

        // Создаем прогресс с фотографиями помеченными для удаления
        let progress = Progress(id: 1, pullUps: 10, pushUps: 20, squats: 30, weight: 70.0)
        progress.user = user
        progress.isSynced = false
        progress.deletePhotoData(.front) // Помечаем фронтальную фотографию для удаления
        context.insert(progress)
        try context.save()

        // Act - используем публичный метод syncProgress
        await service.syncProgress(context: context)

        // Assert - проверяем, что фотография была обработана
        let updatedProgress = try #require(context.fetch(FetchDescriptor<SwiftUI_SotkaApp.Progress>()).first)
        // После синхронизации фотография должна быть очищена (если удаление прошло успешно)
        // или остаться помеченной для удаления (если была ошибка)
        // В данном случае mock не выбрасывает ошибку, поэтому фотография должна быть очищена
        #expect(!updatedProgress.shouldDeletePhoto(.front))
    }

    @Test("Обработка needsPhotoDeletion события вызывает handlePhotoDeletion")
    func handleNeedsPhotoDeletionEventCallsHandlePhotoDeletion() async throws {
        // Arrange
        // Настраиваем mock client чтобы он возвращал прогресс при getProgress()
        let mockProgressResponse = ProgressResponse(
            id: 1,
            pullups: 10,
            pushups: 20,
            squats: 30,
            weight: 70.0,
            createDate: DateFormatterService.stringFromFullDate(Date(), format: .serverDateTimeSec),
            modifyDate: DateFormatterService.stringFromFullDate(Date(), format: .serverDateTimeSec),
            photoFront: nil,
            photoBack: nil,
            photoSide: nil
        )
        let mockClient = MockProgressClient(mockedProgressResponses: [mockProgressResponse])
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

        // Создаем прогресс с фотографиями помеченными для удаления
        let progress = Progress(id: 1, pullUps: 10, pushUps: 20, squats: 30, weight: 70.0)
        progress.user = user
        progress.deletePhotoData(.front)
        progress.deletePhotoData(.back)
        context.insert(progress)
        try context.save()

        // Act
        await service.syncProgress(context: context)

        // Assert
        let updatedProgress = try #require(context.fetch(FetchDescriptor<SwiftUI_SotkaApp.Progress>()).first)
        #expect(!updatedProgress.shouldDeletePhoto(.front))
        #expect(!updatedProgress.shouldDeletePhoto(.back))
        #expect(updatedProgress.isSynced)
    }

    @Test("Последовательное удаление фотографий обрабатывает ошибки корректно")
    func sequentialPhotoDeletionHandlesErrorsCorrectly() async throws {
        // Arrange
        let mockClient = MockProgressClient()
        mockClient.shouldThrowError = true
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

        // Создаем прогресс с фотографиями помеченными для удаления
        let progress = Progress(id: 1, pullUps: 10, pushUps: 20, squats: 30, weight: 70.0)
        progress.user = user
        progress.deletePhotoData(.front)
        context.insert(progress)
        try context.save()

        // Act
        await service.syncProgress(context: context)

        // Assert - прогресс должен остаться с помеченными фотографиями при ошибке
        let updatedProgress = try #require(context.fetch(FetchDescriptor<SwiftUI_SotkaApp.Progress>()).first)
        #expect(updatedProgress.shouldDeletePhoto(.front))
        #expect(!updatedProgress.isSynced)
    }

    @Test("Удаление всех фотографий последовательно")
    func deleteAllPhotosSequentially() async throws {
        // Arrange
        // Настраиваем mock client чтобы он возвращал прогресс при getProgress()
        let mockProgressResponse = ProgressResponse(
            id: 1,
            pullups: 10,
            pushups: 20,
            squats: 30,
            weight: 70.0,
            createDate: DateFormatterService.stringFromFullDate(Date(), format: .serverDateTimeSec),
            modifyDate: DateFormatterService.stringFromFullDate(Date(), format: .serverDateTimeSec),
            photoFront: nil,
            photoBack: nil,
            photoSide: nil
        )
        let mockClient = MockProgressClient(mockedProgressResponses: [mockProgressResponse])
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

        // Создаем прогресс с всеми фотографиями помеченными для удаления
        let progress = Progress(id: 1, pullUps: 10, pushUps: 20, squats: 30, weight: 70.0)
        progress.user = user
        progress.deletePhotoData(.front)
        progress.deletePhotoData(.back)
        progress.deletePhotoData(.side)
        context.insert(progress)
        try context.save()

        // Act
        await service.syncProgress(context: context)

        // Assert
        let updatedProgress = try #require(context.fetch(FetchDescriptor<SwiftUI_SotkaApp.Progress>()).first)
        #expect(!updatedProgress.shouldDeletePhoto(.front))
        #expect(!updatedProgress.shouldDeletePhoto(.back))
        #expect(!updatedProgress.shouldDeletePhoto(.side))
        #expect(updatedProgress.isSynced)
    }

    @Test("Интеграционный тест полного цикла удаления фотографий")
    func fullPhotoDeletionCycleIntegration() async throws {
        // Arrange
        // Настраиваем mock client чтобы он возвращал прогресс при getProgress()
        let mockProgressResponse = ProgressResponse(
            id: 1,
            pullups: 10,
            pushups: 20,
            squats: 30,
            weight: 70.0,
            createDate: DateFormatterService.stringFromFullDate(Date(), format: .serverDateTimeSec),
            modifyDate: DateFormatterService.stringFromFullDate(Date(), format: .serverDateTimeSec),
            photoFront: nil,
            photoBack: nil,
            photoSide: nil
        )
        let mockClient = MockProgressClient(mockedProgressResponses: [mockProgressResponse])
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

        // Создаем прогресс с данными и фотографиями
        let progress = Progress(id: 1, pullUps: 10, pushUps: 20, squats: 30, weight: 70.0)
        progress.user = user
        progress.setPhotoData(.front, data: testImageData)
        progress.setPhotoData(.back, data: testImageData)
        progress.setPhotoData(.side, data: testImageData)
        context.insert(progress)
        try context.save()

        // Помечаем фотографии для удаления
        progress.deletePhotoData(.front)
        progress.deletePhotoData(.back)

        // Act - синхронизируем
        await service.syncProgress(context: context)

        // Assert
        let updatedProgress = try #require(context.fetch(FetchDescriptor<SwiftUI_SotkaApp.Progress>()).first)
        #expect(!updatedProgress.shouldDeletePhoto(.front))
        #expect(!updatedProgress.shouldDeletePhoto(.back))
        #expect(!updatedProgress.shouldDeletePhoto(.side)) // Не была помечена для удаления
        #expect(updatedProgress.getPhotoData(.side) == testImageData) // Должна остаться
        #expect(updatedProgress.isSynced)
    }
}
