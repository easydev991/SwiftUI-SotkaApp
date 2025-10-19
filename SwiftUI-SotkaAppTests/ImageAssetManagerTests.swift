import Foundation
@testable import SwiftUI_SotkaApp
import Testing
import UIKit

/// Unit-тесты для ImageAssetManager
struct ImageAssetManagerTests {
    // MARK: - Тесты получения URL изображений

    @Test
    func getImageURLForMainImage() throws {
        // Тест получения URL для основного изображения
        let url = try #require(ImageAssetManager.getImageURL(for: "1"))
        #expect(url.pathExtension == "png")
    }

    @Test
    func getImageURLForAdditionalImage() throws {
        // Тест получения URL для дополнительного изображения
        let url = try #require(ImageAssetManager.getImageURL(for: "1-1"))
        #expect(url.pathExtension == "png")
    }

    @Test
    func getImageURLForSpecialImage() throws {
        // Тест получения URL для специального изображения
        let url = try #require(ImageAssetManager.getImageURL(for: "aims-0"))
        #expect(url.pathExtension == "png")
    }

    @Test
    func getImageURLForNonExistentImage() {
        // Тест для несуществующего изображения
        let url = ImageAssetManager.getImageURL(for: "nonexistent-image-12345")
        #expect(url == nil)
    }

    @Test
    func getImageURLWithExtension() throws {
        // Тест получения URL с расширением в имени
        let url1 = try #require(ImageAssetManager.getImageURL(for: "1.jpg"))
        let url2 = try #require(ImageAssetManager.getImageURL(for: "1"))
        #expect(url1 == url2)
    }

    // MARK: - Тесты копирования изображений

    @Test
    func copyImageToTemp() throws {
        // Тест копирования изображения во временную директорию
        let tempDir = FileManager.default.temporaryDirectory
        let destinationURL = tempDir.appendingPathComponent("test_image_\(UUID().uuidString).jpg")

        // Очистка перед тестом (на случай, если файл уже существует)
        if FileManager.default.fileExists(atPath: destinationURL.path) {
            try FileManager.default.removeItem(at: destinationURL)
        }

        let success = ImageAssetManager.copyImageToTemp(imageName: "1", destinationURL: destinationURL)
        #expect(success)
        #expect(FileManager.default.fileExists(atPath: destinationURL.path))

        // Очистка после теста
        try FileManager.default.removeItem(at: destinationURL)
    }

    @Test
    func copyImageToTempWithNonExistentImage() {
        // Тест копирования несуществующего изображения
        let tempDir = FileManager.default.temporaryDirectory
        let destinationURL = tempDir.appendingPathComponent("test_nonexistent_\(UUID().uuidString).jpg")

        let success = ImageAssetManager.copyImageToTemp(imageName: "nonexistent-image-12345", destinationURL: destinationURL)

        #expect(!success)
        #expect(!FileManager.default.fileExists(atPath: destinationURL.path))
    }

    @Test
    func copyImageToTempOverwritesExistingFile() throws {
        // Тест перезаписи существующего файла
        let tempDir = FileManager.default.temporaryDirectory
        let destinationURL = tempDir.appendingPathComponent("test_overwrite_\(UUID().uuidString).jpg")

        // Очистка перед тестом (на случай, если файл уже существует)
        if FileManager.default.fileExists(atPath: destinationURL.path) {
            try FileManager.default.removeItem(at: destinationURL)
        }

        // Создаем пустой файл
        try "test content".write(to: destinationURL, atomically: true, encoding: .utf8)
        #expect(FileManager.default.fileExists(atPath: destinationURL.path))

        let success = ImageAssetManager.copyImageToTemp(imageName: "1", destinationURL: destinationURL)
        #expect(success)
        #expect(FileManager.default.fileExists(atPath: destinationURL.path))

        // Проверяем, что содержимое изменилось (файл теперь содержит данные изображения, а не текст)
        let data = try Data(contentsOf: destinationURL)
        #expect(data.count > 0)
        let originalData = try #require("test content".data(using: .utf8))
        #expect(data.count != originalData.count)

        // Очистка после теста
        try FileManager.default.removeItem(at: destinationURL)
    }

    // MARK: - Тесты проверки существования изображений

    @Test
    func imageExists() {
        // Тест проверки существования изображения
        let exists = ImageAssetManager.imageExists("1")
        #expect(exists)
    }

    @Test
    func imageExistsForNonExistentImage() {
        // Тест проверки существования несуществующего изображения
        let exists = ImageAssetManager.imageExists("nonexistent-image-12345")
        #expect(!exists)
    }

    // MARK: - Тесты получения списка изображений

    @Test
    func getAllAvailableImages() {
        // Тест получения списка всех доступных изображений
        let images = ImageAssetManager.getAllAvailableImages()
        #expect(images.count > 0)
    }

    // MARK: - Тесты получения размера изображений

    @Test
    func getImageSize() throws {
        // Тест получения размера изображения
        let size = try #require(ImageAssetManager.getImageSize("1"))
        #expect(size.width > 0)
        #expect(size.height > 0)
    }

    @Test
    func getImageSizeForNonExistentImage() {
        // Тест получения размера несуществующего изображения
        let size = ImageAssetManager.getImageSize("nonexistent-image-12345")
        #expect(size == nil)
    }

    // MARK: - Тесты производительности

    @Test
    func performanceGetImageURL() {
        // Тест производительности получения URL
        let startTime = CFAbsoluteTimeGetCurrent()

        for i in 1 ... 100 {
            _ = ImageAssetManager.getImageURL(for: "\(i % 10 + 1)")
        }

        let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
        #expect(timeElapsed < 1.0)
    }

    @Test
    func performanceGetAllAvailableImages() {
        // Тест производительности получения всех изображений
        let startTime = CFAbsoluteTimeGetCurrent()

        _ = ImageAssetManager.getAllAvailableImages()

        let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
        #expect(timeElapsed < 1.0)
    }
}
