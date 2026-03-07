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
    private let photoDownloadService: PhotoDownloadServiceProtocol
    @ObservationIgnored private let logger = Logger(subsystem: "SotkaApp", category: "ProgressSync")

    /// Флаг загрузки синхронизации
    private(set) var isSyncing = false

    init(
        client: ProgressClient,
        photoDownloadService: PhotoDownloadServiceProtocol = PhotoDownloadService()
    ) {
        self.client = client
        self.photoDownloadService = photoDownloadService
    }

    /// Основной метод синхронизации
    func syncProgress(context: ModelContext) async throws -> SyncResult {
        logger.info("🔄 [TRACE] syncProgress() - начало синхронизации")
        guard !isSyncing else {
            logger.info("⏭️ [TRACE] syncProgress() - синхронизация уже выполняется, выход")
            throw AlreadySyncingError()
        }
        isSyncing = true
        logger.info("🚀 [TRACE] syncProgress() - устанавливаем isSyncing=true, начинаем синхронизацию")
        defer {
            logger.info("🏁 [TRACE] syncProgress() - устанавливаем isSyncing=false, завершение")
            isSyncing = false
        }

        var errors: [SyncError] = []
        var stats: SyncStats?

        do {
            logger.info("🧹 [TRACE] syncProgress() - этап 1: очистка дубликатов")
            // Очищаем дубликаты
            try cleanupDuplicateProgress(context: context)

            logger.info("📸 [TRACE] syncProgress() - этап 2: подготовка снимков данных")
            // Готовим снимки данных (без доступа к контексту в задачах)
            let snapshots = try makeProgressSnapshotsForSync(context: context)
            logger.info("📊 [TRACE] syncProgress() - найдено \(snapshots.count) записей прогресса для синхронизации")

            logger.info("🌐 [TRACE] syncProgress() - этап 3: параллельные сетевые операции")
            // Параллельные сетевые операции (без ModelContext)
            let eventsById = await runSyncTasks(snapshots: snapshots, client: client)

            logger.info("💾 [TRACE] syncProgress() - этап 4: применение результатов к ModelContext")
            // Отправляем локальные изменения на сервер и применяем результаты к ModelContext единым этапом
            stats = await applySyncEvents(eventsById, context: context)
            logger.info("✅ [TRACE] syncProgress() - синхронизация локальных изменений завершена")

            // Собираем ошибки из событий
            for (id, event) in eventsById {
                if case let .failed(_, errorDescription) = event {
                    errors.append(SyncError(
                        type: "sync_failed",
                        message: errorDescription,
                        entityType: "progress",
                        entityId: String(id)
                    ))
                }
            }

            logger.info("📥 [TRACE] syncProgress() - этап 5: загрузка серверных изменений")
            // Затем загружаем серверные изменения
            do {
                try await downloadServerProgress(context: context)
            } catch {
                logger.error("❌ [TRACE] syncProgress() - ошибка загрузки серверных изменений: \(error.localizedDescription)")
                errors.append(SyncError(
                    type: "download_failed",
                    message: error.localizedDescription,
                    entityType: "progress",
                    entityId: nil
                ))
            }

            logger.info("🧹 [TRACE] syncProgress() - этап 6: финальная очистка дубликатов")
            // Финальная очистка дубликатов после всех операций
            try cleanupDuplicateProgress(context: context)

            logger.info("🎉 [TRACE] syncProgress() - синхронизация прогресса завершена успешно")
        } catch {
            logger.error("❌ [TRACE] syncProgress() - ошибка синхронизации: \(error.localizedDescription)")
            logger.error("❌ [TRACE] syncProgress() - тип ошибки: \(String(describing: type(of: error)))")
            errors.append(SyncError(
                type: "sync_error",
                message: error.localizedDescription,
                entityType: "progress",
                entityId: nil
            ))
            throw error
        }

        let resultType = SyncResultType(
            errors: errors.isEmpty ? nil : errors,
            stats: stats ?? SyncStats(created: 0, updated: 0, deleted: 0)
        )
        let details = SyncResultDetails(
            progress: stats ?? SyncStats(created: 0, updated: 0, deleted: 0),
            exercises: nil,
            activities: nil,
            errors: errors.isEmpty ? nil : errors
        )
        return SyncResult(type: resultType, details: details)
    }

    /// Очищает дубликаты прогресса в базе данных
    private func cleanupDuplicateProgress(context: ModelContext) throws {
        logger.info("🧹 [TRACE] cleanupDuplicateProgress() - начало очистки дубликатов")
        do {
            guard let user = try context.fetch(FetchDescriptor<User>()).first else {
                logger.error("❌ [TRACE] cleanupDuplicateProgress() - не удалось получить текущего пользователя")
                return
            }
            logger.info("👤 [TRACE] cleanupDuplicateProgress() - найден пользователь ID: \(user.id)")

            let allProgress = try context.fetch(FetchDescriptor<UserProgress>())
                .filter { $0.user?.id == user.id }
            logger.info("📊 [TRACE] cleanupDuplicateProgress() - найдено \(allProgress.count) записей прогресса пользователя")

            let groupedProgress = Dictionary(grouping: allProgress, by: \.id)
            logger.info("🔍 [TRACE] cleanupDuplicateProgress() - сгруппировано по \(groupedProgress.count) уникальным дням")

            var duplicatesRemoved = 0
            for (dayId, progressList) in groupedProgress {
                logger.info("📅 [TRACE] cleanupDuplicateProgress() - день \(dayId): \(progressList.count) записей")

                // Логируем состояние флагов для каждой записи
                for (index, progress) in progressList.enumerated() {
                    logger
                        .info(
                            "📋 [TRACE] cleanupDuplicateProgress() - запись \(index + 1): isSynced=\(progress.isSynced), shouldDelete=\(progress.shouldDelete), lastModified=\(progress.lastModified)"
                        )
                }

                if progressList.count > 1 {
                    // Сортируем по приоритету: сначала синхронизированные, потом по дате
                    var sortedProgress = progressList.sorted { first, second in
                        if first.isSynced != second.isSynced {
                            return first.isSynced // Синхронизированные записи имеют приоритет
                        }
                        return first.lastModified > second.lastModified
                    }
                    // Оставляем только самую приоритетную запись
                    let toKeep = sortedProgress.removeFirst()
                    for duplicate in sortedProgress {
                        logger
                            .info(
                                "🗑️ [TRACE] cleanupDuplicateProgress() - удаляем дубликат дня \(dayId): isSynced=\(duplicate.isSynced), shouldDelete=\(duplicate.shouldDelete), lastModified=\(duplicate.lastModified)"
                            )
                        context.delete(duplicate)
                        duplicatesRemoved += 1
                    }
                    logger
                        .info(
                            "✅ [TRACE] cleanupDuplicateProgress() - удалено \(sortedProgress.count) дубликатов для дня \(dayId), оставлена запись с датой \(toKeep.lastModified) (isSynced=\(toKeep.isSynced), shouldDelete=\(toKeep.shouldDelete))"
                        )
                } else {
                    logger.info("✅ [TRACE] cleanupDuplicateProgress() - день \(dayId): нет дубликатов")
                }
            }
            if duplicatesRemoved > 0 {
                logger.info("💾 [TRACE] cleanupDuplicateProgress() - сохраняем изменения в контексте")
                try context.save()
                logger.info("✅ [TRACE] cleanupDuplicateProgress() - очистка дубликатов завершена, удалено \(duplicatesRemoved) записей")
            } else {
                logger.info("✅ [TRACE] cleanupDuplicateProgress() - дубликаты не найдены")
            }
        } catch {
            logger.error("❌ [TRACE] cleanupDuplicateProgress() - ошибка очистки дубликатов: \(error.localizedDescription)")
            logger.error("❌ [TRACE] cleanupDuplicateProgress() - тип ошибки: \(String(describing: type(of: error)))")
            throw error
        }
        logger.info("🏁 [TRACE] cleanupDuplicateProgress() - завершение")
    }

    /// Загружает обновленный прогресс с сервера и обрабатывает конфликты
    private func downloadServerProgress(context: ModelContext) async throws {
        do {
            guard let user = try context.fetch(FetchDescriptor<User>()).first else {
                logger.error("Не удалось получить текущего пользователя для синхронизации прогресса")
                struct UserNotFoundError: Error {}
                throw UserNotFoundError()
            }

            let serverProgress = try await client.getProgress()
            logger.info("Получен ответ сервера: \(serverProgress.count) записей")

            await mergeServerProgress(serverProgress, user: user, context: context)
            await handleDeletedProgress(serverProgress, user: user, context: context)

            try context.save()
            logger.info("Серверный прогресс загружен и обработан")
        } catch {
            logger.error("Ошибка загрузки серверного прогресса: \(error.localizedDescription)")

            // Если это CancellationError, пытаемся повторить запрос через некоторое время
            if error is CancellationError {
                logger.info("Обнаружен CancellationError, повторяем попытку загрузки через 1 секунду")
                try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 секунда

                do {
                    let serverProgress = try await client.getProgress()
                    logger.info("Повторная попытка успешна: получен ответ сервера: \(serverProgress.count) записей")

                    guard let user = try context.fetch(FetchDescriptor<User>()).first else {
                        logger.error("Не удалось получить текущего пользователя для повторной попытки")
                        struct UserNotFoundError: Error {}
                        throw UserNotFoundError()
                    }

                    await mergeServerProgress(serverProgress, user: user, context: context)
                    await handleDeletedProgress(serverProgress, user: user, context: context)

                    try context.save()
                    logger.info("Серверный прогресс загружен и обработан после повторной попытки")
                } catch {
                    logger.error("Повторная попытка загрузки серверного прогресса также не удалась: \(error.localizedDescription)")
                    throw error
                }
            } else {
                throw error
            }
        }
    }

    /// Объединяет серверные данные с локальными, разрешая конфликты
    private func mergeServerProgress(_ serverProgress: [ProgressResponse], user: User, context: ModelContext) async {
        do {
            let existingProgress = try context.fetch(FetchDescriptor<UserProgress>())
                .filter { $0.user?.id == user.id }

            logger
                .info(
                    "🔍 [TRACE] mergeServerProgress() - существующие записи: \(existingProgress.map { "день \($0.id): isSynced=\($0.isSynced), shouldDelete=\($0.shouldDelete)" })"
                )
            logger.info("🔍 [TRACE] mergeServerProgress() - серверные записи: \(serverProgress.map { "день \($0.id)" })")

            let existingDict = createExistingProgressDict(existingProgress)

            for progressResponse in serverProgress {
                let internalDay = UserProgress.getInternalDayFromExternalDay(progressResponse.id)

                if let existingProgress = existingDict[internalDay] {
                    await resolveConflict(local: existingProgress, server: progressResponse, internalDay: internalDay)
                } else {
                    // Проверяем, есть ли уже запись в контексте (возможно, она не попала в словарь из-за дубликатов)
                    let allProgressForDay = existingProgress.filter { $0.id == internalDay && $0.user?.id == user.id }
                    if allProgressForDay.isEmpty {
                        // Создаем новую запись только если её действительно нет
                        logger.info("📥 [TRACE] mergeServerProgress() - создаем новую запись дня \(internalDay) из серверного ответа")
                        createNewProgress(from: progressResponse, user: user, context: context, internalDay: internalDay)
                    } else {
                        // Запись существует, но не попала в словарь - используем самую приоритетную
                        let sortedProgress = allProgressForDay.sorted { first, second in
                            if first.isSynced != second.isSynced {
                                return first.isSynced
                            }
                            return first.lastModified > second.lastModified
                        }

                        guard let priorityProgress = sortedProgress.first else {
                            logger.error("📥 [ERROR] mergeServerProgress() - не удалось найти приоритетную запись для дня \(internalDay)")
                            continue
                        }

                        logger
                            .info(
                                "📥 [TRACE] mergeServerProgress() - найдена существующая запись дня \(internalDay), используем для конфликта"
                            )
                        await resolveConflict(local: priorityProgress, server: progressResponse, internalDay: internalDay)
                    }
                }
            }
        } catch {
            logger.error("Ошибка при получении существующих записей прогресса: \(error.localizedDescription)")
        }
    }

    /// Создает словарь существующих записей прогресса с обработкой дубликатов
    private func createExistingProgressDict(_ progressList: [UserProgress]) -> [Int: UserProgress] {
        var dict: [Int: UserProgress] = [:]

        for progress in progressList {
            if let existing = dict[progress.id] {
                // Приоритет: синхронизированные записи > несинхронизированные
                // Внутри каждой группы - по дате модификации
                let shouldReplace: Bool = if existing.isSynced != progress.isSynced {
                    progress.isSynced // Синхронизированные имеют приоритет
                } else {
                    progress.lastModified > existing.lastModified
                }

                if shouldReplace {
                    dict[progress.id] = progress
                    logger
                        .info(
                            "Найден дубликат прогресса дня \(progress.id), используется более приоритетная версия (isSynced=\(progress.isSynced), lastModified=\(progress.lastModified))"
                        )
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
            let existingProgress = try context.fetch(FetchDescriptor<UserProgress>())
                .filter { $0.user?.id == user.id }

            let serverExternalIds = Set(serverProgress.map(\.id))
            let serverInternalIds = Set(serverExternalIds.map { UserProgress.getInternalDayFromExternalDay($0) })

            logger.info("🔍 [TRACE] handleDeletedProgress() - серверные внешние ID: \(serverExternalIds)")
            logger.info("🔍 [TRACE] handleDeletedProgress() - серверные внутренние ID: \(serverInternalIds)")
            logger
                .info(
                    "🔍 [TRACE] handleDeletedProgress() - локальные записи: \(existingProgress.map { "день \($0.id): isSynced=\($0.isSynced), shouldDelete=\($0.shouldDelete)" })"
                )

            for progress in existingProgress where !serverInternalIds.contains(progress.id) && progress.isSynced {
                // Не помечаем для удаления записи, которые только что были синхронизированы
                // и отсутствуют на сервере (это нормально для новых записей)
                // Проверяем, была ли запись синхронизирована недавно (в течение последних 5 секунд)
                let timeSinceSync = Date().timeIntervalSince(progress.lastModified)
                if timeSinceSync < 5.0 {
                    logger.info("Пропускаем прогресс дня \(progress.id) - недавно синхронизирован (\(timeSinceSync)s назад)")
                    continue
                }

                if progress.shouldDelete {
                    context.delete(progress)
                    logger.info("Удален прогресс дня \(progress.id) (отсутствует на сервере)")
                } else {
                    // Помечаем для удаления только если запись была синхронизирована ранее
                    // и не является результатом только что выполненной синхронизации.
                    // Если запись была синхронизирована давно (больше 5 секунд) и отсутствует на сервере,
                    // значит она была удалена на сервере - помечаем как несинхронизированную и для удаления
                    progress.shouldDelete = true
                    progress.isSynced = false
                    logger.info("Помечен для удаления прогресс дня \(progress.id) (отсутствует на сервере), isSynced=false")
                }
            }
        } catch {
            logger.error("Ошибка при обработке удаленных записей прогресса: \(error.localizedDescription)")
        }
    }

    /// Разрешает конфликт между локальной и серверной версией данных
    private func resolveConflict(local: UserProgress, server: ProgressResponse, internalDay: Int) async {
        // Обработка специального случая: элемент удален на сервере, но изменен локально
        if local.shouldDelete {
            // Локальный прогресс помечен для удаления - не восстанавливаем его
            logger.info("Локальный прогресс дня \(internalDay) помечен для удаления, пропускаем")
        } else {
            // Разрешение конфликтов по LWW
            _ = await applyLWWLogic(local: local, server: server, internalDay: internalDay)
        }
    }

    /// Создает новый прогресс из серверного ответа
    private func createNewProgress(from progressResponse: ProgressResponse, user: User, context: ModelContext, internalDay: Int) {
        let newProgress = UserProgress(from: progressResponse, user: user, internalDay: internalDay)
        context.insert(newProgress)
        logger.info("Создан новый прогресс дня \(newProgress.id) из ответа сервера (день \(progressResponse.id))")
        logger
            .info(
                "📋 [TRACE] createNewProgress() - состояние новой записи: isSynced=\(newProgress.isSynced), shouldDelete=\(newProgress.shouldDelete), lastModified=\(newProgress.lastModified)"
            )
    }
}

extension ProgressSyncService {
    /// Ошибка, возникающая при попытке запустить синхронизацию, когда она уже выполняется
    struct AlreadySyncingError: Error {}
}

private extension ProgressSyncService {
    /// Результат конкурентной операции синхронизации одного прогресса
    enum SyncEvent: Hashable {
        case createdOrUpdated(id: Int, server: ProgressResponse)
        /// Локальная запись уже существует на сервере
        case alreadyExists(id: Int)
        case deleted(id: Int)
        /// Требуется удаление фотографий
        case needsPhotoDeletion(id: Int)
        case failed(id: Int, errorDescription: String)
    }

    /// Формирует список снимков локального прогресса, требующих синхронизации
    func makeProgressSnapshotsForSync(context: ModelContext) throws -> [ProgressSnapshot] {
        logger.info("📸 [TRACE] makeProgressSnapshotsForSync() - начало подготовки снимков")

        // Берем все несинхронизированные, а также те, что помечены на удаление
        let toSync = try context.fetch(
            FetchDescriptor<UserProgress>(
                predicate: #Predicate { !$0.isSynced || $0.shouldDelete }
            )
        )

        logger.info("🔍 [TRACE] makeProgressSnapshotsForSync() - найдено \(toSync.count) записей прогресса для проверки синхронизации")

        // Логируем состояние флагов для каждой записи до обработки
        for progress in toSync {
            logger
                .info(
                    "📋 [TRACE] makeProgressSnapshotsForSync() - день \(progress.id): isSynced=\(progress.isSynced), shouldDelete=\(progress.shouldDelete), isEmpty=\(progress.isEmpty)"
                )
        }

        logger.info("🔍 [TRACE] makeProgressSnapshotsForSync() - проверка записей на пустоту")
        // Проверяем каждую запись на "пустоту" и помечаем для удаления при необходимости
        // ВАЖНО: проверяем только несинхронизированные записи, чтобы избежать изменения уже синхронизированных
        for progress in toSync {
            logger.info("🔍 [TRACE] makeProgressSnapshotsForSync() - проверка дня \(progress.id) на пустоту: isEmpty=\(progress.isEmpty)")

            // Дополнительная защита от race condition: не изменяем уже синхронизированные записи
            if progress.isSynced, !progress.shouldDelete {
                logger.info("⏭️ [TRACE] makeProgressSnapshotsForSync() - пропускаем уже синхронизированную запись дня \(progress.id)")
                continue
            }

            checkAndMarkForDeletionIfEmpty(progress)

            // Логируем изменения после проверки
            if progress.shouldDelete {
                logger.info("🚨 [TRACE] makeProgressSnapshotsForSync() - день \(progress.id) помечен для удаления после проверки на пустоту")
            }
        }

        // Логируем информацию о каждой записи для диагностики
        logger.info("📋 [TRACE] makeProgressSnapshotsForSync() - детальная диагностика всех записей:")
        for progress in toSync {
            logger
                .info(
                    "📋 [TRACE] makeProgressSnapshotsForSync() - день \(progress.id): isSynced=\(progress.isSynced), shouldDelete=\(progress.shouldDelete), isEmpty=\(progress.isEmpty)"
                )

            // Дополнительная диагностика для записей, помеченных на удаление
            if progress.shouldDelete {
                logger
                    .info(
                        "🚨 [TRACE] makeProgressSnapshotsForSync() - запись дня \(progress.id) помечена для удаления. Данные: pullUps=\(progress.pullUps ?? 0), pushUps=\(progress.pushUps ?? 0), squats=\(progress.squats ?? 0), weight=\(progress.weight ?? 0), hasPhotos=\(progress.hasAnyPhotoData)"
                    )
            }
        }

        logger.info("🔄 [TRACE] makeProgressSnapshotsForSync() - фильтрация записей для синхронизации")
        // Фильтруем только те записи, которые действительно требуют синхронизации
        let filteredSnapshots: [ProgressSnapshot] = toSync.compactMap { progress in
            // Если запись помечена для удаления
            if progress.shouldDelete {
                // Если запись никогда не была синхронизирована, не отправляем её на сервер
                if !progress.isSynced {
                    logger
                        .info(
                            "⏭️ [TRACE] makeProgressSnapshotsForSync() - пропускаем день \(progress.id) (shouldDelete=true, но isSynced=false)"
                        )
                    return nil
                }
                logger
                    .info(
                        "📤 [TRACE] makeProgressSnapshotsForSync() - добавляем в синхронизацию день \(progress.id) (shouldDelete=true, isSynced=true)"
                    )
                return ProgressSnapshot(from: progress)
            }

            // Если запись синхронизирована - не отправляем (нет изменений)
            if progress.isSynced {
                logger.info("⏭️ [TRACE] makeProgressSnapshotsForSync() - пропускаем день \(progress.id) (isSynced=true)")
                return nil
            }

            // Для несинхронизированных записей всегда отправляем
            logger.info("📤 [TRACE] makeProgressSnapshotsForSync() - добавляем в синхронизацию день \(progress.id) (isSynced=false)")
            return ProgressSnapshot(from: progress)
        }

        logger.info("✅ [TRACE] makeProgressSnapshotsForSync() - подготовлено \(filteredSnapshots.count) снимков для синхронизации")
        return filteredSnapshots
    }

    /// Выполняет конкурентные сетевые операции синхронизации и собирает результаты без доступа к `ModelContext`
    func runSyncTasks(
        snapshots: [ProgressSnapshot],
        client: ProgressClient
    ) async -> [Int: SyncEvent] {
        logger.info("🌐 [TRACE] runSyncTasks() - начало параллельной обработки \(snapshots.count) записей")

        // Логируем состояние каждого snapshot перед обработкой
        for snapshot in snapshots {
            logger
                .info(
                    "📋 [TRACE] runSyncTasks() - snapshot день \(snapshot.id): isSynced=\(snapshot.isSynced), shouldDelete=\(snapshot.shouldDelete), shouldDeletePhoto=\(snapshot.shouldDeletePhoto)"
                )
        }

        return await withTaskGroup(of: (Int, SyncEvent).self) { group in
            for snapshot in snapshots {
                logger.info("🚀 [TRACE] runSyncTasks() - добавляем задачу для дня \(snapshot.id)")

                group.addTask { [snapshot] in
                    self.logger.info("⚡ [TRACE] runSyncTasks() - начинаем обработку дня \(snapshot.id)")
                    let event = await self.performNetworkSync(for: snapshot, client: client)
                    self.logger
                        .info("✅ [TRACE] runSyncTasks() - завершена обработка дня \(snapshot.id), результат: \(String(describing: event))")
                    return (snapshot.id, event)
                }
            }

            logger.info("📥 [TRACE] runSyncTasks() - ожидаем завершения всех задач")
            var eventsById: [Int: SyncEvent] = [:]
            var completedCount = 0
            for await (id, event) in group {
                eventsById[id] = event
                completedCount += 1
                logger.info("📊 [TRACE] runSyncTasks() - получен результат \(completedCount)/\(snapshots.count) для дня \(id)")
            }

            logger.info("✅ [TRACE] runSyncTasks() - все задачи завершены, собрано \(eventsById.count) результатов")
            return eventsById
        }
    }

    /// Выполняет сетевую синхронизацию одного снимка без доступа к `ModelContext`
    func performNetworkSync(
        for snapshot: ProgressSnapshot,
        client: ProgressClient
    ) async -> SyncEvent {
        logger.info("⚡ [TRACE] performNetworkSync() - начало обработки дня \(snapshot.id)")
        logger
            .info(
                "⚡ [TRACE] performNetworkSync() - состояние: isSynced=\(snapshot.isSynced), shouldDelete=\(snapshot.shouldDelete), shouldDeletePhoto=\(snapshot.shouldDeletePhoto)"
            )

        do {
            // Используем правильный день для запроса
            let externalDay = UserProgress.getExternalDayFromProgressId(snapshot.id)
            logger.info("⚡ [TRACE] performNetworkSync() - маппинг дней: внутренний \(snapshot.id) -> внешний \(externalDay)")

            if snapshot.shouldDelete {
                // Если запись никогда не была синхронизирована, не пытаемся удалять её с сервера
                if !snapshot.isSynced {
                    logger.info("⏭️ [TRACE] performNetworkSync() - пропускаем удаление дня \(externalDay) (никогда не был синхронизирован)")
                    return .alreadyExists(id: snapshot.id)
                }

                logger.info("🗑️ [TRACE] performNetworkSync() - удаление записи дня \(externalDay)")
                // Используем правильный день для удаления
                do {
                    try await client.deleteProgress(day: externalDay)
                    logger.info("✅ [TRACE] performNetworkSync() - успешно удален прогресс дня \(externalDay)")
                    return .deleted(id: snapshot.id)
                } catch {
                    // Если не удалось удалить на сервере, помечаем как уже существующую
                    // Это может произойти, если запись не существует на сервере
                    logger
                        .warning(
                            "⚠️ [TRACE] performNetworkSync() - не удалось удалить прогресс дня \(externalDay): \(error.localizedDescription). Помечаем как уже существующий."
                        )
                    return .alreadyExists(id: snapshot.id)
                }
            } else {
                // Собираем данные фотографий для отправки на сервер (только не удаленные)
                let photos = snapshot.photosForUpload
                logger.info("📸 [TRACE] performNetworkSync() - подготовка фотографий для отправки: \(photos.count) файлов")

                // Проверяем, есть ли фотографии для удаления
                if snapshot.shouldDeletePhoto {
                    logger.info("📸 [TRACE] performNetworkSync() - требуется удаление фотографий для дня \(snapshot.id)")

                    // Если есть только фотографии для удаления (нет новых для отправки), обрабатываем отдельно
                    if photos.isEmpty {
                        logger.info("📸 [TRACE] performNetworkSync() - только удаление фотографий, без новых для отправки")
                        return .needsPhotoDeletion(id: snapshot.id)
                    }

                    // Если есть и удаление, и новые фотографии - сначала удаляем, потом отправляем новые
                    logger.info("📸 [TRACE] performNetworkSync() - есть и удаление, и новые фотографии - обрабатываем последовательно")
                    return .needsPhotoDeletion(id: snapshot.id)
                }

                // Создаем запрос с данными фотографий (без photosToDelete)
                let request = ProgressRequest(
                    id: externalDay,
                    pullups: snapshot.pullups,
                    pushups: snapshot.pushups,
                    squats: snapshot.squats,
                    weight: snapshot.weight,
                    modifyDate: DateFormatterService.stringFromFullDate(snapshot.lastModified, format: .isoDateTimeSec),
                    photos: photos.isEmpty ? nil : photos,
                    photosToDelete: nil // Убираем photosToDelete - будем обрабатывать отдельно
                )

                logger
                    .info(
                        "📤 [TRACE] performNetworkSync() - отправляем прогресс дня \(externalDay) с фотографиями: для отправки=\(photos.count), данные: pullups=\(snapshot.pullups ?? 0), pushups=\(snapshot.pushups ?? 0), squats=\(snapshot.squats ?? 0), weight=\(snapshot.weight ?? 0)"
                    )

                // Используем единый подход: всегда пытаемся обновить/создать через updateProgress
                // Сервер сам разберется и применит LWW логику
                logger
                    .info(
                        "🌐 [TRACE] performNetworkSync() - отправляем данные на сервер: внутренний день \(snapshot.id), внешний день \(externalDay)"
                    )
                let response = try await client.updateProgress(day: externalDay, progress: request)
                logger
                    .info(
                        "📥 [TRACE] performNetworkSync() - получен ответ сервера: id=\(response.id), pullups=\(response.pullups ?? 0), pushups=\(response.pushups ?? 0), squats=\(response.squats ?? 0), weight=\(response.weight ?? 0.0)"
                    )
                return .createdOrUpdated(id: snapshot.id, server: response)
            }
        } catch {
            let externalDay = UserProgress.getExternalDayFromProgressId(snapshot.id)
            logger
                .error(
                    "❌ [TRACE] performNetworkSync() - ошибка синхронизации прогресса дня \(snapshot.id) (внешний день \(externalDay)): \(error.localizedDescription)"
                )
            if let decodingError = error as? DecodingError {
                logger.error("❌ [TRACE] performNetworkSync() - детали ошибки декодирования: \(decodingError)")
            }
            return .failed(id: snapshot.id, errorDescription: error.localizedDescription)
        }
    }

    /// Применяет результаты синхронизации к локальному хранилищу в одном месте
    func applySyncEvents(_ events: [Int: SyncEvent], context: ModelContext) async -> SyncStats {
        logger.info("💾 [TRACE] applySyncEvents() - начало применения \(events.count) результатов синхронизации")

        var created = 0
        var updated = 0
        var deleted = 0

        // Логируем все события перед обработкой
        for (id, event) in events {
            logger.info("📋 [TRACE] applySyncEvents() - событие для дня \(id): \(String(describing: event))")
        }

        do {
            // Загружаем текущего пользователя и все записи прогресса заранее
            logger.info("👤 [TRACE] applySyncEvents() - загрузка пользователя и существующих записей")
            guard let user = try context.fetch(FetchDescriptor<User>()).first else {
                logger.error("❌ [TRACE] applySyncEvents() - пользователь не найден")
                return SyncStats(created: created, updated: updated, deleted: deleted)
            }
            let existingCount = (try? context.fetch(FetchDescriptor<UserProgress>()).count(where: { $0.user?.id == user.id })) ?? 0
            logger.info("📊 [TRACE] applySyncEvents() - найдено \(existingCount) существующих записей прогресса")

            let existing = try context.fetch(FetchDescriptor<UserProgress>()).filter { $0.user?.id == user.id }
            let dict = Dictionary(existing.map { ($0.id, $0) }, uniquingKeysWith: { $1 })

            logger.info("🔄 [TRACE] applySyncEvents() - начинаем обработку каждого события")
            for (id, event) in events {
                logger.info("⚡ [TRACE] applySyncEvents() - обработка дня \(id), событие: \(String(describing: event))")

                switch event {
                case let .createdOrUpdated(_, server):
                    if let local = dict[id] {
                        logger.info("🔄 [TRACE] applySyncEvents() - обновление существующей записи дня \(id)")
                        logger
                            .info(
                                "🔄 [TRACE] applySyncEvents() - до обновления: isSynced=\(local.isSynced), shouldDelete=\(local.shouldDelete)"
                            )

                        // Реальный ответ сервера - применяем LWW логику
                        _ = await applyLWWLogic(local: local, server: server, internalDay: id)
                        updated += 1

                        logger
                            .info(
                                "✅ [TRACE] applySyncEvents() - после обновления: isSynced=\(local.isSynced), shouldDelete=\(local.shouldDelete)"
                            )
                    } else {
                        logger.info("➕ [TRACE] applySyncEvents() - создание новой записи дня \(id)")
                        // Создаем новую запись локально по ответу сервера с правильным internalDay
                        // Используем id из события (внутренний ID), а не server.id (внешний ID)
                        let newProgress = UserProgress(from: server, user: user, internalDay: id)
                        context.insert(newProgress)
                        // Обновляем фотографии из ответа сервера
                        await updateProgressFromServerResponse(newProgress, server)
                        created += 1
                        logger
                            .info(
                                "✅ [TRACE] applySyncEvents() - новая запись создана: isSynced=\(newProgress.isSynced), shouldDelete=\(newProgress.shouldDelete)"
                            )
                    }
                case let .alreadyExists(localId):
                    if let local = dict[localId] {
                        logger.info("📌 [TRACE] applySyncEvents() - день \(localId) уже существует на сервере")
                        logger
                            .info(
                                "📌 [TRACE] applySyncEvents() - до изменения: isSynced=\(local.isSynced), shouldDelete=\(local.shouldDelete), lastModified=\(local.lastModified)"
                            )

                        // Локальная запись уже существует на сервере - помечаем как синхронизированную
                        // Обновляем lastModified, чтобы защита от race condition в handleDeletedProgress работала правильно
                        local.isSynced = true
                        local.shouldDelete = false
                        local.lastModified = Date.now
                        updated += 1

                        logger
                            .info(
                                "📌 [TRACE] applySyncEvents() - после изменения: isSynced=\(local.isSynced), shouldDelete=\(local.shouldDelete), lastModified=\(local.lastModified)"
                            )
                    } else {
                        logger.warning("⚠️ [TRACE] applySyncEvents() - запись дня \(localId) не найдена локально (alreadyExists)")
                    }
                case .deleted:
                    if let local = dict[id] {
                        logger.info("🗑️ [TRACE] applySyncEvents() - удаление записи дня \(id)")
                        context.delete(local)
                        deleted += 1
                        logger.info("✅ [TRACE] applySyncEvents() - запись дня \(id) удалена")
                    } else {
                        logger.debug("⚠️ [TRACE] applySyncEvents() - локальный прогресс дня \(id) не найден для удаления")
                    }
                case .needsPhotoDeletion:
                    logger.info("📸 [TRACE] applySyncEvents() - требуется удаление фотографий для дня \(id)")
                    // Обрабатываем удаление фотографий последовательно
                    if let local = dict[id] {
                        await handlePhotoDeletion(local, context: context)
                    } else {
                        logger.warning("⚠️ [TRACE] applySyncEvents() - запись дня \(id) не найдена для удаления фотографий")
                    }
                case let .failed(_, errorDescription):
                    logger.error("❌ [TRACE] applySyncEvents() - ошибка синхронизации прогресса дня \(id): \(errorDescription)")
                }
            }

            // Удаляем локальные записи, которые помечены для удаления, но никогда не были синхронизированы
            logger.info("🧹 [TRACE] applySyncEvents() - удаление локальных записей, помеченных для удаления, но не синхронизированных")
            let allProgress = try context.fetch(FetchDescriptor<UserProgress>()).filter { $0.user?.id == user.id }
            for progress in allProgress {
                if progress.shouldDelete, !progress.isSynced {
                    logger
                        .info(
                            "🗑️ [TRACE] applySyncEvents() - удаляем локальную запись дня \(progress.id) (shouldDelete=true, isSynced=false)"
                        )
                    context.delete(progress)
                    deleted += 1
                }
            }

            logger.info("💾 [TRACE] applySyncEvents() - сохранение всех изменений в контексте")
            try context.save()
            logger.info("✅ [TRACE] applySyncEvents() - все изменения сохранены")

            // Логируем финальное состояние всех записей
            let finalProgress = try context.fetch(FetchDescriptor<UserProgress>()).filter { $0.user?.id == user.id }
            for progress in finalProgress {
                logger
                    .info(
                        "📋 [TRACE] applySyncEvents() - финальное состояние дня \(progress.id): isSynced=\(progress.isSynced), shouldDelete=\(progress.shouldDelete), lastModified=\(progress.lastModified)"
                    )
            }

        } catch {
            logger.error("❌ [TRACE] applySyncEvents() - ошибка применения результатов: \(error.localizedDescription)")
            logger.error("❌ [TRACE] applySyncEvents() - тип ошибки: \(String(describing: type(of: error)))")
        }
        logger.info("🏁 [TRACE] applySyncEvents() - завершение, статистика: created=\(created), updated=\(updated), deleted=\(deleted)")
        return SyncStats(created: created, updated: updated, deleted: deleted)
    }

    /// Обновляет локальный прогресс данными с сервера
    func updateLocalFromServer(_ local: UserProgress, _ server: ProgressResponse, internalDay _: Int) {
        local.pullUps = server.pullups
        local.pushUps = server.pushups
        local.squats = server.squats
        local.weight = server.weight
        // Если modify_date равен null, используем create_date
        local.lastModified = server.modifyDate ?? server.createDate
        local.isSynced = true
        local.shouldDelete = false
    }

    /// Применяет логику Last Write Wins для разрешения конфликтов между локальными и серверными данными
    private func applyLWWLogic(local: UserProgress, server: ProgressResponse, internalDay: Int) async -> Bool {
        logger.info("⚖️ [TRACE] applyLWWLogic() - начало LWW для дня \(internalDay)")
        logger
            .info(
                "⚖️ [TRACE] applyLWWLogic() - текущее состояние локальной записи: isSynced=\(local.isSynced), shouldDelete=\(local.shouldDelete), lastModified=\(local.lastModified)"
            )

        // Если modify_date равен null, используем create_date
        let serverModifyDate = server.modifyDate ?? server.createDate

        // Сравниваем даты модификации
        let localDate = local.lastModified
        let serverDate = serverModifyDate

        logger.info("⚖️ [TRACE] applyLWWLogic() - даты: локальная=\(localDate), серверная=\(serverDate)")

        // Проверяем разницу данных для принятия более обоснованного решения
        let hasDataDifference = local.pullUps != server.pullups ||
            local.pushUps != server.pushups ||
            local.squats != server.squats ||
            abs((local.weight ?? 0) - (server.weight ?? 0)) > 0.01

        if hasDataDifference {
            logger.info("⚖️ [TRACE] applyLWWLogic() - обнаружены различия в данных для дня \(internalDay)")
            logger
                .info(
                    "⚖️ [TRACE] applyLWWLogic() - локальные: pullUps=\(local.pullUps ?? 0), pushUps=\(local.pushUps ?? 0), squats=\(local.squats ?? 0), weight=\(local.weight ?? 0)"
                )
            logger
                .info(
                    "⚖️ [TRACE] applyLWWLogic() - серверные: pullups=\(server.pullups ?? 0), pushups=\(server.pushups ?? 0), squats=\(server.squats ?? 0), weight=\(server.weight ?? 0)"
                )
        } else {
            logger.info("⚖️ [TRACE] applyLWWLogic() - данные идентичны для дня \(internalDay)")
        }

        if localDate > serverDate {
            // Локальная версия новее серверной - сохраняем локальные изменения
            logger
                .info("⚖️ [TRACE] applyLWWLogic() - локальная версия новее серверной для дня \(internalDay) - сохраняем локальные изменения")
            logger.info("⚖️ [TRACE] applyLWWLogic() - до изменения: isSynced=\(local.isSynced), shouldDelete=\(local.shouldDelete)")

            // Убеждаемся, что прогресс остается синхронизированным
            local.isSynced = true
            local.shouldDelete = false

            logger.info("⚖️ [TRACE] applyLWWLogic() - после изменения: isSynced=\(local.isSynced), shouldDelete=\(local.shouldDelete)")
            logger.info("⚖️ [TRACE] applyLWWLogic() - локальные данные сохранены")
            return false // Серверные данные не применялись
        } else if serverDate > localDate {
            // Серверная версия новее - обновляем локальную
            logger.info("⚖️ [TRACE] applyLWWLogic() - серверная версия новее локальной для дня \(internalDay) - обновляем локальные данные")

            updateLocalFromServer(local, server, internalDay: internalDay)
            // Обновляем фотографии из ответа сервера
            await updateProgressFromServerResponse(local, server)

            logger.info("⚖️ [TRACE] applyLWWLogic() - локальные данные обновлены с сервера")
            return true // Серверные данные были применены
        } else {
            // Даты одинаковые или очень близкие - сравниваем данные
            if hasDataDifference {
                logger
                    .warning(
                        "⚠️ [TRACE] applyLWWLogic() - одинаковые даты модификации, но разные данные для дня \(internalDay). Серверная версия имеет приоритет."
                    )
                updateLocalFromServer(local, server, internalDay: internalDay)
                // Обновляем фотографии из ответа сервера
                await updateProgressFromServerResponse(local, server)
                logger.info("⚖️ [TRACE] applyLWWLogic() - данные обновлены с сервера (приоритет сервера)")
                return true // Серверные данные были применены
            } else {
                logger.info("⚖️ [TRACE] applyLWWLogic() - данные идентичны для дня \(internalDay) - помечаем как синхронизированные")
                logger.info("⚖️ [TRACE] applyLWWLogic() - до изменения: isSynced=\(local.isSynced), shouldDelete=\(local.shouldDelete)")

                local.isSynced = true
                local.shouldDelete = false

                logger.info("⚖️ [TRACE] applyLWWLogic() - после изменения: isSynced=\(local.isSynced), shouldDelete=\(local.shouldDelete)")
                return false // Серверные данные не применялись
            }
        }
    }

    /// Проверяет прогресс на "пустоту" и помечает для удаления целиком при необходимости
    private func checkAndMarkForDeletionIfEmpty(_ progress: UserProgress) {
        logger.info("🔍 [TRACE] checkAndMarkForDeletionIfEmpty() - проверка дня \(progress.id)")
        logger
            .info(
                "🔍 [TRACE] checkAndMarkForDeletionIfEmpty() - текущее состояние: isSynced=\(progress.isSynced), shouldDelete=\(progress.shouldDelete), isEmpty=\(progress.isEmpty)"
            )

        // Дополнительная защита от race condition: не изменяем уже синхронизированные записи
        if progress.isSynced, !progress.shouldDelete {
            logger
                .info(
                    "⏭️ [TRACE] checkAndMarkForDeletionIfEmpty() - пропускаем уже синхронизированную запись дня \(progress.id) (isSynced=\(progress.isSynced), shouldDelete=\(progress.shouldDelete))"
                )
            return
        }

        // Проверяем только несинхронизированные записи, которые не помечены для удаления
        guard !progress.isSynced, !progress.shouldDelete else {
            logger
                .info(
                    "⏭️ [TRACE] checkAndMarkForDeletionIfEmpty() - пропускаем день \(progress.id) (isSynced=\(progress.isSynced), shouldDelete=\(progress.shouldDelete))"
                )
            return
        }

        logger.info("🔍 [TRACE] checkAndMarkForDeletionIfEmpty() - проверяем на пустоту день \(progress.id)")

        // Если прогресс стал пустым после изменений, помечаем его для удаления целиком
        // НО только если он не синхронизирован и действительно пустой
        if progress.isEmpty {
            logger.info("🚨 [TRACE] checkAndMarkForDeletionIfEmpty() - день \(progress.id) стал пустым - помечаем для удаления целиком")
            logger
                .info(
                    "🚨 [TRACE] checkAndMarkForDeletionIfEmpty() - до изменения: shouldDelete=\(progress.shouldDelete), isSynced=\(progress.isSynced)"
                )

            progress.shouldDelete = true
            progress.isSynced = false
            progress.lastModified = Date.now

            logger
                .info(
                    "🚨 [TRACE] checkAndMarkForDeletionIfEmpty() - после изменения: shouldDelete=\(progress.shouldDelete), isSynced=\(progress.isSynced), lastModified=\(progress.lastModified)"
                )
        } else {
            logger
                .info(
                    "✅ [TRACE] checkAndMarkForDeletionIfEmpty() - день \(progress.id) не пустой, имеет фотографии или уже синхронизирован"
                )
        }
    }

    /// Обновляет локальный прогресс (фотографии) данными из ответа сервера
    func updateProgressFromServerResponse(_ progress: UserProgress, _ response: ProgressResponse) async {
        logger.info("📸 [TRACE] updateProgressFromServerResponse() - начало обновления дня \(progress.id)")
        logger
            .info(
                "📸 [TRACE] updateProgressFromServerResponse() - текущее состояние: isSynced=\(progress.isSynced), shouldDelete=\(progress.shouldDelete)"
            )
        logger
            .info(
                "📸 [TRACE] updateProgressFromServerResponse() - серверные URL: front=\(response.photoFront ?? "nil"), back=\(response.photoBack ?? "nil"), side=\(response.photoSide ?? "nil")"
            )

        // Обновляем URL фотографий из ответа сервера
        logger.info("📸 [TRACE] updateProgressFromServerResponse() - обновляем URL фотографий")
        progress.urlPhotoFront = response.photoFront
        progress.urlPhotoBack = response.photoBack
        progress.urlPhotoSide = response.photoSide

        // Устанавливаем lastModified в соответствии с серверным временем (делегируем модели)
        logger.info("📸 [TRACE] updateProgressFromServerResponse() - обновляем lastModified из ответа сервера")
        progress.updateLastModified(from: response)

        // Загружаем фотографии синхронно
        logger.info("📸 [TRACE] updateProgressFromServerResponse() - начинаем загрузку фотографий")
        await photoDownloadService.downloadAllPhotos(for: progress)

        logger
            .info(
                "📸 [TRACE] updateProgressFromServerResponse() - до изменения: isSynced=\(progress.isSynced), shouldDelete=\(progress.shouldDelete)"
            )
        // Не устанавливаем isSynced здесь - это должно делаться в LWW логике
        logger
            .info(
                "📸 [TRACE] updateProgressFromServerResponse() - после изменения: isSynced=\(progress.isSynced), shouldDelete=\(progress.shouldDelete)"
            )

        logger.info("✅ [TRACE] updateProgressFromServerResponse() - прогресс дня \(progress.id) обновлен из ответа сервера")
    }

    /// Обрабатывает удаление фотографий последовательно (как в старом приложении)
    private func handlePhotoDeletion(_ progress: UserProgress, context: ModelContext) async {
        logger.info("📸 [TRACE] handlePhotoDeletion() - начало удаления фотографий для дня \(progress.id)")
        logger
            .info(
                "📸 [TRACE] handlePhotoDeletion() - текущее состояние: isSynced=\(progress.isSynced), shouldDelete=\(progress.shouldDelete)"
            )

        var hasErrors = false

        // Проверяем каждую фотографию и удаляем по одной
        for photoType in ProgressPhotoType.allCases {
            logger.info("📸 [TRACE] handlePhotoDeletion() - проверка \(photoType.localizedTitle) для дня \(progress.id)")

            if progress.shouldDeletePhoto(photoType) {
                logger.info("🗑️ [TRACE] handlePhotoDeletion() - требуется удаление \(photoType.localizedTitle) для дня \(progress.id)")

                do {
                    let externalDay = UserProgress.getExternalDayFromProgressId(progress.id)
                    logger
                        .info(
                            "🌐 [TRACE] handlePhotoDeletion() - отправляем запрос на удаление фото: день \(externalDay), тип \(photoType.requestName)"
                        )

                    try await client.deletePhoto(day: externalDay, type: photoType.requestName)

                    logger.info("📸 [TRACE] handlePhotoDeletion() - очищаем данные \(photoType.localizedTitle) локально")
                    // Очищаем данные фотографии после успешного удаления
                    progress.clearPhotoData(photoType)

                    logger
                        .info(
                            "✅ [TRACE] handlePhotoDeletion() - \(photoType.localizedTitle) успешно удалена с сервера для дня \(progress.id)"
                        )
                } catch {
                    logger
                        .error(
                            "❌ [TRACE] handlePhotoDeletion() - ошибка удаления \(photoType.localizedTitle) для дня \(progress.id): \(error.localizedDescription)"
                        )
                    hasErrors = true
                    // Продолжаем с другими фотографиями даже при ошибке
                }
            } else {
                logger.info("⏭️ [TRACE] handlePhotoDeletion() - \(photoType.localizedTitle) не требует удаления")
            }
        }

        logger.info("🔄 [TRACE] handlePhotoDeletion() - завершение обработки всех фотографий, hasErrors=\(hasErrors)")

        // После удаления фотографий проверяем, есть ли новые фотографии для отправки
        if !hasErrors {
            let snapshot = ProgressSnapshot(from: progress)
            let photos = snapshot.photosForUpload

            if !photos.isEmpty {
                logger
                    .info("📸 [TRACE] handlePhotoDeletion() - после удаления найдены новые фотографии для отправки: \(photos.count) файлов")

                do {
                    let externalDay = UserProgress.getExternalDayFromProgressId(progress.id)
                    let request = ProgressRequest(
                        id: externalDay,
                        pullups: snapshot.pullups,
                        pushups: snapshot.pushups,
                        squats: snapshot.squats,
                        weight: snapshot.weight,
                        modifyDate: DateFormatterService.stringFromFullDate(snapshot.lastModified, format: .isoDateTimeSec),
                        photos: photos,
                        photosToDelete: nil
                    )

                    logger.info("📤 [TRACE] handlePhotoDeletion() - отправляем новые фотографии после удаления")
                    let response = try await client.updateProgress(day: externalDay, progress: request)
                    logger.info("✅ [TRACE] handlePhotoDeletion() - новые фотографии успешно отправлены")

                    // Обновляем URL фотографий из ответа сервера
                    progress.urlPhotoFront = response.photoFront
                    progress.urlPhotoBack = response.photoBack
                    progress.urlPhotoSide = response.photoSide
                    progress.updateLastModified(from: response)

                } catch {
                    logger.error("❌ [TRACE] handlePhotoDeletion() - ошибка отправки новых фотографий: \(error.localizedDescription)")
                    hasErrors = true
                }
            } else {
                logger.info("📸 [TRACE] handlePhotoDeletion() - новых фотографий для отправки не найдено")
            }
        }

        // После обработки всех фотографий
        logger.info("🔄 [TRACE] handlePhotoDeletion() - до изменения: shouldDelete=\(progress.shouldDelete), isSynced=\(progress.isSynced)")

        // Помечаем как синхронизированный только если не было ошибок
        if !hasErrors {
            progress.isSynced = true
            progress.shouldDelete = false
            logger.info("✅ [TRACE] handlePhotoDeletion() - помечен как синхронизированный")
        } else {
            logger.warning("⚠️ [TRACE] handlePhotoDeletion() - остались ошибки, не помечаем как синхронизированный")
        }

        logger
            .info("🔄 [TRACE] handlePhotoDeletion() - после изменения: shouldDelete=\(progress.shouldDelete), isSynced=\(progress.isSynced)")

        do {
            logger.info("💾 [TRACE] handlePhotoDeletion() - сохранение контекста")
            try context.save()
            logger.info("✅ [TRACE] handlePhotoDeletion() - последовательное удаление фотографий для дня \(progress.id) завершено")
        } catch {
            logger.error("❌ [TRACE] handlePhotoDeletion() - ошибка сохранения контекста: \(error.localizedDescription)")
        }
    }
}
