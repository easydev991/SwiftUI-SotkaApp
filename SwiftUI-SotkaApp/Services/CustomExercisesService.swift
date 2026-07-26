import Foundation
import Observation
import OSLog
import SwiftData

@MainActor
@Observable
final class CustomExercisesService {
    @ObservationIgnored private let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier!,
        category: String(describing: CustomExercisesService.self)
    )

    private let isReadOnlyMode: Bool

    /// Инициализатор сервиса
    /// - Parameter isReadOnlyMode: Флаг read-only режима (по умолчанию из AppConfiguration)
    init(isReadOnlyMode: Bool = AppConfiguration.isReadOnlyMode) {
        self.isReadOnlyMode = isReadOnlyMode
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
            finalName = "\(name) (\(Date().formatted(date: .omitted, time: .shortened)))"
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
        } catch {
            logger.error("Ошибка удаления упражнения: \(error.localizedDescription)")
        }
    }
}
