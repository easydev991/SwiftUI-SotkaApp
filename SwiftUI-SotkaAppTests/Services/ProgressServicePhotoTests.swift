import Foundation
import SwiftData
@testable import SwiftUI_SotkaApp
import Testing
import UIKit

@MainActor
struct ProgressServicePhotoTests {
    // MARK: - Test Data

    private var testImageData: Data {
        let testImage = UIImage(systemName: "photo") ?? UIImage()
        return testImage.pngData() ?? Data()
    }

    private var largeImageData: Data {
        let size = CGSize(width: 2000, height: 2000)
        UIGraphicsBeginImageContextWithOptions(size, false, 1.0)
        defer { UIGraphicsEndImageContext() }

        UIColor.red.setFill()
        UIRectFill(CGRect(origin: .zero, size: size))

        let image = UIGraphicsGetImageFromCurrentImageContext() ?? UIImage()
        return image.pngData() ?? Data()
    }

    private var invalidImageData: Data {
        Data("not an image".utf8)
    }

    // MARK: - addPhoto Tests

    @Test("Добавление фотографии к прогрессу", arguments: [PhotoType.front, PhotoType.back, PhotoType.side])
    func addPhotoToProgress(photoType: PhotoType) throws {
        let progress = Progress(id: 1)
        let service = ProgressService(progress: progress)
        let testData = testImageData

        try service.addPhoto(testData, type: photoType, to: progress)

        #expect(progress.photos.count == 1)
        let photo = try #require(progress.getPhoto(photoType))
        #expect(photo.data != nil)
        #expect(photo.type == photoType)
        #expect(!photo.isSynced)
    }

    @Test("Добавление фотографии с невалидным размером")
    func addPhotoWithInvalidSize() throws {
        let progress = Progress(id: 1)
        let service = ProgressService(progress: progress)
        let invalidData = Data(repeating: 0, count: 15 * 1024 * 1024) // 15MB

        #expect(throws: ProgressError.invalidImageData) {
            try service.addPhoto(invalidData, type: .front, to: progress)
        }
    }

    @Test("Добавление фотографии с невалидным форматом")
    func addPhotoWithInvalidFormat() throws {
        let progress = Progress(id: 1)
        let service = ProgressService(progress: progress)
        let invalidData = invalidImageData

        #expect(throws: ProgressError.invalidImageData) {
            try service.addPhoto(invalidData, type: .front, to: progress)
        }
    }

    @Test("Добавление фотографии с обработкой изображения")
    func addPhotoWithImageProcessing() throws {
        let progress = Progress(id: 1)
        let service = ProgressService(progress: progress)
        let largeData = largeImageData

        try service.addPhoto(largeData, type: .side, to: progress)

        #expect(progress.photos.count == 1)
        let sidePhoto = try #require(progress.getPhoto(.side))
        #expect(sidePhoto.data != nil)
        #expect(sidePhoto.type == .side)
    }

    // MARK: - deletePhoto Tests

    @Test("Удаление существующей фотографии")
    func deleteExistingPhoto() {
        let progress = Progress(id: 1)
        let service = ProgressService(progress: progress)
        let testData = testImageData

        progress.setPhoto(.front, data: testData)
        #expect(progress.photos.count == 1)

        service.deletePhoto(.front, from: progress)

        #expect(progress.photos.count == 0)
        #expect(progress.getPhoto(.front) == nil)
    }

    @Test("Удаление несуществующей фотографии")
    func deleteNonExistentPhoto() {
        let progress = Progress(id: 1)
        let service = ProgressService(progress: progress)

        service.deletePhoto(.front, from: progress)

        #expect(progress.photos.isEmpty)
    }

    @Test("Удаление фотографии всех типов", arguments: PhotoType.allCases)
    func deletePhotoAllTypes(photoType: PhotoType) {
        let progress = Progress(id: 1)
        let service = ProgressService(progress: progress)
        let testData = testImageData

        // Добавляем фотографию
        progress.setPhoto(photoType, data: testData)
        #expect(progress.photos.count == 1)

        // Удаляем фотографию
        service.deletePhoto(photoType, from: progress)

        // Физическое удаление - фотография должна быть удалена из массива
        #expect(progress.photos.count == 0)
        #expect(progress.getPhoto(photoType) == nil)
    }

    // MARK: - addPhoto with Context Tests

    @Test("Добавление фотографии с сохранением в контекст")
    func addPhotoWithContext() throws {
        let container = try ModelContainer(
            for: Progress.self,
            User.self,
            ProgressPhoto.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = container.mainContext

        let progress = Progress(id: 1)
        context.insert(progress)
        try context.save()

        let service = ProgressService(progress: progress)
        let testData = testImageData

        try service.addPhoto(testData, type: .front, context: context)

        #expect(progress.photos.count == 1)
        let frontPhoto = try #require(progress.getPhoto(.front))
        #expect(frontPhoto.data != nil)
    }

    @Test("Добавление фотографии с nil данными в контекст")
    func addPhotoWithNilDataInContext() throws {
        let container = try ModelContainer(
            for: Progress.self,
            User.self,
            ProgressPhoto.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = container.mainContext

        let progress = Progress(id: 1)
        context.insert(progress)
        try context.save()

        let service = ProgressService(progress: progress)

        #expect(throws: ProgressError.invalidImageData) {
            try service.addPhoto(nil, type: .front, context: context)
        }
    }

    // MARK: - deletePhoto with Context Tests

    @Test("Удаление существующей фотографии с сохранением в контекст")
    func deleteExistingPhotoWithContext() throws {
        let container = try ModelContainer(
            for: Progress.self,
            User.self,
            ProgressPhoto.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = container.mainContext

        let progress = Progress(id: 1)
        let photo = ProgressPhoto(type: .front, data: testImageData)
        progress.photos.append(photo)
        context.insert(progress)
        context.insert(photo)
        try context.save()

        let service = ProgressService(progress: progress)
        try service.deletePhoto(.front, context: context)

        #expect(progress.photos.isEmpty)
    }

    @Test("Удаление несуществующей фотографии в контекст")
    func deleteNonExistentPhotoInContext() throws {
        let container = try ModelContainer(
            for: Progress.self,
            User.self,
            ProgressPhoto.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = container.mainContext

        let progress = Progress(id: 1)
        context.insert(progress)
        try context.save()

        let service = ProgressService(progress: progress)
        try service.deletePhoto(.front, context: context)

        #expect(progress.photos.isEmpty)
    }

    @Test("Удаление уже удаленной фотографии в контекст")
    func deleteAlreadyDeletedPhotoInContext() throws {
        let container = try ModelContainer(
            for: Progress.self,
            User.self,
            ProgressPhoto.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = container.mainContext

        let progress = Progress(id: 1)
        let photo = ProgressPhoto(type: .front, data: testImageData)
        photo.isDeleted = true
        progress.photos.append(photo)
        context.insert(progress)
        context.insert(photo)
        try context.save()

        let service = ProgressService(progress: progress)

        // Теперь метод не выбрасывает ошибку для уже удаленных фотографий
        // Он просто не находит фотографию и не делает ничего
        try service.deletePhoto(.front, context: context)

        // Проверяем, что фотография была удалена из массива прогресса
        // (фотография не была найдена для удаления, так как она уже помечена как удаленная)
        #expect(progress.photos.isEmpty)
    }

    // MARK: - Multiple Photos Tests

    @Test("Добавление множественных фотографий")
    func addMultiplePhotos() throws {
        let progress = Progress(id: 1)
        let service = ProgressService(progress: progress)
        let testData = testImageData

        try service.addPhoto(testData, type: .front, to: progress)
        try service.addPhoto(testData, type: .back, to: progress)
        try service.addPhoto(testData, type: .side, to: progress)

        #expect(progress.photos.count == 3)
        #expect(progress.getPhoto(.front) != nil)
        #expect(progress.getPhoto(.back) != nil)
        #expect(progress.getPhoto(.side) != nil)
    }

    @Test("Замена существующей фотографии")
    func replaceExistingPhoto() throws {
        let progress = Progress(id: 1)
        let service = ProgressService(progress: progress)
        let originalData = testImageData
        let newData = largeImageData // Используем валидные данные изображения

        // Добавляем оригинальную фотографию
        try service.addPhoto(originalData, type: .front, to: progress)
        let originalPhoto = try #require(progress.getPhoto(.front))
        originalPhoto.isSynced = true

        // Заменяем фотографию
        try service.addPhoto(newData, type: .front, to: progress)

        #expect(progress.photos.count == 1)
        let updatedPhoto = try #require(progress.getPhoto(.front))
        #expect(updatedPhoto.data != originalData) // Данные должны отличаться
        #expect(!updatedPhoto.isSynced)
    }

    // MARK: - Error Handling Tests

    @Test("Обработка ошибки обработки изображения")
    func imageProcessingError() throws {
        let progress = Progress(id: 1)
        let service = ProgressService(progress: progress)

        // Создаем данные, которые не пройдут валидацию формата
        let problematicData = Data([0xFF, 0xD8, 0xFF]) // Начало JPEG, но неполный

        #expect(throws: ProgressError.invalidImageData) {
            try service.addPhoto(problematicData, type: .front, to: progress)
        }
    }
}
