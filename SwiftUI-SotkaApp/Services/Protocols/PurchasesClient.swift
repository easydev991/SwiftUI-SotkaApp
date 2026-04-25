import Foundation

/// Протокол для работы с покупками/продлениями календаря через API
protocol PurchasesClient: Sendable {
    /// Получает покупки пользователя (включая даты продлений календаря)
    func getPurchases() async throws -> CalendarPurchasesResponse

    /// Отправляет новую покупку продления календаря
    /// - Parameter date: Дата продления
    func postCalendarPurchase(date: Date) async throws -> CalendarPurchasesResponse
}
