import Foundation

/// Группа записей журнала синхронизаций, сгруппированных по дате
struct DateGroup: Identifiable {
    /// Дата группы (без времени, только дата)
    let date: Date

    /// Идентификатор группы (используется дата)
    var id: Date {
        date
    }

    /// Записи в этой группе
    let entries: [SyncJournalEntry]

    /// Локализованный заголовок даты
    var localizedTitle: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }

    /// Группирует записи по дате
    /// - Parameter entries: Массив записей для группировки
    /// - Returns: Массив групп, отсортированных по дате (новые даты сверху)
    static func groupEntriesByDate(_ entries: [SyncJournalEntry]) -> [DateGroup] {
        guard !entries.isEmpty else { return [] }

        let calendar = Calendar.current

        // Группируем записи по дате (без времени)
        let grouped = Dictionary(grouping: entries) { entry in
            calendar.startOfDay(for: entry.startDate)
        }

        // Создаем группы и сортируем их по дате (новые сверху)
        return grouped.map { date, entries in
            // Сортируем записи внутри группы по startDate (новые сверху)
            let sortedEntries = entries.sorted { $0.startDate > $1.startDate }
            return DateGroup(date: date, entries: sortedEntries)
        }
        .sorted { $0.date > $1.date }
    }
}
