import Foundation
import SwiftData
@testable import SwiftUI_SotkaApp
import Testing
import UIKit

struct ProgressPhotoDataTests {
    // MARK: - Test Data

    private func createTestProgress(context: ModelContext) -> SwiftUI_SotkaApp.Progress {
        let progress = Progress(
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

    // MARK: - Photo Data Management Tests

    @Test("Установка данных изображения")
    func setPhotoData() throws {
        let container = try ModelContainer(for: Progress.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let context = ModelContext(container)
        let progress = createTestProgress(context: context)
        let originalLastModified = progress.lastModified

        progress.setPhotoData(SwiftUI_SotkaApp.PhotoType.front, data: testImageData)

        #expect(progress.getPhotoData(SwiftUI_SotkaApp.PhotoType.front) == testImageData)
        #expect(progress.getPhotoData(SwiftUI_SotkaApp.PhotoType.back) == nil)
        #expect(progress.getPhotoData(SwiftUI_SotkaApp.PhotoType.side) == nil)
        #expect(progress.lastModified > originalLastModified)
        #expect(!progress.isSynced)
    }

    @Test("Получение данных изображения")
    func getPhotoData() throws {
        let container = try ModelContainer(for: Progress.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let context = ModelContext(container)
        let progress = createTestProgress(context: context)
        progress.setPhotoData(SwiftUI_SotkaApp.PhotoType.back, data: testImageData)

        #expect(progress.getPhotoData(SwiftUI_SotkaApp.PhotoType.front) == nil)
        #expect(progress.getPhotoData(SwiftUI_SotkaApp.PhotoType.back) == testImageData)
        #expect(progress.getPhotoData(SwiftUI_SotkaApp.PhotoType.side) == nil)
    }

    @Test("Проверка наличия данных изображения")
    func hasPhotoData() throws {
        let container = try ModelContainer(for: Progress.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let context = ModelContext(container)
        let progress = createTestProgress(context: context)
        progress.setPhotoData(SwiftUI_SotkaApp.PhotoType.side, data: testImageData)

        #expect(!progress.hasPhotoData(SwiftUI_SotkaApp.PhotoType.front))
        #expect(!progress.hasPhotoData(SwiftUI_SotkaApp.PhotoType.back))
        #expect(progress.hasPhotoData(SwiftUI_SotkaApp.PhotoType.side))
    }

    @Test("Удаление данных изображения")
    func deletePhotoData() throws {
        let container = try ModelContainer(for: Progress.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let context = ModelContext(container)
        let progress = createTestProgress(context: context)
        progress.setPhotoData(SwiftUI_SotkaApp.PhotoType.front, data: testImageData)
        let originalLastModified = progress.lastModified

        progress.deletePhotoData(SwiftUI_SotkaApp.PhotoType.front)

        #expect(progress.getPhotoData(SwiftUI_SotkaApp.PhotoType.front) == nil)
        #expect(progress.lastModified > originalLastModified)
        #expect(!progress.isSynced)
    }

    @Test("Проверка наличия любых данных фото")
    func hasAnyPhotoData() throws {
        let container = try ModelContainer(for: Progress.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let context = ModelContext(container)
        let progress = createTestProgress(context: context)

        #expect(!progress.hasAnyPhotoData)

        progress.setPhotoData(SwiftUI_SotkaApp.PhotoType.front, data: testImageData)

        #expect(progress.hasAnyPhotoData)
    }

    @Test("Обновление lastModified из серверного ответа")
    func updateLastModified() throws {
        let container = try ModelContainer(for: Progress.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
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
        let container = try ModelContainer(for: Progress.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
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
        let container = try ModelContainer(for: Progress.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let context = ModelContext(container)

        let progress = Progress(
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
        #expect(progress.getPhotoData(SwiftUI_SotkaApp.PhotoType.front) == nil)
        #expect(progress.getPhotoData(SwiftUI_SotkaApp.PhotoType.back) == nil)
        #expect(progress.getPhotoData(SwiftUI_SotkaApp.PhotoType.side) == nil)
    }

    @Test("Проверка hasAnyPhotoDataIncludingURLs с URL")
    func hasAnyPhotoDataIncludingURLs() throws {
        let container = try ModelContainer(for: Progress.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let context = ModelContext(container)
        let progress = createTestProgress(context: context)

        #expect(progress.hasAnyPhotoDataIncludingURLs)

        progress.urlPhotoFront = nil
        progress.urlPhotoBack = nil
        progress.urlPhotoSide = nil

        #expect(!progress.hasAnyPhotoDataIncludingURLs)

        progress.setPhotoData(SwiftUI_SotkaApp.PhotoType.front, data: testImageData)

        #expect(progress.hasAnyPhotoDataIncludingURLs)
    }

    @Test("Проверка isEmpty")
    func isEmpty() throws {
        let container = try ModelContainer(for: Progress.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let context = ModelContext(container)
        let progress = Progress(id: 1)
        context.insert(progress)

        #expect(progress.isEmpty)

        progress.pullUps = 10

        #expect(!progress.isEmpty)

        progress.pullUps = nil
        progress.setPhotoData(SwiftUI_SotkaApp.PhotoType.front, data: testImageData)

        #expect(!progress.isEmpty)
    }

    @Test("Проверка canBeDeleted")
    func canBeDeleted() throws {
        let container = try ModelContainer(for: Progress.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let context = ModelContext(container)
        let progress = Progress(id: 1)
        context.insert(progress)

        #expect(!progress.canBeDeleted)

        progress.pullUps = 10

        #expect(progress.canBeDeleted)

        progress.pullUps = nil
        progress.urlPhotoFront = "https://example.com/front.jpg"

        #expect(progress.canBeDeleted)
    }
}
