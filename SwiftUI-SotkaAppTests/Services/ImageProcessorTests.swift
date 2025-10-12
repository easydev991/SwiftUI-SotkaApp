import Foundation
@testable import SwiftUI_SotkaApp
import Testing
import UIKit

struct ImageProcessorTests {
    // MARK: - Test Data

    private var testImageData: Data {
        // Создаем тестовые данные изображения (1x1 пиксель PNG)
        let testImage = UIImage(systemName: "photo") ?? UIImage()
        return testImage.pngData() ?? Data()
    }

    private var largeImageData: Data {
        // Создаем большое изображение для тестирования
        let size = CGSize(width: 2000, height: 2000)
        UIGraphicsBeginImageContextWithOptions(size, false, 1.0)
        defer { UIGraphicsEndImageContext() }

        UIColor.red.setFill()
        UIRectFill(CGRect(origin: .zero, size: size))

        let image = UIGraphicsGetImageFromCurrentImageContext() ?? UIImage()
        return image.pngData() ?? Data()
    }

    // MARK: - Image Processing Tests

    @Test("Обработка большого изображения")
    func largeImageProcessing() throws {
        let originalImage = try #require(UIImage(data: largeImageData))
        let processedData = ImageProcessor.processImage(originalImage)

        let processedDataUnwrapped = try #require(processedData)
        #expect(ImageProcessor.validateImageSize(processedDataUnwrapped))
        #expect(ImageProcessor.validateImageFormat(processedDataUnwrapped))
    }

    @Test("Обработка маленького изображения")
    func smallImageProcessing() throws {
        let smallImage = try #require(UIImage(data: testImageData))
        let processedData = ImageProcessor.processImage(smallImage)

        let processedDataUnwrapped = try #require(processedData)
        #expect(ImageProcessor.validateImageSize(processedDataUnwrapped))
        #expect(ImageProcessor.validateImageFormat(processedDataUnwrapped))
    }

    @Test("Обработка пустого изображения")
    func emptyImageProcessing() {
        // Создаем изображение с нулевым размером
        let emptyImage = UIImage()
        let processedData = ImageProcessor.processImage(emptyImage)

        #expect(processedData == nil, "UIImage() создает изображение 1x1 пиксель, но ImageProcessor не может его обработать")
    }

    // MARK: - Thumbnail Creation Tests

    @Test("Создание миниатюры изображения", arguments: [
        CGSize(width: 150, height: 150),
        CGSize(width: 100, height: 100),
        CGSize(width: 200, height: 200)
    ])
    func thumbnailCreation(size: CGSize) throws {
        let originalImage = try #require(UIImage(data: largeImageData))
        let thumbnail = ImageProcessor.createThumbnail(from: originalImage, size: size)

        let thumbnailUnwrapped = try #require(thumbnail)
        #expect(thumbnailUnwrapped.size.width <= size.width)
        #expect(thumbnailUnwrapped.size.height <= size.height)
    }

    @Test("Создание миниатюры с размером по умолчанию")
    func defaultThumbnailCreation() throws {
        let originalImage = try #require(UIImage(data: largeImageData))
        let thumbnail = ImageProcessor.createThumbnail(from: originalImage)

        let thumbnailUnwrapped = try #require(thumbnail)
        #expect(thumbnailUnwrapped.size.width <= 150)
        #expect(thumbnailUnwrapped.size.height <= 150)
    }

    // MARK: - Image Size Validation Tests

    @Test("Валидация размера изображения", arguments: [
        (5 * 1024 * 1024, true), // 5MB - валидно
        (15 * 1024 * 1024, false), // 15MB - слишком большой
        (1024, true) // 1KB - валидно
    ])
    func imageSizeValidation(size: Int, expected: Bool) {
        let testData = Data(repeating: 0, count: size)
        #expect(ImageProcessor.validateImageSize(testData) == expected)
    }

    @Test("Валидация размера с реальными данными изображения")
    func imageSizeValidationWithRealData() {
        let smallData = testImageData
        let largeData = largeImageData

        #expect(ImageProcessor.validateImageSize(smallData))
        #expect(ImageProcessor.validateImageSize(largeData))
    }

    // MARK: - Image Format Validation Tests

    @Test("Валидация формата изображения с валидными данными")
    func imageFormatValidationWithValidData() {
        let validData = testImageData
        #expect(ImageProcessor.validateImageFormat(validData))
    }

    @Test("Валидация формата изображения с невалидными данными")
    func imageFormatValidationWithInvalidData() {
        let invalidData = Data("not an image".utf8)
        let emptyData = Data()

        #expect(!ImageProcessor.validateImageFormat(invalidData), "Текстовые данные не должны проходить валидацию формата изображения")
        #expect(!ImageProcessor.validateImageFormat(emptyData), "Пустые данные не должны проходить валидацию формата изображения")
    }

    // MARK: - Constants Tests

    @Test("Константы ImageProcessor имеют корректные значения")
    func imageProcessorConstants() {
        #expect(ImageProcessor.maxImageSize == 1280)
        #expect(ImageProcessor.compressionQuality == 1.0)
        #expect(ImageProcessor.maxFileSize == 10 * 1024 * 1024)
    }

    // MARK: - Edge Cases Tests

    @Test("Обработка изображения с очень большим размером")
    func veryLargeImageProcessing() throws {
        // Создаем очень большое изображение
        let veryLargeSize = CGSize(width: 5000, height: 5000)
        UIGraphicsBeginImageContextWithOptions(veryLargeSize, false, 1.0)
        defer { UIGraphicsEndImageContext() }

        UIColor.blue.setFill()
        UIRectFill(CGRect(origin: .zero, size: veryLargeSize))

        let veryLargeImage = UIGraphicsGetImageFromCurrentImageContext() ?? UIImage()
        let processedData = ImageProcessor.processImage(veryLargeImage)

        let processedDataUnwrapped = try #require(processedData)
        #expect(ImageProcessor.validateImageSize(processedDataUnwrapped))
        #expect(ImageProcessor.validateImageFormat(processedDataUnwrapped))
    }
}
