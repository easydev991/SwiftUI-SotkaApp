import Foundation

/// Протокол для работы с днями тренировок (дневник) через API
protocol DaysClient: Sendable {
    /// Получить все дни тренировок пользователя
    func getDays() async throws -> [DayResponse]

    /// Создать новый день тренировки (день передается в body)
    func createDay(_ day: DayRequest) async throws -> DayResponse

    /// Обновить существующий день тренировки
    func updateDay(model: DayRequest) async throws -> DayResponse

    /// Удалить день тренировки
    func deleteDay(day: Int) async throws
}
