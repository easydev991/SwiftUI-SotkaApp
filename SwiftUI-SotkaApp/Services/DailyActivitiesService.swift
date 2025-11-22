import Foundation
import Observation
import OSLog
import SwiftData
import SWNetwork
import SWUtils

@MainActor
@Observable
final class DailyActivitiesService {
    @ObservationIgnored private let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "SotkaApp",
        category: String(describing: DailyActivitiesService.self)
    )

    private(set) var isLoading = false
    private(set) var isSyncing = false

    /// Клиент для работы с API
    private let client: DaysClient

    /// Инициализатор сервиса
    /// - Parameter client: Клиент для работы с API
    init(client: DaysClient) {
        self.client = client
    }

    // MARK: - Публичные методы (офлайн-приоритет)

    /// Создает новую ежедневную активность (локально)
    /// - Parameters:
    ///   - activity: Модель активности для сохранения
    ///   - context: Контекст SwiftData
    func createDailyActivity(
        _ activity: DayActivity,
        context: ModelContext
    ) {
        guard let user = try? context.fetch(FetchDescriptor<User>()).first else {
            logger.error("Пользователь не найден для создания активности дня")
            return
        }

        // Проверяем, существует ли уже активность для этого дня
        let existingActivities = (try? context.fetch(FetchDescriptor<DayActivity>())) ?? []
        if let existingActivity = existingActivities.first(where: {
            $0.day == activity.day && $0.user?.id == user.id && !$0.shouldDelete
        }) {
            // Обновляем существующую активность новыми данными
            updateExistingActivity(existingActivity, with: activity, user: user)
            logger.info("Обновлена существующая активность для дня \(activity.day)")
            // Новая активность не создается - обновляем существующую
        } else {
            // Создаем новую активность
            // Установка флагов синхронизации
            activity.isSynced = false
            activity.shouldDelete = false

            // Установка текущих дат для новой активности
            activity.createDate = .now
            activity.modifyDate = .now

            // Привязка активности к пользователю (если еще не привязана)
            if activity.user == nil {
                activity.user = user
            }

            // Присоединение trainings к активности (если они еще не присоединены)
            for training in activity.trainings where training.dayActivity == nil {
                training.dayActivity = activity
            }

            // Вставка активности в контекст
            context.insert(activity)
            logger.info("Активность для дня \(activity.day) создана локально")
        }

        do {
            try context.save()
            logger.info("Синхронизация будет выполнена отдельно через syncDailyActivities")
        } catch {
            logger.error("Ошибка сохранения активности: \(error.localizedDescription)")
        }
    }

    /// Отмечает ежедневную активность как измененную (офлайн-приоритет)
    /// - Parameters:
    ///   - activity: Активность для отметки как измененная
    ///   - context: Контекст SwiftData
    func markDailyActivityAsModified(
        _ activity: DayActivity,
        context: ModelContext
    ) throws {
        activity.modifyDate = .now
        activity.isSynced = false
        try context.save()
        logger.info("Активность для дня \(activity.day) отмечена как измененная")
        logger.info("Синхронизация будет выполнена отдельно через syncDailyActivities")
    }

    /// Удаляет ежедневную активность (офлайн-приоритет, мягкое удаление)
    /// - Parameters:
    ///   - activity: Активность для удаления
    ///   - context: Контекст SwiftData
    func deleteDailyActivity(_ activity: DayActivity, context: ModelContext) {
        // Мягкое удаление: скрываем в UI и синхронизируем удаление с сервером
        activity.shouldDelete = true
        activity.isSynced = false
        activity.modifyDate = .now
        do {
            try context.save()
            logger.info("Активность для дня \(activity.day) помечена для удаления локально")
            logger.info("Синхронизация удаления будет выполнена через syncDailyActivities")
        } catch {
            logger.error("Ошибка удаления активности: \(error.localizedDescription)")
        }
    }

    /// Устанавливает активность для выбранного дня (офлайн-приоритет)
    ///
    /// Обрабатывает только типы `stretch`, `rest`, `sick`. Для типа workout метод логирует сообщение и возвращается без действий.
    /// - Parameters:
    ///   - activityType: Тип активности для установки
    ///   - day: Номер дня (1-100)
    ///   - context: Контекст SwiftData
    func set(_ activityType: DayActivityType, for day: Int, context: ModelContext) {
        if activityType == .workout {
            logger.info("Пропускаем настройку тренировки")
            return
        }
        guard let user = try? context.fetch(FetchDescriptor<User>()).first else {
            logger.error("Пользователь не найден для установки активности дня")
            return
        }
        // Находим существующую активность для дня (включая помеченные на удаление)
        let existingActivities = (try? context.fetch(FetchDescriptor<DayActivity>())) ?? []
        if let existingActivity = existingActivities.first(where: {
            $0.day == day && $0.user?.id == user.id
        }) {
            // Если активность помечена на удаление - снимаем флаг и обновляем тип
            let needsUpdate = existingActivity.activityType != activityType || existingActivity.shouldDelete

            // Если активность существует с тем же типом и не помечена на удаление - ничего не делать
            if !needsUpdate {
                logger.debug("Активность дня \(day) уже имеет тип \(activityType.rawValue), пропускаем обновление")
                return
            }

            // Если активность существует с другим типом - обновляем тип активности
            existingActivity.setNonWorkoutType(activityType, user: user)

            logger.info("Обновлена активность дня \(day) на тип \(activityType.rawValue)")
        } else {
            // Если активности для дня нет - создаем новую с указанным типом
            let newActivity = DayActivity.createNonWorkoutActivity(
                day: day,
                activityType: activityType,
                user: user
            )

            // Вставка активности в контекст
            context.insert(newActivity)
            logger.info("Создана новая активность дня \(day) с типом \(activityType.rawValue)")
        }

        // Сохранение контекста
        do {
            try context.save()
            logger.info("Активность дня \(day) сохранена локально, синхронизация будет выполнена через syncDailyActivities")
        } catch {
            logger.error("Ошибка сохранения активности дня \(day): \(error.localizedDescription)")
        }
    }

    /// Обновляет комментарий для активности дня (офлайн-приоритет)
    /// - Parameters:
    ///   - day: Номер дня (1-100)
    ///   - comment: Комментарий (может быть nil для удаления)
    ///   - context: Контекст SwiftData
    func updateComment(day: Int, comment: String?, context: ModelContext) {
        guard let user = try? context.fetch(FetchDescriptor<User>()).first else {
            logger.error("Пользователь не найден для обновления комментария дня \(day)")
            return
        }

        // Находим существующую активность для дня (включая помеченные на удаление)
        let existingActivities = (try? context.fetch(FetchDescriptor<DayActivity>())) ?? []
        if let existingActivity = existingActivities.first(where: {
            $0.day == day && $0.user?.id == user.id
        }) {
            // Если активность помечена на удаление - снимаем флаг
            if existingActivity.shouldDelete {
                existingActivity.shouldDelete = false
                existingActivity.user = user
            }

            // Обновляем комментарий
            existingActivity.comment = comment
            existingActivity.modifyDate = .now
            existingActivity.isSynced = false

            logger.info("Обновлен комментарий для активности дня \(day)")
        } else {
            // Если активности для дня нет - создаем новую с комментарием
            let newActivity = DayActivity(
                day: day,
                activityTypeRaw: nil,
                count: nil,
                plannedCount: nil,
                executeTypeRaw: nil,
                trainingTypeRaw: nil,
                duration: nil,
                comment: comment,
                createDate: .now,
                modifyDate: .now,
                user: user
            )

            // Установка флагов синхронизации
            newActivity.isSynced = false
            newActivity.shouldDelete = false

            // Вставка активности в контекст
            context.insert(newActivity)
            logger.info("Создана новая активность дня \(day) с комментарием")
        }

        // Сохранение контекста
        do {
            try context.save()
            logger.info("Комментарий для дня \(day) сохранен локально, синхронизация будет выполнена через syncDailyActivities")
        } catch {
            logger.error("Ошибка сохранения комментария для дня \(day): \(error.localizedDescription)")
        }
    }

    /// Синхронизирует ежедневные активности с сервером (двунаправленная синхронизация)
    /// - Parameter context: Контекст SwiftData
    /// - Returns: Результат синхронизации с детальной информацией
    func syncDailyActivities(context: ModelContext) async throws -> SyncResult {
        guard !isLoading else {
            throw AlreadySyncingError()
        }
        isLoading = true
        defer { isLoading = false }

        var errors: [SyncError] = []
        var stats: SyncStats?

        // 1. Сначала отправляем локальные изменения на сервер
        let (syncStats, syncErrors, deletedDays) = await syncUnsyncedActivities(context: context)
        stats = syncStats
        errors.append(contentsOf: syncErrors)

        // 2. Потом загружаем серверные изменения
        do {
            try await downloadServerActivities(context: context, excludeDeletedDays: deletedDays)
        } catch {
            logger.error("Ошибка загрузки серверных активностей: \(error.localizedDescription)")
            errors.append(SyncError(
                type: "download_failed",
                message: error.localizedDescription,
                entityType: "activity",
                entityId: nil
            ))
        }

        // Определяем тип результата
        let resultType = SyncResultType(
            errors: errors.isEmpty ? nil : errors,
            stats: stats
        )

        let details = SyncResultDetails(
            progress: nil,
            exercises: nil,
            activities: stats,
            errors: errors.isEmpty ? nil : errors
        )

        return SyncResult(type: resultType, details: details)
    }
}

extension DailyActivitiesService {
    /// Ошибка, возникающая при попытке запустить синхронизацию, когда она уже выполняется
    struct AlreadySyncingError: Error {}
}

private extension DailyActivitiesService {
    // MARK: - Snapshot & Sync Events (для конкурентной синхронизации без ModelContext)

    /// Результат конкурентной операции синхронизации одной активности
    enum SyncEvent: Sendable, Hashable {
        case createdOrUpdated(day: Int, server: DayResponse)
        case deleted(day: Int)
        case failed(day: Int, errorDescription: String)
    }

    // MARK: - Валидация и проверки

    /// Обновляет существующую активность данными из новой активности
    /// - Parameters:
    ///   - existing: Существующая активность, которую нужно обновить
    ///   - new: Новая активность с данными для обновления
    ///   - user: Пользователь
    func updateExistingActivity(_ existing: DayActivity, with new: DayActivity, user: User) {
        // Сохраняем оригинальную дату создания существующей активности
        // Обновляем все остальные поля данными из новой активности
        existing.activityTypeRaw = new.activityTypeRaw
        existing.count = new.count
        existing.plannedCount = new.plannedCount
        existing.executeTypeRaw = new.executeTypeRaw
        existing.trainingTypeRaw = new.trainingTypeRaw
        existing.duration = new.duration
        existing.comment = new.comment
        existing.modifyDate = .now

        // Установка флагов синхронизации
        existing.isSynced = false
        existing.shouldDelete = false

        // Убеждаемся, что активность привязана к пользователю
        existing.user = user

        // Обновление trainings: удаляем старые и добавляем новые
        existing.trainings.removeAll()
        for training in new.trainings {
            training.dayActivity = existing
            existing.trainings.append(training)
        }
    }

    // MARK: - Внутренние методы синхронизации

    /// Синхронизирует все несинхронизированные активности с сервером
    /// - Parameter context: Контекст SwiftData
    /// - Returns: Кортеж со статистикой синхронизации, списком ошибок и множеством удаленных дней
    func syncUnsyncedActivities(context: ModelContext) async -> (SyncStats, [SyncError], Set<Int>) {
        guard !isSyncing else {
            logger.info("Синхронизация активностей уже выполняется")
            return (SyncStats(created: 0, updated: 0, deleted: 0), [], [])
        }
        isSyncing = true
        defer { isSyncing = false }

        logger.info("Начинаем синхронизацию активностей")

        do {
            // 1) Готовим снимки данных (без доступа к контексту в задачах)
            let snapshots = try makeActivitySnapshotsForSync(context: context)
            logger.info("Начинаем синхронизацию \(snapshots.count) активностей")

            // 2) Параллельные сетевые операции (без ModelContext)
            let eventsByDay = await runSyncTasks(snapshots: snapshots, client: client)

            // Собираем ошибки и удаленные дни из событий
            var syncErrors: [SyncError] = []
            var deletedDays = Set<Int>()
            for (day, event) in eventsByDay {
                if case let .failed(_, errorDescription) = event {
                    syncErrors.append(SyncError(
                        type: "sync_failed",
                        message: errorDescription,
                        entityType: "activity",
                        entityId: String(day)
                    ))
                } else if case .deleted = event {
                    deletedDays.insert(day)
                }
            }

            // 3) Применяем результаты к ModelContext единым этапом
            let stats = applySyncEvents(eventsByDay, context: context)

            logger.info("Синхронизация активностей завершена")
            return (stats, syncErrors, deletedDays)
        } catch {
            logger.error("Ошибка получения несинхронизированных активностей: \(error.localizedDescription)")
            return (SyncStats(created: 0, updated: 0, deleted: 0), [], [])
        }
    }

    /// Формирует список снимков локальных активностей, требующих синхронизации
    func makeActivitySnapshotsForSync(context: ModelContext) throws -> [ActivitySnapshot] {
        // Берем все несинхронизированные, а также те, что помечены на удаление
        let toSync = try context.fetch(
            FetchDescriptor<DayActivity>(
                predicate: #Predicate { !$0.isSynced || $0.shouldDelete }
            )
        )
        return toSync.map(\.activitySnapshot)
    }

    /// Выполняет конкурентные сетевые операции синхронизации и собирает результаты без доступа к `ModelContext`
    func runSyncTasks(
        snapshots: [ActivitySnapshot],
        client: DaysClient
    ) async -> [Int: SyncEvent] {
        await withTaskGroup(of: (Int, SyncEvent).self) { group in
            for snapshot in snapshots {
                let createDateStr = DateFormatterService.stringFromFullDate(snapshot.createDate, format: .isoDateTimeSec)
                let modifyDateStr = DateFormatterService.stringFromFullDate(snapshot.modifyDate, format: .isoDateTimeSec)
                logger.info("Отправляем активность на сервер: день \(snapshot.day)")
                logger
                    .info(
                        "Параметры запроса: day=\(snapshot.day), activity_type=\(snapshot.activityTypeRaw?.description ?? "nil"), count=\(snapshot.count?.description ?? "nil"), create_date=\(createDateStr)"
                    )
                logger.info("modify_date=\(modifyDateStr)")

                group.addTask { [snapshot] in
                    let event = await self.performNetworkSync(for: snapshot, client: client)
                    return (snapshot.day, event)
                }
            }

            var eventsByDay: [Int: SyncEvent] = [:]
            for await (day, event) in group {
                eventsByDay[day] = event
            }
            return eventsByDay
        }
    }

    /// Выполняет сетевую синхронизацию одного снимка без доступа к `ModelContext`
    func performNetworkSync(
        for snapshot: ActivitySnapshot,
        client: DaysClient
    ) async -> SyncEvent {
        do {
            if snapshot.shouldDelete {
                try await client.deleteDay(day: snapshot.day)
                return .deleted(day: snapshot.day)
            } else {
                // Используем вычисляемое свойство snapshot.dayRequest для получения DayRequest
                let request = snapshot.dayRequest
                // Определяем создание или обновление (по isSynced или наличию на сервере)
                // Для упрощения всегда используем updateDay, так как API поддерживает создание через update
                let response = try await client.updateDay(model: request)
                return .createdOrUpdated(day: snapshot.day, server: response)
            }
        } catch {
            let errorDescription = error.localizedDescription
            return .failed(day: snapshot.day, errorDescription: errorDescription)
        }
    }

    /// Применяет результаты синхронизации к локальному хранилищу в одном месте
    /// - Parameters:
    ///   - events: События синхронизации
    ///   - context: Контекст SwiftData
    /// - Returns: Статистика синхронизации (создано/обновлено/удалено)
    func applySyncEvents(_ events: [Int: SyncEvent], context: ModelContext) -> SyncStats {
        var created = 0
        var updated = 0
        var deleted = 0

        do {
            // Загружаем текущего пользователя и все активности заранее
            guard let user = try context.fetch(FetchDescriptor<User>()).first else {
                logger.error("Пользователь не найден при применении результатов синхронизации")
                return SyncStats(created: created, updated: updated, deleted: deleted)
            }
            let existing = try context.fetch(FetchDescriptor<DayActivity>()).filter { $0.user?.id == user.id }
            let dict = Dictionary(existing.map { ($0.day, $0) }, uniquingKeysWith: { $1 })

            for (day, event) in events {
                switch event {
                case let .createdOrUpdated(_, server):
                    if let local = dict[day] {
                        // Если активность помечена на удаление, не обновляем её данными с сервера
                        // Она будет обработана в downloadServerActivities
                        if local.shouldDelete {
                            logger.debug("Активность дня \(day) помечена на удаление, пропускаем обновление в applySyncEvents")
                        } else if local.isSynced, let serverModifyDateString = server.modifyDate {
                            // Проверяем, не новее ли локальная версия серверной для синхронизированных активностей
                            let serverModifyDate = DateFormatterService.dateFromString(
                                serverModifyDateString,
                                format: .serverDateTimeSec
                            )
                            // Сравниваем даты (как в эталоне CustomExercisesService)
                            if local.modifyDate > serverModifyDate {
                                // Локальная версия новее серверной - сохраняем локальные изменения
                                logger
                                    .info(
                                        "Локальная версия новее серверной для активности дня \(day) в applySyncEvents - сохраняем локальные изменения. Локальная: \(local.modifyDate.timeIntervalSince1970), Серверная: \(serverModifyDate.timeIntervalSince1970)"
                                    )
                            } else {
                                // Серверная версия новее или равна - обновляем локальную
                                updateLocalFromServer(local, server)
                                updated += 1
                                logger
                                    .info(
                                        "Обновлено локально активность дня \(day) по данным сервера. Локальная: \(local.modifyDate.timeIntervalSince1970), Серверная: \(serverModifyDate.timeIntervalSince1970)"
                                    )
                            }
                        } else {
                            // Активность не синхронизирована или нет даты в ответе - обновляем локальную
                            updateLocalFromServer(local, server)
                            updated += 1
                            logger.info("Обновлено локально активность дня \(day) по данным сервера")
                        }
                    } else {
                        // Создаем новое локально по ответу сервера
                        let newActivity = DayActivity(from: server, user: user)
                        context.insert(newActivity)
                        created += 1
                        logger.info("Создано локально активность дня \(day) из ответа сервера")
                    }
                case .deleted:
                    if let local = dict[day] {
                        // Если активность помечена на удаление, не удаляем её физически сразу
                        // Проверка в downloadServerActivities определит, нужно ли удалять физически
                        // (если сервер не возвращает её, то удаление подтверждено)
                        if local.shouldDelete {
                            // Оставляем с shouldDelete = true, не удаляем физически
                            // downloadServerActivities проверит, возвращает ли сервер эту активность
                            // Если сервер возвращает её, оставляем с shouldDelete = true
                            // Если сервер не возвращает её, удалим физически в downloadServerActivities
                            logger.debug("Активность дня \(day) помечена на удаление, оставляем для проверки в downloadServerActivities")
                            // Не увеличиваем счетчик deleted здесь, так как удаление еще не подтверждено сервером
                        } else {
                            // Если активность не помечена на удаление, но сервер подтвердил удаление - удаляем физически
                            context.delete(local)
                            deleted += 1
                            logger.info("Удалено локально активность дня \(day)")
                        }
                    } else {
                        // Если локально уже отсутствует — ничего не делаем
                        logger.debug("Удаление: локальная активность дня \(day) не найдена")
                    }
                case let .failed(_, errorDescription):
                    logger.error("Ошибка синхронизации активности дня \(day): \(errorDescription)")
                }
            }

            try context.save()
        } catch {
            logger.error("Ошибка применения результатов синхронизации: \(error.localizedDescription)")
        }

        return SyncStats(created: created, updated: updated, deleted: deleted)
    }

    /// Обновляет локальную активность данными с сервера
    /// - Parameters:
    ///   - local: Локальная активность
    ///   - server: Данные с сервера
    func updateLocalFromServer(_ local: DayActivity, _ server: DayResponse) {
        local.day = server.id
        local.activityTypeRaw = server.activityType
        local.count = server.count
        local.plannedCount = server.plannedCount
        local.executeTypeRaw = server.executeType
        local.trainingTypeRaw = server.trainType
        local.duration = server.duration
        local.comment = server.comment
        local.createDate = DateFormatterService.dateFromString(
            server.createDate,
            format: .serverDateTimeSec
        )
        local.modifyDate = DateFormatterService.dateFromString(
            server.modifyDate,
            format: .serverDateTimeSec
        )

        // Обновление trainings: удаление старых (каскадное удаление через relationship)
        local.trainings.removeAll()

        // Создание новых trainings из server.trainings
        if let serverTrainings = server.trainings {
            local.trainings = serverTrainings.map { training in
                DayActivityTraining(from: training, dayActivity: local)
            }
        }

        local.isSynced = true
        local.shouldDelete = false
    }

    /// Загружает активности с сервера и обрабатывает конфликты
    /// - Parameters:
    ///   - context: Контекст SwiftData
    ///   - excludeDeletedDays: Set дней, которые были удалены в текущем цикле синхронизации
    func downloadServerActivities(context: ModelContext, excludeDeletedDays: Set<Int> = []) async throws {
        do {
            guard let user = try context.fetch(FetchDescriptor<User>()).first else {
                logger.error("Не удалось получить текущего пользователя для синхронизации активностей")
                return
            }
            let activities = try await client.getDays()
            let existingActivities = try context.fetch(FetchDescriptor<DayActivity>())
                .filter { $0.user?.id == user.id }
            let existingDict = Dictionary(existingActivities.map { ($0.day, $0) }, uniquingKeysWith: { $1 })

            for activityResponse in activities {
                if let existingActivity = existingDict[activityResponse.id] {
                    let serverModifyDate = DateFormatterService.dateFromString(
                        activityResponse.modifyDate,
                        format: .serverDateTimeSec
                    )

                    // Порядок проверок для разрешения конфликтов:
                    // 1. shouldDelete - пропуск обновления (элемент помечен на удаление)
                    // 2. hasDataChanged() == false && isSynced == true - пропуск обновления (данные не изменились)
                    // 3. isSynced == false - пропуск обновления (локальные изменения имеют приоритет)
                    // 4. Сравнение дат для синхронизированных активностей с измененными данными

                    // 1. Обработка специального случая: элемент помечен на удаление
                    if existingActivity.shouldDelete {
                        // Если активность помечена на удаление и сервер возвращает её,
                        // оставляем с shouldDelete = true, не восстанавливаем данными с сервера
                        logger
                            .info(
                                "Локальная активность дня \(existingActivity.day) помечена для удаления, но сервер её возвращает - оставляем с shouldDelete = true"
                            )
                    } else {
                        // Проверяем, изменились ли данные на сервере
                        let dataChanged = existingActivity.hasDataChanged(comparedTo: activityResponse)

                        // 2. Данные не изменились и активность синхронизирована - пропускаем обновление
                        if !dataChanged, existingActivity.isSynced {
                            logger.debug("Активность дня \(existingActivity.day) уже синхронизирована, данные не изменились")
                        }
                        // 3. Локальная активность имеет несинхронизированные изменения - пропускаем обновление с сервера
                        else if !existingActivity.isSynced {
                            logger
                                .info(
                                    "Локальная активность дня \(existingActivity.day) имеет несинхронизированные изменения - пропускаем обновление с сервера"
                                )
                        }
                        // 4. Сравнение дат для синхронизированных активностей
                        // (как в эталоне CustomExercisesService - сравниваем даты напрямую без проверки hasDataChanged)
                        else {
                            // Сравниваем даты напрямую (как в эталоне CustomExercisesService)
                            let localTimestamp = existingActivity.modifyDate.timeIntervalSince1970
                            let serverTimestamp = serverModifyDate.timeIntervalSince1970
                            let difference = localTimestamp - serverTimestamp

                            logger
                                .info(
                                    "Сравнение дат для активности дня \(existingActivity.day): локальная \(localTimestamp), серверная \(serverTimestamp), разница \(difference) секунд, dataChanged=\(dataChanged), isSynced=\(existingActivity.isSynced)"
                                )

                            if existingActivity.modifyDate > serverModifyDate {
                                // Локальная версия новее серверной - сохраняем локальные изменения
                                logger
                                    .info(
                                        "Локальная версия новее серверной для активности дня \(existingActivity.day) - сохраняем локальные изменения"
                                    )
                                // Не обновляем локальные данные, они уже новее
                            } else if serverModifyDate > existingActivity.modifyDate {
                                // Серверная версия новее - обновляем локальную
                                updateLocalFromServer(existingActivity, activityResponse)
                                logger
                                    .info(
                                        "Конфликт разрешен для активности дня \(existingActivity.day): локальная \(localTimestamp) vs серверная \(serverTimestamp) -> Серверная версия новее"
                                    )
                            } else {
                                // Даты равны - сохраняем локальные данные
                                logger
                                    .debug("Даты модификации равны для активности дня \(existingActivity.day), сохраняем локальные данные")
                            }
                        }
                    }
                } else {
                    // Если активность была удалена в текущем цикле синхронизации, не восстанавливаем её
                    if excludeDeletedDays.contains(activityResponse.id) {
                        logger.info("Активность дня \(activityResponse.id) была удалена в текущем цикле синхронизации, не восстанавливаем")
                    } else {
                        // Создаем новую активность с сервера
                        let newActivity = DayActivity(from: activityResponse, user: user)
                        context.insert(newActivity)
                        logger.info("Создана новая активность с сервера: день \(newActivity.day)")
                    }
                }
            }

            // Обработка удаленных на сервере элементов (только синхронизированные)
            let serverDays = Set(activities.map(\.id))
            for activity in existingActivities where !serverDays.contains(activity.day) {
                // Если активность была удалена в текущем цикле синхронизации
                if excludeDeletedDays.contains(activity.day) {
                    // Если активность помечена на удаление и была отправлена на удаление,
                    // но сервер не возвращает её - удаление подтверждено, удаляем физически
                    if activity.shouldDelete {
                        context.delete(activity)
                        logger.info("Удалена активность дня \(activity.day) - удаление подтверждено сервером")
                    } else {
                        logger.debug("Активность дня \(activity.day) была удалена в текущем цикле синхронизации, пропускаем")
                    }
                    continue
                }

                // Если активность синхронизирована и отсутствует на сервере - удаляем
                // Активности с shouldDelete = true, которые НЕ в excludeDeletedDays, не удаляем,
                // так как они могут быть восстановлены с сервера в следующей синхронизации
                if activity.isSynced {
                    context.delete(activity)
                    logger.info("Удалена активность дня \(activity.day) (отсутствует на сервере)")
                }
            }

            try context.save()
            logger.info("Серверные активности загружены")
        } catch {
            logger.error("Ошибка загрузки серверных активностей: \(error.localizedDescription)")
        }
    }
}
