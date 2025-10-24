import Foundation
import OSLog

/// Протокол для загрузки фотографий прогресса
protocol PhotoDownloadServiceProtocol {
    @MainActor
    func downloadAllPhotos(for progress: UserProgress) async
}

/// Сервис для загрузки фотографий прогресса
struct PhotoDownloadService: PhotoDownloadServiceProtocol {
    private let logger = Logger(subsystem: "SotkaApp", category: "PhotoDownload")

    /// Загружает все новые фотографии для прогресса
    ///
    /// В процессе загрузки некоторые фото могут упасть в ошибку,
    /// на этот случай нужно предусмотреть повторную загрузку
    /// при следующей синхронизации
    @MainActor
    func downloadAllPhotos(for progress: UserProgress) async {
        let photosToDownload: [(String?, ProgressPhotoType)] = [
            (progress.urlPhotoFront, .front),
            (progress.urlPhotoBack, .back),
            (progress.urlPhotoSide, .side)
        ]

        let array: [(Data?, ProgressPhotoType)] = await withTaskGroup(of: (Data?, ProgressPhotoType).self) { group in
            var results: [(Data?, ProgressPhotoType)] = []
            for (urlString, type) in photosToDownload {
                guard let urlString, let url = URL(string: urlString) else {
                    continue
                }
                group.addTask {
                    do {
                        let (data, _) = try await URLSession.shared.data(from: url)
                        return (data, type)
                    } catch {
                        logger.error("Ошибка загрузки фото \(type): \(error.localizedDescription)")
                        return (nil, type)
                    }
                }
            }
            for await result in group {
                results.append(result)
            }
            return results
        }
        array.forEach { data, type in
            switch type {
            case .front: progress.dataPhotoFront = data
            case .back: progress.dataPhotoBack = data
            case .side: progress.dataPhotoSide = data
            }
        }
    }
}

/// Ошибки загрузки фотографий
enum PhotoError: LocalizedError, Equatable {
    case invalidURL
    case invalidImageData

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            "Некорректный URL изображения"
        case .invalidImageData:
            "Некорректные данные изображения"
        }
    }
}
