import Foundation
import SwiftData
@testable import SwiftUI_SotkaApp
import Testing

@Suite("Тесты для SyncJournalEntry")
struct SyncJournalEntryTests {
    @Test("Создает запись с минимальными данными")
    @MainActor
    func createsEntryWithMinimalData() throws {
        let container = try ModelContainer(
            for: SyncJournalEntry.self,
            User.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = container.mainContext

        let startDate = Date()
        let entry = SyncJournalEntry(
            startDate: startDate,
            result: .success
        )
        context.insert(entry)
        try context.save()

        let fetched = try context.fetch(FetchDescriptor<SyncJournalEntry>())
        let savedEntry = try #require(fetched.first)
        #expect(fetched.count == 1)
        #expect(savedEntry.startDate == startDate)
        #expect(savedEntry.result == .success)
        #expect(savedEntry.endDate == nil)
    }

    @Test("Создает запись со связью с User")
    @MainActor
    func createsEntryWithUserRelationship() throws {
        let container = try ModelContainer(
            for: SyncJournalEntry.self,
            User.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = container.mainContext

        let user = User(id: 1, userName: "testuser", fullName: "Test User", email: "test@example.com")
        context.insert(user)

        let entry = SyncJournalEntry(
            startDate: Date(),
            result: .success,
            user: user
        )
        context.insert(entry)
        try context.save()

        let savedEntry = try #require(context.fetch(FetchDescriptor<SyncJournalEntry>()).first)
        let savedUser = try #require(savedEntry.user)
        #expect(savedUser.id == 1)
        #expect(savedUser.userName == "testuser")
    }

    @Test("Сохраняет запись в SwiftData")
    @MainActor
    func savesEntryToSwiftData() throws {
        let container = try ModelContainer(
            for: SyncJournalEntry.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = container.mainContext

        let startDate = Date()
        let endDate = Date().addingTimeInterval(10)
        let entry = SyncJournalEntry(
            startDate: startDate,
            endDate: endDate,
            result: .error
        )
        context.insert(entry)
        try context.save()

        let fetched = try context.fetch(FetchDescriptor<SyncJournalEntry>())
        let savedEntry = try #require(fetched.first)
        #expect(savedEntry.startDate == startDate)
        let savedEndDate = try #require(savedEntry.endDate)
        #expect(savedEndDate == endDate)
        #expect(savedEntry.result == .error)
    }

    @Test("duration вычисляет разницу между startDate и endDate")
    @MainActor
    func durationCalculatesDifference() throws {
        let container = try ModelContainer(
            for: SyncJournalEntry.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = container.mainContext

        let startDate = Date()
        let endDate = startDate.addingTimeInterval(15.5)
        let entry = SyncJournalEntry(
            startDate: startDate,
            endDate: endDate,
            result: .success
        )
        context.insert(entry)
        try context.save()

        let savedEntry = try #require(context.fetch(FetchDescriptor<SyncJournalEntry>()).first)
        let duration = try #require(savedEntry.duration)
        #expect(duration == 15.5)
    }

    @Test("duration возвращает nil если endDate отсутствует")
    @MainActor
    func durationReturnsNilWhenEndDateMissing() throws {
        let container = try ModelContainer(
            for: SyncJournalEntry.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = container.mainContext

        let entry = SyncJournalEntry(
            startDate: Date(),
            result: .success
        )
        context.insert(entry)
        try context.save()

        let savedEntry = try #require(context.fetch(FetchDescriptor<SyncJournalEntry>()).first)
        #expect(savedEntry.duration == nil)
    }

    @Test("Поддерживает все типы результатов")
    @MainActor
    func supportsAllResultTypes() throws {
        let container = try ModelContainer(
            for: SyncJournalEntry.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = container.mainContext

        let entry1 = SyncJournalEntry(startDate: Date(), result: .success)
        let entry2 = SyncJournalEntry(startDate: Date(), result: .partial)
        let entry3 = SyncJournalEntry(startDate: Date(), result: .error)

        context.insert(entry1)
        context.insert(entry2)
        context.insert(entry3)
        try context.save()

        let fetched = try context.fetch(FetchDescriptor<SyncJournalEntry>())
        #expect(fetched.count == 3)
        let results = fetched.map(\.result)
        #expect(results.contains(.success))
        #expect(results.contains(.partial))
        #expect(results.contains(.error))
    }

    @Test("Сохраняет и читает details как nil")
    @MainActor
    func savesAndReadsDetailsAsNil() throws {
        let container = try ModelContainer(
            for: SyncJournalEntry.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = container.mainContext

        let entry = SyncJournalEntry(
            startDate: Date(),
            result: .success,
            details: nil
        )
        context.insert(entry)
        try context.save()

        let fetched = try context.fetch(FetchDescriptor<SyncJournalEntry>())
        let savedEntry = try #require(fetched.first)
        #expect(savedEntry.details == nil)
    }

    @Test("Сохраняет и читает details с полными данными")
    @MainActor
    func savesAndReadsDetailsWithFullData() throws {
        let container = try ModelContainer(
            for: SyncJournalEntry.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = container.mainContext

        let details = SyncResultDetails(
            progress: SyncStats(created: 1, updated: 2, deleted: 0),
            exercises: SyncStats(created: 3, updated: 1, deleted: 1),
            activities: SyncStats(created: 0, updated: 5, deleted: 0),
            errors: [
                SyncError(type: "network", message: "Ошибка сети", entityType: "progress", entityId: "123")
            ]
        )

        let entry = SyncJournalEntry(
            startDate: Date(),
            result: .partial,
            details: details
        )
        context.insert(entry)
        try context.save()

        let fetched = try context.fetch(FetchDescriptor<SyncJournalEntry>())
        let savedEntry = try #require(fetched.first)
        let savedDetails = try #require(savedEntry.details)
        let savedProgress = try #require(savedDetails.progress)
        #expect(savedProgress.created == 1)
        #expect(savedProgress.updated == 2)
        #expect(savedProgress.deleted == 0)
        let savedExercises = try #require(savedDetails.exercises)
        #expect(savedExercises.created == 3)
        #expect(savedExercises.updated == 1)
        #expect(savedExercises.deleted == 1)
        let savedActivities = try #require(savedDetails.activities)
        #expect(savedActivities.created == 0)
        #expect(savedActivities.updated == 5)
        #expect(savedActivities.deleted == 0)
        let savedErrors = try #require(savedDetails.errors)
        #expect(savedErrors.count == 1)
        #expect(savedErrors[0].type == "network")
        #expect(savedErrors[0].message == "Ошибка сети")
        let savedEntityType = try #require(savedErrors[0].entityType)
        #expect(savedEntityType == "progress")
        let savedEntityId = try #require(savedErrors[0].entityId)
        #expect(savedEntityId == "123")
    }

    @Test("Сохраняет и читает details с частичными данными")
    @MainActor
    func savesAndReadsDetailsWithPartialData() throws {
        let container = try ModelContainer(
            for: SyncJournalEntry.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = container.mainContext

        let details = SyncResultDetails(
            progress: SyncStats(created: 5, updated: 0, deleted: 0),
            exercises: nil,
            activities: nil,
            errors: nil
        )

        let entry = SyncJournalEntry(
            startDate: Date(),
            result: .success,
            details: details
        )
        context.insert(entry)
        try context.save()

        let fetched = try context.fetch(FetchDescriptor<SyncJournalEntry>())
        let savedEntry = try #require(fetched.first)
        let savedDetails = try #require(savedEntry.details)
        let savedProgress = try #require(savedDetails.progress)
        #expect(savedProgress.created == 5)
        #expect(savedProgress.updated == 0)
        #expect(savedProgress.deleted == 0)
        #expect(savedDetails.exercises == nil)
        #expect(savedDetails.activities == nil)
        #expect(savedDetails.errors == nil)
    }

    @Test("Запись с endDate == nil считается в процессе синхронизации")
    @MainActor
    func entryWithNilEndDateIsInProgress() throws {
        let container = try ModelContainer(
            for: SyncJournalEntry.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = container.mainContext

        let entry = SyncJournalEntry(
            startDate: Date(),
            result: .success
        )
        context.insert(entry)
        try context.save()

        let savedEntry = try #require(context.fetch(FetchDescriptor<SyncJournalEntry>()).first)
        #expect(savedEntry.endDate == nil)
    }

    @Test("Запись с endDate != nil считается завершенной")
    @MainActor
    func entryWithEndDateIsCompleted() throws {
        let container = try ModelContainer(
            for: SyncJournalEntry.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = container.mainContext

        let startDate = Date()
        let endDate = startDate.addingTimeInterval(10)
        let entry = SyncJournalEntry(
            startDate: startDate,
            endDate: endDate,
            result: .success
        )
        context.insert(entry)
        try context.save()

        let savedEntry = try #require(context.fetch(FetchDescriptor<SyncJournalEntry>()).first)
        let savedEndDate = try #require(savedEntry.endDate)
        #expect(savedEndDate == endDate)
    }
}
