import Foundation
@testable import SwiftUI_SotkaApp
import Testing
import UIKit

/// Unit-тесты для ImageAssetManager
struct ImageAssetManagerTests {
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
}
