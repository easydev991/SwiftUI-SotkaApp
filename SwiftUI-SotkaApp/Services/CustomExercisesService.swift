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
        do {
            let exercises = try await client.getCustomExercises()
            // Получаем существующие упражнения из базы
            let existingExercises = try context.fetch(FetchDescriptor<CustomExercise>())
            // Создаем словарь существующих упражнений для быстрого поиска
            let existingDict = Dictionary(uniqueKeysWithValues: existingExercises.map { ($0.id, $0) })
            // Обрабатываем упражнения с сервера
            for exerciseResponse in exercises {
                if let existingExercise = existingDict[exerciseResponse.id] {
                    // Обновляем существующее упражнение
                    existingExercise.name = exerciseResponse.name
                    existingExercise.imageId = exerciseResponse.imageId
                    existingExercise.modifyDate = DateFormatterService.dateFromString(
                        exerciseResponse.modifyDate,
                        format: .serverDateTimeSec
                    )
                } else {
                    // Создаем новое упражнение
                    let newExercise = CustomExercise(from: exerciseResponse)
                    context.insert(newExercise)
                }
            }
            // Удаляем упражнения, которых нет на сервере
            let serverIds = Set(exercises.map(\.id))
            for existingExercise in existingExercises {
                if !serverIds.contains(existingExercise.id) {
                    context.delete(existingExercise)
                }
            }
            try context.save()
            logger.info("Синхронизация пользовательских упражнений завершена успешно")
        } catch {
            logger.error("Ошибка синхронизации пользовательских упражнений: \(error.localizedDescription)")
        }
        isLoading = false
    }
}
