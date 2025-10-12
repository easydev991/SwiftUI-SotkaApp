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
    }

    // MARK: - syncPhotos Tests

    @Test("Синхронизация фотографий без несинхронизированных фото")
    func syncPhotosWithNoUnsyncedPhotos() async throws {
        let mockClient = MockProgressClient()
        let service = ProgressSyncService(client: mockClient)
        let progress = Progress(id: 1)

        // Создаем синхронизированную фотографию
        let photo = ProgressPhoto(type: .front, data: testImageData)
        photo.isSynced = true
        progress.photos.append(photo)

        await service.syncPhotos(for: progress, client: mockClient)

        // Проверяем, что метод не выбрасывает ошибку
        #expect(progress.photos.count == 1)
    }

    @Test("Синхронизация фотографий с несинхронизированными фото")
    func syncPhotosWithUnsyncedPhotos() async throws {
        let mockClient = MockProgressClient()
        let service = ProgressSyncService(client: mockClient)
        let progress = Progress(id: 1)

        // Создаем несинхронизированную фотографию
        let photo = ProgressPhoto(type: .front, data: testImageData)
        photo.isSynced = false
        progress.photos.append(photo)

        // Мокаем ответ сервера с URL фотографии
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
        mockClient.mockedProgressResponses = [serverResponse]

        await service.syncPhotos(for: progress, client: mockClient)

        // Проверяем, что фотография обновлена с URL
        let updatedPhoto = try #require(progress.getPhoto(.front))
        #expect(updatedPhoto.urlString == "https://example.com/photo_front.jpg")
        #expect(updatedPhoto.isSynced)
    }

    @Test("Синхронизация фотографий с фотографиями для удаления")
    func syncPhotosWithPhotosToDelete() async throws {
        let mockClient = MockProgressClient()
        let service = ProgressSyncService(client: mockClient)
        let progress = Progress(id: 1)

        // Создаем фотографию для удаления
        let photo = ProgressPhoto(type: .front, data: testImageData)
        photo.isDeleted = true
        progress.photos.append(photo)

        await service.syncPhotos(for: progress, client: mockClient)

        // Проверяем, что метод не выбрасывает ошибку
        #expect(progress.photos.count == 1)
    }

    @Test("Синхронизация фотографий с ошибкой сети")
    func syncPhotosWithNetworkError() async throws {
        let mockClient = MockProgressClient()
        let service = ProgressSyncService(client: mockClient)
        let progress = Progress(id: 1)

        // Создаем несинхронизированную фотографию
        let photo = ProgressPhoto(type: .front, data: testImageData)
        photo.isSynced = false
        progress.photos.append(photo)

        // Настраиваем клиент на выброс ошибки
        mockClient.shouldThrowError = true

        await service.syncPhotos(for: progress, client: mockClient)

        // Проверяем, что фотография остается несинхронизированной
        let unsyncedPhoto = try #require(progress.getPhoto(.front))
        #expect(!unsyncedPhoto.isSynced)
    }

    // MARK: - prepareProgressDataWithPhotos Tests

    @Test("Подготовка данных прогресса с фотографиями")
    func prepareProgressDataWithPhotos() async throws {
        let mockClient = MockProgressClient()
        let service = ProgressSyncService(client: mockClient)
        let progress = Progress(id: 1, pullUps: 10, pushUps: 20, squats: 30, weight: 70.0)

        // Добавляем фотографии
        let frontPhoto = ProgressPhoto(type: .front, data: testImageData)
        let backPhoto = ProgressPhoto(type: .back, data: testImageData)
        let sidePhoto = ProgressPhoto(type: .side, data: testImageData)

        progress.photos.append(frontPhoto)
        progress.photos.append(backPhoto)
        progress.photos.append(sidePhoto)

        // Используем рефлексию для доступа к приватному методу
        let mirror = Mirror(reflecting: service)
        _ = mirror.children.first { $0.label == "prepareProgressDataWithPhotos" }

        // Поскольку метод приватный, мы не можем его протестировать напрямую
        // Вместо этого тестируем через публичный метод syncPhotos
        await service.syncPhotos(for: progress, client: mockClient)

        #expect(progress.photos.count == 3)
    }

    // MARK: - updateProgressFromServerResponse Tests

    @Test("Обновление прогресса из ответа сервера с новыми фотографиями")
    func updateProgressFromServerResponseWithNewPhotos() async throws {
        let mockClient = MockProgressClient()
        let service = ProgressSyncService(client: mockClient)
        let progress = Progress(id: 1)
        progress.isSynced = false // Устанавливаем как несинхронизированный

        // Добавляем несинхронизированную фотографию, чтобы syncPhotos не выходил рано
        let unsyncedPhoto = ProgressPhoto(type: .front, data: testImageData)
        unsyncedPhoto.isSynced = false
        progress.photos.append(unsyncedPhoto)

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
        mockClient.mockedProgressResponses = [serverResponse]

        await service.syncPhotos(for: progress, client: mockClient)

        // Проверяем, что фотографии созданы с URL
        #expect(progress.photos.count == 3)

        let frontPhoto = try #require(progress.getPhoto(.front))
        #expect(frontPhoto.urlString == "https://example.com/photo_front.jpg")
        #expect(frontPhoto.isSynced)

        let backPhoto = try #require(progress.getPhoto(.back))
        #expect(backPhoto.urlString == "https://example.com/photo_back.jpg")
        #expect(backPhoto.isSynced)

        let sidePhoto = try #require(progress.getPhoto(.side))
        #expect(sidePhoto.urlString == "https://example.com/photo_side.jpg")
        #expect(sidePhoto.isSynced)
    }

    @Test("Обновление прогресса из ответа сервера с обновлением существующих фотографий")
    func updateProgressFromServerResponseWithExistingPhotos() async throws {
        let mockClient = MockProgressClient()
        let service = ProgressSyncService(client: mockClient)
        let progress = Progress(id: 1)

        // Создаем существующие фотографии
        let frontPhoto = ProgressPhoto(type: .front, data: testImageData)
        frontPhoto.isSynced = false
        progress.photos.append(frontPhoto)

        let serverResponse = ProgressResponse(
            id: 1,
            pullups: 10,
            pushups: 20,
            squats: 30,
            weight: 70.0,
            createDate: DateFormatterService.stringFromFullDate(Date(), format: .serverDateTimeSec),
            modifyDate: DateFormatterService.stringFromFullDate(Date(), format: .serverDateTimeSec),
            photoFront: "https://example.com/updated_photo_front.jpg"
        )
        mockClient.mockedProgressResponses = [serverResponse]

        await service.syncPhotos(for: progress, client: mockClient)

        // Проверяем, что существующая фотография обновлена
        #expect(progress.photos.count == 1)
        let updatedPhoto = try #require(progress.getPhoto(.front))
        #expect(updatedPhoto.urlString == "https://example.com/updated_photo_front.jpg")
        #expect(updatedPhoto.isSynced)
    }

    @Test("Обновление прогресса из ответа сервера без фотографий")
    func updateProgressFromServerResponseWithoutPhotos() async throws {
        let mockClient = MockProgressClient()
        let service = ProgressSyncService(client: mockClient)
        let progress = Progress(id: 1)
        progress.isSynced = false // Устанавливаем начальное состояние

        // Добавляем несинхронизированную фотографию, чтобы syncPhotos не выходил рано
        let unsyncedPhoto = ProgressPhoto(type: .front, data: testImageData)
        unsyncedPhoto.isSynced = false
        progress.photos.append(unsyncedPhoto)

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

        await service.syncPhotos(for: progress, client: mockClient)

        // Проверяем, что несинхронизированная фотография осталась
        // (так как сервер не вернул фотографий, но локальная фотография не удаляется)
        #expect(progress.photos.count == 1)
        #expect(progress.isSynced) // После синхронизации должно быть true
    }

    // MARK: - Integration Tests

    @Test("Полная синхронизация фотографий", arguments: [false, true])
    func fullPhotoSync(initialIsSynced: Bool) async throws {
        let mockClient = MockProgressClient()
        let service = ProgressSyncService(client: mockClient)
        let progress = Progress(id: 1)
        progress.isSynced = initialIsSynced

        // Добавляем несинхронизированную фотографию
        let photo = ProgressPhoto(type: .front, data: testImageData)
        photo.isSynced = false
        progress.photos.append(photo)

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
        mockClient.mockedProgressResponses = [serverResponse]

        await service.syncPhotos(for: progress, client: mockClient)

        // Проверяем результат
        #expect(progress.isSynced)
        #expect(progress.photos.count == 1)

        let syncedPhoto = try #require(progress.getPhoto(.front))
        #expect(syncedPhoto.isSynced)
        #expect(syncedPhoto.urlString == "https://example.com/photo_front.jpg")
    }
}
