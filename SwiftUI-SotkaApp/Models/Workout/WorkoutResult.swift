import Foundation

/// Результат выполнения тренировки
struct WorkoutResult: Equatable, Codable {
    /// Количество выполненных кругов/подходов
    let count: Int
    /// Длительность тренировки в секундах (nil, если время начала не было засечено)
    let duration: Int?
    /// Дата начала тренировки (nil, если не зафиксирована) — для записи в HealthKit
    var startDate: Date? = nil
    /// Дата завершения тренировки — момент формирования результата (nil, если не зафиксирована)
    var endDate: Date? = nil
    /// Признак прерванной тренировки (путь «Стоп»)
    var isInterrupted = false

    init(
        count: Int,
        duration: Int?,
        startDate: Date? = nil,
        endDate: Date? = nil,
        isInterrupted: Bool = false
    ) {
        self.count = count
        self.duration = duration
        self.startDate = startDate
        self.endDate = endDate
        self.isInterrupted = isInterrupted
    }

    /// Синтезированный декодер требует все ключи — старый JSON (до HealthKit-полей) падал с keyNotFound.
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.count = try container.decode(Int.self, forKey: .count)
        self.duration = try container.decodeIfPresent(Int.self, forKey: .duration)
        self.startDate = try container.decodeIfPresent(Date.self, forKey: .startDate)
        self.endDate = try container.decodeIfPresent(Date.self, forKey: .endDate)
        self.isInterrupted = try container.decodeIfPresent(Bool.self, forKey: .isInterrupted) ?? false
    }
}
