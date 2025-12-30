import Foundation

/// Результат выполнения тренировки
struct WorkoutResult: Equatable, Codable {
    /// Количество выполненных кругов/подходов
    let count: Int
    /// Длительность тренировки в секундах (nil, если время начала не было засечено)
    let duration: Int?
}
