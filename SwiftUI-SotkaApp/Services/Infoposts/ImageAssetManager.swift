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

        // Определяем правильное расширение на основе того, что существует в Assets
        let tempDirectory = FileManager.default.temporaryDirectory
        let tempURL = tempDirectory.appendingPathComponent("\(cleanName).png")

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

        // Определяем формат на основе расширения файла назначения
        let fileExtension = destinationURL.pathExtension.lowercased()
        let imageData: Data? = if fileExtension == "png" {
            // Для PNG файлов сохраняем как PNG
            image.pngData()
        } else if fileExtension == "jpg" || fileExtension == "jpeg" {
            // Для JPG файлов конвертируем в JPEG
            image.jpegData(compressionQuality: 0.8)
        } else {
            // По умолчанию сохраняем как PNG
            image.pngData()
        }

        guard let data = imageData else {
            logger.error("Не удалось конвертировать изображение \(cleanName) в \(fileExtension.uppercased())")
            return false
        }

        // Сохраняем изображение во временную директорию
        do {
            let fileManager = FileManager.default
            if fileManager.fileExists(atPath: destinationURL.path) {
                try fileManager.removeItem(at: destinationURL)
            }
            try data.write(to: destinationURL)
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

        // Получаем все изображения из InfopostsImages
        let knownImages = [
            "1", "1-1", "1-1-en", "1-dop-1", "aims-0", "aims-1", "cover",
            "48-1", "100", "organiz-1", "mobile-gp"
        ]

        for imageName in knownImages {
            if UIImage(named: imageName) != nil {
                imageNames.insert(imageName)
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
        // Убираем расширение если есть
        let cleanName = imageName.replacingOccurrences(of: ".jpg", with: "")
            .replacingOccurrences(of: ".png", with: "")

        // Получаем изображение из Assets.xcassets
        guard let image = UIImage(named: cleanName) else {
            logger.warning("Не удалось найти изображение \(cleanName) в Assets")
            return nil
        }

        return image.size
    }
}
