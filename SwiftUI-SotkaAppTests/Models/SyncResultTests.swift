import Foundation
@testable import SwiftUI_SotkaApp
import Testing

@Suite("Тесты для SyncResult")
struct SyncResultTests {
    @Test("Создает результат успешной синхронизации")
    func createsSuccessResult() throws {
        let stats = SyncStats(created: 5, updated: 3, deleted: 1)
        let details = SyncResultDetails(progress: stats, exercises: nil, activities: nil, errors: nil)
        let result = SyncResult(type: .success, details: details)

        #expect(result.type == .success)
        let progressStats = try #require(result.details.progress)
        #expect(progressStats.created == 5)
        #expect(progressStats.updated == 3)
        #expect(progressStats.deleted == 1)
    }

    @Test("Создает результат с ошибками")
    func createsResultWithErrors() throws {
        let error = SyncError(
            type: "network",
            message: "Network error",
            entityType: "progress",
            entityId: "1"
        )
        let details = SyncResultDetails(progress: nil, exercises: nil, activities: nil, errors: [error])
        let result = SyncResult(type: .error, details: details)

        #expect(result.type == .error)
        let errors = try #require(result.details.errors)
        #expect(errors.count == 1)
        let firstError = try #require(errors.first)
        #expect(firstError.type == "network")
        #expect(firstError.message == "Network error")
    }

    @Test("Создает результат частичной синхронизации")
    func createsPartialResult() throws {
        let progressStats = SyncStats(created: 2, updated: 1, deleted: 0)
        let exerciseStats = SyncStats(created: 0, updated: 0, deleted: 0)
        let error = SyncError(type: "validation", message: "Validation error", entityType: "exercise", entityId: "ex1")
        let details = SyncResultDetails(progress: progressStats, exercises: exerciseStats, activities: nil, errors: [error])
        let result = SyncResult(type: .partial, details: details)

        #expect(result.type == .partial)
        #expect(result.details.progress != nil)
        #expect(result.details.exercises != nil)
        let errors = try #require(result.details.errors)
        #expect(errors.count == 1)
    }

    @Test("Сериализует и десериализует SyncResult")
    func serializesAndDeserializesSyncResult() throws {
        let progressStats = SyncStats(created: 5, updated: 3, deleted: 1)
        let exerciseStats = SyncStats(created: 2, updated: 1, deleted: 0)
        let error = SyncError(type: "network", message: "Network error", entityType: "progress", entityId: "1")
        let details = SyncResultDetails(progress: progressStats, exercises: exerciseStats, activities: nil, errors: [error])
        let original = SyncResult(type: .partial, details: details)

        let encoder = JSONEncoder()
        let data = try encoder.encode(original)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(SyncResult.self, from: data)

        #expect(decoded.type == .partial)
        let decodedProgress = try #require(decoded.details.progress)
        #expect(decodedProgress.created == 5)
        #expect(decodedProgress.updated == 3)
        #expect(decodedProgress.deleted == 1)
        let decodedExercises = try #require(decoded.details.exercises)
        #expect(decodedExercises.created == 2)
        let decodedErrors = try #require(decoded.details.errors)
        #expect(decodedErrors.count == 1)
        let firstDecodedError = try #require(decodedErrors.first)
        #expect(firstDecodedError.type == "network")
    }

    @Test("Создает SyncStats с нулевыми значениями")
    func createsSyncStatsWithZeroValues() {
        let stats = SyncStats(created: 0, updated: 0, deleted: 0)
        #expect(stats.created == 0)
        #expect(stats.updated == 0)
        #expect(stats.deleted == 0)
    }

    @Test("Создает SyncError с опциональными полями")
    func createsSyncErrorWithOptionalFields() {
        let error1 = SyncError(type: "error", message: "Error message", entityType: nil, entityId: nil)
        #expect(error1.type == "error")
        #expect(error1.message == "Error message")
        #expect(error1.entityType == nil)
        #expect(error1.entityId == nil)

        let error2 = SyncError(type: "error", message: "Error message", entityType: "progress", entityId: "1")
        #expect(error2.entityType == "progress")
        #expect(error2.entityId == "1")
    }

    @Test("Создает SyncResultDetails с частичными данными")
    func createsSyncResultDetailsWithPartialData() {
        let progressStats = SyncStats(created: 1, updated: 0, deleted: 0)
        let details = SyncResultDetails(progress: progressStats, exercises: nil, activities: nil, errors: nil)

        #expect(details.progress != nil)
        #expect(details.exercises == nil)
        #expect(details.activities == nil)
        #expect(details.errors == nil)
    }

    @Test("Вычисляет totalOperations для SyncStats")
    func calculatesTotalOperations() {
        let stats1 = SyncStats(created: 5, updated: 3, deleted: 1)
        #expect(stats1.totalOperations == 9)

        let stats2 = SyncStats(created: 0, updated: 0, deleted: 0)
        #expect(stats2.totalOperations == 0)

        let stats3 = SyncStats(created: 10, updated: 0, deleted: 0)
        #expect(stats3.totalOperations == 10)
    }

    @Test("Определяет тип результата как success когда нет ошибок")
    func determinesSuccessTypeWhenNoErrors() {
        let stats = SyncStats(created: 5, updated: 3, deleted: 1)
        let resultType = SyncResultType(errors: [], stats: stats)
        #expect(resultType == .success)
    }

    @Test("Определяет тип результата как success когда ошибки nil и статистика есть")
    func determinesSuccessTypeWhenErrorsNilAndStatsExist() {
        let stats = SyncStats(created: 5, updated: 3, deleted: 1)
        let resultType = SyncResultType(errors: nil, stats: stats)
        #expect(resultType == .success)
    }

    @Test("Определяет тип результата как partial когда есть ошибки и статистика > 0")
    func determinesPartialTypeWhenErrorsExistAndStatsGreaterThanZero() {
        let stats = SyncStats(created: 5, updated: 3, deleted: 1)
        let errors = [SyncError(type: "network", message: "Network error", entityType: "progress", entityId: "1")]
        let resultType = SyncResultType(errors: errors, stats: stats)
        #expect(resultType == .partial)
    }

    @Test("Определяет тип результата как error когда есть ошибки и статистика = 0")
    func determinesErrorTypeWhenErrorsExistAndStatsZero() {
        let stats = SyncStats(created: 0, updated: 0, deleted: 0)
        let errors = [SyncError(type: "network", message: "Network error", entityType: "progress", entityId: "1")]
        let resultType = SyncResultType(errors: errors, stats: stats)
        #expect(resultType == .error)
    }

    @Test("Определяет тип результата как error когда есть ошибки и статистика nil")
    func determinesErrorTypeWhenErrorsExistAndStatsNil() {
        let errors = [SyncError(type: "network", message: "Network error", entityType: "progress", entityId: "1")]
        let resultType = SyncResultType(errors: errors, stats: nil)
        #expect(resultType == .error)
    }

    @Test("Определяет тип результата как partial когда есть ошибки и статистика > 0 (частичные операции)")
    func determinesPartialTypeWhenErrorsExistAndPartialOperations() {
        let stats = SyncStats(created: 2, updated: 0, deleted: 0)
        let errors = [SyncError(type: "network", message: "Network error", entityType: "progress", entityId: "1")]
        let resultType = SyncResultType(errors: errors, stats: stats)
        #expect(resultType == .partial)
    }

    @Test("Объединяет статистику от нескольких сервисов")
    func combinesStatsFromMultipleServices() throws {
        let progressStats = SyncStats(created: 5, updated: 3, deleted: 1)
        let exercisesStats = SyncStats(created: 2, updated: 1, deleted: 0)
        let activitiesStats = SyncStats(created: 1, updated: 2, deleted: 1)

        let combined = try #require(SyncStats(combining: progressStats, exercises: exercisesStats, activities: activitiesStats))

        #expect(combined.created == 8)
        #expect(combined.updated == 6)
        #expect(combined.deleted == 2)
        #expect(combined.totalOperations == 16)
    }

    @Test("Возвращает nil при объединении пустых статистик")
    func returnsNilWhenCombiningEmptyStats() {
        let progressStats = SyncStats(created: 0, updated: 0, deleted: 0)
        let exercisesStats = SyncStats(created: 0, updated: 0, deleted: 0)
        let activitiesStats = SyncStats(created: 0, updated: 0, deleted: 0)

        let combined = SyncStats(combining: progressStats, exercises: exercisesStats, activities: activitiesStats)

        #expect(combined == nil)
    }

    @Test("Возвращает nil при объединении nil статистик")
    func returnsNilWhenCombiningNilStats() {
        let combined = SyncStats(combining: nil, exercises: nil, activities: nil)

        #expect(combined == nil)
    }

    @Test("Объединяет статистику с частичными nil значениями")
    func combinesStatsWithPartialNilValues() throws {
        let progressStats = SyncStats(created: 5, updated: 3, deleted: 1)
        let exercisesStats: SyncStats? = nil
        let activitiesStats = SyncStats(created: 2, updated: 0, deleted: 0)

        let combined = try #require(SyncStats(combining: progressStats, exercises: exercisesStats, activities: activitiesStats))

        #expect(combined.created == 7)
        #expect(combined.updated == 3)
        #expect(combined.deleted == 1)
    }

    @Test("Объединяет статистику когда только один сервис имеет данные")
    func combinesStatsWhenOnlyOneServiceHasData() throws {
        let progressStats = SyncStats(created: 10, updated: 5, deleted: 2)
        let exercisesStats: SyncStats? = nil
        let activitiesStats: SyncStats? = nil

        let combined = try #require(SyncStats(combining: progressStats, exercises: exercisesStats, activities: activitiesStats))

        #expect(combined.created == 10)
        #expect(combined.updated == 5)
        #expect(combined.deleted == 2)
    }

    @Test("Форматирует краткую статистику со всеми значениями")
    func formatsSummaryTextWithAllValues() throws {
        let progressStats = SyncStats(created: 5, updated: 3, deleted: 1)
        let exercisesStats = SyncStats(created: 2, updated: 1, deleted: 0)
        let activitiesStats = SyncStats(created: 0, updated: 0, deleted: 0)
        let details = SyncResultDetails(progress: progressStats, exercises: exercisesStats, activities: activitiesStats, errors: nil)

        let summaryText = try #require(details.summaryText)
        #expect(summaryText.contains("7"))
        #expect(summaryText.contains("4"))
        #expect(summaryText.contains("1"))
    }

    @Test("Отображает только ненулевые значения в краткой статистике")
    func showsOnlyNonZeroValuesInSummary() throws {
        let progressStats = SyncStats(created: 5, updated: 0, deleted: 0)
        let details = SyncResultDetails(progress: progressStats, exercises: nil, activities: nil, errors: nil)

        let summaryText = try #require(details.summaryText)
        #expect(summaryText.contains("5"))
        #expect(!summaryText.contains("0"))
    }

    @Test("Возвращает nil для краткой статистики при нулевой статистике")
    func returnsNilForSummaryWhenStatsAreZero() {
        let progressStats = SyncStats(created: 0, updated: 0, deleted: 0)
        let exercisesStats = SyncStats(created: 0, updated: 0, deleted: 0)
        let activitiesStats = SyncStats(created: 0, updated: 0, deleted: 0)
        let details = SyncResultDetails(progress: progressStats, exercises: exercisesStats, activities: activitiesStats, errors: nil)

        #expect(details.summaryText == nil)
    }

    @Test("Возвращает nil для краткой статистики при nil статистике")
    func returnsNilForSummaryWhenStatsAreNil() {
        let details = SyncResultDetails(progress: nil, exercises: nil, activities: nil, errors: nil)

        #expect(details.summaryText == nil)
    }

    @Test("Проверяет наличие статистики прогресса")
    func checksHasProgressStats() {
        let progressStats = SyncStats(created: 5, updated: 3, deleted: 1)
        let details = SyncResultDetails(progress: progressStats, exercises: nil, activities: nil, errors: nil)

        #expect(details.hasProgressStats)
    }

    @Test("Проверяет отсутствие статистики прогресса")
    func checksNoProgressStats() {
        let details = SyncResultDetails(progress: nil, exercises: nil, activities: nil, errors: nil)

        #expect(!details.hasProgressStats)
    }

    @Test("Проверяет наличие статистики упражнений")
    func checksHasExercisesStats() {
        let exercisesStats = SyncStats(created: 2, updated: 1, deleted: 0)
        let details = SyncResultDetails(progress: nil, exercises: exercisesStats, activities: nil, errors: nil)

        #expect(details.hasExercisesStats)
    }

    @Test("Проверяет отсутствие статистики упражнений")
    func checksNoExercisesStats() {
        let details = SyncResultDetails(progress: nil, exercises: nil, activities: nil, errors: nil)

        #expect(!details.hasExercisesStats)
    }

    @Test("Проверяет наличие статистики активностей")
    func checksHasActivitiesStats() {
        let activitiesStats = SyncStats(created: 1, updated: 2, deleted: 1)
        let details = SyncResultDetails(progress: nil, exercises: nil, activities: activitiesStats, errors: nil)

        #expect(details.hasActivitiesStats)
    }

    @Test("Проверяет отсутствие статистики активностей")
    func checksNoActivitiesStats() {
        let details = SyncResultDetails(progress: nil, exercises: nil, activities: nil, errors: nil)

        #expect(!details.hasActivitiesStats)
    }

    @Test("Проверяет наличие ошибок")
    func checksHasErrors() {
        let error = SyncError(type: "network", message: "Network error", entityType: "progress", entityId: "1")
        let details = SyncResultDetails(progress: nil, exercises: nil, activities: nil, errors: [error])

        #expect(details.hasErrors)
    }

    @Test("Проверяет отсутствие ошибок")
    func checksNoErrors() {
        let details = SyncResultDetails(progress: nil, exercises: nil, activities: nil, errors: nil)

        #expect(!details.hasErrors)
    }

    @Test("Проверяет отсутствие ошибок при пустом массиве")
    func checksNoErrorsWithEmptyArray() {
        let details = SyncResultDetails(progress: nil, exercises: nil, activities: nil, errors: [])

        #expect(!details.hasErrors)
    }

    @Test("Проверяет наличие данных в SyncStats когда есть созданные записи")
    func checksHasDataWhenCreatedGreaterThanZero() {
        let stats = SyncStats(created: 5, updated: 0, deleted: 0)

        #expect(stats.hasData)
    }

    @Test("Проверяет наличие данных в SyncStats когда есть обновленные записи")
    func checksHasDataWhenUpdatedGreaterThanZero() {
        let stats = SyncStats(created: 0, updated: 3, deleted: 0)

        #expect(stats.hasData)
    }

    @Test("Проверяет наличие данных в SyncStats когда есть удаленные записи")
    func checksHasDataWhenDeletedGreaterThanZero() {
        let stats = SyncStats(created: 0, updated: 0, deleted: 2)

        #expect(stats.hasData)
    }

    @Test("Проверяет наличие данных в SyncStats когда есть все типы операций")
    func checksHasDataWhenAllOperationsGreaterThanZero() {
        let stats = SyncStats(created: 5, updated: 3, deleted: 1)

        #expect(stats.hasData)
    }

    @Test("Проверяет отсутствие данных в SyncStats когда все значения равны нулю")
    func checksNoDataWhenAllValuesAreZero() {
        let stats = SyncStats(created: 0, updated: 0, deleted: 0)

        #expect(!stats.hasData)
    }

    @Test("Создает массив статистики только для элементов с данными")
    func createsStatisticsItemsOnlyForItemsWithData() throws {
        let progressStats = SyncStats(created: 5, updated: 3, deleted: 1)
        let exercisesStats = SyncStats(created: 0, updated: 0, deleted: 0)
        let activitiesStats = SyncStats(created: 2, updated: 0, deleted: 0)
        let details = SyncResultDetails(progress: progressStats, exercises: exercisesStats, activities: activitiesStats, errors: nil)

        let items = details.statisticsItems
        #expect(items.count == 2)
        let progressItem = try #require(items.first { $0.title == String(localized: .syncJournalDetailScreenProgressTitle) })
        #expect(progressItem.stats.created == 5)
        let activitiesItem = try #require(items.first { $0.title == String(localized: .syncJournalDetailScreenActivitiesTitle) })
        #expect(activitiesItem.stats.created == 2)
    }

    @Test("Возвращает пустой массив статистики когда все значения равны нулю")
    func returnsEmptyStatisticsItemsWhenAllValuesAreZero() {
        let progressStats = SyncStats(created: 0, updated: 0, deleted: 0)
        let exercisesStats = SyncStats(created: 0, updated: 0, deleted: 0)
        let activitiesStats = SyncStats(created: 0, updated: 0, deleted: 0)
        let details = SyncResultDetails(progress: progressStats, exercises: exercisesStats, activities: activitiesStats, errors: nil)

        #expect(details.statisticsItems.isEmpty)
    }

    @Test("Возвращает пустой массив статистики когда все статистики nil")
    func returnsEmptyStatisticsItemsWhenAllStatsAreNil() {
        let details = SyncResultDetails(progress: nil, exercises: nil, activities: nil, errors: nil)

        #expect(details.statisticsItems.isEmpty)
    }

    @Test("Создает массив статистики со всеми элементами когда все имеют данные")
    func createsStatisticsItemsWithAllItemsWhenAllHaveData() {
        let progressStats = SyncStats(created: 5, updated: 3, deleted: 1)
        let exercisesStats = SyncStats(created: 2, updated: 1, deleted: 0)
        let activitiesStats = SyncStats(created: 1, updated: 2, deleted: 1)
        let details = SyncResultDetails(progress: progressStats, exercises: exercisesStats, activities: activitiesStats, errors: nil)

        let items = details.statisticsItems
        #expect(items.count == 3)
    }

    @Test("Создает массив ошибок для отображения")
    func createsDisplayableErrorsArray() {
        let error1 = SyncError(type: "network", message: "Network error", entityType: "progress", entityId: "1")
        let error2 = SyncError(type: "validation", message: "Validation error", entityType: "exercise", entityId: "ex1")
        let details = SyncResultDetails(progress: nil, exercises: nil, activities: nil, errors: [error1, error2])

        let errors = details.displayableErrors
        #expect(errors.count == 2)
        #expect(errors[0].message == "Network error")
        #expect(errors[1].message == "Validation error")
    }

    @Test("Возвращает пустой массив ошибок когда ошибок нет")
    func returnsEmptyDisplayableErrorsWhenNoErrors() {
        let details = SyncResultDetails(progress: nil, exercises: nil, activities: nil, errors: nil)

        #expect(details.displayableErrors.isEmpty)
    }

    @Test("Возвращает пустой массив ошибок когда массив ошибок пустой")
    func returnsEmptyDisplayableErrorsWhenErrorsArrayIsEmpty() {
        let details = SyncResultDetails(progress: nil, exercises: nil, activities: nil, errors: [])

        #expect(details.displayableErrors.isEmpty)
    }

    @Test("SyncError имеет уникальный id")
    func syncErrorHasUniqueId() {
        let error1 = SyncError(type: "network", message: "Network error", entityType: "progress", entityId: "1")
        let error2 = SyncError(type: "validation", message: "Validation error", entityType: "exercise", entityId: "ex1")

        #expect(error1.id != error2.id)
    }

    @Test("Создает секцию statistics с данными")
    func createsStatisticsSectionWithData() throws {
        let progressStats = SyncStats(created: 5, updated: 3, deleted: 1)
        let details = SyncResultDetails(progress: progressStats, exercises: nil, activities: nil, errors: nil)

        let sections = details.sections
        #expect(sections.count == 1)
        let section = try #require(sections.first)
        if case let .statistics(items) = section {
            #expect(items.count == 1)
        } else {
            Issue.record("Ожидалась секция statistics")
        }
    }

    @Test("Создает секцию errors с данными")
    func createsErrorsSectionWithData() throws {
        let error = SyncError(type: "network", message: "Network error", entityType: "progress", entityId: "1")
        let details = SyncResultDetails(progress: nil, exercises: nil, activities: nil, errors: [error])

        let sections = details.sections
        #expect(sections.count == 1)
        let section = try #require(sections.first)
        if case let .errors(errors) = section {
            #expect(errors.count == 1)
        } else {
            Issue.record("Ожидалась секция errors")
        }
    }

    @Test("Создает обе секции когда есть статистика и ошибки")
    func createsBothSectionsWhenStatisticsAndErrorsExist() {
        let progressStats = SyncStats(created: 5, updated: 3, deleted: 1)
        let error = SyncError(type: "network", message: "Network error", entityType: "progress", entityId: "1")
        let details = SyncResultDetails(progress: progressStats, exercises: nil, activities: nil, errors: [error])

        let sections = details.sections
        #expect(sections.count == 2)
    }

    @Test("Возвращает пустой массив секций когда нет данных")
    func returnsEmptySectionsWhenNoData() {
        let details = SyncResultDetails(progress: nil, exercises: nil, activities: nil, errors: nil)

        #expect(details.sections.isEmpty)
    }

    @Test("Возвращает пустой массив секций когда все статистики пустые и ошибок нет")
    func returnsEmptySectionsWhenAllStatsEmptyAndNoErrors() {
        let progressStats = SyncStats(created: 0, updated: 0, deleted: 0)
        let details = SyncResultDetails(progress: progressStats, exercises: nil, activities: nil, errors: nil)

        #expect(details.sections.isEmpty)
    }

    @Test("Section statistics имеет правильный localizedTitle")
    func statisticsSectionHasCorrectLocalizedTitle() throws {
        let progressStats = SyncStats(created: 5, updated: 3, deleted: 1)
        let details = SyncResultDetails(progress: progressStats, exercises: nil, activities: nil, errors: nil)

        let sections = details.sections
        let statisticsSection = sections.first(where: \.isStatistics)
        let section = try #require(statisticsSection)
        let title = section.localizedTitle
        let expectedTitle = String(localized: .syncJournalDetailScreenStatisticsTitle)
        #expect(title == expectedTitle)
    }

    @Test("Section errors имеет правильный localizedTitle")
    func errorsSectionHasCorrectLocalizedTitle() throws {
        let error = SyncError(type: "network", message: "Network error", entityType: "progress", entityId: "1")
        let details = SyncResultDetails(progress: nil, exercises: nil, activities: nil, errors: [error])

        let sections = details.sections
        let errorsSection = sections.first(where: \.isErrors)
        let section = try #require(errorsSection)
        let title = section.localizedTitle
        let expectedTitle = String(localized: .syncJournalDetailScreenErrorsTitle)
        #expect(title == expectedTitle)
    }

    @Test("SyncError description возвращает описание с entityType и entityId")
    func syncErrorDescriptionReturnsDescriptionWithEntityTypeAndId() throws {
        let error = SyncError(type: "network", message: "Network error", entityType: "progress", entityId: "1")
        let description = try #require(error.description)
        #expect(description == "progress (1)")
    }

    @Test("SyncError description возвращает описание только с entityType когда нет entityId")
    func syncErrorDescriptionReturnsDescriptionWithEntityTypeOnly() throws {
        let error = SyncError(type: "network", message: "Network error", entityType: "progress", entityId: nil)
        let description = try #require(error.description)
        #expect(description == "progress")
    }

    @Test("SyncError description возвращает nil когда нет entityType")
    func syncErrorDescriptionReturnsNilWhenNoEntityType() {
        let error = SyncError(type: "network", message: "Network error", entityType: nil, entityId: "1")
        #expect(error.description == nil)
    }

    @Test("SyncError description возвращает nil когда нет entityType и entityId")
    func syncErrorDescriptionReturnsNilWhenNoEntityTypeAndId() {
        let error = SyncError(type: "network", message: "Network error", entityType: nil, entityId: nil)
        #expect(error.description == nil)
    }

    @Test("SyncStats.items возвращает все три кейса когда все значения больше нуля")
    func syncStatsItemsReturnsAllThreeCasesWhenAllValuesGreaterThanZero() {
        let stats = SyncStats(created: 5, updated: 3, deleted: 1)
        let items = stats.items

        #expect(items.count == 3)
        #expect(items[0] == SyncStats.Item.created)
        #expect(items[1] == SyncStats.Item.updated)
        #expect(items[2] == SyncStats.Item.deleted)
    }

    @Test("SyncStats.items возвращает только created когда только created больше нуля")
    func syncStatsItemsReturnsOnlyCreatedWhenOnlyCreatedGreaterThanZero() {
        let stats = SyncStats(created: 5, updated: 0, deleted: 0)
        let items = stats.items

        #expect(items.count == 1)
        #expect(items[0] == SyncStats.Item.created)
    }

    @Test("SyncStats.items возвращает только updated когда только updated больше нуля")
    func syncStatsItemsReturnsOnlyUpdatedWhenOnlyUpdatedGreaterThanZero() {
        let stats = SyncStats(created: 0, updated: 3, deleted: 0)
        let items = stats.items

        #expect(items.count == 1)
        #expect(items[0] == SyncStats.Item.updated)
    }

    @Test("SyncStats.items возвращает только deleted когда только deleted больше нуля")
    func syncStatsItemsReturnsOnlyDeletedWhenOnlyDeletedGreaterThanZero() {
        let stats = SyncStats(created: 0, updated: 0, deleted: 2)
        let items = stats.items

        #expect(items.count == 1)
        #expect(items[0] == SyncStats.Item.deleted)
    }

    @Test("SyncStats.items возвращает пустой массив когда все значения равны нулю")
    func syncStatsItemsReturnsEmptyArrayWhenAllValuesAreZero() {
        let stats = SyncStats(created: 0, updated: 0, deleted: 0)
        let items = stats.items

        #expect(items.isEmpty)
    }

    @Test("SyncStats.items возвращает created и updated когда только они больше нуля")
    func syncStatsItemsReturnsCreatedAndUpdatedWhenOnlyTheyGreaterThanZero() {
        let stats = SyncStats(created: 5, updated: 3, deleted: 0)
        let items = stats.items

        #expect(items.count == 2)
        #expect(items[0] == SyncStats.Item.created)
        #expect(items[1] == SyncStats.Item.updated)
    }

    @Test("SyncStats.items возвращает created и deleted когда только они больше нуля")
    func syncStatsItemsReturnsCreatedAndDeletedWhenOnlyTheyGreaterThanZero() {
        let stats = SyncStats(created: 5, updated: 0, deleted: 2)
        let items = stats.items

        #expect(items.count == 2)
        #expect(items[0] == SyncStats.Item.created)
        #expect(items[1] == SyncStats.Item.deleted)
    }

    @Test("SyncStats.items возвращает updated и deleted когда только они больше нуля")
    func syncStatsItemsReturnsUpdatedAndDeletedWhenOnlyTheyGreaterThanZero() {
        let stats = SyncStats(created: 0, updated: 3, deleted: 2)
        let items = stats.items

        #expect(items.count == 2)
        #expect(items[0] == SyncStats.Item.updated)
        #expect(items[1] == SyncStats.Item.deleted)
    }

    @Test("SyncStats.Item.created имеет правильный localizedTitle")
    func syncStatsItemCreatedHasCorrectLocalizedTitle() {
        let item = SyncStats.Item.created
        let localizedTitle = item.localizedTitle
        let expectedTitle = String(localized: .syncJournalDetailScreenCreated)

        #expect(localizedTitle == expectedTitle)
    }

    @Test("SyncStats.Item.updated имеет правильный localizedTitle")
    func syncStatsItemUpdatedHasCorrectLocalizedTitle() {
        let item = SyncStats.Item.updated
        let localizedTitle = item.localizedTitle
        let expectedTitle = String(localized: .syncJournalDetailScreenUpdated)

        #expect(localizedTitle == expectedTitle)
    }

    @Test("SyncStats.Item.deleted имеет правильный localizedTitle")
    func syncStatsItemDeletedHasCorrectLocalizedTitle() {
        let item = SyncStats.Item.deleted
        let localizedTitle = item.localizedTitle
        let expectedTitle = String(localized: .syncJournalDetailScreenDeleted)

        #expect(localizedTitle == expectedTitle)
    }
}

extension SyncResultDetails.Section {
    /// Проверяет, является ли секция секцией статистики
    var isStatistics: Bool {
        if case .statistics = self {
            return true
        }
        return false
    }

    /// Проверяет, является ли секция секцией ошибок
    var isErrors: Bool {
        if case .errors = self {
            return true
        }
        return false
    }
}
