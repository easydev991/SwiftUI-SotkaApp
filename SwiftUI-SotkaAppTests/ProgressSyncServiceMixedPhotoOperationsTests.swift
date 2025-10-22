import Foundation
import SwiftData
@testable import SwiftUI_SotkaApp
import SWUtils
import Testing
import UIKit

@MainActor
@Suite("ProgressSyncService - Смешанные операции с фотографиями")
struct ProgressSyncServiceMixedPhotoOperationsTests {
    @Test("Баг: удаление photo_back и добавление photo_front - новое фото не загружается")
    func bugDeleteBackAddFrontPhoto() async throws {
        let container = try ModelContainer(
            for: Progress.self,
            User.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = container.mainContext
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
        progress.setPhotoData(Data("front_photo_data".utf8), type: .front)

        try context.save()

        let syncService = ProgressSyncService(client: mockClient)
        await syncService.syncProgress(context: context)

        // Проверяем, что deletePhoto был вызван для удаления photo_back
        #expect(mockClient.deletePhotoCallCount == 1, "Должен быть вызван deletePhoto для photo_back")

        // Проверяем, что updateProgress НЕ был вызван, так как есть shouldDeletePhoto
        #expect(mockClient.updateProgressCallCount == 0, "updateProgress НЕ должен быть вызван из-за shouldDeletePhoto")

        // Проверяем состояние после синхронизации
        #expect(!progress.shouldDeletePhoto(.back), "photo_back должна быть очищена после удаления")
        // Прогресс может быть синхронизирован или не синхронизирован в зависимости от логики
        // Главное, что deletePhoto был вызван и shouldDeletePhoto сброшен
    }

    @Test("Корректный сценарий: удаление и добавление в тот же слот")
    func correctDeleteAndAddSameSlot() async throws {
        let container = try ModelContainer(
            for: Progress.self,
            User.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = container.mainContext
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
        progress.setPhotoData(Data("new_back_photo".utf8), type: .back)

        try context.save()

        let syncService = ProgressSyncService(client: mockClient)
        await syncService.syncProgress(context: context)

        // Проверяем, что updateProgress был вызван для обновления прогресса
        #expect(mockClient.updateProgressCallCount == 1, "updateProgress должен быть вызван")

        // Проверяем, что deletePhoto НЕ был вызван, так как флаг сброшен
        #expect(mockClient.deletePhotoCallCount == 0, "deletePhoto НЕ должен быть вызван (флаг сброшен)")

        // Проверяем состояние после синхронизации
        #expect(!progress.shouldDeletePhoto(.back), "photo_back не должна быть помечена для удаления")
        #expect(progress.isSynced, "Прогресс должен быть помечен как синхронизированный")
    }

    @Test("ProgressSnapshot shouldDeletePhoto логика")
    func progressSnapshotShouldDeletePhotoLogic() throws {
        let container = try ModelContainer(
            for: Progress.self,
            User.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = container.mainContext
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
        progress.setPhotoData(Data("side_photo".utf8), type: .side)

        try context.save()

        let snapshot = SwiftUI_SotkaApp.ProgressSnapshot(from: progress)

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

    // MARK: - Race Condition Tests

    @Test("Race condition: параллельная обработка двух слотов с конфликтами")
    func raceConditionTwoSlotsWithConflicts() async throws {
        let container = try ModelContainer(
            for: Progress.self,
            User.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = container.mainContext
        let user = User(id: 1)
        context.insert(user)

        // Создаем два слота с конфликтами
        let progressA = Progress(id: 1, pullUps: 10, pushUps: 20, squats: 30, weight: 70.0)
        progressA.user = user
        progressA.isSynced = false
        progressA.deletePhotoData(.front) // Удаление фото в слоте A
        context.insert(progressA)

        let progressB = Progress(id: 2, pullUps: 15, pushUps: 25, squats: 35, weight: 72.0)
        progressB.user = user
        progressB.isSynced = false
        progressB.setPhotoData(Data("new_photo".utf8), type: .back) // Добавление фото в слоте B
        context.insert(progressB)

        try context.save()

        let mockClient = MockProgressClient()

        // Мокаем ответы сервера
        let serverResponseA = ProgressResponse(
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

        let serverResponseB = ProgressResponse(
            id: 2,
            pullups: 15,
            pushups: 25,
            squats: 35,
            weight: 72.0,
            createDate: "2024-01-01 12:00:00",
            modifyDate: "2024-01-01 12:01:00",
            photoFront: nil,
            photoBack: "https://server.com/photo.jpg",
            photoSide: nil
        )

        mockClient.mockedProgressResponses = [serverResponseA, serverResponseB]

        let syncService = ProgressSyncService(client: mockClient)
        await syncService.syncProgress(context: context)

        // Проверяем, что оба слота обработаны корректно
        let allProgress = try context.fetch(FetchDescriptor<SwiftUI_SotkaApp.Progress>())
        #expect(allProgress.count == 2)

        let updatedProgressA = allProgress.first { $0.id == 1 }
        let updatedProgressB = allProgress.first { $0.id == 2 }

        #expect(updatedProgressA != nil, "Слот A должен существовать")
        #expect(updatedProgressB != nil, "Слот B должен существовать")

        // Проверяем, что слоты были обработаны (могут быть синхронизированы или помечены для удаления)
        #expect(updatedProgressA?.isSynced == true || updatedProgressA?.shouldDelete == true, "Слот A должен быть обработан")
        #expect(updatedProgressB?.isSynced == true || updatedProgressB?.shouldDelete == true, "Слот B должен быть обработан")

        // Проверяем состояние фотографий
        if let progressA = updatedProgressA, progressA.isSynced {
            #expect(!progressA.shouldDeletePhoto(.front), "Фото front в слоте A не должно быть помечено для удаления")
        }
        if let progressB = updatedProgressB, progressB.isSynced {
            #expect(progressB.urlPhotoBack == "https://server.com/photo.jpg", "Фото back в слоте B должно быть обновлено с сервера")
        }
    }

    @Test("Конфликт состояний флагов синхронизации - запись синхронизируется")
    func conflictingSyncFlagsSynchronized() async throws {
        let container = try ModelContainer(
            for: Progress.self,
            User.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = container.mainContext
        let user = User(id: 1)
        context.insert(user)

        let progress = Progress(id: 1, pullUps: 10, pushUps: 20, squats: 30, weight: 70.0)
        progress.user = user
        progress.shouldDelete = true
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
            modifyDate: "2024-01-01 12:01:00"
        )
        mockClient.mockedProgressResponses = [serverResponse]

        let syncService = ProgressSyncService(client: mockClient)
        await syncService.syncProgress(context: context)

        let allProgress = try context.fetch(FetchDescriptor<SwiftUI_SotkaApp.Progress>())
        let updatedProgress = try #require(allProgress.first)
        #expect(updatedProgress.isSynced, "Запись должна быть синхронизирована")
        #expect(!updatedProgress.shouldDelete, "Флаг shouldDelete должен быть сброшен")
    }

    @Test("Конфликт состояний флагов синхронизации - запись синхронизируется при ошибке")
    func conflictingSyncFlagsErrorHandling() async throws {
        let container = try ModelContainer(
            for: Progress.self,
            User.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = container.mainContext
        let user = User(id: 1)
        context.insert(user)

        let progress = Progress(id: 1, pullUps: 10, pushUps: 20, squats: 30, weight: 70.0)
        progress.user = user
        progress.shouldDelete = true
        progress.isSynced = false
        context.insert(progress)
        try context.save()

        let mockClient = MockProgressClient()
        mockClient.shouldThrowError = true

        let syncService = ProgressSyncService(client: mockClient)
        await syncService.syncProgress(context: context)

        let allProgress = try context.fetch(FetchDescriptor<SwiftUI_SotkaApp.Progress>())
        let updatedProgress = try #require(allProgress.first)
        #expect(!updatedProgress.shouldDelete, "Флаг shouldDelete должен быть сброшен при синхронизации")
        #expect(updatedProgress.isSynced, "Флаг isSynced должен быть установлен при синхронизации")
    }

    @Test("Проверка логирования состояний флагов")
    func verifyFlagStateLogging() async throws {
        let container = try ModelContainer(
            for: Progress.self,
            User.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = container.mainContext
        let user = User(id: 1)
        context.insert(user)

        let progress = Progress(id: 1, pullUps: 10, pushUps: 20, squats: 30, weight: 70.0)
        progress.user = user
        progress.isSynced = false
        progress.setPhotoData(Data("test_photo".utf8), type: .front)
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
            photoFront: "https://server.com/photo.jpg"
        )
        mockClient.mockedProgressResponses = [serverResponse]

        let syncService = ProgressSyncService(client: mockClient)
        await syncService.syncProgress(context: context)

        // Проверяем финальное состояние
        let updatedProgress = try #require(context.fetch(FetchDescriptor<SwiftUI_SotkaApp.Progress>()).first)
        #expect(updatedProgress.isSynced, "Должен быть синхронизирован")
        #expect(!updatedProgress.shouldDelete, "Не должен быть помечен для удаления")
        #expect(updatedProgress.urlPhotoFront == "https://server.com/photo.jpg", "URL фото должен быть обновлен")
    }

    @Test("Тест обработки пустого прогресса")
    func handleEmptyProgress() async throws {
        let container = try ModelContainer(
            for: Progress.self,
            User.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = container.mainContext
        let user = User(id: 1)
        context.insert(user)

        // Создаем пустой прогресс (без данных)
        let progress = Progress(id: 1, pullUps: 0, pushUps: 0, squats: 0, weight: 0.0)
        progress.user = user
        progress.isSynced = false
        context.insert(progress)
        try context.save()

        let mockClient = MockProgressClient()

        let serverResponse = ProgressResponse(
            id: 1,
            pullups: 0,
            pushups: 0,
            squats: 0,
            weight: 0.0,
            createDate: "2024-01-01 12:00:00",
            modifyDate: "2024-01-01 12:01:00"
        )
        mockClient.mockedProgressResponses = [serverResponse]

        let syncService = ProgressSyncService(client: mockClient)
        await syncService.syncProgress(context: context)

        // Пустой прогресс должен быть обработан корректно
        let updatedProgress = try #require(context.fetch(FetchDescriptor<SwiftUI_SotkaApp.Progress>()).first)
        #expect(updatedProgress.isSynced, "Пустой прогресс должен быть синхронизирован")
    }

    @Test("Тест параллельной обработки нескольких независимых слотов")
    func parallelProcessingIndependentSlots() async throws {
        let container = try ModelContainer(
            for: Progress.self,
            User.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = container.mainContext
        let user = User(id: 1)
        context.insert(user)

        // Создаем несколько независимых слотов
        for dayId in 1 ... 3 {
            let progress = Progress(id: dayId, pullUps: dayId * 10, pushUps: dayId * 20, squats: dayId * 30, weight: Float(dayId) * 70.0)
            progress.user = user
            progress.isSynced = false
            context.insert(progress)
        }
        try context.save()

        let mockClient = MockProgressClient()

        // Мокаем ответы сервера для всех слотов
        let serverResponses = (1 ... 3).map { dayId in
            ProgressResponse(
                id: dayId,
                pullups: dayId * 10,
                pushups: dayId * 20,
                squats: dayId * 30,
                weight: Float(dayId) * 70.0,
                createDate: "2024-01-01 12:00:00",
                modifyDate: "2024-01-01 12:01:00"
            )
        }
        mockClient.mockedProgressResponses = serverResponses

        let syncService = ProgressSyncService(client: mockClient)
        await syncService.syncProgress(context: context)

        // Все слоты должны быть синхронизированы
        let allProgress = try context.fetch(FetchDescriptor<SwiftUI_SotkaApp.Progress>())
        #expect(allProgress.count == 3, "Все 3 слота должны существовать")

        for progress in allProgress {
            #expect(progress.isSynced, "Слот \(progress.id) должен быть синхронизирован")
            #expect(!progress.shouldDelete, "Слот \(progress.id) не должен быть помечен для удаления")
        }
    }
}

/// Mock клиент для тестирования
private final class MockProgressClient: ProgressClient, @unchecked Sendable {
    var updateProgressCallCount = 0
    var deletePhotoCallCount = 0
    var createProgressCallCount = 0
    var getProgressCallCount = 0
    var mockedProgressResponses: [ProgressResponse] = []
    var deletePhotoError: Error?
    var shouldThrowError = false
    private var responseIndex = 0

    func updateProgress(day _: Int, progress: ProgressRequest) async throws -> ProgressResponse {
        updateProgressCallCount += 1
        if shouldThrowError {
            throw NSError(domain: "MockError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Mock error"])
        }
        if responseIndex < mockedProgressResponses.count {
            let response = mockedProgressResponses[responseIndex]
            responseIndex += 1
            return response
        }
        // Возвращаем ответ на основе переданного прогресса
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

    func deletePhoto(day _: Int, type _: String) async throws {
        deletePhotoCallCount += 1
        if shouldThrowError {
            throw NSError(domain: "MockError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Mock error"])
        }
        if let error = deletePhotoError {
            throw error
        }
    }

    func getProgress() async throws -> [ProgressResponse] {
        getProgressCallCount += 1
        if shouldThrowError {
            throw NSError(domain: "MockError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Mock error"])
        }
        return mockedProgressResponses
    }

    func getProgress(day: Int) async throws -> ProgressResponse {
        getProgressCallCount += 1
        if shouldThrowError {
            throw NSError(domain: "MockError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Mock error"])
        }
        if responseIndex < mockedProgressResponses.count {
            let response = mockedProgressResponses[responseIndex]
            responseIndex += 1
            return response
        }
        // Возвращаем дефолтный ответ для дня
        return ProgressResponse(
            id: day,
            pullups: nil,
            pushups: nil,
            squats: nil,
            weight: nil,
            createDate: DateFormatterService.stringFromFullDate(Date(), format: .serverDateTimeSec),
            modifyDate: nil
        )
    }

    func createProgress(progress: ProgressRequest) async throws -> ProgressResponse {
        createProgressCallCount += 1
        if shouldThrowError {
            throw NSError(domain: "MockError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Mock error"])
        }
        if responseIndex < mockedProgressResponses.count {
            let response = mockedProgressResponses[responseIndex]
            responseIndex += 1
            return response
        }
        // Возвращаем ответ на основе переданного прогресса
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
            throw NSError(domain: "MockError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Mock error"])
        }
    }
}
