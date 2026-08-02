import OSLog
import UIKit

/// Менеджер для работы с изображениями инфопостов из Assets.xcassets
enum ImageAssetManager {
    private static let logger = Logger(subsystem: Bundle.sotkaAppBundleId, category: String(describing: ImageAssetManager.self))

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
}
