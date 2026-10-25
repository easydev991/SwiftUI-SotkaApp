import Foundation
import SwiftData

/// Локальная запись продления календаря
@Model
final class CalendarExtensionRecord {
    /// Дата продления
    var date: Date

    /// Флаг удаления (резерв; записи удаляются физически)
    var shouldDelete: Bool

    /// Пользователь-владелец записи
    var user: User?

    init(
        date: Date,
        shouldDelete: Bool = false,
        user: User? = nil
    ) {
        self.date = date
        self.shouldDelete = shouldDelete
        self.user = user
    }
}
