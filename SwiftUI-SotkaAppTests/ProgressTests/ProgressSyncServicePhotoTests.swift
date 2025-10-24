import Foundation
import SwiftData
@testable import SwiftUI_SotkaApp
import SWUtils
import Testing
import UIKit

extension AllProgressTests {
    @MainActor
    struct ProgressSyncServicePhotoTests {
        private var testImageData: Data {
            let testImage = UIImage(systemName: "photo") ?? UIImage()
            return testImage.pngData() ?? Data()
        }

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

            let progress = UserProgress(from: serverResponse, user: user)

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

            let progress = UserProgress(from: serverResponse, user: user)

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

            let progress = UserProgress(from: serverResponse, user: user)

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

            let progress = UserProgress(from: serverResponse, user: user)

            #expect(progress.lastModified >= originalDate)
            #expect(progress.isSynced)
        }

        @Test("Проверка работы с локальными данными фотографий")
        func progressPhotoDataHandling() {
            let progress = UserProgress(id: 1, pullUps: 10, pushUps: 20, squats: 30, weight: 70.0)
            progress.setPhotoData(testImageData, type: .front)
            progress.setPhotoData(testImageData, type: .back)
            progress.setPhotoData(testImageData, type: .side)
            #expect(progress.hasAnyPhotoData)
        }

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

            let progress = UserProgress(from: serverResponse, user: user)

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

            let progress = UserProgress(from: serverResponse, user: user, internalDay: 100)

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

            let progress = UserProgress(from: serverResponse, user: user)

            #expect(progress.id == dayId)
            #expect(progress.isSynced)
            #expect(progress.urlPhotoFront == "https://example.com/photo_front.jpg")
        }

        @Test("Синхронизация прогресса с фотографиями для удаления возвращает needsPhotoDeletion")
        func syncProgressWithPhotosToDeleteReturnsNeedsPhotoDeletion() async throws {
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
            progress.isSynced = false
            progress.deletePhotoData(.front) // Помечаем фронтальную фотографию для удаления
            context.insert(progress)
            try context.save()

            // Act - используем публичный метод syncProgress
            await service.syncProgress(context: context)

            // Assert - проверяем, что фотография была обработана
            let updatedProgress = try #require(context.fetch(FetchDescriptor<UserProgress>()).first)
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
            await service.syncProgress(context: context)

            // Assert
            let updatedProgress = try #require(context.fetch(FetchDescriptor<UserProgress>()).first)
            #expect(!updatedProgress.shouldDeletePhoto(.front))
            #expect(!updatedProgress.shouldDeletePhoto(.back))
            #expect(updatedProgress.isSynced)
        }

        @Test("Последовательное удаление фотографий обрабатывает ошибки корректно")
        func sequentialPhotoDeletionHandlesErrorsCorrectly() async throws {
            // Arrange
            let mockClient = MockProgressClient()
            mockClient.shouldThrowError = true
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
            await service.syncProgress(context: context)

            // Assert - прогресс должен остаться с помеченными фотографиями при ошибке
            let updatedProgress = try #require(context.fetch(FetchDescriptor<UserProgress>()).first)
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

            // Создаем прогресс с всеми фотографиями помеченными для удаления
            let progress = UserProgress(id: 1, pullUps: 10, pushUps: 20, squats: 30, weight: 70.0)
            progress.user = user
            progress.deletePhotoData(.front)
            progress.deletePhotoData(.back)
            progress.deletePhotoData(.side)
            context.insert(progress)
            try context.save()

            // Act
            await service.syncProgress(context: context)

            // Assert
            let updatedProgress = try #require(context.fetch(FetchDescriptor<UserProgress>()).first)
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

            // Создаем прогресс с данными и фотографиями
            let progress = UserProgress(id: 1, pullUps: 10, pushUps: 20, squats: 30, weight: 70.0)
            progress.user = user
            progress.setPhotoData(testImageData, type: .front)
            progress.setPhotoData(testImageData, type: .back)
            progress.setPhotoData(testImageData, type: .side)
            context.insert(progress)
            try context.save()

            // Помечаем фотографии для удаления
            progress.deletePhotoData(.front)
            progress.deletePhotoData(.back)

            // Act - синхронизируем
            await service.syncProgress(context: context)

            // Assert
            let updatedProgress = try #require(context.fetch(FetchDescriptor<UserProgress>()).first)
            #expect(!updatedProgress.shouldDeletePhoto(.front))
            #expect(!updatedProgress.shouldDeletePhoto(.back))
            #expect(!updatedProgress.shouldDeletePhoto(.side)) // Не была помечена для удаления
            #expect(updatedProgress.getPhotoData(.side) == testImageData) // Должна остаться
            #expect(updatedProgress.isSynced)
        }

        @Test("Тест ProgressSnapshot логики фильтрации фотографий")
        func progressSnapshotPhotoFiltering() {
            let progress = UserProgress(id: 1, pullUps: 10, pushUps: 20, squats: 30, weight: 70.0)

            // Устанавливаем данные фотографий
            let frontData = Data("front_photo".utf8)
            let backData = Data("back_photo".utf8)
            let sideData = Data("side_photo".utf8)

            progress.setPhotoData(frontData, type: .front)
            progress.setPhotoData(backData, type: .back)
            progress.setPhotoData(sideData, type: .side)

            // Помечаем заднюю фотографию для удаления
            progress.deletePhotoData(.back)

            let snapshot = ProgressSnapshot(from: progress)

            #expect(snapshot.shouldDeletePhoto, "shouldDeletePhoto должен быть true (есть фото для удаления)")
            #expect(!snapshot.isSynced, "Прогресс не синхронизирован")
            #expect(!snapshot.shouldDelete, "Прогресс не помечен для удаления (только фото помечено для удаления)")

            // Проверяем photosForUpload - только не удаленные фото должны быть включены
            let photosForUpload = snapshot.photosForUpload
            #expect(photosForUpload.count == 2, "Должно быть 2 фото для загрузки")
            #expect(photosForUpload["photo_front"] != nil, "photo_front должна быть в photosForUpload")
            #expect(photosForUpload["photo_side"] != nil, "photo_side должна быть в photosForUpload")
            #expect(photosForUpload["photo_back"] == nil, "photo_back НЕ должна быть в photosForUpload (помечена для удаления)")
        }

        @Test("Тест ProgressSnapshot с несколькими типами данных")
        func progressSnapshotMultipleDataTypes() {
            let progress = UserProgress(id: 1, pullUps: 10, pushUps: 20, squats: 30, weight: 70.0)

            // Устанавливаем только некоторые данные
            progress.setPhotoData(Data("front_photo".utf8), type: .front)
            progress.deletePhotoData(.side) // Помечаем для удаления без данных

            let snapshot = ProgressSnapshot(from: progress)

            #expect(snapshot.pullups == 10, "pullups должен соответствовать")
            #expect(snapshot.pushups == 20, "pushups должен соответствовать")
            #expect(snapshot.squats == 30, "squats должен соответствовать")
            #expect(snapshot.weight == 70.0, "weight должен соответствовать")

            #expect(snapshot.shouldDeletePhoto, "shouldDeletePhoto должен быть true")
            #expect(snapshot.photosForUpload.count == 1, "Должно быть 1 фото для загрузки")
            #expect(snapshot.photosForUpload["photo_front"] != nil, "photo_front должна быть в photosForUpload")
            #expect(snapshot.photosForUpload["photo_side"] == nil, "photo_side не должна быть в photosForUpload")
        }

        @Test("Тест ProgressSnapshot без фотографий для удаления")
        func progressSnapshotNoPhotosToDelete() {
            let progress = UserProgress(id: 1, pullUps: 10, pushUps: 20, squats: 30, weight: 70.0)
            progress.setPhotoData(Data("front_photo".utf8), type: .front)
            progress.setPhotoData(Data("back_photo".utf8), type: .back)

            let snapshot = ProgressSnapshot(from: progress)

            #expect(!snapshot.shouldDeletePhoto, "shouldDeletePhoto должен быть false")
            #expect(snapshot.photosForUpload.count == 2, "Должно быть 2 фото для загрузки")
            #expect(snapshot.photosForUpload["photo_front"] != nil, "photo_front должна быть в photosForUpload")
            #expect(snapshot.photosForUpload["photo_back"] != nil, "photo_back должна быть в photosForUpload")
        }

        @Test("Тест ProgressSnapshot с пустыми данными")
        func progressSnapshotEmptyData() {
            let progress = UserProgress(id: 1, pullUps: 0, pushUps: 0, squats: 0, weight: 0.0)

            let snapshot = ProgressSnapshot(from: progress)

            #expect(!snapshot.shouldDeletePhoto, "shouldDeletePhoto должен быть false")
            #expect(snapshot.photosForUpload.isEmpty, "photosForUpload должен быть пустым")
            #expect(snapshot.pullups == 0, "pullups должен быть 0")
            #expect(snapshot.pushups == 0, "pushups должен быть 0")
            #expect(snapshot.squats == 0, "squats должен быть 0")
            #expect(snapshot.weight == 0.0, "weight должен быть 0.0")
        }

        @Test("Тест isDeletedPhoto логики")
        func isDeletedPhotoLogic() {
            let progress = UserProgress(id: 1, pullUps: 10, pushUps: 20, squats: 30, weight: 70.0)

            // Тестируем с DELETED_DATA
            progress.setPhotoData(UserProgress.DELETED_DATA, type: .front)
            progress.setPhotoData(Data("normal_photo".utf8), type: .back)

            let snapshot = ProgressSnapshot(from: progress)

            #expect(snapshot.shouldDeletePhoto, "shouldDeletePhoto должен быть true")
            #expect(snapshot.photosForUpload.count == 1, "Должно быть 1 фото для загрузки")
            #expect(snapshot.photosForUpload["photo_front"] == nil, "photo_front не должна быть в photosForUpload")
            #expect(snapshot.photosForUpload["photo_back"] != nil, "photo_back должна быть в photosForUpload")
        }
    }
}
