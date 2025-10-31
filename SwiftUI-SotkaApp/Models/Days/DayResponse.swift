import Foundation

/// Модель ответа сервера для дня тренировки
struct DayResponse: Codable, Sendable, Hashable, Equatable {
    /// День (1..100)
    let id: Int
    /// Тип активности
    let activityType: Int?
    /// Количество кругов/повторов за день
    let count: Int?
    /// Плановое количество повторений (если поддерживается сервером)
    let plannedCount: Int?
    /// Тип выполнения
    let executeType: Int?
    /// Тип тренировки
    let trainType: Int?
    /// Массив тренировок
    let trainings: [Training]?
    /// ISO дата создания
    let createDate: String?
    /// ISO дата изменения
    let modifyDate: String?
    /// Продолжительность (в минутах/секундах — как на сервере)
    let duration: Int?
    /// Произвольный комментарий к дню
    let comment: String?
}

extension DayResponse {
    /// Тренировка внутри дня в ответе сервера
    struct Training: Codable, Sendable, Hashable, Equatable {
        /// Идентификатор стандартного типа упражнения (если задан)
        let typeId: Int?
        /// Идентификатор пользовательского типа упражнения (если задан)
        let customTypeId: String?
        /// Количество повторений/подходов по элементу
        let count: Int?
        /// Порядок следования в списке тренировок
        let sortOrder: Int?
    }
}
