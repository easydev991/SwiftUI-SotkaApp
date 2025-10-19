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

    var displayMode: ProgressDisplayMode

    // MARK: - Edited Values (данные для редактирования)

    var pullUps = ""
    var pushUps = ""
    var squats = ""
    var weight = ""

    // MARK: - Progress Reference

    private let progressModel: Progress

    /// Доступ к прогрессу (для использования в других экранах)
    var progress: Progress {
        progressModel
    }

    // MARK: - Initialization

    /// Инициализирует сервис с прогрессом
    /// - Parameters:
    ///   - progress: Модель прогресса для изменения
    ///   - mode: Режим отображения
    init(progress: Progress, mode: ProgressDisplayMode) {
        self.progressModel = progress
        self.displayMode = mode
        loadProgress()
    }

    // MARK: - Public Methods

    /// Загружает данные прогресса в сервис для редактирования
    func loadProgress() {
        // Предварительная ссылка для логирования
        let logId = progress.id
        logger.info("Загружаем данные прогресса для дня \(logId)")

        // Загружаем текущие значения, преобразуя 0 в пустые строки
        let newPullUps = progressModel.pullUps.stringFromInt()
        let newPushUps = progressModel.pushUps.stringFromInt()
        let newSquats = progressModel.squats.stringFromInt()
        let newWeight = progressModel.weight.stringFromFloat()

        // Обновляем только если данные изменились
        if pullUps != newPullUps || pushUps != newPushUps || squats != newSquats || weight != newWeight {
            pullUps = newPullUps
            pushUps = newPushUps
            squats = newSquats
            weight = newWeight

            let logPullUps = pullUps
            let logPushUps = pushUps
            let logSquats = squats
            let logWeight = weight
            logger
                .info("Данные прогресса загружены: pullUps=\(logPullUps), pushUps=\(logPushUps), squats=\(logSquats), weight=\(logWeight)")
        } else {
            logger.info("Данные прогресса не изменились, пропускаем обновление")
        }
    }

    /// Сохраняет прогресс (создание или обновление)
    /// - Parameter context: Контекст SwiftData
    func saveProgress(context: ModelContext) throws {
        // Предварительная ссылка для логирования
        let logId = progress.id
        logger.info("Сохраняем прогресс для дня \(logId)")

        // Валидируем данные перед сохранением
        guard canSave else {
            logger.error("Невозможно сохранить прогресс: данные не прошли валидацию")
            throw ProgressValidationError.invalidData
        }

        // Определяем, является ли это новым прогрессом
        let isNewProgress = progressModel.pullUps == nil && progressModel.pushUps == nil &&
            progressModel.squats == nil && progressModel.weight == nil

        // Проверяем, есть ли реальные изменения в данных
        let currentPullUps = progressModel.pullUps.stringFromInt()
        let currentPushUps = progressModel.pushUps.stringFromInt()
        let currentSquats = progressModel.squats.stringFromInt()
        let currentWeight = progressModel.weight.stringFromFloat()

        let hasRealChanges = pullUps != currentPullUps || pushUps != currentPushUps ||
            squats != currentSquats || weight != currentWeight

        // Обновляем данные прогресса только если есть изменения
        if hasRealChanges {
            progressModel.pullUps = pullUps.isEmpty ? nil : Int(pullUps)
            progressModel.pushUps = pushUps.isEmpty ? nil : Int(pushUps)
            progressModel.squats = squats.isEmpty ? nil : Int(squats)
            progressModel.weight = weight.isEmpty ? nil : Float.fromUIString(weight)

            // Обновляем флаги синхронизации только при реальных изменениях
            progressModel.isSynced = false
            progressModel.shouldDelete = false
            progressModel.lastModified = Date.now

            logger.info("Данные прогресса обновлены для дня \(logId)")
        } else {
            // Данные не изменились - просто обновляем флаги синхронизации
            progressModel.isSynced = true
            progressModel.shouldDelete = false
            logger.info("Данные прогресса не изменились для дня \(logId) - помечаем как синхронизированные")
        }

        // Устанавливаем связь с пользователем, если она не установлена
        if progressModel.user == nil {
            let user = try getCurrentUser(context: context)
            progressModel.user = user
            logger.info("Установлена связь прогресса с пользователем: \(user.id)")
        }

        // Сохраняем в контексте
        try context.save()

        // Предварительные ссылки для логирования
        let logPullUps = progressModel.pullUps?.description ?? "nil"
        let logPushUps = progressModel.pushUps?.description ?? "nil"
        let logSquats = progressModel.squats?.description ?? "nil"
        let logWeight = progressModel.weight?.description ?? "nil"

        logger
            .info(
                "Прогресс сохранен в SwiftData: id=\(logId), pullUps=\(logPullUps), pushUps=\(logPushUps), squats=\(logSquats), weight=\(logWeight)"
            )

        if isNewProgress {
            logger.info("Новый прогресс создан для дня \(logId)")
        } else {
            logger.info("Прогресс обработан для дня \(logId)")
        }
        logger.info("Синхронизация будет выполнена отдельно")
    }

    /// Удаляет прогресс (мягкое удаление)
    /// - Parameter context: Контекст SwiftData
    func deleteProgress(context: ModelContext) throws {
        // Предварительная ссылка для логирования
        let logId = progressModel.id
        let logShouldDelete = progressModel.shouldDelete
        logger.info("Удаляем прогресс для дня \(logId), текущий shouldDelete: \(logShouldDelete)")

        // Мягкое удаление: помечаем для удаления
        progressModel.shouldDelete = true
        progressModel.isSynced = false
        progressModel.lastModified = Date.now

        try context.save()

        let logNewShouldDelete = progressModel.shouldDelete
        logger.info("Прогресс для дня \(logId) помечен для удаления, новый shouldDelete: \(logNewShouldDelete)")
        logger.info("Синхронизация удаления будет выполнена отдельно")
    }

    // MARK: - Private Methods

    // MARK: - Computed Properties

    /// Проверяет, можно ли сохранить прогресс
    var canSave: Bool {
        // Проверяем, что есть хотя бы одно заполненное поле или фото
        let hasTextData = [pullUps, pushUps, squats, weight].contains { !$0.isEmpty }
        let hasPhotoData = progressModel.hasAnyPhotoData

        guard hasTextData || hasPhotoData else {
            logger.debug("Нет данных для сохранения")
            return false
        }

        // Валидируем только заполненные поля (сервер и Android позволяют частично заполненные данные)
        // Разрешаем 0 как допустимое значение (например, если упражнение еще не выполнялось)
        let pullUpsValid = pullUps.isValidNonNegativeInteger
        let pushUpsValid = pushUps.isValidNonNegativeInteger
        let squatsValid = squats.isValidNonNegativeInteger
        let weightValid = weight.isValidNonNegativeFloat

        let isValid = pullUpsValid && pushUpsValid && squatsValid && weightValid

        if !isValid {
            logger
                .debug(
                    "Данные не прошли валидацию: pullUps=\(pullUpsValid), pushUps=\(pushUpsValid), squats=\(squatsValid), weight=\(weightValid)"
                )
        }

        return isValid
    }

    /// Проверяет, есть ли изменения в данных
    var hasChanges: Bool {
        // Получаем оригинальные значения из progress, преобразуя 0 в пустые строки
        let originalPullUps = progressModel.pullUps.stringFromInt()
        let originalPushUps = progressModel.pushUps.stringFromInt()
        let originalSquats = progressModel.squats.stringFromInt()
        let originalWeight = progressModel.weight.stringFromFloat()

        // Проверяем, является ли это новым прогрессом (все оригинальные значения пустые)
        let isNewProgress = originalPullUps.isEmpty && originalPushUps.isEmpty &&
            originalSquats.isEmpty && originalWeight.isEmpty

        if isNewProgress {
            // Для нового прогресса проверяем, есть ли хотя бы одно заполненное поле
            let hasAnyData = !pullUps.isEmpty || !pushUps.isEmpty || !squats.isEmpty || !weight.isEmpty
            if hasAnyData {
                logger.debug("Новый прогресс с данными")
            }
            return hasAnyData
        } else {
            // Для существующего прогресса сравниваем с оригинальными значениями
            let hasChanges = pullUps != originalPullUps || pushUps != originalPushUps ||
                squats != originalSquats || weight != originalWeight

            if hasChanges {
                logger.debug("Обнаружены изменения в данных прогресса")
            }

            return hasChanges
        }
    }
}

// MARK: - Error Types

enum ProgressValidationError: LocalizedError {
    case invalidData
    case userNotFound

    var errorDescription: String? {
        switch self {
        case .invalidData:
            "Некорректные данные прогресса"
        case .userNotFound:
            "Пользователь не найден"
        }
    }
}

enum ProgressError: LocalizedError {
    case invalidImageData
    case imageProcessingFailed
    case photoNotFound

    var errorDescription: String? {
        switch self {
        case .invalidImageData:
            "Некорректные данные изображения"
        case .imageProcessingFailed:
            "Ошибка обработки изображения"
        case .photoNotFound:
            "Фотография не найдена"
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
            throw ProgressValidationError.userNotFound
        }
        logger.info("Найден пользователь с ID: \(user.id)")
        return user
    }
}

// MARK: - Photo Management

extension ProgressService {
    /// Добавляет фотографию к прогрессу
    /// - Parameters:
    ///   - data: Данные изображения
    ///   - type: Тип фотографии
    ///   - context: Контекст SwiftData для сохранения
    func addPhoto(_ data: Data?, type: PhotoType, context: ModelContext) throws {
        guard let data else {
            throw ProgressError.invalidImageData
        }

        guard ImageProcessor.validateImageSize(data),
              ImageProcessor.validateImageFormat(data) else {
            throw ProgressError.invalidImageData
        }

        guard let image = UIImage(data: data) else {
            throw ProgressError.invalidImageData
        }

        let processedData = ImageProcessor.processImage(image)
        guard let processedData else {
            throw ProgressError.imageProcessingFailed
        }

        // Используем новые методы модели Progress
        progressModel.setPhotoData(type, data: processedData)

        // Устанавливаем связь с пользователем, если она не установлена
        if progressModel.user == nil {
            let user = try getCurrentUser(context: context)
            progressModel.user = user
            logger.info("Установлена связь прогресса с пользователем: \(user.id)")
        }

        try context.save()
        let progressId = progressModel.id
        logger.info("\(type.localizedTitle) добавлена к прогрессу дня \(progressId)")
    }

    /// Удаляет фотографию из прогресса
    /// - Parameters:
    ///   - type: Тип фотографии
    ///   - context: Контекст SwiftData для сохранения
    func deletePhoto(_ type: PhotoType, context: ModelContext) throws {
        let dayNumber = progressModel.id
        logger.info("Удаляем фотографию \(type.localizedTitle) для прогресса дня \(dayNumber)")

        // Используем новые методы модели Progress
        progressModel.deletePhotoData(type)

        // Устанавливаем связь с пользователем, если она не установлена
        if progressModel.user == nil {
            let user = try getCurrentUser(context: context)
            progressModel.user = user
            logger.info("Установлена связь прогресса с пользователем: \(user.id)")
        }

        try context.save()
        logger.info("Фотография \(type.localizedTitle) успешно удалена")
    }
}
