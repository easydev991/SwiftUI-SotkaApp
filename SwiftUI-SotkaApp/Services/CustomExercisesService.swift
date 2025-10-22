import Foundation
import Observation
import OSLog
import SwiftData
import SWNetwork
import SWUtils

@MainActor
@Observable
final class CustomExercisesService {
    private let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier!,
        category: String(describing: CustomExercisesService.self)
    )

    private(set) var isLoading = false
    private(set) var isSyncing = false

    /// Максимальное количество попыток синхронизации при ошибке
    /// Стандартная практика для предотвращения бесконечных циклов
    private let maxRetryAttempts = 3
    /// Задержка между попытками (в секундах)
    /// Используется фиксированная задержка для простоты (можно заменить на экспоненциальную)
    private let retryDelay: TimeInterval = 2.0

    /// Клиент для работы с API
    private let client: ExerciseClient

    /// Инициализатор сервиса
    /// - Parameter client: Клиент для работы с API
    init(client: ExerciseClient) {
        self.client = client
    }

    // MARK: - Snapshot & Sync Events (для конкурентной синхронизации без ModelContext)

    /// Создает новое пользовательское упражнение (офлайн-приоритет)
    /// - Parameters:
    ///   - name: Название упражнения
    ///   - imageId: ID иконки упражнения
    ///   - context: Контекст Swift Data
    func createCustomExercise(
        name: String,
        imageId: Int,
        context: ModelContext
    ) {
        guard let user = try? context.fetch(FetchDescriptor<User>()).first else {
            logger.error("Пользователь не найден для создания упражнения")
            return
        }

        var finalName = name
        // Проверяем на конфликт имен локально (если упражнение не помечено на удаление)
        let existingExercises = (try? context.fetch(FetchDescriptor<CustomExercise>())) ?? []
        if existingExercises.contains(where: { $0.name == name && $0.user?.id == user.id && !$0.shouldDelete }) {
            finalName = "\(name) (\(DateFormatterService.stringFromFullDate(Date(), format: .mediumTime)))"
            logger.warning("Конфликт имени упражнения: '\(name)'. Изменено на '\(finalName)'.")
        }

        // Генерируем уникальный числовой ID для локального создания
        // Используем timestamp + случайное число для уникальности
        let timestamp = Int(Date().timeIntervalSince1970)
        let randomSuffix = Int.random(in: 1000 ... 9999)
        let exerciseId = "\(timestamp)\(randomSuffix)"
        let exercise = CustomExercise(
            id: exerciseId,
            name: finalName,
            imageId: imageId,
            createDate: .now,
            modifyDate: .now,
            user: user
        )
        context.insert(exercise)
        do {
            try context.save()
            logger.info("Упражнение '\(finalName)' создано локально с ID: \(exerciseId)")
            logger.info("Синхронизация будет выполнена отдельно через syncCustomExercises")
        } catch {
            logger.error("Ошибка сохранения упражнения: \(error.localizedDescription)")
        }
    }

    /// Отмечает пользовательское упражнение как измененное (офлайн-приоритет)
    /// - Parameters:
    ///   - exercise: Упражнение для отметки как измененное
    ///   - context: Контекст Swift Data
    func markCustomExerciseAsModified(
        _ exercise: CustomExercise,
        context: ModelContext
    ) throws {
        exercise.modifyDate = .now
        exercise.isSynced = false
        try context.save()
        logger.info("Упражнение '\(exercise.name)' отмечено как измененное")
        logger.info("Синхронизация будет выполнена отдельно через syncCustomExercises")
    }

    /// Удаляет пользовательское упражнение (офлайн-приоритет)
    /// - Parameters:
    ///   - exercise: Упражнение для удаления
    ///   - context: Контекст Swift Data
    func deleteCustomExercise(_ exercise: CustomExercise, context: ModelContext) {
        // Мягкое удаление: скрываем в UI и синхронизируем удаление с сервером
        exercise.shouldDelete = true
        exercise.isSynced = false
        exercise.modifyDate = .now
        do {
            try context.save()
            logger.info("Упражнение '\(exercise.name)' помечено для удаления локально")
            logger.info("Синхронизация удаления будет выполнена через syncCustomExercises")
        } catch {
            logger.error("Ошибка удаления упражнения: \(error.localizedDescription)")
        }
    }

    /// Синхронизирует пользовательские упражнения с сервером (двунаправленная синхронизация)
    /// - Parameter context: Контекст Swift Data
    func syncCustomExercises(context: ModelContext) async {
        guard !isLoading else { return }
        isLoading = true

        // 1. Сначала отправляем локальные изменения на сервер
        await syncUnsyncedExercises(context: context)

        // 2. Потом загружаем серверные изменения
        await downloadServerExercises(context: context)

        isLoading = false
    }
}

private extension CustomExercisesService {
    /// Снимок локального упражнения для безопасной передачи в конкурентные задачи без доступа к ModelContext
    struct ExerciseSnapshot: Sendable, Hashable {
        let id: String
        let name: String
        let imageId: Int
        let createDate: Date
        let modifyDate: Date
        let isSynced: Bool
        let shouldDelete: Bool
        let userId: Int?
    }

    /// Результат конкурентной операции синхронизации одного упражнения
    enum SyncEvent: Sendable, Hashable {
        case createdOrUpdated(id: String, server: CustomExerciseResponse)
        case deleted(id: String)
        case failed(id: String, errorDescription: String)
    }

    /// Синхронизирует одно упражнение с повторными попытками
    /// - Parameters:
    ///   - exercise: Упражнение для синхронизации
    ///   - context: Контекст Swift Data
    ///   - attempt: Номер текущей попытки
    func syncSingleExerciseWithRetry(
        _ exercise: CustomExercise,
        context: ModelContext,
        attempt: Int
    ) async {
        do {
            if exercise.shouldDelete {
                // Удаляем на сервере
                try await client.deleteCustomExercise(id: exercise.id)
                context.delete(exercise)
                try context.save()
                logger.info("Упражнение '\(exercise.name)' удалено с сервера")
            } else {
                // Создаем или обновляем на сервере
                let request: CustomExerciseRequest

                // Всегда отправляем как обновление, если упражнение существует на сервере
                // (определяем по наличию числового ID, который был получен с сервера)
                request = CustomExerciseRequest(
                    id: exercise.id,
                    name: exercise.name,
                    imageId: exercise.imageId,
                    createDate: DateFormatterService.stringFromFullDate(exercise.createDate, format: .isoDateTimeSec),
                    modifyDate: DateFormatterService.stringFromFullDate(exercise.modifyDate, format: .isoDateTimeSec),
                    isHidden: false
                )

                let response = try await client.saveCustomExercise(id: exercise.id, exercise: request)

                // Обновляем локальные данные из ответа сервера
                exercise.name = response.name
                exercise.imageId = response.imageId
                exercise.createDate = DateFormatterService.dateFromString(response.createDate, format: .serverDateTimeSec)
                exercise.modifyDate = DateFormatterService.dateFromString(response.modifyDate, format: .serverDateTimeSec)
                exercise.isSynced = true
                exercise.shouldDelete = false

                try context.save()
                logger.info("Упражнение '\(exercise.name)' синхронизировано с сервером")
            }
        } catch {
            logger.error("Ошибка синхронизации упражнения '\(exercise.name)': \(error)")
            logger.error("Детали ошибки: \(error.localizedDescription)")
            if let apiError = error as? APIError {
                logger.error("API Error: \(apiError)")
            }
            let limit = maxRetryAttempts
            let delay = retryDelay
            if attempt < limit {
                logger
                    .warning(
                        "Ошибка синхронизации упражнения '\(exercise.name)' (попытка \(attempt)/\(limit)): \(error.localizedDescription). Повтор через \(delay)с"
                    )
                try? await Task.sleep(nanoseconds: UInt64(retryDelay * 1_000_000_000))
                await syncSingleExerciseWithRetry(exercise, context: context, attempt: attempt + 1)
            } else {
                logger
                    .error(
                        "Ошибка синхронизации упражнения '\(exercise.name)' после \(limit) попыток: \(error.localizedDescription). Продолжаем работу локально"
                    )
            }
        }
    }

    /// Загружает упражнения с сервера и обрабатывает конфликты
    /// - Parameter context: Контекст Swift Data
    func downloadServerExercises(context: ModelContext) async {
        do {
            guard let user = try context.fetch(FetchDescriptor<User>()).first else {
                logger.error("Не удалось получить текущего пользователя для синхронизации упражнений")
                return
            }
            let exercises = try await client.getCustomExercises()
            let existingExercises = try context.fetch(FetchDescriptor<CustomExercise>())
                .filter { $0.user?.id == user.id }
            let existingDict = Dictionary(existingExercises.map { ($0.id, $0) }, uniquingKeysWith: { $1 })

            for exerciseResponse in exercises {
                if let existingExercise = existingDict[exerciseResponse.id] {
                    let serverModifyDate = DateFormatterService.dateFromString(
                        exerciseResponse.modifyDate, format: .serverDateTimeSec
                    )

                    // Обработка специального случая: элемент удален на сервере, но изменен локально
                    if existingExercise.shouldDelete {
                        // Локальное упражнение помечено для удаления - не восстанавливаем его
                        logger.info("Локальное упражнение '\(existingExercise.name)' помечено для удаления, пропускаем")
                    } else if existingExercise.modifyDate > serverModifyDate {
                        // Локальная версия новее серверной - сохраняем локальные изменения
                        logger.info("Локальная версия новее серверной для '\(existingExercise.name)' - сохраняем локальные изменения")
                        // Не обновляем локальные данные, они уже новее
                    } else if serverModifyDate > existingExercise.modifyDate {
                        // Серверная версия новее - обновляем локальную (только для синхронизированных упражнений)
                        updateLocalFromServer(existingExercise, exerciseResponse)
                        logger
                            .info(
                                "Конфликт разрешен для упражнения \(existingExercise.id): локальная \(existingExercise.modifyDate) vs серверная \(serverModifyDate) -> Серверная версия новее"
                            )
                    } else {
                        // Локальная версия новее - уже отправлена на сервер
                        logger.info("Локальная версия новее серверной для \(existingExercise.name)")
                    }
                } else {
                    // Создаем новое упражнение с сервера
                    let newExercise = CustomExercise(from: exerciseResponse, user: user)
                    context.insert(newExercise)
                    logger.info("Создано новое упражнение с сервера: '\(newExercise.name)'")
                }
            }

            // Обработка удаленных на сервере элементов (только синхронизированные)
            let serverIds = Set(exercises.map(\.id))
            for exercise in existingExercises where !serverIds.contains(exercise.id) && exercise.isSynced {
                if exercise.shouldDelete {
                    // Уже помечено для удаления - удаляем локально
                    context.delete(exercise)
                    logger.info("Удалено упражнение '\(exercise.name)' (отсутствует на сервере)")
                } else {
                    // Не помечено для удаления - помечаем для удаления
                    exercise.shouldDelete = true
                    exercise.isSynced = false
                    logger.info("Помечено для удаления упражнение '\(exercise.name)' (отсутствует на сервере)")
                }
            }

            try context.save()
            logger.info("Серверные упражнения загружены")
        } catch {
            logger.error("Ошибка загрузки серверных упражнений: \(error.localizedDescription)")
        }
    }

    /// Синхронизирует все несинхронизированные упражнения с сервером
    /// - Parameter context: Контекст Swift Data
    func syncUnsyncedExercises(context: ModelContext) async {
        guard !isSyncing else {
            logger.info("Синхронизация упражнений уже выполняется")
            return
        }
        isSyncing = true
        logger.info("Начинаем синхронизацию упражнений")

        do {
            // 1) Готовим снимки данных (без доступа к контексту в задачах)
            let snapshots = try makeExerciseSnapshotsForSync(context: context)
            logger.info("Начинаем синхронизацию \(snapshots.count) упражнений")

            // 2) Параллельные сетевые операции (без ModelContext)
            let eventsById = await runSyncTasks(snapshots: snapshots, client: client)

            // 3) Применяем результаты к ModelContext единым этапом
            applySyncEvents(eventsById, context: context)

            logger.info("Синхронизация упражнений завершена")
        } catch {
            logger.error("Ошибка получения несинхронизированных упражнений: \(error.localizedDescription)")
        }

        isSyncing = false
    }

    /// Обновляет локальное упражнение данными с сервера
    /// - Parameters:
    ///   - local: Локальное упражнение
    ///   - server: Данные с сервера
    func updateLocalFromServer(_ local: CustomExercise, _ server: CustomExerciseResponse) {
        local.name = server.name
        local.imageId = server.imageId
        local.createDate = DateFormatterService.dateFromString(server.createDate, format: .serverDateTimeSec)
        local.modifyDate = DateFormatterService.dateFromString(server.modifyDate, format: .serverDateTimeSec)
        local.isSynced = true
        local.shouldDelete = false
    }

    /// Формирует список снимков локальных упражнений, требующих синхронизации
    func makeExerciseSnapshotsForSync(context: ModelContext) throws -> [ExerciseSnapshot] {
        // Берем все несинхронизированные, а также те, что помечены на удаление
        let toSync = try context.fetch(
            FetchDescriptor<CustomExercise>(
                predicate: #Predicate { !$0.isSynced || $0.shouldDelete }
            )
        )
        let snapshots: [ExerciseSnapshot] = toSync.map { exercise in
            ExerciseSnapshot(
                id: exercise.id,
                name: exercise.name,
                imageId: exercise.imageId,
                createDate: exercise.createDate,
                modifyDate: exercise.modifyDate,
                isSynced: exercise.isSynced,
                shouldDelete: exercise.shouldDelete,
                userId: exercise.user?.id
            )
        }
        return snapshots
    }

    /// Выполняет конкурентные сетевые операции синхронизации и собирает результаты без доступа к `ModelContext`
    func runSyncTasks(
        snapshots: [ExerciseSnapshot],
        client: ExerciseClient
    ) async -> [String: SyncEvent] {
        await withTaskGroup(of: (String, SyncEvent).self) { group in
            for snapshot in snapshots {
                // Локальные отладочные логи перед выполнением задач
                let createDateStr = DateFormatterService.stringFromFullDate(snapshot.createDate, format: .isoDateTimeSec)
                let modifyDateStr = DateFormatterService.stringFromFullDate(snapshot.modifyDate, format: .isoDateTimeSec)
                logger.info("Отправляем упражнение на сервер: \(snapshot.name), ID: \(snapshot.id)")
                logger
                    .info(
                        "Параметры запроса: id=\(snapshot.id), name=\(snapshot.name), image_id=\(snapshot.imageId), create_date=\(createDateStr), is_hidden=false"
                    )
                logger.info("modify_date=\(modifyDateStr)")

                group.addTask { [snapshot] in
                    let event = await self.performNetworkSync(for: snapshot, client: client)
                    return (snapshot.id, event)
                }
            }

            var eventsById: [String: SyncEvent] = [:]
            for await (id, event) in group {
                eventsById[id] = event
            }
            return eventsById
        }
    }

    /// Выполняет сетевую синхронизацию одного снимка без доступа к `ModelContext`
    func performNetworkSync(
        for snapshot: ExerciseSnapshot,
        client: ExerciseClient
    ) async -> SyncEvent {
        do {
            if snapshot.shouldDelete {
                try await client.deleteCustomExercise(id: snapshot.id)
                return .deleted(id: snapshot.id)
            } else {
                let request = CustomExerciseRequest(
                    id: snapshot.id,
                    name: snapshot.name,
                    imageId: snapshot.imageId,
                    createDate: DateFormatterService.stringFromFullDate(snapshot.createDate, format: .isoDateTimeSec),
                    modifyDate: DateFormatterService.stringFromFullDate(snapshot.modifyDate, format: .isoDateTimeSec),
                    isHidden: false
                )
                let response = try await client.saveCustomExercise(id: snapshot.id, exercise: request)
                return .createdOrUpdated(id: snapshot.id, server: response)
            }
        } catch {
            return .failed(id: snapshot.id, errorDescription: error.localizedDescription)
        }
    }

    /// Применяет результаты синхронизации к локальному хранилищу в одном месте
    func applySyncEvents(_ events: [String: SyncEvent], context: ModelContext) {
        do {
            // Загружаем текущего пользователя и все упражнения заранее
            guard let user = try context.fetch(FetchDescriptor<User>()).first else {
                logger.error("Пользователь не найден при применении результатов синхронизации")
                return
            }
            let existing = try context.fetch(FetchDescriptor<CustomExercise>()).filter { $0.user?.id == user.id }
            let dict = Dictionary(existing.map { ($0.id, $0) }, uniquingKeysWith: { $1 })

            for (id, event) in events {
                switch event {
                case let .createdOrUpdated(_, server):
                    if let local = dict[id] {
                        // LWW — берем серверную модификацию, так как она возвращается с актуальной датой
                        updateLocalFromServer(local, server)
                        logger.info("Обновлено локально упражнение '\(local.name)' по данным сервера")
                    } else {
                        // Создаем новое локально по ответу сервера
                        let newExercise = CustomExercise(from: server, user: user)
                        context.insert(newExercise)
                        logger.info("Создано локально упражнение '\(newExercise.name)' из ответа сервера")
                    }
                case .deleted:
                    if let local = dict[id] {
                        context.delete(local)
                        logger.info("Удалено локально упражнение с ID \(id)")
                    } else {
                        // Если локально уже отсутствует — ничего не делаем
                        logger.debug("Удаление: локальное упражнение с ID \(id) не найдено")
                    }
                case let .failed(_, errorDescription):
                    logger.error("Ошибка синхронизации упражнения с ID \(id): \(errorDescription)")
                }
            }

            try context.save()
        } catch {
            logger.error("Ошибка применения результатов синхронизации: \(error.localizedDescription)")
        }
    }
}
