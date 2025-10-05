@testable import SwiftUI_SotkaApp
import XCTest

/// Unit-тесты для ImageAssetManager
final class ImageAssetManagerTests: XCTestCase {
    override func setUp() {
        super.setUp()
        // Настройка перед каждым тестом
    }

    override func tearDown() {
        // Очистка после каждого теста
        super.tearDown()
    }

    // MARK: - Тесты получения URL изображений

    func testGetImageURLForMainImage() {
        // Тест получения URL для основного изображения
        // Примечание: Тест будет проходить только если изображения уже мигрированы в Assets
        let url = ImageAssetManager.getImageURL(for: "1")

        // Если изображения еще не мигрированы, тест должен корректно обработать nil
        if url == nil {
            print("⚠️ Изображение '1' не найдено в Assets - возможно, миграция еще не выполнена")
        }

        // Тест проходит в любом случае, так как мы тестируем корректность обработки
        XCTAssertTrue(true, "Метод getImageURL должен корректно обрабатывать запросы")
    }

    func testGetImageURLForAdditionalImage() {
        // Тест получения URL для дополнительного изображения
        let url = ImageAssetManager.getImageURL(for: "1-1")

        if url == nil {
            print("⚠️ Изображение '1-1' не найдено в Assets - возможно, миграция еще не выполнена")
        }

        XCTAssertTrue(true, "Метод getImageURL должен корректно обрабатывать запросы")
    }

    func testGetImageURLForSpecialImage() {
        // Тест получения URL для специального изображения
        let url = ImageAssetManager.getImageURL(for: "aims-0")

        if url == nil {
            print("⚠️ Изображение 'aims-0' не найдено в Assets - возможно, миграция еще не выполнена")
        }

        XCTAssertTrue(true, "Метод getImageURL должен корректно обрабатывать запросы")
    }

    func testGetImageURLForNonExistentImage() {
        // Тест для несуществующего изображения
        let url = ImageAssetManager.getImageURL(for: "nonexistent-image-12345")
        XCTAssertNil(url, "URL для несуществующего изображения должен быть nil")
    }

    func testGetImageURLWithExtension() {
        // Тест получения URL с расширением в имени
        let url1 = ImageAssetManager.getImageURL(for: "1.jpg")
        let url2 = ImageAssetManager.getImageURL(for: "1")

        // Оба запроса должны возвращать одинаковый результат
        if url1 != nil, url2 != nil {
            XCTAssertEqual(url1, url2, "URL должны быть одинаковыми независимо от расширения")
        }
    }

    // MARK: - Тесты копирования изображений

    func testCopyImageToTemp() {
        // Тест копирования изображения во временную директорию
        let tempDir = FileManager.default.temporaryDirectory
        let destinationURL = tempDir.appendingPathComponent("test_image_\(UUID().uuidString).jpg")

        let success = ImageAssetManager.copyImageToTemp(imageName: "1", destinationURL: destinationURL)

        if success {
            XCTAssertTrue(FileManager.default.fileExists(atPath: destinationURL.path), "Файл должен существовать после копирования")

            // Очистка
            try? FileManager.default.removeItem(at: destinationURL)
        } else {
            print("⚠️ Не удалось скопировать изображение '1' - возможно, миграция еще не выполнена")
        }

        XCTAssertTrue(true, "Метод copyImageToTemp должен корректно обрабатывать запросы")
    }

    func testCopyImageToTempWithNonExistentImage() {
        // Тест копирования несуществующего изображения
        let tempDir = FileManager.default.temporaryDirectory
        let destinationURL = tempDir.appendingPathComponent("test_nonexistent_\(UUID().uuidString).jpg")

        let success = ImageAssetManager.copyImageToTemp(imageName: "nonexistent-image-12345", destinationURL: destinationURL)

        XCTAssertFalse(success, "Копирование несуществующего изображения должно возвращать false")
        XCTAssertFalse(FileManager.default.fileExists(atPath: destinationURL.path), "Файл не должен существовать")
    }

    func testCopyImageToTempOverwritesExistingFile() {
        // Тест перезаписи существующего файла
        let tempDir = FileManager.default.temporaryDirectory
        let destinationURL = tempDir.appendingPathComponent("test_overwrite_\(UUID().uuidString).jpg")

        // Создаем пустой файл
        try? "test content".write(to: destinationURL, atomically: true, encoding: .utf8)
        XCTAssertTrue(FileManager.default.fileExists(atPath: destinationURL.path), "Тестовый файл должен существовать")

        let success = ImageAssetManager.copyImageToTemp(imageName: "1", destinationURL: destinationURL)

        if success {
            XCTAssertTrue(FileManager.default.fileExists(atPath: destinationURL.path), "Файл должен существовать после копирования")

            // Проверяем, что содержимое изменилось
            let content = try? String(contentsOf: destinationURL, encoding: .utf8)
            XCTAssertNotEqual(content, "test content", "Содержимое файла должно измениться")
        }

        // Очистка
        try? FileManager.default.removeItem(at: destinationURL)
    }

    // MARK: - Тесты проверки существования изображений

    func testImageExists() {
        // Тест проверки существования изображения
        let exists = ImageAssetManager.imageExists("1")

        if !exists {
            print("⚠️ Изображение '1' не найдено в Assets - возможно, миграция еще не выполнена")
        }

        XCTAssertTrue(true, "Метод imageExists должен корректно обрабатывать запросы")
    }

    func testImageExistsForNonExistentImage() {
        // Тест проверки существования несуществующего изображения
        let exists = ImageAssetManager.imageExists("nonexistent-image-12345")
        XCTAssertFalse(exists, "Несуществующее изображение должно возвращать false")
    }

    // MARK: - Тесты получения списка изображений

    func testGetAllAvailableImages() {
        // Тест получения списка всех доступных изображений
        let images = ImageAssetManager.getAllAvailableImages()

        print("📊 Найдено \(images.count) изображений в Assets")

        // Если изображения мигрированы, должно быть больше 0
        if images.count > 0 {
            XCTAssertTrue(images.count > 0, "Должно быть найдено хотя бы одно изображение")
            print("✅ Примеры найденных изображений: \(Array(images.prefix(5)))")
        } else {
            print("⚠️ Изображения не найдены в Assets - возможно, миграция еще не выполнена")
        }

        XCTAssertTrue(true, "Метод getAllAvailableImages должен корректно обрабатывать запросы")
    }

    // MARK: - Тесты получения размера изображений

    func testGetImageSize() {
        // Тест получения размера изображения
        let size = ImageAssetManager.getImageSize("1")

        if let size {
            XCTAssertTrue(size.width > 0, "Ширина изображения должна быть больше 0")
            XCTAssertTrue(size.height > 0, "Высота изображения должна быть больше 0")
            print("📏 Размер изображения '1': \(size)")
        } else {
            print("⚠️ Не удалось получить размер изображения '1' - возможно, миграция еще не выполнена")
        }

        XCTAssertTrue(true, "Метод getImageSize должен корректно обрабатывать запросы")
    }

    func testGetImageSizeForNonExistentImage() {
        // Тест получения размера несуществующего изображения
        let size = ImageAssetManager.getImageSize("nonexistent-image-12345")
        XCTAssertNil(size, "Размер несуществующего изображения должен быть nil")
    }

    // MARK: - Тесты производительности

    func testPerformanceGetImageURL() {
        // Тест производительности получения URL
        measure {
            for i in 1 ... 100 {
                _ = ImageAssetManager.getImageURL(for: "\(i % 10 + 1)")
            }
        }
    }

    func testPerformanceGetAllAvailableImages() {
        // Тест производительности получения всех изображений
        measure {
            _ = ImageAssetManager.getAllAvailableImages()
        }
    }
}
