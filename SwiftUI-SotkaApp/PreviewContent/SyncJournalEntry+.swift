#if DEBUG
import Foundation

extension SyncJournalEntry {
    /// Успешная синхронизация с полной статистикой
    static var previewSuccessWithDetails: SyncJournalEntry {
        let startDate = Date().addingTimeInterval(-3600)
        let endDate = Date()
        let progressStats = SyncStats(created: 5, updated: 3, deleted: 1)
        let exercisesStats = SyncStats(created: 2, updated: 1, deleted: 0)
        let details = SyncResultDetails(progress: progressStats, exercises: exercisesStats, activities: nil, errors: nil)
        return SyncJournalEntry(
            startDate: startDate,
            endDate: endDate,
            result: .success,
            details: details
        )
    }

    /// Частичная синхронизация с ошибками
    static var previewPartialWithErrors: SyncJournalEntry {
        let startDate = Date().addingTimeInterval(-1800)
        let endDate = Date()
        let progressStats = SyncStats(created: 2, updated: 1, deleted: 0)
        let error = SyncError(
            type: "network",
            message: "Ошибка сети при синхронизации",
            entityType: "progress",
            entityId: "1"
        )
        let details = SyncResultDetails(progress: progressStats, exercises: nil, activities: nil, errors: [error])
        return SyncJournalEntry(
            startDate: startDate,
            endDate: endDate,
            result: .partial,
            details: details
        )
    }

    /// Ошибка синхронизации
    static var previewError: SyncJournalEntry {
        let startDate = Date().addingTimeInterval(-900)
        let endDate = Date()
        let error = SyncError(
            type: "server",
            message: "Сервер недоступен",
            entityType: nil,
            entityId: nil
        )
        let details = SyncResultDetails(progress: nil, exercises: nil, activities: nil, errors: [error])
        return SyncJournalEntry(
            startDate: startDate,
            endDate: endDate,
            result: .error,
            details: details
        )
    }

    /// В процессе синхронизации
    static var previewInProgress: SyncJournalEntry {
        let startDate = Date().addingTimeInterval(-120)
        let progressStats = SyncStats(created: 1, updated: 0, deleted: 0)
        let details = SyncResultDetails(progress: progressStats, exercises: nil, activities: nil, errors: nil)
        return SyncJournalEntry(
            startDate: startDate,
            endDate: nil,
            result: .success,
            details: details
        )
    }

    /// Без деталей
    static var previewWithoutDetails: SyncJournalEntry {
        let startDate = Date().addingTimeInterval(-7200)
        let endDate = Date().addingTimeInterval(-3600)
        return SyncJournalEntry(
            startDate: startDate,
            endDate: endDate,
            result: .success,
            details: nil
        )
    }

    /// С полной статистикой (progress, exercises, activities)
    static var previewWithFullStats: SyncJournalEntry {
        let startDate = Date().addingTimeInterval(-3600)
        let endDate = Date()
        let progressStats = SyncStats(created: 5, updated: 3, deleted: 1)
        let exercisesStats = SyncStats(created: 2, updated: 1, deleted: 0)
        let activitiesStats = SyncStats(created: 1, updated: 2, deleted: 1)
        let details = SyncResultDetails(
            progress: progressStats,
            exercises: exercisesStats,
            activities: activitiesStats,
            errors: nil
        )
        return SyncJournalEntry(
            startDate: startDate,
            endDate: endDate,
            result: .success,
            details: details
        )
    }

    /// С ошибками (несколько ошибок)
    static var previewWithMultipleErrors: SyncJournalEntry {
        let startDate = Date().addingTimeInterval(-1800)
        let endDate = Date()
        let progressStats = SyncStats(created: 2, updated: 1, deleted: 0)
        let error1 = SyncError(
            type: "network",
            message: "Ошибка сети при синхронизации прогресса",
            entityType: "progress",
            entityId: "1"
        )
        let error2 = SyncError(
            type: "validation",
            message: "Ошибка валидации данных",
            entityType: "exercise",
            entityId: "ex1"
        )
        let details = SyncResultDetails(
            progress: progressStats,
            exercises: nil,
            activities: nil,
            errors: [error1, error2]
        )
        return SyncJournalEntry(
            startDate: startDate,
            endDate: endDate,
            result: .partial,
            details: details
        )
    }

    /// С частичными данными (только exercises)
    static var previewWithPartialData: SyncJournalEntry {
        let startDate = Date().addingTimeInterval(-2700)
        let endDate = Date()
        let exercisesStats = SyncStats(created: 3, updated: 0, deleted: 0)
        let details = SyncResultDetails(
            progress: nil,
            exercises: exercisesStats,
            activities: nil,
            errors: nil
        )
        return SyncJournalEntry(
            startDate: startDate,
            endDate: endDate,
            result: .success,
            details: details
        )
    }

    /// Только ошибки без статистики
    static var previewErrorsOnly: SyncJournalEntry {
        let startDate = Date().addingTimeInterval(-600)
        let endDate = Date()
        let error = SyncError(
            type: "server",
            message: "Сервер недоступен",
            entityType: nil,
            entityId: nil
        )
        let details = SyncResultDetails(
            progress: nil,
            exercises: nil,
            activities: nil,
            errors: [error]
        )
        return SyncJournalEntry(
            startDate: startDate,
            endDate: endDate,
            result: .error,
            details: details
        )
    }
}
#endif
