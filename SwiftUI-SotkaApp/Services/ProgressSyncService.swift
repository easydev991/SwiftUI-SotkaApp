import Foundation
import Observation
import OSLog
import SwiftData
import SWUtils

/// Сервис синхронизации прогресса пользователя
@MainActor
@Observable
final class ProgressSyncService {
    private let client: ProgressClient
    private let logger = Logger(subsystem: "SotkaApp", category: "ProgressSync")

    /// Флаг загрузки синхронизации
    private(set) var isSyncing = false

    init(client: ProgressClient) {
        self.client = client
    }

    /// Основной метод синхронизации
    func syncProgress(context: ModelContext) async {
        guard !isSyncing else {
            logger.info("Синхронизация прогресса уже выполняется")
            return
        }

        isSyncing = true
        logger.info("Начинаем синхронизацию прогресса")

        // 0. Сначала очищаем дубликаты
        cleanupDuplicateProgress(context: context)

        // 1. Потом отправляем локальные изменения на сервер
        await syncUnsyncedProgress(context: context)

        // 2. Затем загружаем серверные изменения
        await downloadServerProgress(context: context)

        logger.info("Синхронизация прогресса завершена успешно")

        isSyncing = false
    }

    /// Синхронизирует все несинхронизированные записи прогресса с сервером
    private func syncUnsyncedProgress(context: ModelContext) async {
        do {
            // 1) Готовим снимки данных (без доступа к контексту в задачах)
            let snapshots = try makeProgressSnapshotsForSync(context: context)
            logger.info("Начинаем синхронизацию \(snapshots.count) записей прогресса")

            // 2) Параллельные сетевые операции (без ModelContext)
            let eventsById = await runSyncTasks(snapshots: snapshots, client: client)

            // 3) Применяем результаты к ModelContext единым этапом
            applySyncEvents(eventsById, context: context)

            logger.info("Синхронизация несинхронизированных записей прогресса завершена")
        } catch {
            logger.error("Ошибка получения несинхронизированного прогресса: \(error.localizedDescription)")
        }
    }

    /// Очищает дубликаты прогресса в базе данных
    private func cleanupDuplicateProgress(context: ModelContext) {
        do {
            guard let user = try context.fetch(FetchDescriptor<User>()).first else {
                logger.error("Не удалось получить текущего пользователя для очистки дубликатов")
                return
            }

            let allProgress = try context.fetch(FetchDescriptor<Progress>())
                .filter { $0.user?.id == user.id }

            // Группируем по id
            let groupedProgress = Dictionary(grouping: allProgress) { $0.id }

            var duplicatesRemoved = 0
            for (dayId, progressList) in groupedProgress {
                if progressList.count > 1 {
                    // Сортируем по lastModified (новые первыми)
                    let sortedProgress = progressList.sorted { $0.lastModified > $1.lastModified }

                    // Оставляем только первую (самую новую) запись
                    let toKeep = sortedProgress.first!
                    let toRemove = Array(sortedProgress.dropFirst())

                    // Удаляем дубликаты
                    for duplicate in toRemove {
                        context.delete(duplicate)
                        duplicatesRemoved += 1
                    }

                    logger.info("Удалено \(toRemove.count) дубликатов для дня \(dayId), оставлена запись с датой \(toKeep.lastModified)")
                }
            }

            if duplicatesRemoved > 0 {
                try context.save()
                logger.info("Очистка дубликатов завершена, удалено \(duplicatesRemoved) записей")
            }
        } catch {
            logger.error("Ошибка очистки дубликатов прогресса: \(error.localizedDescription)")
        }
    }

    /// Загружает обновленный прогресс с сервера и обрабатывает конфликты
    private func downloadServerProgress(context: ModelContext) async {
        do {
            guard let user = try context.fetch(FetchDescriptor<User>()).first else {
                logger.error("Не удалось получить текущего пользователя для синхронизации прогресса")
                return
            }

            let serverProgressList = try await client.getProgress()
            logger.info("Получен ответ сервера: \(serverProgressList.count) записей")

            await mergeServerProgress(serverProgressList, user: user, context: context)
            await handleDeletedProgress(serverProgressList, user: user, context: context)

            try context.save()
            logger.info("Серверный прогресс загружен и обработан")
        } catch {
            logger.error("Ошибка загрузки серверного прогресса: \(error.localizedDescription)")
        }
    }

    /// Объединяет серверные данные с локальными, разрешая конфликты
    private func mergeServerProgress(_ serverProgress: [ProgressResponse], user: User, context: ModelContext) async {
        do {
            let existingProgress = try context.fetch(FetchDescriptor<Progress>())
                .filter { $0.user?.id == user.id }

            let existingDict = createExistingProgressDict(existingProgress)

            for progressResponse in serverProgress {
                let internalDay = Progress.getInternalDayFromExternalDay(progressResponse.id)

                if let existingProgress = existingDict[internalDay] {
                    await resolveConflict(local: existingProgress, server: progressResponse, internalDay: internalDay)
                } else {
                    createNewProgress(from: progressResponse, user: user, context: context, internalDay: internalDay)
                }
            }
        } catch {
            logger.error("Ошибка при получении существующих записей прогресса: \(error.localizedDescription)")
        }
    }

    /// Создает словарь существующих записей прогресса с обработкой дубликатов
    private func createExistingProgressDict(_ progressList: [Progress]) -> [Int: Progress] {
        var dict: [Int: Progress] = [:]

        for progress in progressList {
            if let existing = dict[progress.id] {
                // LWW: берем запись с более новой датой модификации
                if progress.lastModified > existing.lastModified {
                    dict[progress.id] = progress
                    logger.info("Найден дубликат прогресса дня \(progress.id), используется более новая версия")
                }
            } else {
                dict[progress.id] = progress
            }
        }

        return dict
    }

    /// Обрабатывает удаленные на сервере элементы
    private func handleDeletedProgress(_ serverProgress: [ProgressResponse], user: User, context: ModelContext) async {
        do {
            let existingProgress = try context.fetch(FetchDescriptor<Progress>())
                .filter { $0.user?.id == user.id }

            let serverExternalIds = Set(serverProgress.map(\.id))
            let serverInternalIds = Set(serverExternalIds.map { Progress.getInternalDayFromExternalDay($0) })

            for progress in existingProgress where !serverInternalIds.contains(progress.id) && progress.isSynced {
                if progress.shouldDelete {
                    context.delete(progress)
                    logger.info("Удален прогресс дня \(progress.id) (отсутствует на сервере)")
                } else {
                    progress.shouldDelete = true
                    progress.isSynced = false
                    logger.info("Помечен для удаления прогресс дня \(progress.id) (отсутствует на сервере)")
                }
            }
        } catch {
            logger.error("Ошибка при обработке удаленных записей прогресса: \(error.localizedDescription)")
        }
    }

    /// Разрешает конфликт между локальной и серверной версией данных
    private func resolveConflict(local: Progress, server: ProgressResponse, internalDay: Int) async {
        // Обработка специального случая: элемент удален на сервере, но изменен локально
        if local.shouldDelete {
            // Локальный прогресс помечен для удаления - не восстанавливаем его
            logger.info("Локальный прогресс дня \(internalDay) помечен для удаления, пропускаем")
        } else {
            // Разрешение конфликтов по LWW
            applyLWWLogic(local: local, server: server, internalDay: internalDay)
        }
    }

    /// Создает новый прогресс из серверного ответа
    private func createNewProgress(from progressResponse: ProgressResponse, user: User, context: ModelContext, internalDay: Int) {
        let newProgress = Progress(from: progressResponse, user: user, internalDay: internalDay)
        context.insert(newProgress)
        logger.info("Создан новый прогресс дня \(newProgress.id) из ответа сервера (день \(progressResponse.id))")
        logger.info("Количество фотографий в новом прогрессе: \(newProgress.photos.count)")
        for photo in newProgress.photos {
            logger.info("Фотография типа \(photo.type.rawValue) с URL: \(photo.urlString ?? "nil")")
        }
    }
}

// MARK: - Snapshot & Sync Events (для конкурентной синхронизации без ModelContext)

private extension ProgressSyncService {
    /// Снимок локального прогресса для безопасной передачи в конкурентные задачи без доступа к ModelContext
    struct ProgressSnapshot: Sendable, Hashable {
        let id: Int
        let pullups: Int?
        let pushups: Int?
        let squats: Int?
        let weight: Float?
        let lastModified: Date
        let isSynced: Bool
        let shouldDelete: Bool
        let userId: Int?

        // Поля для фотографий
        let hasUnsyncedPhotos: Bool
        let hasPhotosToDelete: Bool
        let photosData: [String: Data] // Sendable данные фотографий

        /// Создает ProgressSnapshot из Progress модели
        init(from progress: Progress) {
            self.id = progress.id
            self.pullups = progress.pullUps
            self.pushups = progress.pushUps
            self.squats = progress.squats
            self.weight = progress.weight
            self.lastModified = progress.lastModified
            self.isSynced = progress.isSynced
            self.shouldDelete = progress.shouldDelete
            self.userId = progress.user?.id

            // Проверяем фотографии
            self.hasUnsyncedPhotos = progress.photos.contains { !$0.isSynced && !$0.isDeleted }
            self.hasPhotosToDelete = progress.photos.contains { $0.isDeleted }

            // Подготавливаем данные фотографий для отправки
            var photosData: [String: Data] = [:]
            if let frontPhoto = progress.getPhoto(.front), let frontData = frontPhoto.data {
                photosData["photo_front"] = frontData
            }
            if let backPhoto = progress.getPhoto(.back), let backData = backPhoto.data {
                photosData["photo_back"] = backData
            }
            if let sidePhoto = progress.getPhoto(.side), let sideData = sidePhoto.data {
                photosData["photo_side"] = sideData
            }
            self.photosData = photosData

            // Логирование для диагностики (только если есть фотографии)
            if !photosData.isEmpty {
                print(
                    "ProgressSnapshot для дня \(progress.id): hasUnsyncedPhotos=\(hasUnsyncedPhotos), hasPhotosToDelete=\(hasPhotosToDelete), photosData.count=\(photosData.count)"
                )
            }
        }
    }

    /// Результат конкурентной операции синхронизации одного прогресса
    enum SyncEvent: Sendable, Hashable {
        case createdOrUpdated(id: Int, server: ProgressResponse)
        case alreadyExists(id: Int) // Локальная запись уже существует на сервере
        case deleted(id: Int)
        case failed(id: Int, errorDescription: String)
    }

    /// Формирует список снимков локального прогресса, требующих синхронизации
    func makeProgressSnapshotsForSync(context: ModelContext) throws -> [ProgressSnapshot] {
        // Берем все несинхронизированные, а также те, что помечены на удаление
        let toSync = try context.fetch(
            FetchDescriptor<Progress>(
                predicate: #Predicate { !$0.isSynced || $0.shouldDelete }
            )
        )

        logger.info("Найдено \(toSync.count) записей прогресса для проверки синхронизации")

        // Логируем информацию о каждой записи для диагностики
        for progress in toSync {
            let photosCount = progress.photos.count
            let unsyncedPhotos = progress.photos.count(where: { !$0.isSynced && !$0.isDeleted })
            let deletedPhotos = progress.photos.count(where: { $0.isDeleted })
            logger
                .info(
                    "День \(progress.id): isSynced=\(progress.isSynced), shouldDelete=\(progress.shouldDelete), photos=\(photosCount), unsynced=\(unsyncedPhotos), deleted=\(deletedPhotos)"
                )

            // Дополнительная диагностика для записей, помеченных на удаление
            if progress.shouldDelete {
                logger
                    .info(
                        "Запись дня \(progress.id) помечена для удаления. Данные: pullUps=\(progress.pullUps ?? 0), pushUps=\(progress.pushUps ?? 0), squats=\(progress.squats ?? 0), weight=\(progress.weight ?? 0)"
                    )
            }
        }

        // Фильтруем только те записи, которые действительно требуют синхронизации
        // Исключаем записи, которые помечены как синхронизированные, но не имеют реальных изменений
        let filteredSnapshots: [ProgressSnapshot] = toSync.compactMap { progress in
            // Если запись помечена для удаления - всегда отправляем
            if progress.shouldDelete {
                return ProgressSnapshot(from: progress)
            }

            // Если запись синхронизирована - проверяем, есть ли реальные изменения
            if progress.isSynced {
                // Проверяем, есть ли несинхронизированные фотографии
                let hasUnsyncedPhotos = progress.photos.contains { !$0.isSynced && !$0.isDeleted }
                let hasPhotosToDelete = progress.photos.contains { $0.isDeleted }

                // Логирование для диагностики
                if hasUnsyncedPhotos || hasPhotosToDelete {
                    logger
                        .info(
                            "День \(progress.id): hasUnsyncedPhotos=\(hasUnsyncedPhotos), hasPhotosToDelete=\(hasPhotosToDelete), photos.count=\(progress.photos.count)"
                        )
                }

                // Если нет изменений в основных данных и нет изменений в фотографиях - не отправляем
                if !hasUnsyncedPhotos, !hasPhotosToDelete {
                    return nil
                }
            }

            // Для несинхронизированных записей или записей с изменениями в фотографиях всегда отправляем
            return ProgressSnapshot(from: progress)
        }

        logger.info("Найдено \(filteredSnapshots.count) записей прогресса для синхронизации")
        return filteredSnapshots
    }

    /// Выполняет конкурентные сетевые операции синхронизации и собирает результаты без доступа к `ModelContext`
    func runSyncTasks(
        snapshots: [ProgressSnapshot],
        client: ProgressClient
    ) async -> [Int: SyncEvent] {
        await withTaskGroup(of: (Int, SyncEvent).self) { group in
            for snapshot in snapshots {
                logger.info("Отправляем прогресс на сервер: день \(snapshot.id)")

                group.addTask { [snapshot] in
                    let event = await self.performNetworkSync(for: snapshot, client: client)
                    return (snapshot.id, event)
                }
            }

            var eventsById: [Int: SyncEvent] = [:]
            for await (id, event) in group {
                eventsById[id] = event
            }
            return eventsById
        }
    }

    /// Выполняет сетевую синхронизацию одного снимка без доступа к `ModelContext`
    func performNetworkSync(
        for snapshot: ProgressSnapshot,
        client: ProgressClient
    ) async -> SyncEvent {
        do {
            // Используем правильный день для запроса
            let externalDay = Progress.getExternalDayFromProgressId(snapshot.id)

            if snapshot.shouldDelete {
                // Используем правильный день для удаления
                do {
                    try await client.deleteProgress(day: externalDay)
                    return .deleted(id: snapshot.id)
                } catch {
                    // Если не удалось удалить на сервере, помечаем как уже существующую
                    // Это может произойти, если запись не существует на сервере
                    logger
                        .warning(
                            "Не удалось удалить прогресс дня \(externalDay) на сервере: \(error.localizedDescription). Помечаем как уже существующий."
                        )
                    return .alreadyExists(id: snapshot.id)
                }
            } else {
                // Создаем запрос с фотографиями, если они есть
                let request = ProgressRequest(
                    id: externalDay,
                    pullups: snapshot.pullups,
                    pushups: snapshot.pushups,
                    squats: snapshot.squats,
                    weight: snapshot.weight,
                    modifyDate: DateFormatterService.stringFromFullDate(snapshot.lastModified, format: .isoDateTimeSec),
                    photos: snapshot.photosData.isEmpty ? nil : snapshot.photosData
                )

                // Логирование для диагностики
                if !snapshot.photosData.isEmpty {
                    logger.info("Отправляем прогресс дня \(externalDay) с \(snapshot.photosData.count) фотографиями")
                    for (key, data) in snapshot.photosData {
                        logger.info("Фотография \(key): размер \(data.count) байт")
                    }
                } else {
                    logger.info("Отправляем прогресс дня \(externalDay) без фотографий")
                }

                // Используем единый подход: всегда пытаемся обновить/создать через updateProgress
                // Сервер сам разберется и применит LWW логику
                let response = try await client.updateProgress(day: externalDay, progress: request)
                return .createdOrUpdated(id: snapshot.id, server: response)
            }
        } catch {
            return .failed(id: snapshot.id, errorDescription: error.localizedDescription)
        }
    }

    /// Применяет результаты синхронизации к локальному хранилищу в одном месте
    func applySyncEvents(_ events: [Int: SyncEvent], context: ModelContext) {
        do {
            // Загружаем текущего пользователя и все записи прогресса заранее
            guard let user = try context.fetch(FetchDescriptor<User>()).first else {
                logger.error("Пользователь не найден при применении результатов синхронизации")
                return
            }
            let existing = try context.fetch(FetchDescriptor<Progress>()).filter { $0.user?.id == user.id }
            let dict = Dictionary(uniqueKeysWithValues: existing.map { ($0.id, $0) })

            for (id, event) in events {
                switch event {
                case let .createdOrUpdated(_, server):
                    if let local = dict[id] {
                        // Реальный ответ сервера - применяем LWW логику
                        applyLWWLogic(local: local, server: server, internalDay: id)
                        // Обновляем фотографии из ответа сервера
                        updateProgressFromServerResponse(local, server)
                    } else {
                        // Создаем новую запись локально по ответу сервера
                        let newProgress = Progress(from: server, user: user)
                        context.insert(newProgress)
                        // Обновляем фотографии из ответа сервера
                        updateProgressFromServerResponse(newProgress, server)
                    }
                case let .alreadyExists(localId):
                    if let local = dict[localId] {
                        // Локальная запись уже существует на сервере - помечаем как синхронизированную
                        local.isSynced = true
                        local.shouldDelete = false
                        logger.info("Помечаем прогресс дня \(localId) как синхронизированный (уже существует на сервере)")
                    }
                case .deleted:
                    if let local = dict[id] {
                        context.delete(local)
                    } else {
                        logger.debug("Удаление: локальный прогресс дня \(id) не найден")
                    }
                case let .failed(id, errorDescription):
                    logger.error("Ошибка синхронизации прогресса дня \(id): \(errorDescription)")
                }
            }

            try context.save()
        } catch {
            logger.error("Ошибка применения результатов синхронизации: \(error.localizedDescription)")
        }
    }

    /// Обновляет локальный прогресс данными с сервера
    func updateLocalFromServer(_ local: Progress, _ server: ProgressResponse, internalDay _: Int) {
        local.pullUps = server.pullups
        local.pushUps = server.pushups
        local.squats = server.squats
        local.weight = server.weight
        // Если modify_date равен null, используем create_date
        local.lastModified = server.modifyDate.flatMap {
            DateFormatterService.dateFromString($0, format: .serverDateTimeSec)
        } ?? DateFormatterService.dateFromString(server.createDate, format: .serverDateTimeSec)
        local.isSynced = true
        local.shouldDelete = false
    }

    /// Применяет логику Last Write Wins для разрешения конфликтов между локальными и серверными данными
    private func applyLWWLogic(local: Progress, server: ProgressResponse, internalDay: Int) {
        // Если modify_date равен null, используем create_date
        let serverModifyDate = server.modifyDate.flatMap {
            DateFormatterService.dateFromString($0, format: .serverDateTimeSec)
        } ?? DateFormatterService.dateFromString(server.createDate, format: .serverDateTimeSec)

        // Сравниваем даты модификации
        let localDate = local.lastModified
        let serverDate = serverModifyDate

        logger.info("Разрешение конфликта LWW для дня \(internalDay): локальная дата=\(localDate), серверная дата=\(serverDate)")

        // Проверяем разницу данных для принятия более обоснованного решения
        let hasDataDifference = local.pullUps != server.pullups ||
            local.pushUps != server.pushups ||
            local.squats != server.squats ||
            abs((local.weight ?? 0) - (server.weight ?? 0)) > 0.01

        if hasDataDifference {
            logger.info("Обнаружены различия в данных для дня \(internalDay)")
        }

        if localDate > serverDate {
            // Локальная версия новее серверной - сохраняем локальные изменения
            logger.info("Локальная версия новее серверной для дня \(internalDay) - сохраняем локальные изменения")
            // Убеждаемся, что прогресс остается синхронизированным
            local.isSynced = true
            local.shouldDelete = false
        } else if serverDate > localDate {
            // Серверная версия новее - обновляем локальную
            logger.info("Серверная версия новее локальной для дня \(internalDay) - обновляем локальные данные")
            logger
                .info(
                    "Локальные данные: pullUps=\(local.pullUps ?? 0), pushUps=\(local.pushUps ?? 0), squats=\(local.squats ?? 0), weight=\(local.weight ?? 0)"
                )
            logger
                .info(
                    "Серверные данные: pullups=\(server.pullups ?? 0), pushups=\(server.pushups ?? 0), squats=\(server.squats ?? 0), weight=\(server.weight ?? 0)"
                )

            updateLocalFromServer(local, server, internalDay: internalDay)
            // Обновляем фотографии из ответа сервера
            updateProgressFromServerResponse(local, server)
        } else {
            // Даты одинаковые или очень близкие - сравниваем данные
            if hasDataDifference {
                logger.warning("Одинаковые даты модификации, но разные данные для дня \(internalDay). Серверная версия имеет приоритет.")
                updateLocalFromServer(local, server, internalDay: internalDay)
                // Обновляем фотографии из ответа сервера
                updateProgressFromServerResponse(local, server)
            } else {
                logger.info("Данные идентичны для дня \(internalDay) - помечаем как синхронизированные")
                local.isSynced = true
                local.shouldDelete = false
            }
        }
    }
}

// MARK: - Photo Synchronization

extension ProgressSyncService {
    func syncPhotos(for progress: Progress, client: ProgressClient) async {
        // Проверяем, есть ли несинхронизированные фотографии
        let hasUnsyncedPhotos = progress.photos.contains { !$0.isSynced && !$0.isDeleted }
        let hasPhotosToDelete = progress.photos.contains { $0.isDeleted }

        if !hasUnsyncedPhotos, !hasPhotosToDelete {
            logger.info("Нет фотографий для синхронизации для прогресса дня \(progress.id)")
            return
        }

        logger.info("Начинаем синхронизацию фотографий для прогресса дня \(progress.id)")

        do {
            // Подготавливаем данные для отправки
            let request = prepareProgressDataWithPhotos(progress)

            // Отправляем данные прогресса вместе с фотографиями
            let response: ProgressResponse = if progress.isSynced {
                try await client.updateProgress(day: progress.id, progress: request)
            } else {
                try await client.createProgress(progress: request)
            }

            // Обновляем локальные данные из ответа сервера
            updateProgressFromServerResponse(progress, response)

            logger.info("Синхронизация фотографий завершена для прогресса дня \(progress.id)")
        } catch {
            logger.error("Ошибка синхронизации фотографий для прогресса дня \(progress.id): \(error.localizedDescription)")
        }
    }

    /// Подготавливает данные для отправки прогресса с фотографиями
    private func prepareProgressDataWithPhotos(_ progress: Progress) -> ProgressRequest {
        var photosData: [String: Data] = [:]

        // Подготавливаем данные фотографий для отправки
        if let frontPhoto = progress.getPhoto(.front), let frontData = frontPhoto.data {
            photosData["photo_front"] = frontData
        }
        if let backPhoto = progress.getPhoto(.back), let backData = backPhoto.data {
            photosData["photo_back"] = backData
        }
        if let sidePhoto = progress.getPhoto(.side), let sideData = sidePhoto.data {
            photosData["photo_side"] = sideData
        }

        return ProgressRequest(
            id: progress.id,
            pullups: progress.pullUps,
            pushups: progress.pushUps,
            squats: progress.squats,
            weight: progress.weight,
            modifyDate: progress.lastModified.ISO8601Format(),
            photos: photosData.isEmpty ? nil : photosData
        )
    }

    /// Обновляет локальный прогресс данными из ответа сервера
    func updateProgressFromServerResponse(_ progress: Progress, _ response: ProgressResponse) {
        logger.info("Обновляем фотографии для прогресса дня \(progress.id) из ответа сервера")

        if let photoFrontUrl = response.photoFront {
            if let frontPhoto = progress.getPhoto(.front) {
                // Обновляем существующую фотографию
                frontPhoto.urlString = photoFrontUrl
                frontPhoto.isSynced = true
                frontPhoto.progress = progress // Убеждаемся, что связь установлена
                logger.info("Обновлена существующая фотография front с URL: \(photoFrontUrl)")
            } else {
                // Создаем новую фотографию с URL с сервера
                let newPhoto = ProgressPhoto(type: .front, urlString: photoFrontUrl)
                newPhoto.isSynced = true
                newPhoto.progress = progress
                progress.photos.append(newPhoto)
                logger.info("Создана новая фотография front с URL: \(photoFrontUrl)")
            }
        }
        if let photoBackUrl = response.photoBack {
            if let backPhoto = progress.getPhoto(.back) {
                // Обновляем существующую фотографию
                backPhoto.urlString = photoBackUrl
                backPhoto.isSynced = true
                backPhoto.progress = progress // Убеждаемся, что связь установлена
                logger.info("Обновлена существующая фотография back с URL: \(photoBackUrl)")
            } else {
                // Создаем новую фотографию с URL с сервера
                let newPhoto = ProgressPhoto(type: .back, urlString: photoBackUrl)
                newPhoto.isSynced = true
                newPhoto.progress = progress
                progress.photos.append(newPhoto)
                logger.info("Создана новая фотография back с URL: \(photoBackUrl)")
            }
        }
        if let photoSideUrl = response.photoSide {
            if let sidePhoto = progress.getPhoto(.side) {
                // Обновляем существующую фотографию
                sidePhoto.urlString = photoSideUrl
                sidePhoto.isSynced = true
                sidePhoto.progress = progress // Убеждаемся, что связь установлена
                logger.info("Обновлена существующая фотография side с URL: \(photoSideUrl)")
            } else {
                // Создаем новую фотографию с URL с сервера
                let newPhoto = ProgressPhoto(type: .side, urlString: photoSideUrl)
                newPhoto.isSynced = true
                newPhoto.progress = progress
                progress.photos.append(newPhoto)
                logger.info("Создана новая фотография side с URL: \(photoSideUrl)")
            }
        }

        // Помечаем прогресс как синхронизированный
        progress.isSynced = true
        logger.info("Количество фотографий в прогрессе после обновления: \(progress.photos.count)")
        progress.lastModified = Date()
    }
}
