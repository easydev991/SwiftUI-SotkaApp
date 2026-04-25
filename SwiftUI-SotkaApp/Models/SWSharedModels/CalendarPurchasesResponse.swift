import Foundation

/// Ответ сервера по покупкам пользователя
struct CalendarPurchasesResponse: Codable, Hashable {
    /// Флаг покупки custom editor (для совместимости API)
    let customEditor: Bool

    /// Массив дат продлений календаря в ISO8601-совместимом формате
    let calendars: [String]
}

/// Запрос отправки продления календаря
struct CalendarPurchaseRequest: Codable, Hashable {
    /// Дата продления в ISO8601-совместимом формате
    let date: String
}
