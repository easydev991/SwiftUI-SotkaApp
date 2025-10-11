import Foundation
import SwiftData

/// Прогресс пользователя
@Model
final class Progress {
    /// Совпадает с номером дня
    var id: Int
    var pullUps: Int?
    var pushUps: Int?
    var squats: Int?
    var weight: Float?
    var isSynced = false
    var shouldDelete = false
    var lastModified = Date.now

    init(
        id: Int,
        pullUps: Int? = nil,
        pushUps: Int? = nil,
        squats: Int? = nil,
        weight: Float? = nil
    ) {
        self.id = id
        self.pullUps = pullUps
        self.pushUps = pushUps
        self.squats = squats
        self.weight = weight
    }

    /// Проверяет, заполнены ли все результаты прогресса
    var isFilled: Bool {
        guard let pullUps, let pushUps, let squats, let weight else {
            return false
        }
        return [pullUps, pushUps, squats].allSatisfy { $0 > 0 } && weight > 0
    }
}
