import Foundation
import SwiftData
@testable import SwiftUI_SotkaApp
import Testing

@Suite("Тесты SwiftData миграции")
@MainActor
struct SwiftDataMigrationTests {
    @Test("Открытие legacy БД не падает и сохраняет данные")
    func opensLegacySchemaAndPreservesData() throws {
        let (directoryURL, storeURL) = makeStoreURLs()
        defer { try? FileManager.default.removeItem(at: directoryURL) }

        do {
            let oldSchema = makeLegacySchema()
            let oldConfiguration = ModelConfiguration("MigrationTest", schema: oldSchema, url: storeURL)
            let oldContainer = try ModelContainer(for: oldSchema, configurations: [oldConfiguration])
            let oldContext = oldContainer.mainContext

            let user = User(id: 42, userName: "legacy-user", fullName: "Legacy", email: "legacy@example.com")
            let progress = UserProgress(id: 49, pullUps: 10, pushUps: 20, squats: 30, weight: 75)
            progress.user = user

            oldContext.insert(user)
            oldContext.insert(progress)
            try oldContext.save()
        }

        let newSchema = makeCurrentSchema()
        let newConfiguration = ModelConfiguration("MigrationTest", schema: newSchema, url: storeURL)
        let migratedContainer = try ModelContainer(for: newSchema, configurations: [newConfiguration])
        let context = migratedContainer.mainContext

        let users = try context.fetch(FetchDescriptor<User>())
        let progressList = try context.fetch(FetchDescriptor<UserProgress>())
        let extensions = try context.fetch(FetchDescriptor<CalendarExtensionRecord>())
        let firstUser = try #require(users.first)
        let firstProgress = try #require(progressList.first)

        #expect(users.count == 1)
        #expect(firstUser.id == 42)
        #expect(progressList.count == 1)
        #expect(firstProgress.id == 49)
        #expect(extensions.isEmpty)
    }

    @Test("Новая сущность CalendarExtensionRecord доступна после открытия legacy БД")
    func calendarExtensionEntityIsAvailableAfterLegacyOpen() throws {
        let (directoryURL, storeURL) = makeStoreURLs()
        defer { try? FileManager.default.removeItem(at: directoryURL) }

        do {
            let oldSchema = makeLegacySchema()
            let oldConfiguration = ModelConfiguration("MigrationEntityTest", schema: oldSchema, url: storeURL)
            _ = try ModelContainer(for: oldSchema, configurations: [oldConfiguration])
        }

        let newSchema = makeCurrentSchema()
        let newConfiguration = ModelConfiguration("MigrationEntityTest", schema: newSchema, url: storeURL)
        let migratedContainer = try ModelContainer(for: newSchema, configurations: [newConfiguration])
        let context = migratedContainer.mainContext

        let user = User(id: 777, userName: "post-migration-user", fullName: "User", email: "user@example.com")
        context.insert(user)

        let record = CalendarExtensionRecord(
            date: Date(timeIntervalSince1970: 1_700_000_000),
            isSynced: false,
            shouldDelete: false,
            lastModified: .now,
            user: user
        )
        context.insert(record)
        try context.save()

        let stored = try context.fetch(FetchDescriptor<CalendarExtensionRecord>())
        let firstStoredRecord = try #require(stored.first)
        #expect(stored.count == 1)
        let storedUser = try #require(firstStoredRecord.user)
        #expect(storedUser.id == 777)
    }

    @Test("Повторное открытие контейнера после legacy upgrade идемпотентно")
    func legacyUpgradeIsIdempotentOnReopen() throws {
        let (directoryURL, storeURL) = makeStoreURLs()
        defer { try? FileManager.default.removeItem(at: directoryURL) }

        do {
            let oldSchema = makeLegacySchema()
            let oldConfiguration = ModelConfiguration("MigrationIdempotentTest", schema: oldSchema, url: storeURL)
            let oldContainer = try ModelContainer(for: oldSchema, configurations: [oldConfiguration])
            let oldContext = oldContainer.mainContext
            oldContext.insert(User(id: 99, userName: "legacy", fullName: nil, email: nil))
            try oldContext.save()
        }

        let newSchema = makeCurrentSchema()
        let newConfiguration = ModelConfiguration("MigrationIdempotentTest", schema: newSchema, url: storeURL)

        let firstOpenContainer = try ModelContainer(for: newSchema, configurations: [newConfiguration])
        var users = try firstOpenContainer.mainContext.fetch(FetchDescriptor<User>())
        #expect(users.count == 1)

        let secondOpenContainer = try ModelContainer(for: newSchema, configurations: [newConfiguration])
        users = try secondOpenContainer.mainContext.fetch(FetchDescriptor<User>())
        #expect(users.count == 1)
    }

    private func makeLegacySchema() -> Schema {
        Schema(
            [
                User.self,
                Country.self,
                CustomExercise.self,
                UserProgress.self,
                DayActivity.self,
                DayActivityTraining.self,
                SyncJournalEntry.self
            ]
        )
    }

    private func makeCurrentSchema() -> Schema {
        Schema(
            [
                User.self,
                Country.self,
                CustomExercise.self,
                UserProgress.self,
                DayActivity.self,
                DayActivityTraining.self,
                SyncJournalEntry.self,
                CalendarExtensionRecord.self
            ]
        )
    }

    private func makeStoreURLs() -> (directory: URL, store: URL) {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("SwiftDataMigrationTests", isDirectory: true)
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return (directory, directory.appendingPathComponent("store.sqlite"))
    }
}
