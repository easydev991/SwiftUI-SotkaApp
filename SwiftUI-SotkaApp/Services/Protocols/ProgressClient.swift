import Foundation

/// Протокол для работы с прогрессом пользователя через API
protocol ProgressClient: Sendable {
    /// Получить список прогресса пользователя
    func getProgress() async throws -> [ProgressResponse]

    /// Получить прогресс для конкретного дня
    func getProgress(day: Int) async throws -> ProgressResponse

    /// Создать новый прогресс (день передается в body)
    func createProgress(progress: ProgressRequest) async throws -> ProgressResponse

    /// Обновить существующий прогресс для конкретного дня
    func updateProgress(day: Int, progress: ProgressRequest) async throws -> ProgressResponse

    /// Удалить прогресс для конкретного дня
    func deleteProgress(day: Int) async throws

    /// Удалить фотографию определенного типа для конкретного дня
    func deletePhoto(day: Int, type: String) async throws
}
