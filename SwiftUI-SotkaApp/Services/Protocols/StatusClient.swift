import Foundation

protocol StatusClient: Sendable {
    /// Стартует сотку с нуля
    ///
    /// При расхождении даты старта на сайте и в приложении нужно делать синхронизацию
    /// - Parameter date: Дата начала программы
    /// - Returns: Модель текущего дня
    func start(date: String) async throws -> CurrentRunResponse

    /// Запрашивает данные о текущем дне
    /// - Returns: Модель текущего дня
    func current() async throws -> CurrentRunResponse
}
