import Foundation
import SwiftData

/// Запись в журнале синхронизаций
@Model
final class SyncJournalEntry: Identifiable, Hashable {
    var id: UUID
    var startDate: Date
    var endDate: Date?
    var result: SyncResultType

    /// Детальная информация о результатах синхронизации (хранится как Data для SwiftData)
    private var detailsData: Data?

    @Relationship(inverse: \User.syncJournalEntries) var user: User?

    init(
        id: UUID = UUID(),
        startDate: Date,
        endDate: Date? = nil,
        result: SyncResultType,
        details: SyncResultDetails? = nil,
        user: User? = nil
    ) {
        self.id = id
        self.startDate = startDate
        self.endDate = endDate
        self.result = result
        self.detailsData = nil
        self.user = user
        self.details = details
    }

    /// Детальная информация о результатах синхронизации
    var details: SyncResultDetails? {
        get {
            guard let detailsData else { return nil }
            return try? JSONDecoder().decode(SyncResultDetails.self, from: detailsData)
        }
        set {
            if let newValue {
                detailsData = try? JSONEncoder().encode(newValue)
            } else {
                detailsData = nil
            }
        }
    }

    var duration: TimeInterval? {
        guard let endDate else { return nil }
        return endDate.timeIntervalSince(startDate)
    }
}
