import OSLog
import UIKit

enum ImageProcessor {
    /// Максимальный размер стороны изображения (аналогично Android: 1280x720)
    static let maxImageSize: CGFloat = 1280
    /// Качество сжатия JPEG (аналогично Android: 100% = без потери качества)
    static let compressionQuality: CGFloat = 1.0
    /// Максимальный размер файла (ограничение сервера) - 10 МБ
    static let maxFileSize = 10 * 1024 * 1024

    /// Обрабатывает изображение перед отправкой на сервер (аналогично Android приложению)
    ///
    /// 1. Масштабирует изображение до максимального размера 1280x720
    /// 2. Сжимает как JPEG с качеством 100% (без потери качества)
    /// 3. Аналогично логике Android: readScaledBitmap + handleSamplingAndRotationBitmap
    static func processImage(_ image: UIImage) -> Data? {
        guard let resizedImage = resizeImage(image, to: maxImageSize),
              let compressedData = compressImage(resizedImage, quality: compressionQuality) else {
            Logger.imageProcessor.error("Не удалось обработать изображение")
            return nil
        }
        return compressedData
    }

    /// Создает уменьшенную копию изображения для предварительного просмотра
    static func createThumbnail(from image: UIImage, size: CGSize = CGSize(width: 150, height: 150)) -> UIImage? {
        resizeImage(image, to: min(size.width, size.height))
    }

    static func validateImageSize(_ data: Data) -> Bool {
        data.count <= maxFileSize
    }

    /// Проверяет формат изображения
    static func validateImageFormat(_ data: Data) -> Bool {
        guard let image = UIImage(data: data) else { return false }
        return image.size.width > 0 && image.size.height > 0
    }

    /// Масштабирует изображение до указанного максимального размера (аналогично Android calculateInSampleSize)
    ///
    /// Сохраняет пропорции изображения, уменьшая размер до тех пор, пока обе стороны не станут <= maxSize
    private static func resizeImage(_ image: UIImage, to maxSize: CGFloat) -> UIImage? {
        let originalSize = image.size
        let minSide = min(originalSize.width, originalSize.height)

        guard minSide > maxSize else { return image }

        let scale = maxSize / minSide
        let newSize = CGSize(width: originalSize.width * scale, height: originalSize.height * scale)

        UIGraphicsBeginImageContextWithOptions(newSize, false, image.scale)
        defer { UIGraphicsEndImageContext() }
        image.draw(in: CGRect(origin: .zero, size: newSize))
        return UIGraphicsGetImageFromCurrentImageContext()
    }

    /// Сжимает изображение в формат JPEG с указанным качеством (аналогично Android compress)
    private static func compressImage(_ image: UIImage, quality: CGFloat) -> Data? {
        image.jpegData(compressionQuality: quality)
    }
}

private extension Logger {
    static let imageProcessor = Logger(subsystem: "SotkaApp", category: "ImageProcessor")
}
