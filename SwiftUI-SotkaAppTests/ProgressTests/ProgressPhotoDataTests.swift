import Foundation
import SwiftData
@testable import SwiftUI_SotkaApp
import Testing
import UIKit

extension AllProgressTests {
    struct ProgressPhotoDataTests {
        private func createTestProgress(context: ModelContext) -> UserProgress {
            let progress = UserProgress(
                id: 1,
                pullUps: 10,
                pushUps: 20,
                squats: 30,
                weight: 70.0,
                urlPhotoFront: "https://example.com/front.jpg",
                urlPhotoBack: "https://example.com/back.jpg",
                urlPhotoSide: "https://example.com/side.jpg"
            )
            context.insert(progress)
            try! context.save()
            return progress
        }

        private var testImageData: Data {
            let testImage = UIImage(systemName: "photo") ?? UIImage()
            return testImage.pngData() ?? Data()
        }

        @Test("Установка данных изображения")
        func setPhotoData() throws {
            let container = try ModelContainer(for: UserProgress.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
            let context = ModelContext(container)
            let progress = createTestProgress(context: context)
            let originalLastModified = progress.lastModified

            progress.setPhotoData(testImageData, type: .front)

            #expect(progress.getPhotoData(.front) == testImageData)
            #expect(progress.getPhotoData(.back) == nil)
            #expect(progress.getPhotoData(.side) == nil)
            #expect(progress.lastModified > originalLastModified)
            #expect(!progress.isSynced)
        }

        @Test("Получение данных изображения")
        func getPhotoData() throws {
            let container = try ModelContainer(for: UserProgress.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
            let context = ModelContext(container)
            let progress = createTestProgress(context: context)
            progress.setPhotoData(testImageData, type: .back)

            #expect(progress.getPhotoData(.front) == nil)
            #expect(progress.getPhotoData(.back) == testImageData)
            #expect(progress.getPhotoData(.side) == nil)
        }

        @Test("Удаление данных изображения")
        func deletePhotoData() throws {
            let container = try ModelContainer(for: UserProgress.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
            let context = ModelContext(container)
            let progress = createTestProgress(context: context)
            progress.setPhotoData(testImageData, type: .front)
            let originalLastModified = progress.lastModified

            progress.deletePhotoData(.front)

            #expect(progress.getPhotoData(.front) == nil)
            #expect(progress.lastModified > originalLastModified)
            #expect(!progress.isSynced)
        }

        @Test("Проверка наличия любых данных фото")
        func hasAnyPhotoData() throws {
            let container = try ModelContainer(for: UserProgress.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
            let context = ModelContext(container)
            let progress = createTestProgress(context: context)

            #expect(!progress.hasAnyPhotoData)

            progress.setPhotoData(testImageData, type: .front)

            #expect(progress.hasAnyPhotoData)
        }

        @Test("Обновление lastModified из серверного ответа")
        func updateLastModified() throws {
            let container = try ModelContainer(for: UserProgress.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
            let context = ModelContext(container)
            let progress = createTestProgress(context: context)
            let originalLastModified = progress.lastModified

            let response = ProgressResponse(
                id: 1,
                pullups: 10,
                pushups: 20,
                squats: 30,
                weight: 70.0,
                createDate: "2024-01-01T00:00:00Z",
                modifyDate: "2024-01-02T00:00:00Z",
                photoFront: "https://example.com/front.jpg",
                photoBack: "https://example.com/back.jpg",
                photoSide: "https://example.com/side.jpg"
            )

            progress.updateLastModified(from: response)

            #expect(progress.lastModified > originalLastModified)
        }

        @Test("Обновление lastModified когда modifyDate равен null")
        func updateLastModifiedWithNullModifyDate() throws {
            let container = try ModelContainer(for: UserProgress.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
            let context = ModelContext(container)
            let progress = createTestProgress(context: context)
            let originalLastModified = progress.lastModified

            let response = ProgressResponse(
                id: 1,
                pullups: 10,
                pushups: 20,
                squats: 30,
                weight: 70.0,
                createDate: "2024-01-01T00:00:00Z",
                modifyDate: nil,
                photoFront: "https://example.com/front.jpg",
                photoBack: "https://example.com/back.jpg",
                photoSide: "https://example.com/side.jpg"
            )

            progress.updateLastModified(from: response)

            #expect(progress.lastModified > originalLastModified)
        }

        @Test("Создание прогресса с URL фотографий")
        func progressCreationWithPhotoURLs() throws {
            let container = try ModelContainer(for: UserProgress.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
            let context = ModelContext(container)

            let progress = UserProgress(
                id: 1,
                pullUps: 10,
                pushUps: 20,
                squats: 30,
                weight: 70.0,
                urlPhotoFront: "https://example.com/front.jpg",
                urlPhotoBack: "https://example.com/back.jpg",
                urlPhotoSide: "https://example.com/side.jpg"
            )
            context.insert(progress)

            #expect(progress.urlPhotoFront == "https://example.com/front.jpg")
            #expect(progress.urlPhotoBack == "https://example.com/back.jpg")
            #expect(progress.urlPhotoSide == "https://example.com/side.jpg")
            #expect(progress.getPhotoData(.front) == nil)
            #expect(progress.getPhotoData(.back) == nil)
            #expect(progress.getPhotoData(.side) == nil)
        }

        @Test("Проверка hasAnyPhotoDataIncludingURLs с URL")
        func hasAnyPhotoDataIncludingURLs() throws {
            let container = try ModelContainer(for: UserProgress.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
            let context = ModelContext(container)
            let progress = createTestProgress(context: context)

            #expect(progress.hasAnyPhotoDataIncludingURLs)

            progress.urlPhotoFront = nil
            progress.urlPhotoBack = nil
            progress.urlPhotoSide = nil

            #expect(!progress.hasAnyPhotoDataIncludingURLs)

            progress.setPhotoData(testImageData, type: .front)

            #expect(progress.hasAnyPhotoDataIncludingURLs)
        }

        @Test("Проверка isEmpty")
        func isEmpty() throws {
            let container = try ModelContainer(for: UserProgress.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
            let context = ModelContext(container)
            let progress = UserProgress(id: 1)
            context.insert(progress)

            #expect(progress.isEmpty)

            progress.pullUps = 10
            try context.save()

            #expect(!progress.isEmpty)

            progress.pullUps = nil
            progress.setPhotoData(testImageData, type: .front)

            #expect(!progress.isEmpty)
        }

        @Test("Проверка canBeDeleted")
        func canBeDeleted() throws {
            let container = try ModelContainer(for: UserProgress.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
            let context = ModelContext(container)
            let progress = UserProgress(id: 1)
            context.insert(progress)

            #expect(!progress.canBeDeleted)

            progress.pullUps = 10
            try context.save()

            #expect(progress.canBeDeleted)

            progress.pullUps = nil
            progress.urlPhotoFront = "https://example.com/front.jpg"

            #expect(progress.canBeDeleted)
        }

        @Test("DELETED_DATA константа имеет правильное значение")
        func deletedDataConstantHasCorrectValue() throws {
            let container = try ModelContainer(for: UserProgress.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
            let context = ModelContext(container)
            let progress = UserProgress(id: 1)
            context.insert(progress)

            // Устанавливаем DELETED_DATA через deletePhotoData
            progress.deletePhotoData(.front)

            // Проверяем, что getPhotoData возвращает nil для DELETED_DATA
            #expect(progress.getPhotoData(.front) == nil)
            #expect(progress.shouldDeletePhoto(.front))
        }

        @Test("shouldDeletePhoto возвращает true для помеченных фотографий")
        func shouldDeletePhotoReturnsTrueForMarkedPhotos() throws {
            let container = try ModelContainer(for: UserProgress.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
            let context = ModelContext(container)
            let progress = UserProgress(id: 1)
            context.insert(progress)

            // Изначально фотографии не помечены для удаления
            #expect(!progress.shouldDeletePhoto(.front))
            #expect(!progress.shouldDeletePhoto(.back))
            #expect(!progress.shouldDeletePhoto(.side))

            // Помечаем фронтальную фотографию для удаления
            progress.deletePhotoData(.front)

            #expect(progress.shouldDeletePhoto(.front))
            #expect(!progress.shouldDeletePhoto(.back))
            #expect(!progress.shouldDeletePhoto(.side))

            // Помечаем заднюю фотографию для удаления
            progress.deletePhotoData(.back)

            #expect(progress.shouldDeletePhoto(.front))
            #expect(progress.shouldDeletePhoto(.back))
            #expect(!progress.shouldDeletePhoto(.side))
        }

        @Test("hasPhotosToDelete возвращает true при наличии фотографий для удаления")
        func hasPhotosToDeleteReturnsTrueWhenPhotosMarkedForDeletion() throws {
            let container = try ModelContainer(for: UserProgress.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
            let context = ModelContext(container)
            let progress = UserProgress(id: 1)
            context.insert(progress)

            // Изначально нет фотографий для удаления
            #expect(!progress.hasPhotosToDelete())

            // Помечаем одну фотографию для удаления
            progress.deletePhotoData(.front)
            #expect(progress.hasPhotosToDelete())

            // Помечаем все фотографии для удаления
            progress.deletePhotoData(.back)
            progress.deletePhotoData(.side)
            #expect(progress.hasPhotosToDelete())
        }

        @Test("clearPhotoData очищает данные после успешного удаления")
        func clearPhotoDataClearsDataAfterSuccessfulDeletion() throws {
            let container = try ModelContainer(for: UserProgress.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
            let context = ModelContext(container)
            let progress = UserProgress(id: 1)
            context.insert(progress)

            // Устанавливаем данные фотографии
            progress.setPhotoData(testImageData, type: .front)
            progress.urlPhotoFront = "https://example.com/front.jpg"

            // Помечаем для удаления
            progress.deletePhotoData(.front)
            #expect(progress.shouldDeletePhoto(.front))

            // Очищаем после успешного удаления
            progress.clearPhotoData(.front)

            #expect(!progress.shouldDeletePhoto(.front))
            #expect(progress.getPhotoData(.front) == nil)
            #expect(progress.urlPhotoFront == nil)
            #expect(!progress.isSynced, "isSynced устанавливается в handlePhotoDeletion после обработки всех фотографий")
        }

        @Test("deletePhotoData устанавливает DELETED_DATA вместо физического удаления")
        func deletePhotoDataSetsDeletedDataInsteadOfPhysicalDeletion() throws {
            let container = try ModelContainer(for: UserProgress.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
            let context = ModelContext(container)
            let progress = UserProgress(id: 1)
            context.insert(progress)

            // Устанавливаем данные фотографии
            progress.setPhotoData(testImageData, type: .front)
            progress.urlPhotoFront = "https://example.com/front.jpg"
            let originalLastModified = progress.lastModified

            // Удаляем фотографию
            progress.deletePhotoData(.front)

            // Проверяем, что данные помечены для удаления, но не физически удалены
            #expect(progress.shouldDeletePhoto(.front))
            #expect(progress.getPhotoData(.front) == nil)
            #expect(progress.urlPhotoFront == nil)
            #expect(progress.lastModified > originalLastModified)
            #expect(!progress.isSynced)
        }

        @Test(
            "Параметризированный тест shouldDeletePhoto",
            arguments: [ProgressPhotoType.front, ProgressPhotoType.back, ProgressPhotoType.side]
        )
        func shouldDeletePhotoParameterized(photoType: ProgressPhotoType) throws {
            let container = try ModelContainer(for: UserProgress.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
            let context = ModelContext(container)
            let progress = UserProgress(id: 1)
            context.insert(progress)

            // Изначально фотография не помечена для удаления
            #expect(!progress.shouldDeletePhoto(photoType))

            // Помечаем для удаления
            progress.deletePhotoData(photoType)
            #expect(progress.shouldDeletePhoto(photoType))

            // Очищаем после успешного удаления
            progress.clearPhotoData(photoType)
            #expect(!progress.shouldDeletePhoto(photoType))
        }
    }
}
