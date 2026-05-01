import Foundation
import OSLog
import SwiftData
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

        logger
            .info(
                "[createDailyActivity] Начинаем сохранение для дня \(activity.day), count=\(activity.count ?? -1), plannedCount=\(activity.plannedCount ?? -1)"
            )

        // Проверяем, существует ли уже активность для этого дня
        let existingActivities = (try? context.fetch(FetchDescriptor<DayActivity>())) ?? []
        if let existingActivity = existingActivities.first(where: {
            $0.day == activity.day && $0.user?.id == user.id && !$0.shouldDelete
        }) {
            let trainingsSnapshot = activity.trainings.map(\.trainingReplacementSnapshot)
            logger
                .info(
                    "[createDailyActivity] Найдена существующая активность: день=\(existingActivity.day), старый count=\(existingActivity.count ?? -1), modifyDate=\(existingActivity.modifyDate)"
                )
            // Обновляем существующую активность новыми данными
            updateExistingActivity(
                existingActivity,
                with: activity,
                trainingsSnapshot: trainingsSnapshot,
                user: user
            )
            logger.info("[createDailyActivity] → Обновлена существующая активность для дня \(activity.day)")
            // Новая активность не создается - обновляем существующую
        } else {
            logger.info("[createDailyActivity] Существующая активность не найдена, создаем новую")
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
            logger.info("[createDailyActivity] → Активность для дня \(activity.day) создана локально, modifyDate=\(activity.modifyDate)")
        }

        do {
            try context.save()
            logger.info("[createDailyActivity] ✓ Context сохранен, синхронизация будет выполнена отдельно")
        } catch {
            logger.error("[createDailyActivity] ✗ Ошибка сохранения: \(error.localizedDescription)")
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
        logger.info("[markModified] Активность дня \(activity.day) отмечена как измененная, modifyDate=\(activity.modifyDate)")
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
            logger.info("[delete] Активность дня \(activity.day) помечена для удаления, modifyDate=\(activity.modifyDate)")
        } catch {
            logger.error("[delete] Ошибка удаления активности дня \(activity.day): \(error.localizedDescription)")
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
            logger.info("[set] Пропускаем настройку тренировки для дня \(day)")
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
                logger.debug("[set] Активность дня \(day) уже имеет тип \(activityType.rawValue), пропускаем")
                return
            }

            // Если активность существует с другим типом - обновляем тип активности
            existingActivity.setNonWorkoutType(activityType, user: user)

            logger.info("[set] Обновлена активность дня \(day) на тип \(activityType.rawValue), modifyDate=\(existingActivity.modifyDate)")
        } else {
            // Если активности для дня нет - создаем новую с указанным типом
            let newActivity = DayActivity.createNonWorkoutActivity(
                day: day,
                activityType: activityType,
                user: user
            )

            // Вставка активности в контекст
            context.insert(newActivity)
            logger.info("[set] Создана новая активность дня \(day) с типом \(activityType.rawValue)")
        }

        // Сохранение контекста
        do {
            try context.save()
            logger.info("[set] Активность дня \(day) сохранена")
        } catch {
            logger.error("[set] Ошибка сохранения активности дня \(day): \(error.localizedDescription)")
        }
    }

    /// Получает активность для указанного дня
    /// - Parameters:
    ///   - dayNumber: Номер дня (1-100)
    ///   - context: Контекст SwiftData
    /// - Returns: Активность дня или nil, если активность не найдена или помечена на удаление
    func getActivity(dayNumber: Int, context: ModelContext) -> DayActivity? {
        // Получаем пользователя с минимальным id для предсказуемости в тестах
        let userDescriptor = FetchDescriptor<User>(sortBy: [SortDescriptor(\.id)])
        guard let user = try? context.fetch(userDescriptor).first else {
            logger.error("Пользователь не найден для получения активности дня")
            return nil
        }

        let userId = user.id
        let predicate = #Predicate<DayActivity> { activity in
            activity.day == dayNumber && !activity.shouldDelete
        }
        let descriptor = FetchDescriptor<DayActivity>(predicate: predicate)
        let allActivities = (try? context.fetch(descriptor)) ?? []
        return allActivities.first { $0.user?.id == userId }
    }

    /// Получает тип активности для указанного дня
    /// - Parameters:
    ///   - day: Номер дня (1-100)
    ///   - context: Контекст SwiftData
    /// - Returns: Тип активности или nil, если активность не найдена
    func getActivityType(day: Int, context: ModelContext) -> DayActivityType? {
        getActivity(dayNumber: day, context: context)?.activityType
    }

    /// Получает предыдущую пройденную тренировку (исключая turbo) для текущего пользователя.
    ///
    /// Логика выбора day-based: берется запись с максимальным `day` среди подходящих.
    /// Если указан `currentDay`, учитываются только записи с `day < currentDay`.
    /// - Parameters:
    ///   - context: Контекст SwiftData
    ///   - currentDay: Текущий день программы. Если задан, поиск ограничивается днями меньше текущего.
    /// - Returns: Предыдущая пройденная тренировка или nil, если не найдена
    func getLastPassedNonTurboWorkoutActivity(context: ModelContext, currentDay: Int? = nil) -> DayActivity? {
        let userDescriptor = FetchDescriptor<User>(sortBy: [SortDescriptor(\.id)])
        guard let user = try? context.fetch(userDescriptor).first else {
            logger.error("Пользователь не найден для получения последней пройденной тренировки")
            return nil
        }

        let workoutTypeRaw = DayActivityType.workout.rawValue
        let turboTypeRaw = ExerciseExecutionType.turbo.rawValue
        let predicate = #Predicate<DayActivity> { activity in
            activity.activityTypeRaw == workoutTypeRaw &&
                activity.count != nil &&
                !activity.shouldDelete &&
                (activity.executeTypeRaw == nil || activity.executeTypeRaw != turboTypeRaw)
        }

        let descriptor = FetchDescriptor<DayActivity>(predicate: predicate)

        let activities = ((try? context.fetch(descriptor)) ?? [])
            .filter { activity in
                guard activity.user?.id == user.id else { return false }
                if let currentDay {
                    return activity.day < currentDay
                }
                return true
            }
            .sorted {
                if $0.day != $1.day {
                    return $0.day > $1.day
                }
                return $0.modifyDate > $1.modifyDate
            }

        // Логируем все найденные активности для диагностики
        logger.info("[getLastPassed] Найдено \(activities.count) пройденных тренировок (не turbo):")
        for (index, activity) in activities.enumerated() {
            let isCurrentUser = activity.user?.id == user.id
            logger
                .info(
                    "[getLastPassed]   [\(index)] день=\(activity.day), count=\(activity.count ?? 0), modifyDate=\(activity.modifyDate), createDate=\(activity.createDate), currentUser=\(isCurrentUser)"
                )
        }

        let lastActivity = activities.first

        if let activity = lastActivity {
            logger
                .info("[getLastPassed] → Возвращаем: день \(activity.day), count=\(activity.count ?? 0), modifyDate=\(activity.modifyDate)")
        } else {
            logger.info("[getLastPassed] → Пройденные тренировки для текущего пользователя не найдены")
        }

        return lastActivity
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

            logger.info("[updateComment] Обновлен комментарий для дня \(day), modifyDate=\(existingActivity.modifyDate)")
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
        logger.info("[sync] Начинаем синхронизацию активностей")

        if let user = try? context.fetch(FetchDescriptor<User>()).first, user.isOfflineOnly {
            let emptyStats = SyncStats(created: 0, updated: 0, deleted: 0)
            logger.info("[sync] Офлайн-пользователь: сетевой sync активностей пропущен")
            return SyncResult(
                type: SyncResultType(errors: nil, stats: emptyStats),
                details: SyncResultDetails(
                    progress: nil,
                    exercises: nil,
                    activities: emptyStats,
                    errors: nil
                )
            )
        }

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
    enum SyncEvent: Hashable {
        case createdOrUpdated(day: Int, server: DayResponse)
        case deleted(day: Int)
        case failed(day: Int, errorDescription: String)
    }

    // MARK: - Валидация и проверки

    /// Обновляет существующую активность данными из новой активности
    /// - Parameters:
    ///   - existing: Существующая активность, которую нужно обновить
    ///   - new: Новая активность с данными для обновления
    ///   - trainingsSnapshot: Локальный snapshot для безопасной замены relationship `trainings`
    ///   - user: Пользователь
    func updateExistingActivity(
        _ existing: DayActivity,
        with new: DayActivity,
        trainingsSnapshot: [TrainingReplacementSnapshot],
        user: User
    ) {
        logger.info("[updateExisting] Обновляем день=\(existing.day): старый count=\(existing.count ?? -1), новый count=\(new.count ?? -1)")
        logger.info("[updateExisting]   старый modifyDate=\(existing.modifyDate), createDate=\(existing.createDate)")

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

        // Безопасный replace relationship без итерации по `new.trainings` в момент мутации.
        let oldTrainings = existing.trainings
        let replacedTrainings = trainingsSnapshot.map(\.dayActivityTraining)

        if let context = existing.modelContext {
            for training in replacedTrainings where training.modelContext == nil {
                context.insert(training)
            }
        }
        existing.trainings = replacedTrainings

        if let context = existing.modelContext {
            let replacedIDs = Set(replacedTrainings.map(ObjectIdentifier.init))
            for oldTraining in oldTrainings where !replacedIDs.contains(ObjectIdentifier(oldTraining)) {
                context.delete(oldTraining)
            }
        }

        logger.info("[updateExisting] → Новый modifyDate=\(existing.modifyDate)")
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
                        } else if local.isSynced, let serverModifyDate = server.modifyDate {
                            // Проверяем, не новее ли локальная версия серверной для синхронизированных активностей
                            // Сравниваем даты (как в эталоне CustomExercisesService)
                            switch SyncDateComparisonPolicy.compare(local: local.modifyDate, server: serverModifyDate) {
                            case .localNewer:
                                logger
                                    .info(
                                        "Локальная версия новее серверной для активности дня \(day) в applySyncEvents - сохраняем локальные изменения. Локальная: \(local.modifyDate.timeIntervalSince1970), Серверная: \(serverModifyDate.timeIntervalSince1970)"
                                    )
                            case .serverNewer:
                                updateLocalFromServer(local, server)
                                updated += 1
                                logger
                                    .info(
                                        "Обновлено локально активность дня \(day) по данным сервера. Локальная: \(local.modifyDate.timeIntervalSince1970), Серверная: \(serverModifyDate.timeIntervalSince1970)"
                                    )
                            case .equal:
                                logger
                                    .debug(
                                        "Даты модификации равны для активности дня \(day) в applySyncEvents, сохраняем локальные данные"
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
        logger
            .info(
                "[updateLocalFromServer] Обновляем день=\(local.day) с сервера: server.modifyDate=\(server.modifyDate ?? .distantPast), server.count=\(server.count ?? -1)"
            )
        logger.info("[updateLocalFromServer]   локальный modifyDate ДО=\(local.modifyDate)")

        // Сохраняем текущий modifyDate чтобы не перезаписывать его серверным
        // (сервер может вернуть время в другом часовом поясе или время обработки запроса)
        let localModifyDate = local.modifyDate

        local.day = server.id
        local.activityTypeRaw = server.activityType
        local.count = server.count
        local.plannedCount = server.plannedCount
        local.executeTypeRaw = server.executeType
        local.trainingTypeRaw = server.trainType
        local.duration = server.duration
        local.comment = server.comment
        local.createDate = server.createDate ?? .now
        // Восстанавливаем локальный modifyDate - он отражает реальное время изменения пользователем
        local.modifyDate = localModifyDate

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

        logger.info("[updateLocalFromServer]   локальный modifyDate ПОСЛЕ=\(local.modifyDate)")
    }

    /// Загружает активности с сервера и обрабатывает конфликты
    /// - Parameters:
    ///   - context: Контекст SwiftData
    ///   - excludeDeletedDays: Set дней, которые были удалены в текущем цикле синхронизации
    func downloadServerActivities(context: ModelContext, excludeDeletedDays: Set<Int> = []) async throws {
        logger.info("[downloadServer] Начинаем загрузку активностей с сервера")
        do {
            guard let user = try context.fetch(FetchDescriptor<User>()).first else {
                logger.error("Не удалось получить текущего пользователя для синхронизации активностей")
                return
            }
            let activities = try await client.getDays()
            logger.info("[downloadServer] Получено \(activities.count) активностей с сервера")
            let existingActivities = try context.fetch(FetchDescriptor<DayActivity>())
                .filter { $0.user?.id == user.id }
            let existingDict = Dictionary(existingActivities.map { ($0.day, $0) }, uniquingKeysWith: { $1 })

            for activityResponse in activities {
                if let existingActivity = existingDict[activityResponse.id] {
                    let serverModifyDate = activityResponse.modifyDate ?? activityResponse.createDate ?? .now

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

                            switch SyncDateComparisonPolicy.compare(local: existingActivity.modifyDate, server: serverModifyDate) {
                            case .localNewer:
                                logger
                                    .info(
                                        "Локальная версия новее серверной для активности дня \(existingActivity.day) - сохраняем локальные изменения"
                                    )
                            case .serverNewer:
                                updateLocalFromServer(existingActivity, activityResponse)
                                logger
                                    .info(
                                        "Конфликт разрешен для активности дня \(existingActivity.day): локальная \(localTimestamp) vs серверная \(serverTimestamp) -> Серверная версия новее"
                                    )
                            case .equal:
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
                        logger
                            .info(
                                "[downloadServer] Создана новая активность с сервера: день \(newActivity.day), count=\(newActivity.count ?? -1), modifyDate=\(newActivity.modifyDate)"
                            )
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

private extension DailyActivitiesService {
    struct TrainingReplacementSnapshot {
        let count: Int?
        let typeId: Int?
        let customTypeId: String?
        let sortOrder: Int?

        var dayActivityTraining: DayActivityTraining {
            DayActivityTraining(
                count: count,
                typeId: typeId,
                customTypeId: customTypeId,
                sortOrder: sortOrder
            )
        }
    }
}

private extension DayActivityTraining {
    var trainingReplacementSnapshot: DailyActivitiesService.TrainingReplacementSnapshot {
        .init(
            count: count,
            typeId: typeId,
            customTypeId: customTypeId,
            sortOrder: sortOrder
        )
    }
}
