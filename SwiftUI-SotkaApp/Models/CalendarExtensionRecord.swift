import Foundation
import SwiftData

/// Локальная запись продления календаря
@Model
final class CalendarExtensionRecord {
    /// Дата продления
    var date: Date

    /// Флаг синхронизации с сервером
    var isSynced: Bool

    /// Флаг удаления на сервере (зарезервирован для дальнейших сценариев)
    var shouldDelete: Bool

    /// Дата последнего изменения записи
    var lastModified: Date

    /// Пользователь-владелец записи
    var user: User?

    init(
        date: Date,
        isSynced: Bool = false,
        shouldDelete: Bool = false,
        lastModified: Date = .now,
        user: User? = nil
    ) {
        self.date = date
        self.isSynced = isSynced
        self.shouldDelete = shouldDelete
        self.lastModified = lastModified
        self.user = user
    }
}

/// DTO локальной записи продления для безопасной передачи между слоями
struct CalendarExtensionRecordDTO: Codable, Hashable {
    var date: Date

    init(date: Date) {
        self.date = date
    }

    init(record: CalendarExtensionRecord) {
        self.date = record.date
    }
}
