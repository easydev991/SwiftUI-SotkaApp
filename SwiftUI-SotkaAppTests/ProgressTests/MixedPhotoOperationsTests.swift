import Foundation
import SwiftData
@testable import SwiftUI_SotkaApp
import SWUtils
import Testing
import UIKit

extension AllProgressTests {
    @MainActor
    @Suite("ProgressSyncService - Смешанные операции с фотографиями")
    struct MixedPhotoOperationsTests {
        @Test("Исправление: удаление photo_back и добавление photo_front - новое фото загружается корректно")
        func bugDeleteBackAddFrontPhoto() async throws {
            let container = try ModelContainer(
                for: UserProgress.self,
                User.self,
                configurations: ModelConfiguration(isStoredInMemoryOnly: true)
            )
            let context = container.mainContext
            let user = User(id: 1)
            context.insert(user)

            let progress = UserProgress(
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
                createDate: Date(),
                modifyDate: Date().addingTimeInterval(60),
                photoFront: nil,
                photoBack: nil,
                photoSide: nil
            )
            mockClient.mockedProgressResponses = [serverResponse]

            progress.deletePhotoData(.back)
            progress.setPhotoData(Data("front_photo_data".utf8), type: .front)

            try context.save()

            let syncService = ProgressSyncService.makeMock(client: mockClient)
            _ = try await syncService.syncProgress(context: context)

            // Проверяем, что deletePhoto был вызван для удаления photo_back
            #expect(mockClient.deletePhotoCallCount == 1, "Должен быть вызван deletePhoto для photo_back")

            // Проверяем, что updateProgress БЫЛ вызван для отправки нового фото, несмотря на shouldDeletePhoto
            #expect(mockClient.updateProgressCallCount == 1, "updateProgress должен быть вызван для отправки нового фото")

            // Проверяем состояние после синхронизации
            #expect(!progress.shouldDeletePhoto(.back), "photo_back должна быть очищена после удаления")
            // Теперь прогресс должен быть синхронизирован, так как и удаление, и добавление обработаны
            #expect(progress.isSynced, "Прогресс должен быть помечен как синхронизированный")
        }

        @Test("Корректный сценарий: удаление и добавление в тот же слот")
        func correctDeleteAndAddSameSlot() async throws {
            let container = try ModelContainer(
                for: UserProgress.self,
                User.self,
                configurations: ModelConfiguration(isStoredInMemoryOnly: true)
            )
            let context = container.mainContext
            let user = User(id: 1)
            context.insert(user)

            let progress = UserProgress(
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
                createDate: Date(),
                modifyDate: Date().addingTimeInterval(60),
                photoFront: nil,
                photoBack: "https://example.com/new_back_photo.jpg",
                photoSide: nil
            )
            mockClient.mockedProgressResponses = [serverResponse]

            progress.deletePhotoData(.back)
            progress.setPhotoData(Data("new_back_photo".utf8), type: .back)

            try context.save()

            let syncService = ProgressSyncService.makeMock(client: mockClient)
            _ = try await syncService.syncProgress(context: context)

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
                for: UserProgress.self,
                User.self,
                configurations: ModelConfiguration(isStoredInMemoryOnly: true)
            )
            let context = container.mainContext
            let user = User(id: 1)
            context.insert(user)

            let progress = UserProgress(
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

            progress.deletePhotoData(ProgressPhotoType.back)
            progress.setPhotoData(Data("side_photo".utf8), type: .side)

            try context.save()

            let snapshot = ProgressSnapshot(from: progress)

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

        @Test("Race condition: параллельная обработка двух слотов с конфликтами")
        func raceConditionTwoSlotsWithConflicts() async throws {
            let container = try ModelContainer(
                for: UserProgress.self,
                User.self,
                configurations: ModelConfiguration(isStoredInMemoryOnly: true)
            )
            let context = container.mainContext
            let user = User(id: 1)
            context.insert(user)

            // Создаем два слота с конфликтами
            let progressA = UserProgress(id: 1, pullUps: 10, pushUps: 20, squats: 30, weight: 70.0)
            progressA.user = user
            progressA.isSynced = false
            progressA.deletePhotoData(.front) // Удаление фото в слоте A
            context.insert(progressA)

            let progressB = UserProgress(id: 2, pullUps: 15, pushUps: 25, squats: 35, weight: 72.0)
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
                createDate: Date(),
                modifyDate: Date().addingTimeInterval(60),
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
                createDate: Date(),
                modifyDate: Date().addingTimeInterval(60),
                photoFront: nil,
                photoBack: "https://example.com/photo.jpg",
                photoSide: nil
            )

            mockClient.mockedProgressResponses = [serverResponseA, serverResponseB]

            let syncService = ProgressSyncService.makeMock(client: mockClient)
            _ = try await syncService.syncProgress(context: context)

            // Проверяем, что оба слота обработаны корректно
            let allProgress = try context.fetch(FetchDescriptor<UserProgress>())
            #expect(allProgress.count == 2)

            // Проверяем, что оба слота синхронизированы
            let updatedProgressA = try #require(allProgress.first { $0.id == 1 }, "Слот A должен существовать")
            let updatedProgressB = try #require(allProgress.first { $0.id == 2 }, "Слот B должен существовать")
            #expect(updatedProgressA.isSynced, "Слот A должен быть синхронизирован")
            #expect(updatedProgressB.isSynced, "Слот B должен быть синхронизирован")
            #expect(!updatedProgressA.shouldDelete, "Слот A не должен быть помечен для удаления")
            #expect(!updatedProgressB.shouldDelete, "Слот B не должен быть помечен для удаления")

            // Проверяем состояние фотографий после синхронизации
            #expect(!updatedProgressA.shouldDeletePhoto(.front), "Фото front в слоте A не должно быть помечено для удаления")
            #expect(updatedProgressB.urlPhotoBack == "https://example.com/photo.jpg", "Фото back в слоте B должно быть обновлено с сервера")
        }

        @Test("Конфликт состояний флагов синхронизации - запись синхронизируется")
        func conflictingSyncFlagsSynchronized() async throws {
            let container = try ModelContainer(
                for: UserProgress.self,
                User.self,
                configurations: ModelConfiguration(isStoredInMemoryOnly: true)
            )
            let context = container.mainContext
            let user = User(id: 1)
            context.insert(user)

            let progress = UserProgress(id: 1, pullUps: 10, pushUps: 20, squats: 30, weight: 70.0)
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
                createDate: Date(),
                modifyDate: Date().addingTimeInterval(60)
            )
            mockClient.mockedProgressResponses = [serverResponse]

            let syncService = ProgressSyncService.makeMock(client: mockClient)
            _ = try await syncService.syncProgress(context: context)

            let allProgress = try context.fetch(FetchDescriptor<UserProgress>())
            let updatedProgress = try #require(allProgress.first)
            #expect(updatedProgress.isSynced, "Запись должна быть синхронизирована")
            #expect(!updatedProgress.shouldDelete, "Флаг shouldDelete должен быть сброшен")
        }

        @Test("Конфликт состояний флагов синхронизации - запись удаляется при ошибке")
        func conflictingSyncFlagsErrorHandlingRecordDeleted() async throws {
            let container = try ModelContainer(
                for: UserProgress.self,
                User.self,
                configurations: ModelConfiguration(isStoredInMemoryOnly: true)
            )
            let context = container.mainContext
            let user = User(id: 1)
            context.insert(user)

            let progress = UserProgress(id: 1, pullUps: 10, pushUps: 20, squats: 30, weight: 70.0)
            progress.user = user
            progress.shouldDelete = true
            progress.isSynced = false
            context.insert(progress)
            try context.save()

            let mockClient = MockProgressClient()
            mockClient.shouldThrowError = true

            let syncService = ProgressSyncService.makeMock(client: mockClient)
            _ = try await syncService.syncProgress(context: context)

            let allProgress = try context.fetch(FetchDescriptor<UserProgress>())
            #expect(allProgress.isEmpty, "При ошибке запись должна быть удалена из контекста")
        }

        @Test("Проверка логирования состояний флагов")
        func verifyFlagStateLogging() async throws {
            let container = try ModelContainer(
                for: UserProgress.self,
                User.self,
                configurations: ModelConfiguration(isStoredInMemoryOnly: true)
            )
            let context = container.mainContext
            let user = User(id: 1)
            context.insert(user)

            let progress = UserProgress(id: 1, pullUps: 10, pushUps: 20, squats: 30, weight: 70.0)
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
                createDate: Date(),
                modifyDate: Date().addingTimeInterval(60),
                photoFront: "https://example.com/photo.jpg"
            )
            mockClient.mockedProgressResponses = [serverResponse]

            let syncService = ProgressSyncService.makeMock(client: mockClient)
            _ = try await syncService.syncProgress(context: context)

            // Проверяем финальное состояние
            let updatedProgress = try #require(context.fetch(FetchDescriptor<UserProgress>()).first)
            #expect(updatedProgress.isSynced, "Должен быть синхронизирован")
            #expect(!updatedProgress.shouldDelete, "Не должен быть помечен для удаления")
            #expect(updatedProgress.urlPhotoFront == "https://example.com/photo.jpg", "URL фото должен быть обновлен")
        }

        @Test("Тест обработки пустого прогресса")
        func handleEmptyProgress() async throws {
            let container = try ModelContainer(
                for: UserProgress.self,
                User.self,
                configurations: ModelConfiguration(isStoredInMemoryOnly: true)
            )
            let context = container.mainContext
            let user = User(id: 1)
            context.insert(user)

            // Создаем пустой прогресс (без данных)
            let progress = UserProgress(id: 1, pullUps: 0, pushUps: 0, squats: 0, weight: 0.0)
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
                createDate: Date(),
                modifyDate: Date().addingTimeInterval(60)
            )
            mockClient.mockedProgressResponses = [serverResponse]

            let syncService = ProgressSyncService.makeMock(client: mockClient)
            _ = try await syncService.syncProgress(context: context)

            // Пустой прогресс должен быть обработан корректно
            let updatedProgress = try #require(context.fetch(FetchDescriptor<UserProgress>()).first)
            #expect(updatedProgress.isSynced, "Пустой прогресс должен быть синхронизирован")
        }

        @Test("Тест параллельной обработки нескольких независимых слотов")
        func parallelProcessingIndependentSlots() async throws {
            let container = try ModelContainer(
                for: UserProgress.self,
                User.self,
                configurations: ModelConfiguration(isStoredInMemoryOnly: true)
            )
            let context = container.mainContext
            let user = User(id: 1)
            context.insert(user)

            // Создаем несколько независимых слотов
            for dayId in 1 ... 3 {
                let progress = UserProgress(
                    id: dayId,
                    pullUps: dayId * 10,
                    pushUps: dayId * 20,
                    squats: dayId * 30,
                    weight: Float(dayId) * 70.0
                )
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
                    createDate: Date(),
                    modifyDate: Date().addingTimeInterval(60)
                )
            }
            mockClient.mockedProgressResponses = serverResponses

            let syncService = ProgressSyncService.makeMock(client: mockClient)
            _ = try await syncService.syncProgress(context: context)

            // Все слоты должны быть синхронизированы
            let allProgress = try context.fetch(FetchDescriptor<UserProgress>())
            #expect(allProgress.count == 3, "Все 3 слота должны существовать")

            for progress in allProgress {
                #expect(progress.isSynced, "Слот \(progress.id) должен быть синхронизирован")
                #expect(!progress.shouldDelete, "Слот \(progress.id) не должен быть помечен для удаления")
            }
        }

        /// Тест воспроизводит проблему: при удалении фото спереди и добавлении фото сзади в одной итерации,
        /// фото сзади не отправляется на сервер до следующего изменения
        @Test("Должен корректно синхронизировать удаление и добавление фотографий в одной итерации")
        func photoDeletionAndAdditionInSameIteration() async throws {
            // Arrange
            let mockClient = MockProgressClient()
            let service = ProgressSyncService.makeMock(client: mockClient)

            // Создаем контейнер для тестов
            let container = try ModelContainer(
                for: User.self, UserProgress.self,
                configurations: ModelConfiguration(isStoredInMemoryOnly: true)
            )
            let context = ModelContext(container)

            // Создаем пользователя
            let user = User(id: 1, userName: "Test User", email: "test@example.com")
            context.insert(user)

            // Создаем прогресс с фото спереди (которое будем удалять) и фото сзади (которое будем добавлять)
            let progress = UserProgress(
                id: 49,
                pullUps: 2,
                pushUps: 2,
                squats: 2,
                weight: 20.0,
                lastModified: Date.now
            )
            progress.user = user

            // Устанавливаем фото спереди (будет удалено)
            progress.setPhotoData(Data("front_photo_data".utf8), type: .front)
            progress.urlPhotoFront = "https://example.com/front.jpg"

            // Устанавливаем фото сзади (будет добавлено)
            progress.setPhotoData(Data("back_photo_data".utf8), type: .back)
            // urlPhotoBack остается nil - это новая фотография

            // Помечаем фото спереди на удаление
            progress.deletePhotoData(.front)

            // Помечаем как несинхронизированный
            progress.isSynced = false
            progress.shouldDelete = false

            context.insert(progress)
            try context.save()

            // Act
            _ = try await service.syncProgress(context: context)

            // Assert
            // Проверяем, что были вызваны правильные методы клиента
            #expect(mockClient.deletePhotoCallCount == 1, "Должен быть вызван deletePhoto для удаления фото спереди")
            #expect(mockClient.updateProgressCallCount == 1, "Должен быть вызван updateProgress для отправки новых фотографий")

            // Проверяем параметры вызова deletePhoto
            let deletePhotoCall = try #require(mockClient.deletePhotoCalls.first)
            #expect(deletePhotoCall.day == 49, "День должен быть 49")
            #expect(deletePhotoCall.type == "front", "Тип должен быть front")

            // Проверяем параметры вызова updateProgress
            let updateProgressCall = try #require(mockClient.updateProgressCalls.first)
            #expect(updateProgressCall.day == 49, "День должен быть 49")
            let photos = try #require(updateProgressCall.progress.photos)
            #expect(photos.count == 1, "Должна быть отправлена 1 фотография")

            // Проверяем, что отправлена фотография сзади
            let sentPhoto = try #require(photos.first)
            #expect(sentPhoto.key == "photo_back", "Тип отправленной фотографии должен быть photo_back")
            #expect(sentPhoto.value == Data("back_photo_data".utf8), "Данные фотографии должны совпадать")

            // Проверяем финальное состояние прогресса
            let finalProgress = try #require(try context.fetch(FetchDescriptor<UserProgress>()).first)
            #expect(finalProgress.isSynced, "Прогресс должен быть помечен как синхронизированный")
            #expect(!finalProgress.shouldDelete, "Прогресс не должен быть помечен на удаление")
        }

        /// Тест проверяет, что при отсутствии фотографий для удаления новые фотографии отправляются корректно
        @Test("Должен корректно синхронизировать только добавление новых фотографий")
        func onlyPhotoAddition() async throws {
            // Arrange
            let mockClient = MockProgressClient()
            let service = ProgressSyncService.makeMock(client: mockClient)

            let container = try ModelContainer(
                for: User.self, UserProgress.self,
                configurations: ModelConfiguration(isStoredInMemoryOnly: true)
            )
            let context = ModelContext(container)

            let user = User(id: 1, userName: "Test User", email: "test@example.com")
            context.insert(user)

            let progress = UserProgress(
                id: 49,
                pullUps: 2,
                pushUps: 2,
                squats: 2,
                weight: 20.0,
                lastModified: Date.now
            )
            progress.user = user

            // Добавляем только новую фотографию (без удаления)
            progress.setPhotoData(Data("back_photo_data".utf8), type: .back)
            progress.isSynced = false
            progress.shouldDelete = false

            context.insert(progress)
            try context.save()

            // Act
            _ = try await service.syncProgress(context: context)

            // Assert
            #expect(mockClient.deletePhotoCallCount == 0, "deletePhoto не должен вызываться")
            #expect(mockClient.updateProgressCallCount == 1, "updateProgress должен быть вызван")

            let updateProgressCall = try #require(mockClient.updateProgressCalls.first)
            let photos = try #require(updateProgressCall.progress.photos)
            #expect(photos.count == 1, "Должна быть отправлена 1 фотография")

            let sentPhoto = try #require(photos.first)
            #expect(sentPhoto.key == "photo_back", "Тип отправленной фотографии должен быть photo_back")
        }

        /// Тест проверяет, что при отсутствии новых фотографий удаление происходит корректно
        @Test("Должен корректно синхронизировать только удаление фотографий")
        func onlyPhotoDeletion() async throws {
            // Arrange
            let mockClient = MockProgressClient()
            let service = ProgressSyncService.makeMock(client: mockClient)

            let container = try ModelContainer(
                for: User.self, UserProgress.self,
                configurations: ModelConfiguration(isStoredInMemoryOnly: true)
            )
            let context = ModelContext(container)

            let user = User(id: 1, userName: "Test User", email: "test@example.com")
            context.insert(user)

            let progress = UserProgress(
                id: 49,
                pullUps: 2,
                pushUps: 2,
                squats: 2,
                weight: 20.0,
                lastModified: Date.now
            )
            progress.user = user

            // Устанавливаем фото спереди и помечаем на удаление
            progress.setPhotoData(Data("front_photo_data".utf8), type: .front)
            progress.urlPhotoFront = "https://example.com/front.jpg"
            progress.deletePhotoData(.front)
            progress.isSynced = false
            progress.shouldDelete = false

            context.insert(progress)
            try context.save()

            // Act
            _ = try await service.syncProgress(context: context)

            // Assert
            #expect(mockClient.deletePhotoCallCount == 1, "deletePhoto должен быть вызван")
            #expect(mockClient.updateProgressCallCount == 0, "updateProgress не должен вызываться при отсутствии новых фотографий")

            let deletePhotoCall = try #require(mockClient.deletePhotoCalls.first)
            #expect(deletePhotoCall.day == 49, "День должен быть 49")
            #expect(deletePhotoCall.type == "front", "Тип должен быть front")
        }
    }
}
