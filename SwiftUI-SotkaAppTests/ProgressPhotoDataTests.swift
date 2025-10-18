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
        // Создаем тестовые данные изображения (1x1 пиксель PNG)
        let testImage = UIImage(systemName: "photo") ?? UIImage()
        return testImage.pngData() ?? Data()
    }

    // MARK: - Photo Data Management Tests

    @Test("Установка данных изображения")
    func testSetPhotoData() throws {
        // Given
        let container = try ModelContainer(for: Progress.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let context = ModelContext(container)
        let progress = createTestProgress(context: context)
        let originalLastModified = progress.lastModified

        // When
        progress.setPhotoData(SwiftUI_SotkaApp.PhotoType.front, data: testImageData)

        // Then
        #expect(progress.getPhotoData(SwiftUI_SotkaApp.PhotoType.front) == testImageData)
        #expect(progress.getPhotoData(SwiftUI_SotkaApp.PhotoType.back) == nil)
        #expect(progress.getPhotoData(SwiftUI_SotkaApp.PhotoType.side) == nil)
        #expect(progress.lastModified > originalLastModified)
        #expect(progress.isSynced == false)
    }

    @Test("Получение данных изображения")
    func testGetPhotoData() throws {
        // Given
        let container = try ModelContainer(for: Progress.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let context = ModelContext(container)
        let progress = createTestProgress(context: context)
        progress.setPhotoData(SwiftUI_SotkaApp.PhotoType.back, data: testImageData)

        // When/Then
        #expect(progress.getPhotoData(SwiftUI_SotkaApp.PhotoType.front) == nil)
        #expect(progress.getPhotoData(SwiftUI_SotkaApp.PhotoType.back) == testImageData)
        #expect(progress.getPhotoData(SwiftUI_SotkaApp.PhotoType.side) == nil)
    }

    @Test("Проверка наличия данных изображения")
    func testHasPhotoData() throws {
        // Given
        let container = try ModelContainer(for: Progress.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let context = ModelContext(container)
        let progress = createTestProgress(context: context)
        progress.setPhotoData(SwiftUI_SotkaApp.PhotoType.side, data: testImageData)

        // When/Then
        #expect(progress.hasPhotoData(SwiftUI_SotkaApp.PhotoType.front) == false)
        #expect(progress.hasPhotoData(SwiftUI_SotkaApp.PhotoType.back) == false)
        #expect(progress.hasPhotoData(SwiftUI_SotkaApp.PhotoType.side) == true)
    }

    @Test("Удаление данных изображения")
    func testDeletePhotoData() throws {
        // Given
        let container = try ModelContainer(for: Progress.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let context = ModelContext(container)
        let progress = createTestProgress(context: context)
        progress.setPhotoData(SwiftUI_SotkaApp.PhotoType.front, data: testImageData)
        let originalLastModified = progress.lastModified

        // When
        progress.deletePhotoData(SwiftUI_SotkaApp.PhotoType.front)

        // Then
        #expect(progress.getPhotoData(SwiftUI_SotkaApp.PhotoType.front) == nil)
        #expect(progress.lastModified > originalLastModified)
        #expect(progress.isSynced == false)
    }

    @Test("Проверка наличия любых данных фото")
    func testHasAnyPhotoData() throws {
        // Given
        let container = try ModelContainer(for: Progress.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let context = ModelContext(container)
        let progress = createTestProgress(context: context)

        // When/Then (изначально нет данных)
        #expect(progress.hasAnyPhotoData == false)

        // When (добавляем данные)
        progress.setPhotoData(SwiftUI_SotkaApp.PhotoType.front, data: testImageData)

        // Then
        #expect(progress.hasAnyPhotoData == true)
    }

    @Test("Проверка наличия всех данных фото")
    func testHasAllPhotoData() throws {
        // Given
        let container = try ModelContainer(for: Progress.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let context = ModelContext(container)
        let progress = createTestProgress(context: context)

        // When/Then (изначально нет данных)
        #expect(progress.hasAllPhotoData == false)

        // When (добавляем данные для всех типов)
        progress.setPhotoData(SwiftUI_SotkaApp.PhotoType.front, data: testImageData)
        progress.setPhotoData(SwiftUI_SotkaApp.PhotoType.back, data: testImageData)
        progress.setPhotoData(SwiftUI_SotkaApp.PhotoType.side, data: testImageData)

        // Then
        #expect(progress.hasAllPhotoData == true)
    }

    @Test("Обновление lastModified из серверного ответа")
    func testUpdateLastModified() throws {
        // Given
        let container = try ModelContainer(for: Progress.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let context = ModelContext(container)
        let progress = createTestProgress(context: context)
        let originalLastModified = progress.lastModified

        // Создаем моковый ответ сервера
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

        // When
        progress.updateLastModified(from: response)

        // Then
        #expect(progress.lastModified > originalLastModified)
    }

    @Test("Обновление lastModified когда modifyDate равен null")
    func updateLastModifiedWithNullModifyDate() throws {
        // Given
        let container = try ModelContainer(for: Progress.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let context = ModelContext(container)
        let progress = createTestProgress(context: context)
        let originalLastModified = progress.lastModified

        // Создаем моковый ответ сервера без modifyDate
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

        // When
        progress.updateLastModified(from: response)

        // Then
        #expect(progress.lastModified > originalLastModified)
    }

    @Test("Создание прогресса с URL фотографий")
    func progressCreationWithPhotoURLs() throws {
        // Given
        let container = try ModelContainer(for: Progress.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let context = ModelContext(container)

        // When
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

        // Then
        #expect(progress.urlPhotoFront == "https://example.com/front.jpg")
        #expect(progress.urlPhotoBack == "https://example.com/back.jpg")
        #expect(progress.urlPhotoSide == "https://example.com/side.jpg")
        #expect(progress.getPhotoData(SwiftUI_SotkaApp.PhotoType.front) == nil)
        #expect(progress.getPhotoData(SwiftUI_SotkaApp.PhotoType.back) == nil)
        #expect(progress.getPhotoData(SwiftUI_SotkaApp.PhotoType.side) == nil)
    }
}
