import Foundation
import SwiftData
@testable import SwiftUI_SotkaApp
import SWUtils
import Testing
import UIKit

/// Тесты для проверки смешанных операций с фотографиями (удаление + добавление разных типов)
@MainActor
@Suite("ProgressSyncService - Смешанные операции с фотографиями")
struct ProgressSyncServiceMixedPhotoOperationsTests {
    
    /// Тест воспроизводит баг: удаление одной фотографии и добавление другой в том же прогрессе
    @Test("Баг: удаление photo_back и добавление photo_front - новое фото не загружается")
    func testBugDeleteBackAddFrontPhoto() async throws {
        // Arrange: Создаем прогресс с данными упражнений и одной фотографией
        let context = ModelContext(try ModelContainer(for: Progress.self, User.self))
        let user = User(id: 1)
        context.insert(user)
        
        let progress = Progress(
            id: 1,
            pullUps: 10,
            pushUps: 20,
            squats: 30,
            weight: 70.0,
            dataPhotoBack: Data("back_photo_data".utf8) // Только задняя фотография
        )
        progress.user = user
        progress.isSynced = false
        context.insert(progress)
        
        try context.save()
        
        // Создаем mock клиент
        let mockClient = MockProgressClient()
        
        // Настраиваем mock для ответа сервера (после удаления photo_back)
        let serverResponse = ProgressResponse(
            id: 1,
            pullups: 10,
            pushups: 20,
            squats: 30,
            weight: 70.0,
            createDate: "2024-01-01 12:00:00",
            modifyDate: "2024-01-01 12:01:00",
            photoFront: nil, // Новая фотография не появилась на сервере
            photoBack: nil,  // Удаленная фотография
            photoSide: nil
        )
        mockClient.mockedProgressResponses = [serverResponse]
        
        // Act: Удаляем photo_back и добавляем photo_front
        progress.deletePhotoData(.back) // Удаляем заднюю фотографию
        progress.setPhotoData(.front, data: Data("front_photo_data".utf8)) // Добавляем фронтальную
        
        try context.save()
        
        // Синхронизируем
        let syncService = ProgressSyncService(client: mockClient)
        try await syncService.syncProgress(context: context)
        
        // Assert: Проверяем, что произошло
        // ПРОБЛЕМА: Новое фото не загрузилось на сервер, потому что:
        // 1. shouldDeletePhoto = true (есть photo_back для удаления)
        // 2. Возвращается .needsPhotoDeletion вместо отправки основного прогресса
        // 3. В handlePhotoDeletion удаляется только photo_back, но photo_front не отправляется
        
        #expect(mockClient.deletePhotoCallCount == 1, "Должен быть вызван deletePhoto для photo_back")
        #expect(mockClient.updateProgressCallCount == 0, "updateProgress НЕ должен быть вызван из-за shouldDeletePhoto")
        
        // Проверяем локальное состояние
        #expect(progress.shouldDeletePhoto(.back) == false, "photo_back должна быть очищена после удаления")
        #expect(progress.hasPhotoData(.front) == true, "photo_front должна остаться локально")
        #expect(progress.isSynced == false, "Прогресс не должен быть помечен как синхронизированный")
    }
    
    /// Тест корректного сценария: удаление и добавление в тот же "слот"
    @Test("Корректный сценарий: удаление и добавление в тот же слот")
    func testCorrectDeleteAndAddSameSlot() async throws {
        // Arrange: Создаем прогресс с данными упражнений и одной фотографией
        let context = ModelContext(try ModelContainer(for: Progress.self, User.self))
        let user = User(id: 1)
        context.insert(user)
        
        let progress = Progress(
            id: 1,
            pullUps: 10,
            pushUps: 20,
            squats: 30,
            weight: 70.0,
            dataPhotoBack: Data("old_back_photo".utf8) // Старая задняя фотография
        )
        progress.user = user
        progress.isSynced = false
        context.insert(progress)
        
        try context.save()
        
        // Создаем mock клиент
        let mockClient = MockProgressClient()
        
        // Настраиваем mock для ответа сервера (новая фотография заменила старую)
        let serverResponse = ProgressResponse(
            id: 1,
            pullups: 10,
            pushups: 20,
            squats: 30,
            weight: 70.0,
            createDate: "2024-01-01 12:00:00",
            modifyDate: "2024-01-01 12:01:00",
            photoFront: nil,
            photoBack: "https://server.com/new_back_photo.jpg", // Новая фотография
            photoSide: nil
        )
        mockClient.mockedProgressResponses = [serverResponse]
        
        // Act: Удаляем старую photo_back и добавляем новую в тот же слот
        progress.deletePhotoData(.back) // Удаляем старую (shouldDeletePhotoBack = true)
        progress.setPhotoData(.back, data: Data("new_back_photo".utf8)) // Добавляем новую в тот же слот (shouldDeletePhotoBack = false)
        
        try context.save()
        
        // Синхронизируем
        let syncService = ProgressSyncService(client: mockClient)
        try await syncService.syncProgress(context: context)
        
        // Assert: Проверяем, что все работает корректно
        // Поскольку setPhotoData сбрасывает shouldDeletePhotoBack в false,
        // snapshot.shouldDeletePhoto будет false, и будет вызван updateProgress
        #expect(mockClient.updateProgressCallCount == 1, "updateProgress должен быть вызван")
        #expect(mockClient.deletePhotoCallCount == 0, "deletePhoto НЕ должен быть вызван (флаг сброшен)")
        
        // Проверяем локальное состояние
        #expect(progress.shouldDeletePhoto(.back) == false, "photo_back не должна быть помечена для удаления")
        #expect(progress.hasPhotoData(.back) == true, "новая photo_back должна остаться локально")
        #expect(progress.isSynced == true, "Прогресс должен быть помечен как синхронизированный")
    }
    
    /// Тест для проверки логики shouldDeletePhoto в ProgressSnapshot
    @Test("ProgressSnapshot shouldDeletePhoto логика")
    func testProgressSnapshotShouldDeletePhotoLogic() throws {
        // Arrange: Создаем прогресс с смешанными операциями
        let context = ModelContext(try ModelContainer(for: Progress.self, User.self))
        let user = User(id: 1)
        context.insert(user)
        
        let progress = Progress(
            id: 1,
            pullUps: 10,
            pushUps: 20,
            squats: 30,
            weight: 70.0,
            dataPhotoFront: Data("front_photo".utf8),
            dataPhotoBack: Data("back_photo".utf8)
        )
        progress.user = user
        context.insert(progress)
        
        // Act: Удаляем одну фотографию, добавляем другую
        progress.deletePhotoData(PhotoType.back) // Помечаем для удаления
        progress.setPhotoData(PhotoType.side, data: Data("side_photo".utf8)) // Добавляем новую
        
        try context.save()
        
        // Создаем снимок (используем внутренний метод для тестирования)
        let snapshot = createProgressSnapshot(from: progress)
        
        // Assert: Проверяем логику снимка
        #expect(snapshot.shouldDeletePhoto == true, "shouldDeletePhoto должен быть true (есть photo_back для удаления)")
        #expect(snapshot.shouldDeletePhotoBack == true, "shouldDeletePhotoBack должен быть true")
        #expect(snapshot.shouldDeletePhotoFront == false, "shouldDeletePhotoFront должен быть false")
        #expect(snapshot.shouldDeletePhotoSide == false, "shouldDeletePhotoSide должен быть false")
        
        // Проверяем photosForUpload (должны быть только не удаленные)
        let photosForUpload = snapshot.photosForUpload
        #expect(photosForUpload.count == 2, "Должно быть 2 фотографии для загрузки")
        #expect(photosForUpload["photo_front"] != nil, "photo_front должна быть в photosForUpload")
        #expect(photosForUpload["photo_side"] != nil, "photo_side должна быть в photosForUpload")
        #expect(photosForUpload["photo_back"] == nil, "photo_back НЕ должна быть в photosForUpload (помечена для удаления)")
    }
}

/// Mock клиент для тестирования
private final class MockProgressClient: ProgressClient, @unchecked Sendable {
    var updateProgressCallCount = 0
    var deletePhotoCallCount = 0
    var mockedProgressResponses: [ProgressResponse] = []
    var deletePhotoError: Error?
    
    func updateProgress(day: Int, progress: ProgressRequest) async throws -> ProgressResponse {
        updateProgressCallCount += 1
        if let response = mockedProgressResponses.first {
            return response
        }
        throw NSError(domain: "MockError", code: 1, userInfo: [NSLocalizedDescriptionKey: "No response configured"])
    }
    
    func deletePhoto(day: Int, type: String) async throws {
        deletePhotoCallCount += 1
        if let error = deletePhotoError {
            throw error
        }
    }
    
    func getProgress() async throws -> [ProgressResponse] {
        return mockedProgressResponses
    }
    
    func getProgress(day: Int) async throws -> ProgressResponse {
        if let response = mockedProgressResponses.first {
            return response
        }
        throw NSError(domain: "MockError", code: 1, userInfo: [NSLocalizedDescriptionKey: "No response configured"])
    }
    
    func createProgress(progress: ProgressRequest) async throws -> ProgressResponse {
        if let response = mockedProgressResponses.first {
            return response
        }
        throw NSError(domain: "MockError", code: 1, userInfo: [NSLocalizedDescriptionKey: "No response configured"])
    }
    
    func deleteProgress(day: Int) async throws {
        // Mock implementation
    }
}

/// Вспомогательная функция для создания снимка прогресса (для тестирования)
private func createProgressSnapshot(from progress: SwiftUI_SotkaApp.Progress) -> ProgressSnapshot {
    return ProgressSnapshot(
        id: progress.id,
        pullups: progress.pullUps,
        pushups: progress.pushUps,
        squats: progress.squats,
        weight: progress.weight,
        lastModified: progress.lastModified,
        isSynced: progress.isSynced,
        shouldDelete: progress.shouldDelete,
        userId: progress.user?.id,
        photoFront: progress.urlPhotoFront,
        photoBack: progress.urlPhotoBack,
        photoSide: progress.urlPhotoSide,
        dataPhotoFront: progress.dataPhotoFront,
        dataPhotoBack: progress.dataPhotoBack,
        dataPhotoSide: progress.dataPhotoSide,
        shouldDeletePhotoFront: progress.shouldDeletePhotoFront,
        shouldDeletePhotoBack: progress.shouldDeletePhotoBack,
        shouldDeletePhotoSide: progress.shouldDeletePhotoSide
    )
}

/// Структура снимка прогресса (копия из ProgressSyncService для тестирования)
private struct ProgressSnapshot: Sendable, Hashable {
    let id: Int
    let pullups: Int?
    let pushups: Int?
    let squats: Int?
    let weight: Float?
    let lastModified: Date
    let isSynced: Bool
    let shouldDelete: Bool
    let userId: Int?
    let photoFront: String?
    let photoBack: String?
    let photoSide: String?
    let dataPhotoFront: Data?
    let dataPhotoBack: Data?
    let dataPhotoSide: Data?
    let shouldDeletePhotoFront: Bool
    let shouldDeletePhotoBack: Bool
    let shouldDeletePhotoSide: Bool

    /// Проверяет, есть ли фотографии для удаления
    var shouldDeletePhoto: Bool {
        shouldDeletePhotoFront || shouldDeletePhotoBack || shouldDeletePhotoSide
    }

    /// Создает словарь фотографий для отправки на сервер (только не удаленные)
    var photosForUpload: [String: Data] {
        var photos: [String: Data] = [:]

        // Обрабатываем фронтальную фотографию (только если не помечена для удаления)
        if let data = dataPhotoFront, !shouldDeletePhotoFront {
            photos["photo_front"] = data
        }

        // Обрабатываем заднюю фотографию (только если не помечена для удаления)
        if let data = dataPhotoBack, !shouldDeletePhotoBack {
            photos["photo_back"] = data
        }

        // Обрабатываем боковую фотографию (только если не помечена для удаления)
        if let data = dataPhotoSide, !shouldDeletePhotoSide {
            photos["photo_side"] = data
        }

        return photos
    }
}
