import Foundation
import OSLog
import UIKit

private let logger = Logger(subsystem: "SotkaApp", category: "PhotoDownload")

/// Сервис для асинхронной загрузки и кэширования фотографий прогресса
struct PhotoDownloadService {
    /// Загружает фотографию по URL и сохраняет в модель прогресса
    @MainActor
    func downloadAndCachePhoto(_ urlString: String, for progress: Progress, type: PhotoType) async throws {
        // 1. Проверяем, что URL валидный и является HTTP/HTTPS
        guard let url = URL(string: urlString),
              let scheme = url.scheme,
              scheme == "http" || scheme == "https" else {
            throw PhotoError.invalidURL
        }

        // 2. Загружаем данные изображения
        let (data, _) = try await URLSession.shared.data(from: url)

        // 3. Проверяем размер (не более 10MB как в Android)
        guard data.count <= 10 * 1024 * 1024 else {
            throw PhotoError.fileTooLarge
        }

        // 4. Сохраняем данные в модель прогресса
        progress.setPhotoData(type, data: data)

        // 5. Помечаем прогресс как измененный
        progress.isSynced = false
        progress.lastModified = Date()
    }

    /// Автоматически загружает все новые фотографии для прогресса
    @MainActor
    func downloadAllPhotos(for progress: Progress) async {
        let photosToDownload: [(String?, PhotoType)] = [
            (progress.urlPhotoFront, .front),
            (progress.urlPhotoBack, .back),
            (progress.urlPhotoSide, .side)
        ]

        for (urlString, type) in photosToDownload {
            guard let urlString else { continue }

            // Проверяем, нужно ли загружать (если данных нет или URL обновился)
            if progress.getPhotoData(type) == nil {
                do {
                    try await downloadAndCachePhoto(urlString, for: progress, type: type)
                } catch {
                    logger.error("Ошибка загрузки фото \(type.rawValue): \(error.localizedDescription)")
                }
            }
        }
    }
}

/// Ошибки загрузки фотографий
enum PhotoError: LocalizedError, Equatable {
    case invalidURL
    case fileTooLarge
    case invalidImageData

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            "Некорректный URL изображения"
        case .fileTooLarge:
            "Размер файла превышает 10MB"
        case .invalidImageData:
            "Некорректные данные изображения"
        }
    }
}
