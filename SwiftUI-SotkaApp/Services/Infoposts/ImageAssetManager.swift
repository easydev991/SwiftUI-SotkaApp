import OSLog
import UIKit

/// Менеджер для работы с изображениями инфопостов из Assets.xcassets
enum ImageAssetManager {
    private static let logger = Logger(subsystem: "SotkaApp", category: "ImageAssetManager")

    /// Получает URL изображения из Assets.xcassets
    /// - Parameter imageName: Имя изображения (например, "1", "1-1", "aims-0")
    /// - Returns: URL изображения или nil если не найдено
    static func getImageURL(for imageName: String) -> URL? {
        // Убираем расширение если есть
        let cleanName = imageName.replacingOccurrences(of: ".jpg", with: "")
            .replacingOccurrences(of: ".png", with: "")

        // Проверяем, существует ли изображение в Assets.xcassets
        guard UIImage(named: cleanName) != nil else {
            logger.warning("Изображение \(cleanName) не найдено в Assets")
            return nil
        }

        // Создаем временный URL для изображения
        let tempDirectory = FileManager.default.temporaryDirectory
        let tempURL = tempDirectory.appendingPathComponent("\(cleanName).jpg")

        logger.debug("Найдено изображение \(cleanName) в Assets")
        return tempURL
    }

    /// Копирует изображение из Assets во временную директорию
    /// - Parameters:
    ///   - imageName: Имя изображения
    ///   - destinationURL: URL назначения
    /// - Returns: true если успешно скопировано
    static func copyImageToTemp(imageName: String, destinationURL: URL) -> Bool {
        // Убираем расширение если есть
        let cleanName = imageName.replacingOccurrences(of: ".jpg", with: "")
            .replacingOccurrences(of: ".png", with: "")

        // Получаем изображение из Assets.xcassets
        guard let image = UIImage(named: cleanName) else {
            logger.warning("Не удалось найти изображение \(cleanName) в Assets")
            return false
        }

        // Конвертируем изображение в JPEG данные
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            logger.error("Не удалось конвертировать изображение \(cleanName) в JPEG")
            return false
        }

        // Сохраняем изображение во временную директорию
        do {
            let fileManager = FileManager.default
            if fileManager.fileExists(atPath: destinationURL.path) {
                try fileManager.removeItem(at: destinationURL)
            }
            try imageData.write(to: destinationURL)
            logger.debug("Успешно скопировано изображение \(cleanName) в \(destinationURL.path)")
            return true
        } catch {
            logger.error("Ошибка при сохранении изображения \(cleanName): \(error.localizedDescription)")
            return false
        }
    }

    /// Получает список всех доступных изображений в Assets
    /// - Returns: Set имен изображений
    static func getAllAvailableImages() -> Set<String> {
        var imageNames = Set<String>()

        let infopostsPath = "Assets.xcassets/InfopostsImages"

        if let infopostsURL = Bundle.main.url(forResource: nil, withExtension: nil, subdirectory: infopostsPath) {
            do {
                let contents = try FileManager.default.contentsOfDirectory(at: infopostsURL, includingPropertiesForKeys: nil)

                for url in contents {
                    if url.pathExtension == "imageset" {
                        let imageName = url.lastPathComponent.replacingOccurrences(of: ".imageset", with: "")
                        imageNames.insert(imageName)
                    }
                }
            } catch {
                logger.error("Ошибка чтения папки InfopostsImages: \(error.localizedDescription)")
            }
        }

        logger.debug("Найдено \(imageNames.count) изображений в Assets")
        return imageNames
    }

    /// Проверяет, существует ли изображение в Assets
    /// - Parameter imageName: Имя изображения
    /// - Returns: true если изображение существует
    static func imageExists(_ imageName: String) -> Bool {
        getImageURL(for: imageName) != nil
    }

    /// Получает размер изображения в Assets (если возможно)
    /// - Parameter imageName: Имя изображения
    /// - Returns: Размер изображения или nil
    static func getImageSize(_ imageName: String) -> CGSize? {
        guard let imageURL = getImageURL(for: imageName) else {
            return nil
        }

        guard let imageSource = CGImageSourceCreateWithURL(imageURL as CFURL, nil) else {
            return nil
        }

        guard let imageProperties = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, nil) as? [CFString: Any] else {
            return nil
        }

        if let width = imageProperties[kCGImagePropertyPixelWidth] as? NSNumber,
           let height = imageProperties[kCGImagePropertyPixelHeight] as? NSNumber {
            return CGSize(width: width.doubleValue, height: height.doubleValue)
        }

        return nil
    }
}
