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
            createDate: Date(),
            modifyDate: Date(),
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

    /// Обновляет пользовательское упражнение (офлайн-приоритет)
    /// - Parameters:
    ///   - exercise: Упражнение для обновления
    ///   - name: Новое название
    ///   - imageId: Новый ID иконки
    ///   - context: Контекст Swift Data
    func updateCustomExercise(
        _ exercise: CustomExercise,
        name: String,
        imageId: Int,
        context: ModelContext
    ) async -> Bool {
        exercise.name = name
        exercise.imageId = imageId
        exercise.modifyDate = Date()
        exercise.isSynced = false
        do {
            try context.save()
            logger.info("Упражнение '\(name)' обновлено локально")
            logger.info("Синхронизация будет выполнена отдельно через syncCustomExercises")
            return true
        } catch {
            logger.error("Ошибка обновления упражнения: \(error.localizedDescription)")
            return false
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
        exercise.modifyDate = Date()
        exercise.isSynced = false
        try context.save()
        logger.info("Упражнение '\(exercise.name)' отмечено как измененное")
        logger.info("Синхронизация будет выполнена отдельно через syncCustomExercises")
    }

    /// Удаляет пользовательское упражнение (офлайн-приоритет)
    /// - Parameters:
    ///   - exercise: Упражнение для удаления
    ///   - context: Контекст Swift Data
    func deleteCustomExercise(
        _ exercise: CustomExercise,
        context: ModelContext
    ) throws {
        // Сохраняем ID для синхронизации удаления с сервером
        if exercise.isSynced {
            var deletedIds = UserDefaults.standard.stringArray(forKey: "deletedExerciseIds") ?? []
            deletedIds.append(exercise.id)
            UserDefaults.standard.set(deletedIds, forKey: "deletedExerciseIds")
        }

        // Всегда удаляем локально сразу для лучшего UX
        context.delete(exercise)
        try context.save()
        logger.info("Упражнение '\(exercise.name)' удалено локально")
        logger.info("Синхронизация удаления будет выполнена отдельно через syncCustomExercises")
    }

    /// Синхронизирует одно упражнение с сервером с повторными попытками
    /// - Parameters:
    ///   - exercise: Упражнение для синхронизации
    ///   - context: Контекст Swift Data
    private func syncSingleExercise(
        _ exercise: CustomExercise,
        context: ModelContext
    ) async {
        await syncSingleExerciseWithRetry(exercise, context: context, attempt: 1)
    }

    /// Конвертирует UUID в числовой ID для совместимости с сервером
    /// - Parameter uuid: UUID строка
    /// - Returns: Числовой ID как строка
    private func convertUUIDToNumericID(_ uuid: String) -> String {
        // Если это уже числовой ID, возвращаем как есть
        if uuid.allSatisfy(\.isNumber) {
            return uuid
        }

        // Конвертируем UUID в числовой ID
        // Используем хеш от UUID для получения числового значения
        let hash = abs(uuid.hashValue)
        return String(hash)
    }

    /// Синхронизирует одно упражнение с повторными попытками
    /// - Parameters:
    ///   - exercise: Упражнение для синхронизации
    ///   - context: Контекст Swift Data
    ///   - attempt: Номер текущей попытки
    private func syncSingleExerciseWithRetry(
        _ exercise: CustomExercise,
        context: ModelContext,
        attempt: Int
    ) async {
        do {
            if exercise.shouldDelete {
                // Удаляем на сервере
                let numericId = convertUUIDToNumericID(exercise.id)
                try await client.deleteCustomExercise(id: numericId)
                context.delete(exercise)
                try context.save()
                logger.info("Упражнение '\(exercise.name)' удалено с сервера")
            } else {
                // Создаем или обновляем на сервере
                let numericId = convertUUIDToNumericID(exercise.id)
                let request: CustomExerciseRequest

                // Всегда отправляем как обновление, если упражнение существует на сервере
                // (определяем по наличию числового ID, который был получен с сервера)
                request = CustomExerciseRequest(
                    id: numericId,
                    name: exercise.name,
                    imageId: exercise.imageId,
                    createDate: DateFormatterService.stringFromFullDate(exercise.createDate, format: .isoDateTimeSec),
                    modifyDate: DateFormatterService.stringFromFullDate(exercise.modifyDate, format: .isoDateTimeSec),
                    isHidden: false
                )

                let response = try await client.saveCustomExercise(id: numericId, exercise: request)

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

    /// Синхронизирует все несинхронизированные упражнения с сервером
    /// - Parameter context: Контекст Swift Data
    func syncUnsyncedExercises(context: ModelContext) async {
        guard !isSyncing else { return }
        isSyncing = true

        do {
            // Получаем все несинхронизированные упражнения
            let unsyncedExercises = try context.fetch(
                FetchDescriptor<CustomExercise>(
                    predicate: #Predicate { !$0.isSynced }
                )
            )

            logger.info("Начинаем синхронизацию \(unsyncedExercises.count) упражнений")

            // Синхронизируем каждое упражнение
            for exercise in unsyncedExercises {
                logger.info("Отправляем упражнение на сервер: \(exercise.name), ID: \(exercise.id)")
                logger
                    .info(
                        "Параметры запроса: id=\(exercise.id), name=\(exercise.name), image_id=\(exercise.imageId), create_date=\(DateFormatterService.stringFromFullDate(exercise.createDate, format: .isoDateTimeSec)), is_hidden=false"
                    )
                logger.info("modify_date=\(DateFormatterService.stringFromFullDate(exercise.modifyDate, format: .isoDateTimeSec))")
                await syncSingleExercise(exercise, context: context)
            }

            logger.info("Синхронизация упражнений завершена")
        } catch {
            logger.error("Ошибка получения несинхронизированных упражнений: \(error.localizedDescription)")
        }

        isSyncing = false
    }

    /// Синхронизирует пользовательские упражнения с сервером (двунаправленная синхронизация)
    /// - Parameter context: Контекст Swift Data
    func syncCustomExercises(context: ModelContext) async {
        guard !isLoading else { return }
        isLoading = true

        // 1. Сначала отправляем локальные изменения на сервер
        await syncUnsyncedExercises(context: context)

        // 2. Синхронизируем удаления с сервером
        await syncDeletions(context: context)

        // 3. Потом загружаем серверные изменения
        await downloadServerExercises(context: context)

        isLoading = false
    }

    /// Синхронизирует удаления с сервером
    /// - Parameter context: Контекст Swift Data
    private func syncDeletions(context _: ModelContext) async {
        // Получаем список удаленных упражнений из UserDefaults
        let deletedIds = UserDefaults.standard.stringArray(forKey: "deletedExerciseIds") ?? []

        if !deletedIds.isEmpty {
            logger.info("Синхронизируем удаления \(deletedIds.count) упражнений")

            for exerciseId in deletedIds {
                do {
                    let numericId = convertUUIDToNumericID(exerciseId)
                    try await client.deleteCustomExercise(id: numericId)
                    logger.info("Упражнение с ID \(exerciseId) удалено с сервера")
                } catch {
                    logger.error("Ошибка удаления упражнения с ID \(exerciseId): \(error.localizedDescription)")
                }
            }

            // Очищаем список удаленных упражнений
            UserDefaults.standard.removeObject(forKey: "deletedExerciseIds")
        }
    }

    /// Загружает упражнения с сервера и обрабатывает конфликты
    /// - Parameter context: Контекст Swift Data
    func downloadServerExercises(context: ModelContext) async {
        // Получаем пользователя
        guard let user = try? context.fetch(FetchDescriptor<User>()).first else { return }

        do {
            let exercises = try await client.getCustomExercises()
            let existingExercises = try context.fetch(FetchDescriptor<CustomExercise>())
                .filter { $0.user?.id == user.id }
            let existingDict = Dictionary(uniqueKeysWithValues: existingExercises.map { ($0.id, $0) })

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

    /// Обновляет локальное упражнение данными с сервера
    /// - Parameters:
    ///   - local: Локальное упражнение
    ///   - server: Данные с сервера
    private func updateLocalFromServer(_ local: CustomExercise, _ server: CustomExerciseResponse) {
        local.name = server.name
        local.imageId = server.imageId
        local.createDate = DateFormatterService.dateFromString(server.createDate, format: .serverDateTimeSec)
        local.modifyDate = DateFormatterService.dateFromString(server.modifyDate, format: .serverDateTimeSec)
        local.isSynced = true
        local.shouldDelete = false
    }
}
