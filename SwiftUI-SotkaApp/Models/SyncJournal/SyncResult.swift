import Foundation
import SwiftUI

typealias SyncResultType = SyncResult.SyncResultType
typealias SyncResultDetails = SyncResult.SyncResultDetails
typealias SyncStats = SyncResult.SyncResultDetails.SyncStats
typealias SyncError = SyncResult.SyncResultDetails.SyncError

/// Результат синхронизации с детальной информацией
struct SyncResult: Codable {
    /// Тип результата синхронизации
    var type: SyncResultType
    /// Детальная информация о результатах синхронизации
    var details: SyncResultDetails

    /// Проверяет, является ли результат успешным
    var isSuccess: Bool {
        type == .success
    }
}

extension SyncResult {
    /// Тип результата синхронизации
    enum SyncResultType: Int, Codable {
        case success = 0
        case partial = 1
        case error = 2

        /// Инициализатор для определения типа результата на основе ошибок и статистики
        /// - Parameters:
        ///   - errors: Список ошибок синхронизации (может быть nil или пустым)
        ///   - stats: Статистика синхронизации (может быть nil)
        /// - Returns: `.success` если нет ошибок, `.partial` если есть ошибки и статистика > 0, `.error` если есть ошибки и статистика =
        /// 0/nil
        init(errors: [SyncError]?, stats: SyncStats?) {
            let hasErrors: Bool = if let errors {
                !errors.isEmpty
            } else {
                false
            }
            let totalOps = stats?.totalOperations ?? 0

            if !hasErrors {
                self = .success
            } else if totalOps > 0 {
                self = .partial
            } else {
                self = .error
            }
        }

        var localizedTitle: String {
            switch self {
            case .success:
                String(localized: .syncResultTypeSuccess)
            case .partial:
                String(localized: .syncResultTypePartial)
            case .error:
                String(localized: .syncResultTypeError)
            }
        }

        var color: Color {
            switch self {
            case .success:
                .green
            case .partial:
                .orange
            case .error:
                .red
            }
        }

        var systemImageName: String {
            switch self {
            case .success: "checkmark"
            case .partial, .error: "exclamationmark"
            }
        }
    }

    /// Детальная информация о результатах синхронизации
    struct SyncResultDetails: Codable {
        /// Статистика синхронизации прогресса
        var progress: SyncStats?
        /// Статистика синхронизации упражнений
        var exercises: SyncStats?
        /// Статистика синхронизации активностей
        var activities: SyncStats?
        /// Список ошибок синхронизации
        var errors: [SyncError]?

        /// Краткая статистика синхронизации (форматированная строка или nil)
        var summaryText: String? {
            let combined = SyncStats(combining: progress, exercises: exercises, activities: activities)
            guard let combined else { return nil }

            var parts: [String] = []
            if combined.created > 0 {
                parts.append(String(localized: .syncResultDetailsSummaryCreated(combined.created)))
            }
            if combined.updated > 0 {
                parts.append(String(localized: .syncResultDetailsSummaryUpdated(combined.updated)))
            }
            if combined.deleted > 0 {
                parts.append(String(localized: .syncResultDetailsSummaryDeleted(combined.deleted)))
            }

            return parts.isEmpty ? nil : parts.joined(separator: ", ")
        }

        /// Проверяет наличие статистики прогресса
        var hasProgressStats: Bool {
            progress != nil
        }

        /// Проверяет наличие статистики упражнений
        var hasExercisesStats: Bool {
            exercises != nil
        }

        /// Проверяет наличие статистики активностей
        var hasActivitiesStats: Bool {
            activities != nil
        }

        /// Проверяет наличие ошибок
        var hasErrors: Bool {
            if let errors {
                !errors.isEmpty
            } else {
                false
            }
        }

        /// Элемент статистики для отображения
        struct StatisticItem: Identifiable {
            var id: UUID
            var title: String
            var stats: SyncStats

            init(id: UUID = UUID(), title: String, stats: SyncStats) {
                self.id = id
                self.title = title
                self.stats = stats
            }
        }

        /// Массив элементов статистики с данными для отображения
        var statisticsItems: [StatisticItem] {
            var items: [StatisticItem] = []

            if let progress, progress.hasData {
                items.append(StatisticItem(
                    title: String(localized: .syncJournalDetailScreenProgressTitle),
                    stats: progress
                ))
            }

            if let exercises, exercises.hasData {
                items.append(StatisticItem(
                    title: String(localized: .syncJournalDetailScreenExercisesTitle),
                    stats: exercises
                ))
            }

            if let activities, activities.hasData {
                items.append(StatisticItem(
                    title: String(localized: .syncJournalDetailScreenActivitiesTitle),
                    stats: activities
                ))
            }

            return items
        }

        /// Массив ошибок для отображения
        var displayableErrors: [SyncError] {
            if let errors {
                errors
            } else {
                []
            }
        }

        /// Секция для отображения в детальном экране
        enum Section: Identifiable {
            var id: Int {
                switch self {
                case .statistics: 1
                case .errors: 2
                }
            }

            /// Секция со статистикой
            case statistics([StatisticItem])
            /// Секция с ошибками
            case errors([SyncError])

            /// Локализованный заголовок секции
            var localizedTitle: String {
                switch self {
                case .statistics:
                    String(localized: .syncJournalDetailScreenStatisticsTitle)
                case .errors:
                    String(localized: .syncJournalDetailScreenErrorsTitle)
                }
            }
        }

        /// Массив секций для отображения в детальном экране
        var sections: [Section] {
            var result: [Section] = []

            if !statisticsItems.isEmpty {
                result.append(.statistics(statisticsItems))
            }

            if !displayableErrors.isEmpty {
                result.append(.errors(displayableErrors))
            }

            return result
        }
    }
}

extension SyncResult.SyncResultDetails {
    /// Статистика синхронизации (создано/обновлено/удалено)
    struct SyncStats: Codable {
        /// Количество созданных записей
        var created: Int
        /// Количество обновленных записей
        var updated: Int
        /// Количество удаленных записей
        var deleted: Int

        /// Memberwise initializer
        init(created: Int, updated: Int, deleted: Int) {
            self.created = created
            self.updated = updated
            self.deleted = deleted
        }

        /// Общее количество операций (создано + обновлено + удалено)
        var totalOperations: Int {
            created + updated + deleted
        }

        /// Проверяет наличие фактических данных (хотя бы одно значение > 0)
        var hasData: Bool {
            created > 0 || updated > 0 || deleted > 0
        }

        /// Объединяет статистику от нескольких сервисов
        /// - Parameters:
        ///   - progress: Статистика синхронизации прогресса
        ///   - exercises: Статистика синхронизации упражнений
        ///   - activities: Статистика синхронизации активностей
        /// - Returns: Объединенная статистика или nil, если все статистики nil/пустые
        init?(combining progress: SyncStats?, exercises: SyncStats?, activities: SyncStats?) {
            let totalCreated = (progress?.created ?? 0) + (exercises?.created ?? 0) + (activities?.created ?? 0)
            let totalUpdated = (progress?.updated ?? 0) + (exercises?.updated ?? 0) + (activities?.updated ?? 0)
            let totalDeleted = (progress?.deleted ?? 0) + (exercises?.deleted ?? 0) + (activities?.deleted ?? 0)

            if totalCreated == 0, totalUpdated == 0, totalDeleted == 0 {
                return nil
            }

            self.init(created: totalCreated, updated: totalUpdated, deleted: totalDeleted)
        }

        /// Элемент статистики для отображения
        enum Item: Identifiable {
            var id: Self { self }
            case created
            case updated
            case deleted

            /// Локализованный заголовок элемента
            var localizedTitle: String {
                switch self {
                case .created:
                    String(localized: .syncJournalDetailScreenCreated)
                case .updated:
                    String(localized: .syncJournalDetailScreenUpdated)
                case .deleted:
                    String(localized: .syncJournalDetailScreenDeleted)
                }
            }
        }

        /// Массив элементов статистики с ненулевыми значениями (в порядке: created, updated, deleted)
        var items: [Item] {
            var result: [Item] = []

            if created > 0 {
                result.append(.created)
            }
            if updated > 0 {
                result.append(.updated)
            }
            if deleted > 0 {
                result.append(.deleted)
            }

            return result
        }

        /// Получает значение для указанного элемента
        /// - Parameter item: Элемент статистики
        /// - Returns: Значение для указанного элемента
        func value(for item: Item) -> Int {
            switch item {
            case .created:
                created
            case .updated:
                updated
            case .deleted:
                deleted
            }
        }
    }

    /// Ошибка синхронизации
    struct SyncError: Codable, Identifiable {
        /// Уникальный идентификатор ошибки
        var id: UUID
        /// Тип ошибки
        var type: String
        /// Локализованное сообщение об ошибке
        var message: String
        /// Тип сущности (progress/exercise/activity)
        var entityType: String?
        /// ID сущности
        var entityId: String?

        init(id: UUID = UUID(), type: String, message: String, entityType: String? = nil, entityId: String? = nil) {
            self.id = id
            self.type = type
            self.message = message
            self.entityType = entityType
            self.entityId = entityId
        }

        /// Описание сущности для отображения (entityType с опциональным entityId)
        var description: String? {
            guard let entityType else { return nil }
            if let entityId {
                return "\(entityType) (\(entityId))"
            } else {
                return entityType
            }
        }

        enum CodingKeys: String, CodingKey {
            case id
            case type
            case message
            case entityType
            case entityId
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
            self.type = try container.decode(String.self, forKey: .type)
            self.message = try container.decode(String.self, forKey: .message)
            self.entityType = try container.decodeIfPresent(String.self, forKey: .entityType)
            self.entityId = try container.decodeIfPresent(String.self, forKey: .entityId)
        }
    }
}
