import Foundation

protocol ExerciseClient: Sendable {
    /// Загружает список пользовательских упражнений
    /// - Returns: Список пользовательских упражнений
    func getCustomExercises() async throws -> [CustomExerciseResponse]

    /// Сохраняет пользовательское упражнение (создание или обновление)
    /// - Parameters:
    ///   - id: Идентификатор упражнения
    ///   - exercise: Данные упражнения для сохранения
    /// - Returns: Ответ сервера с данными упражнения
    func saveCustomExercise(id: String, exercise: CustomExerciseRequest) async throws -> CustomExerciseResponse

    /// Удаляет пользовательское упражнение
    /// - Parameter id: Идентификатор упражнения для удаления
    func deleteCustomExercise(id: String) async throws
}
