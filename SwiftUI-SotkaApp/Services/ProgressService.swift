import Foundation
import Observation
import OSLog
import SwiftData
import SWUtils
import UIKit

@MainActor
@Observable
final class ProgressService {
    private let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier!,
        category: String(describing: ProgressService.self)
    )
    private let progressModel: Progress
    private let initialPhotoModels: [TempPhotoModel]
    var displayMode: ProgressDisplayMode
    var metricsModel = TempMetricsModel()
    var photoModels = [TempPhotoModel]()

    /// Инициализирует сервис
    /// - Parameters:
    ///   - progress: Модель прогресса для изменения
    ///   - mode: Режим отображения
    init(progress: Progress, mode: ProgressDisplayMode) {
        self.progressModel = progress
        self.initialPhotoModels = progress.tempPhotoItems
        self.displayMode = mode
        loadProgress()
    }

    /// Загружает данные прогресса в сервис для редактирования
    func loadProgress() {
        // Предварительная ссылка для логирования
        let logId = progress.id
        logger.info("Загружаем данные прогресса для дня \(logId)")
        let initialMetrics = TempMetricsModel(progress: progressModel)
        metricsModel = initialMetrics
        photoModels = progress.tempPhotoItems
        let logPhotos = photoModels
        logger.info("Данные прогресса загружены: \(initialMetrics), photos: \(logPhotos)")
    }

    /// Сохраняет прогресс (создание или обновление)
    /// - Parameter context: Контекст SwiftData
    func saveProgress(context: ModelContext) throws {
        let logId = progress.id
        logger.info("Сохраняем прогресс для дня \(logId)")
        guard canSave else {
            logger.error("Невозможно сохранить прогресс: данные не прошли валидацию")
            throw ServiceError.invalidData
        }
        let isNewProgress = progressModel.isEmpty
        progressModel.setMetricsData(metricsModel)
        progressModel.setPhotosData(photoModels)
        logger.info("Данные прогресса обновлены для дня \(logId)")
        // Устанавливаем связь с пользователем, если она не установлена
        if progressModel.user == nil {
            let user = try getCurrentUser(context: context)
            progressModel.user = user
            logger.info("Установлена связь прогресса с пользователем: \(user.id)")
        }
        try context.save()
        let updatedProgress = progressModel
        logger.info("Прогресс сохранен в SwiftData: \(updatedProgress)")
        if isNewProgress {
            logger.info("Новый прогресс создан для дня \(logId)")
        } else {
            logger.info("Прогресс обновлен для дня \(logId)")
        }
        logger.info("Синхронизация с сервером будет выполнена отдельно")
    }

    /// Удаляет прогресс (мягкое удаление)
    /// - Parameter context: Контекст SwiftData
    func deleteProgress(context: ModelContext) throws {
        let logId = progressModel.id
        let logShouldDelete = progressModel.shouldDelete
        logger.info("Удаляем прогресс для дня \(logId), текущий shouldDelete: \(logShouldDelete)")
        progressModel.shouldDelete = true
        progressModel.isSynced = false
        progressModel.lastModified = .now
        try context.save()
        let logNewShouldDelete = progressModel.shouldDelete
        logger
            .info(
                "Прогресс для дня \(logId) помечен для удаления, новый shouldDelete: \(logNewShouldDelete), синхронизация с сервером будет выполнена отдельно"
            )
    }
}

extension ProgressService {
    /// Доступ к прогрессу (для использования в других экранах)
    var progress: Progress {
        progressModel
    }

    /// Проверяет, можно ли сохранить прогресс
    ///
    /// - Валидируем только заполненные поля (сервер такое позволяет)
    /// - Разрешаем 0 как допустимое значение (например, если упражнение еще не выполнялось)
    var canSave: Bool {
        let isValid = metricsModel.hasValidNumbers
        if !isValid {
            logger.debug("Данные не прошли валидацию")
        }
        if !hasChanges {
            logger.debug("Данные не содержат изменений")
        }
        return isValid && hasChanges
    }

    private var hasChanges: Bool {
        let hasMetricsChanges = metricsModel.hasChanges(to: progressModel)
        let hasPhotoChanges = photoModels != initialPhotoModels
        return hasMetricsChanges || hasPhotoChanges
    }
}

extension ProgressService {
    enum ServiceError: LocalizedError {
        case invalidData
        case userNotFound
        case invalidImageData
        case invalidPhotoType
        case imageProcessingFailed
        case photoNotFound

        var errorDescription: String? {
            switch self {
            case .invalidData:
                "Некорректные данные прогресса"
            case .userNotFound:
                "Пользователь не найден"
            case .invalidImageData:
                "Некорректные данные изображения"
            case .invalidPhotoType:
                "Неподдерживаемый тип фотографии"
            case .imageProcessingFailed:
                "Ошибка обработки изображения"
            case .photoNotFound:
                "Фотография не найдена"
            }
        }
    }
}

private extension ProgressService {
    /// Получает текущего пользователя из базы данных
    /// - Parameter context: Контекст модели данных
    /// - Returns: Текущий пользователь
    /// - Throws: Ошибка при работе с базой данных
    func getCurrentUser(context: ModelContext) throws -> User {
        guard let user = try context.fetch(FetchDescriptor<User>()).first else {
            logger.error("Пользователь не найден в базе данных")
            throw ServiceError.userNotFound
        }
        logger.info("Найден пользователь с ID: \(user.id)")
        return user
    }
}

// MARK: - Управление фотографиями

extension ProgressService {
    func deleteTempPhoto(type: PhotoType) {
        let logId = progress.id
        logger.info(
            "Начинаем удалять временное фото \(type) для прогресса дня \(logId)"
        )
        do {
            guard let index = photoModels.firstIndex(where: { $0.type == type }) else {
                throw ServiceError.invalidPhotoType
            }
            let updatedPhotoModel = TempPhotoModel(
                type: type,
                urlString: nil,
                data: Progress.DELETED_DATA
            )
            photoModels[index] = updatedPhotoModel
            logger.info("Удалили временное фото \(type) для прогресса дня \(logId)")
        } catch {
            logger.error("\(error.localizedDescription), день № \(logId)")
        }
    }

    func pickTempPhoto(_ data: Data?, type: PhotoType) {
        let logId = progress.id
        logger.info("Обновляем фотографию типа \(type) для прогресса дня \(logId)")
        do {
            guard let index = photoModels.firstIndex(where: { $0.type == type }) else {
                throw ServiceError.invalidPhotoType
            }
            guard let data else {
                throw ServiceError.invalidImageData
            }
            guard ImageProcessor.validateImageSize(data),
                  ImageProcessor.validateImageFormat(data),
                  let image = UIImage(data: data)
            else {
                throw ServiceError.invalidImageData
            }
            let processedData = ImageProcessor.processImage(image)
            guard let processedData else {
                throw ServiceError.imageProcessingFailed
            }
            let updatedPhotoModel = TempPhotoModel(
                type: type,
                urlString: nil,
                data: processedData
            )
            photoModels[index] = updatedPhotoModel
            logger.info(
                "Фотография типа \(type) успешно обновлена в photoModels, \(updatedPhotoModel)"
            )
        } catch {
            logger.error("\(error.localizedDescription), день № \(logId)")
        }
    }
}
