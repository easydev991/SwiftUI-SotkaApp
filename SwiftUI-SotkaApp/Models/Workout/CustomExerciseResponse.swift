import Foundation

/// Модель пользовательского упражнения
struct CustomExerciseResponse: Codable, Identifiable, Hashable, Sendable {
    /// Уникальный идентификатор упражнения
    let id: String
    /// Название упражнения
    let name: String
    /// Номер стандартной картинки упражнения
    let imageId: Int
    /// Дата создания упражнения в формате ISO 8601
    let createDate: String
    /// Дата последнего изменения упражнения в формате ISO 8601
    let modifyDate: String
}
