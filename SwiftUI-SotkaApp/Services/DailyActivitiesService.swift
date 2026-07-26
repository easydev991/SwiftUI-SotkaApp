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

    init() {}

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
            logger.info("Комментарий для дня \(day) сохранен локально")
        } catch {
            logger.error("Ошибка сохранения комментария для дня \(day): \(error.localizedDescription)")
        }
    }
}

private extension DailyActivitiesService {
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
