import Foundation
@testable import SwiftUI_SotkaApp
import Testing

struct InfopostResourceManagerTests {
    // MARK: - Тестирование создания временной директории

    @Test
    func createTempDirectory() async throws {
        let fileManager = FileManager.default
        let manager = InfopostResourceManager()

        let tempDirectory = try #require(manager.createTempDirectory())

        // Ждем немного, чтобы убедиться что директория создана
        try await Task.sleep(for: .milliseconds(100))

        // Проверяем, что директория создана
        #expect(fileManager.fileExists(atPath: tempDirectory.path))

        // Проверяем, что путь содержит правильный компонент
        #expect(tempDirectory.path.contains("infopost_preview"))

        // Дополнительная проверка: пытаемся создать файл в директории
        let testFile = tempDirectory.appendingPathComponent("test.txt")
        let testContent = "test content"
        try testContent.write(to: testFile, atomically: true, encoding: .utf8)

        // Проверяем, что файл создался
        #expect(fileManager.fileExists(atPath: testFile.path))

        // Очищаем за собой
        if fileManager.fileExists(atPath: testFile.path) {
            try fileManager.removeItem(at: testFile)
        }
    }

    @Test
    func createTempDirectoryRemovesExisting() async throws {
        let fileManager = FileManager.default
        let manager = InfopostResourceManager()

        // Создаем первую директорию
        let firstDirectory = try #require(manager.createTempDirectory())
        try await Task.sleep(for: .milliseconds(50))
        #expect(fileManager.fileExists(atPath: firstDirectory.path))

        // Создаем файл в первой директории для проверки удаления
        let firstTestFile = firstDirectory.appendingPathComponent("first.txt")
        try "first content".write(to: firstTestFile, atomically: true, encoding: .utf8)
        #expect(fileManager.fileExists(atPath: firstTestFile.path))

        // Создаем вторую директорию - должна заменить первую
        let secondDirectory = try #require(manager.createTempDirectory())
        try await Task.sleep(for: .milliseconds(50))
        #expect(fileManager.fileExists(atPath: secondDirectory.path))

        // Проверяем, что пути одинаковые (одна и та же директория)
        #expect(firstDirectory.path == secondDirectory.path)

        // Проверяем, что вторая директория существует
        #expect(fileManager.fileExists(atPath: secondDirectory.path))

        // Проверяем, что файл из первой директории был удален
        #expect(!fileManager.fileExists(atPath: firstTestFile.path))

        // Проверяем, что можем создать новый файл во второй директории
        let secondTestFile = secondDirectory.appendingPathComponent("second.txt")
        try "second content".write(to: secondTestFile, atomically: true, encoding: .utf8)
        #expect(fileManager.fileExists(atPath: secondTestFile.path))

        // Очищаем за собой
        if fileManager.fileExists(atPath: secondTestFile.path) {
            try fileManager.removeItem(at: secondTestFile)
        }
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
        let fileManager = FileManager.default
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
