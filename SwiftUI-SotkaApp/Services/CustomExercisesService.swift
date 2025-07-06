import Foundation
import Observation
import OSLog
import SwiftData
import SWUtils

@MainActor
@Observable
final class CustomExercisesService {
    private let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier!,
        category: String(describing: CustomExercisesService.self)
    )

    private(set) var isLoading = false

    /// Синхронизирует пользовательские упражнения с сервером
    /// - Parameters:
    ///   - context: Контекст Swift Data
    ///   - client: Клиент для работы с API
    func syncCustomExercises(
        context: ModelContext,
        client: ExerciseClient
    ) async {
        guard !isLoading else { return }
        isLoading = true

        // Получаем пользователя
        guard let user = try? context.fetch(FetchDescriptor<User>()).first else {
            isLoading = false
            return
        }

        do {
            let exercises = try await client.getCustomExercises()
            // Получаем существующие упражнения пользователя
            let existingExercises = try context.fetch(
                FetchDescriptor<CustomExercise>()
            ).filter { $0.user?.id == user.id }
            // Создаем словарь существующих упражнений для быстрого поиска
            let existingDict = Dictionary(uniqueKeysWithValues: existingExercises.map { ($0.id, $0) })

            for exerciseResponse in exercises {
                if let existingExercise = existingDict[exerciseResponse.id] {
                    existingExercise.name = exerciseResponse.name
                    existingExercise.imageId = exerciseResponse.imageId
                    existingExercise.createDate = DateFormatterService.dateFromString(
                        exerciseResponse.createDate,
                        format: .serverDateTimeSec
                    )
                    existingExercise.modifyDate = DateFormatterService.dateFromString(
                        exerciseResponse.modifyDate,
                        format: .serverDateTimeSec
                    )
                } else {
                    // Создаем новое упражнение
                    let newExercise = CustomExercise(from: exerciseResponse, user: user)
                    context.insert(newExercise)
                }
            }

            // Удаляем упражнения, которых больше нет на сервере
            let serverIds = Set(exercises.map(\.id))
            for exercise in existingExercises where !serverIds.contains(exercise.id) {
                context.delete(exercise)
            }
            try context.save()
            logger.info("Пользовательские упражнения успешно синхронизированы")
        } catch {
            logger.error("Ошибка синхронизации пользовательских упражнений: \(error.localizedDescription)")
        }
        isLoading = false
    }
}
