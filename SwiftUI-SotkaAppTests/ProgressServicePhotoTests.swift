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

    // MARK: - Helper Methods

    private func createTestModelContext() throws -> ModelContext {
        let modelConfiguration = ModelConfiguration(isStoredInMemoryOnly: true)
        let modelContainer = try ModelContainer(for: User.self, Progress.self, configurations: modelConfiguration)

        // Создаем тестового пользователя
        let user = User(id: 1, userName: "test", email: "test@test.com", cityID: nil)
        modelContainer.mainContext.insert(user)
        try modelContainer.mainContext.save()

        return modelContainer.mainContext
    }

    // MARK: - addPhoto Tests

    @Test(
        "Добавление фотографии к прогрессу",
        arguments: [PhotoType.front, PhotoType.back, PhotoType.side]
    )
    func addPhotoToProgress(photoType: PhotoType) throws {
        let modelConfiguration = ModelConfiguration(isStoredInMemoryOnly: true)
        let modelContainer = try ModelContainer(for: User.self, Progress.self, configurations: modelConfiguration)
        let context = modelContainer.mainContext

        // Создаем пользователя в контексте
        let user = User(id: 1, userName: "testuser", fullName: "Test User", email: "test@example.com")
        context.insert(user)
        try context.save()

        // Создаем прогресс в контексте
        let progress = Progress(id: 1)
        progress.user = user // Устанавливаем связь
        context.insert(progress)
        try context.save()

        // Создаем сервис с прогрессом из контекста
        let service = ProgressService(progress: progress, mode: .metrics)
        let testData = testImageData

        try service.addPhoto(testData, type: photoType, context: context)

        #expect(progress.hasPhotoData(photoType))
        let photoData = try #require(progress.getPhotoData(photoType))
        #expect(!photoData.isEmpty)
        #expect(!progress.isSynced)
    }

    @Test("Добавление фотографии с невалидным размером")
    func addPhotoWithInvalidSize() throws {
        let progress = Progress(id: 1)
        let service = ProgressService(progress: progress, mode: .metrics)
        let invalidData = Data(repeating: 0, count: 15 * 1024 * 1024) // 15MB
        let context = try createTestModelContext()

        #expect(throws: ProgressError.invalidImageData) {
            try service.addPhoto(invalidData, type: PhotoType.front, context: context)
        }
    }

    @Test("Добавление фотографии с невалидным форматом")
    func addPhotoWithInvalidFormat() throws {
        let progress = Progress(id: 1)
        let service = ProgressService(progress: progress, mode: .metrics)
        let invalidData = invalidImageData
        let context = try createTestModelContext()

        #expect(throws: ProgressError.invalidImageData) {
            try service.addPhoto(invalidData, type: PhotoType.front, context: context)
        }
    }

    @Test("Добавление фотографии с обработкой изображения")
    func addPhotoWithImageProcessing() throws {
        let modelConfiguration = ModelConfiguration(isStoredInMemoryOnly: true)
        let modelContainer = try ModelContainer(for: User.self, Progress.self, configurations: modelConfiguration)
        let context = modelContainer.mainContext

        // Создаем пользователя в контексте
        let user = User(id: 1, userName: "testuser", fullName: "Test User", email: "test@example.com")
        context.insert(user)
        try context.save()

        // Создаем прогресс в контексте
        let progress = Progress(id: 1)
        progress.user = user // Устанавливаем связь
        context.insert(progress)
        try context.save()

        // Создаем сервис с прогрессом из контекста
        let service = ProgressService(progress: progress, mode: .metrics)
        let largeData = largeImageData

        try service.addPhoto(largeData, type: PhotoType.side, context: context)

        #expect(progress.hasPhotoData(PhotoType.side))
        let sidePhotoData = try #require(progress.getPhotoData(PhotoType.side))
        #expect(!sidePhotoData.isEmpty)
    }

    // MARK: - deletePhoto Tests

    @Test("Удаление существующей фотографии")
    func deleteExistingPhoto() throws {
        let modelConfiguration = ModelConfiguration(isStoredInMemoryOnly: true)
        let modelContainer = try ModelContainer(for: User.self, Progress.self, configurations: modelConfiguration)
        let context = modelContainer.mainContext

        // Создаем пользователя в контексте
        let user = User(id: 1, userName: "testuser", fullName: "Test User", email: "test@example.com")
        context.insert(user)
        try context.save()

        // Создаем прогресс в контексте
        let progress = Progress(id: 1)
        progress.user = user // Устанавливаем связь
        context.insert(progress)
        try context.save()

        // Создаем сервис с прогрессом из контекста
        let service = ProgressService(progress: progress, mode: .metrics)
        let testData = testImageData

        progress.setPhotoData(.front, data: testData)
        #expect(progress.hasPhotoData(.front))

        try service.deletePhoto(PhotoType.front, context: context)

        #expect(!progress.hasPhotoData(.front))
        #expect(progress.getPhotoData(.front) == nil)
    }

    @Test("Удаление несуществующей фотографии")
    func deleteNonExistentPhoto() throws {
        let modelConfiguration = ModelConfiguration(isStoredInMemoryOnly: true)
        let modelContainer = try ModelContainer(for: User.self, Progress.self, configurations: modelConfiguration)
        let context = modelContainer.mainContext

        // Создаем пользователя в контексте
        let user = User(id: 1, userName: "testuser", fullName: "Test User", email: "test@example.com")
        context.insert(user)
        try context.save()

        // Создаем прогресс в контексте
        let progress = Progress(id: 1)
        progress.user = user // Устанавливаем связь
        context.insert(progress)
        try context.save()

        // Создаем сервис с прогрессом из контекста
        let service = ProgressService(progress: progress, mode: .metrics)

        try service.deletePhoto(PhotoType.front, context: context)

        #expect(!progress.hasPhotoData(.front))
    }

    @Test(
        "Удаление фотографии всех типов",
        arguments: PhotoType.allCases
    )
    func deletePhotoAllTypes(photoType: PhotoType) throws {
        let modelConfiguration = ModelConfiguration(isStoredInMemoryOnly: true)
        let modelContainer = try ModelContainer(for: User.self, Progress.self, configurations: modelConfiguration)
        let context = modelContainer.mainContext

        // Создаем пользователя в контексте
        let user = User(id: 1, userName: "testuser", fullName: "Test User", email: "test@example.com")
        context.insert(user)
        try context.save()

        // Создаем прогресс в контексте
        let progress = Progress(id: 1)
        progress.user = user // Устанавливаем связь
        context.insert(progress)
        try context.save()

        // Создаем сервис с прогрессом из контекста
        let service = ProgressService(progress: progress, mode: .metrics)
        let testData = testImageData

        // Добавляем фотографию
        progress.setPhotoData(photoType, data: testData)
        #expect(progress.hasPhotoData(photoType))

        // Удаляем фотографию
        try service.deletePhoto(photoType, context: context)

        // Физическое удаление - данные должны быть удалены
        #expect(!progress.hasPhotoData(photoType))
        #expect(progress.getPhotoData(photoType) == nil)
    }

    // MARK: - addPhoto with Context Tests

    @Test("Добавление фотографии с сохранением в контекст")
    func addPhotoWithContext() throws {
        let modelConfiguration = ModelConfiguration(isStoredInMemoryOnly: true)
        let modelContainer = try ModelContainer(for: User.self, Progress.self, configurations: modelConfiguration)
        let context = modelContainer.mainContext

        // Создаем пользователя в контексте
        let user = User(id: 1, userName: "testuser", fullName: "Test User", email: "test@example.com")
        context.insert(user)
        try context.save()

        // Создаем прогресс в контексте
        let progress = Progress(id: 1)
        progress.user = user // Устанавливаем связь
        context.insert(progress)
        try context.save()

        // Создаем сервис с прогрессом из контекста
        let service = ProgressService(progress: progress, mode: .metrics)
        let testData = testImageData

        try service.addPhoto(testData, type: .front, context: context)

        #expect(progress.hasPhotoData(.front))
        let frontPhotoData = try #require(progress.getPhotoData(.front))
        #expect(!frontPhotoData.isEmpty)
    }

    @Test("Добавление фотографии с nil данными в контекст")
    func addPhotoWithNilDataInContext() throws {
        let progress = Progress(id: 1)
        let service = ProgressService(progress: progress, mode: .metrics)
        let context = try createTestModelContext()

        #expect(throws: ProgressError.invalidImageData) {
            try service.addPhoto(Data(), type: .front, context: context)
        }
    }

    // MARK: - deletePhoto with Context Tests

    @Test("Удаление существующей фотографии с сохранением в контекст")
    func deleteExistingPhotoWithContext() throws {
        let modelConfiguration = ModelConfiguration(isStoredInMemoryOnly: true)
        let modelContainer = try ModelContainer(for: User.self, Progress.self, configurations: modelConfiguration)
        let context = modelContainer.mainContext

        // Создаем пользователя в контексте
        let user = User(id: 1, userName: "testuser", fullName: "Test User", email: "test@example.com")
        context.insert(user)
        try context.save()

        // Создаем прогресс в контексте
        let progress = Progress(id: 1)
        progress.user = user // Устанавливаем связь
        context.insert(progress)
        try context.save()

        // Создаем сервис с прогрессом из контекста
        let service = ProgressService(progress: progress, mode: .metrics)
        progress.setPhotoData(.front, data: testImageData)

        try service.deletePhoto(PhotoType.front, context: context)

        #expect(!progress.hasPhotoData(.front))
    }

    @Test("Удаление несуществующей фотографии в контекст")
    func deleteNonExistentPhotoInContext() throws {
        let modelConfiguration = ModelConfiguration(isStoredInMemoryOnly: true)
        let modelContainer = try ModelContainer(for: User.self, Progress.self, configurations: modelConfiguration)
        let context = modelContainer.mainContext

        // Создаем пользователя в контексте
        let user = User(id: 1, userName: "testuser", fullName: "Test User", email: "test@example.com")
        context.insert(user)
        try context.save()

        // Создаем прогресс в контексте
        let progress = Progress(id: 1)
        progress.user = user // Устанавливаем связь
        context.insert(progress)
        try context.save()

        // Создаем сервис с прогрессом из контекста
        let service = ProgressService(progress: progress, mode: .metrics)
        // Метод не выбрасывает ошибку для несуществующей фотографии
        try service.deletePhoto(PhotoType.front, context: context)

        #expect(!progress.hasPhotoData(.front))
    }

    // MARK: - Multiple Photos Tests

    @Test("Добавление множественных фотографий")
    func addMultiplePhotos() throws {
        let modelConfiguration = ModelConfiguration(isStoredInMemoryOnly: true)
        let modelContainer = try ModelContainer(for: User.self, Progress.self, configurations: modelConfiguration)
        let context = modelContainer.mainContext

        // Создаем пользователя в контексте
        let user = User(id: 1, userName: "testuser", fullName: "Test User", email: "test@example.com")
        context.insert(user)
        try context.save()

        // Создаем прогресс в контексте
        let progress = Progress(id: 1)
        progress.user = user // Устанавливаем связь
        context.insert(progress)
        try context.save()

        // Создаем сервис с прогрессом из контекста
        let service = ProgressService(progress: progress, mode: .metrics)
        let testData = testImageData

        try service.addPhoto(testData, type: PhotoType.front, context: context)
        try service.addPhoto(testData, type: PhotoType.back, context: context)
        try service.addPhoto(testData, type: PhotoType.side, context: context)

        #expect(progress.hasPhotoData(PhotoType.front))
        #expect(progress.hasPhotoData(PhotoType.back))
        #expect(progress.hasPhotoData(PhotoType.side))
        #expect(progress.getPhotoData(PhotoType.front) != nil)
        #expect(progress.getPhotoData(PhotoType.back) != nil)
        #expect(progress.getPhotoData(PhotoType.side) != nil)
    }

    @Test("Замена существующей фотографии")
    func replaceExistingPhoto() throws {
        let modelConfiguration = ModelConfiguration(isStoredInMemoryOnly: true)
        let modelContainer = try ModelContainer(for: User.self, Progress.self, configurations: modelConfiguration)
        let context = modelContainer.mainContext

        // Создаем пользователя в контексте
        let user = User(id: 1, userName: "testuser", fullName: "Test User", email: "test@example.com")
        context.insert(user)
        try context.save()

        // Создаем прогресс в контексте
        let progress = Progress(id: 1)
        progress.user = user // Устанавливаем связь
        context.insert(progress)
        try context.save()

        // Создаем сервис с прогрессом из контекста
        let service = ProgressService(progress: progress, mode: .metrics)
        let originalData = testImageData
        let newData = largeImageData // Используем валидные данные изображения

        // Добавляем оригинальную фотографию
        try service.addPhoto(originalData, type: PhotoType.front, context: context)
        progress.isSynced = true

        // Заменяем фотографию
        try service.addPhoto(newData, type: PhotoType.front, context: context)

        #expect(progress.hasPhotoData(PhotoType.front))
        let updatedPhotoData = try #require(progress.getPhotoData(PhotoType.front))
        #expect(updatedPhotoData != originalData, "Данные должны отличаться")
        #expect(!progress.isSynced)
    }

    // MARK: - Error Handling Tests

    @Test("Обработка ошибки обработки изображения")
    func imageProcessingError() throws {
        let progress = Progress(id: 1)
        let service = ProgressService(progress: progress, mode: .metrics)
        let context = try createTestModelContext()

        // Создаем данные, которые не пройдут валидацию формата
        let problematicData = Data([0xFF, 0xD8, 0xFF]) // Начало JPEG, но неполный

        #expect(throws: ProgressError.invalidImageData) {
            try service.addPhoto(problematicData, type: PhotoType.front, context: context)
        }
    }
}
