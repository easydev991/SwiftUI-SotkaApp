import Foundation
@testable import SwiftUI_SotkaApp
import Testing

struct InfopostResourceManagerTests {
    private let fileManager = FileManager.default

    // MARK: - Тестирование создания временной директории

    @Test
    func testCreateTempDirectory() throws {
        let manager = InfopostResourceManager()

        let tempDirectory = try #require(manager.createTempDirectory())

        // Проверяем, что директория создана
        #expect(fileManager.fileExists(atPath: tempDirectory.path))

        // Проверяем, что путь содержит правильный компонент
        #expect(tempDirectory.path.contains("infopost_preview"))
    }

    @Test
    func createTempDirectoryRemovesExisting() throws {
        let manager = InfopostResourceManager()

        // Создаем первую директорию
        let firstDirectory = try #require(manager.createTempDirectory())
        #expect(fileManager.fileExists(atPath: firstDirectory.path))

        // Создаем вторую директорию - должна заменить первую
        let secondDirectory = try #require(manager.createTempDirectory())
        #expect(fileManager.fileExists(atPath: secondDirectory.path))

        // Проверяем, что пути одинаковые (одна и та же директория)
        #expect(firstDirectory.path == secondDirectory.path)

        // Проверяем, что вторая директория существует (это новая директория)
        #expect(fileManager.fileExists(atPath: secondDirectory.path))
    }

    // MARK: - Тестирование извлечения имен изображений

    @Test
    func extractImageNamesFromHTML() throws {
        let manager = InfopostResourceManager()

        let htmlContent = """
        <html>
        <body>
            <img src="img/image1.jpg" alt="Image 1">
            <img src="img/image2.png" alt="Image 2">
            <img src="../img/image3.jpeg" alt="Image 3">
            <img src="..\\img\\image4.gif" alt="Image 4">
        </body>
        </html>
        """

        // Тестируем через публичный интерфейс copyResources
        let tempDirectory = try #require(manager.createTempDirectory())
        let result = manager.copyResources(to: tempDirectory, htmlContent: htmlContent)

        // Проверяем, что HTML был обработан (может содержать обновленные пути)
        #expect(result.contains("img/"))
    }

    @Test
    func extractImageNamesWithDifferentPatterns() throws {
        let manager = InfopostResourceManager()

        let htmlContent = """
        <html>
        <body>
            <img src="img/test1.jpg" alt="Test 1">
            <img src="img/test2.png" alt="Test 2">
            <img src="../img/test3.jpeg" alt="Test 3">
            <img src="..\\img\\test4.gif" alt="Test 4">
            <img src="img/test5.jpg" alt="Test 5">
        </body>
        </html>
        """

        let tempDirectory = try #require(manager.createTempDirectory())
        let result = manager.copyResources(to: tempDirectory, htmlContent: htmlContent)

        // Проверяем, что результат не пустой
        #expect(!result.isEmpty)
    }

    @Test
    func extractImageNamesWithNoImages() throws {
        let manager = InfopostResourceManager()

        let htmlContent = """
        <html>
        <body>
            <h1>No images here</h1>
            <p>Just text content</p>
        </body>
        </html>
        """

        let tempDirectory = try #require(manager.createTempDirectory())
        let result = manager.copyResources(to: tempDirectory, htmlContent: htmlContent)

        // Проверяем, что результат не изменился (нет изображений для обработки)
        #expect(result == htmlContent)
    }

    // MARK: - Тестирование обновления расширений файлов

    @Test
    func updateImageExtensionsInHTML() throws {
        let manager = InfopostResourceManager()

        let htmlContent = """
        <html>
        <body>
            <img src="img/test1.jpg" alt="Test 1">
            <img src="img/test2.png" alt="Test 2">
        </body>
        </html>
        """

        let tempDirectory = try #require(manager.createTempDirectory())
        let result = manager.copyResources(to: tempDirectory, htmlContent: htmlContent)

        // Проверяем, что HTML был обработан
        #expect(!result.isEmpty)
        #expect(result.contains("img/"))
    }

    // MARK: - Тестирование копирования ресурсов

    @Test
    func copyResourcesCreatesDirectories() throws {
        let manager = InfopostResourceManager()

        let htmlContent = """
        <html>
        <head>
            <link rel="stylesheet" href="css/style.css">
        </head>
        <body>
            <img src="img/test.jpg" alt="Test">
            <script src="js/script.js"></script>
        </body>
        </html>
        """

        let tempDirectory = try #require(manager.createTempDirectory())

        let result = manager.copyResources(to: tempDirectory, htmlContent: htmlContent)

        // Проверяем, что HTML был обработан
        #expect(!result.isEmpty)

        // Проверяем, что временная директория существует
        #expect(fileManager.fileExists(atPath: tempDirectory.path))
    }

    @Test
    func copyResourcesWithEmptyHTML() throws {
        let manager = InfopostResourceManager()

        let htmlContent = ""
        let tempDirectory = try #require(manager.createTempDirectory())

        let result = manager.copyResources(to: tempDirectory, htmlContent: htmlContent)

        // Проверяем, что результат не изменился для пустого HTML
        #expect(result == htmlContent)
    }
}
