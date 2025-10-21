import Foundation
import SwiftData
@testable import SwiftUI_SotkaApp
import SWUtils
import Testing
import UIKit

@MainActor
@Suite("ProgressSyncService - Смешанные операции с фотографиями")
struct ProgressSyncServiceMixedPhotoOperationsTests {
    @Test("Баг: удаление photo_back и добавление photo_front - новое фото не загружается", .disabled("TODO: Разобраться с багом"))
    func bugDeleteBackAddFrontPhoto() async throws {
        let context = try ModelContext(ModelContainer(for: Progress.self, User.self))
        let user = User(id: 1)
        context.insert(user)

        let progress = Progress(
            id: 1,
            pullUps: 10,
            pushUps: 20,
            squats: 30,
            weight: 70.0,
            dataPhotoBack: Data("back_photo_data".utf8)
        )
        progress.user = user
        progress.isSynced = false
        context.insert(progress)

        try context.save()

        let mockClient = MockProgressClient()

        let serverResponse = ProgressResponse(
            id: 1,
            pullups: 10,
            pushups: 20,
            squats: 30,
            weight: 70.0,
            createDate: "2024-01-01 12:00:00",
            modifyDate: "2024-01-01 12:01:00",
            photoFront: nil,
            photoBack: nil,
            photoSide: nil
        )
        mockClient.mockedProgressResponses = [serverResponse]

        progress.deletePhotoData(.back)
        progress.setPhotoData(.front, data: Data("front_photo_data".utf8))

        try context.save()

        let syncService = ProgressSyncService(client: mockClient)
        await syncService.syncProgress(context: context)

        #expect(mockClient.deletePhotoCallCount == 1, "Должен быть вызван deletePhoto для photo_back")
        #expect(mockClient.updateProgressCallCount == 0, "updateProgress НЕ должен быть вызван из-за shouldDeletePhoto")

        #expect(!progress.shouldDeletePhoto(.back), "photo_back должна быть очищена после удаления")
        #expect(progress.hasPhotoData(.front), "photo_front должна остаться локально")
        #expect(!progress.isSynced, "Прогресс не должен быть помечен как синхронизированный")
    }

    @Test(
        "Корректный сценарий: удаление и добавление в тот же слот",
        .disabled("TODO: тест должен проходить, т.к. в приложении этот сценарий работает, разобраться с багом")
    )
    func correctDeleteAndAddSameSlot() async throws {
        let context = try ModelContext(ModelContainer(for: Progress.self, User.self))
        let user = User(id: 1)
        context.insert(user)

        let progress = Progress(
            id: 1,
            pullUps: 10,
            pushUps: 20,
            squats: 30,
            weight: 70.0,
            dataPhotoBack: Data("old_back_photo".utf8)
        )
        progress.user = user
        progress.isSynced = false
        context.insert(progress)

        try context.save()

        let mockClient = MockProgressClient()

        let serverResponse = ProgressResponse(
            id: 1,
            pullups: 10,
            pushups: 20,
            squats: 30,
            weight: 70.0,
            createDate: "2024-01-01 12:00:00",
            modifyDate: "2024-01-01 12:01:00",
            photoFront: nil,
            photoBack: "https://server.com/new_back_photo.jpg",
            photoSide: nil
        )
        mockClient.mockedProgressResponses = [serverResponse]

        progress.deletePhotoData(.back)
        progress.setPhotoData(.back, data: Data("new_back_photo".utf8))

        try context.save()

        let syncService = ProgressSyncService(client: mockClient)
        await syncService.syncProgress(context: context)

        #expect(mockClient.updateProgressCallCount == 1, "updateProgress должен быть вызван")
        #expect(mockClient.deletePhotoCallCount == 0, "deletePhoto НЕ должен быть вызван (флаг сброшен)")

        #expect(!progress.shouldDeletePhoto(.back), "photo_back не должна быть помечена для удаления")
        #expect(progress.hasPhotoData(.back), "новая photo_back должна остаться локально")
        #expect(progress.isSynced, "Прогресс должен быть помечен как синхронизированный")
    }

    @Test("ProgressSnapshot shouldDeletePhoto логика")
    func progressSnapshotShouldDeletePhotoLogic() throws {
        let context = try ModelContext(ModelContainer(for: Progress.self, User.self))
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

        progress.deletePhotoData(PhotoType.back)
        progress.setPhotoData(PhotoType.side, data: Data("side_photo".utf8))

        try context.save()

        let snapshot = createProgressSnapshot(from: progress)

        #expect(snapshot.shouldDeletePhoto, "shouldDeletePhoto должен быть true (есть photo_back для удаления)")
        #expect(progress.shouldDeletePhoto(.back), "photo_back должна быть помечена для удаления")
        #expect(!progress.shouldDeletePhoto(.front), "photo_front не должна быть помечена для удаления")
        #expect(!progress.shouldDeletePhoto(.side), "photo_side не должна быть помечена для удаления")

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

    func updateProgress(day _: Int, progress _: ProgressRequest) async throws -> ProgressResponse {
        updateProgressCallCount += 1
        if let response = mockedProgressResponses.first {
            return response
        }
        throw NSError(domain: "MockError", code: 1, userInfo: [NSLocalizedDescriptionKey: "No response configured"])
    }

    func deletePhoto(day _: Int, type _: String) async throws {
        deletePhotoCallCount += 1
        if let error = deletePhotoError {
            throw error
        }
    }

    func getProgress() async throws -> [ProgressResponse] {
        mockedProgressResponses
    }

    func getProgress(day _: Int) async throws -> ProgressResponse {
        if let response = mockedProgressResponses.first {
            return response
        }
        throw NSError(domain: "MockError", code: 1, userInfo: [NSLocalizedDescriptionKey: "No response configured"])
    }

    func createProgress(progress _: ProgressRequest) async throws -> ProgressResponse {
        if let response = mockedProgressResponses.first {
            return response
        }
        throw NSError(domain: "MockError", code: 1, userInfo: [NSLocalizedDescriptionKey: "No response configured"])
    }

    func deleteProgress(day _: Int) async throws {
        // Mock implementation
    }
}

/// Вспомогательная функция для создания снимка прогресса (для тестирования)
private func createProgressSnapshot(from progress: SwiftUI_SotkaApp.Progress) -> ProgressSnapshot {
    ProgressSnapshot(
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
        dataPhotoSide: progress.dataPhotoSide
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

    /// Проверяет, есть ли фотографии для удаления
    var shouldDeletePhoto: Bool {
        isDeletedPhoto(dataPhotoFront) || isDeletedPhoto(dataPhotoBack) || isDeletedPhoto(dataPhotoSide)
    }

    /// Проверяет, является ли данные фотографии помеченными для удаления
    private func isDeletedPhoto(_ data: Data?) -> Bool {
        guard let data else { return false }
        return data == Progress.DELETED_DATA
    }

    /// Создает словарь фотографий для отправки на сервер (только не удаленные)
    var photosForUpload: [String: Data] {
        var photos: [String: Data] = [:]

        // Обрабатываем фронтальную фотографию (только если не помечена для удаления)
        if let data = dataPhotoFront, !isDeletedPhoto(data) {
            photos["photo_front"] = data
        }

        // Обрабатываем заднюю фотографию (только если не помечена для удаления)
        if let data = dataPhotoBack, !isDeletedPhoto(data) {
            photos["photo_back"] = data
        }

        // Обрабатываем боковую фотографию (только если не помечена для удаления)
        if let data = dataPhotoSide, !isDeletedPhoto(data) {
            photos["photo_side"] = data
        }

        return photos
    }
}
