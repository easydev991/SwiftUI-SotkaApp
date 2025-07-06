import Foundation

protocol ExerciseClient: Sendable {
    /// Загружает список пользовательских упражнений
    /// - Returns: Список пользовательских упражнений
    func getCustomExercises() async throws -> [CustomExerciseResponse]
}
