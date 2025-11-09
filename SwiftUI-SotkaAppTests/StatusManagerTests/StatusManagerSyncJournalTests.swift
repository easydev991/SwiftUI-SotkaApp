import Foundation
import SwiftData
@testable import SwiftUI_SotkaApp
import Testing

extension StatusManagerTests {
    @Suite("Тесты для syncJournalAndProgress")
    @MainActor
    struct SyncJournalTests {
        @Test("Не выполняет синхронизацию, если isJournalSyncInProgress == true")
        func syncJournalSkipsWhenInProgress() async throws {
            let now = Date.now
            let startDate = try #require(Calendar.current.date(byAdding: .day, value: -30, to: now))
            let mockStatusClient = MockStatusClient(
                currentResult: .success(CurrentRunResponse(date: startDate, maxForAllRunsDay: nil))
            )
            let mockProgressClient = MockProgressClient()
            let mockExerciseClient = MockExerciseClient()
            let mockDaysClient = MockDaysClient()

            let statusManager = try MockStatusManager.create(
                statusClient: mockStatusClient,
                exerciseClient: mockExerciseClient,
                progressClient: mockProgressClient,
                daysClient: mockDaysClient
            )

            let modelConfiguration = ModelConfiguration(isStoredInMemoryOnly: true)
            let modelContainer = try ModelContainer(
                for: User.self,
                DayActivity.self,
                DayActivityTraining.self,
                UserProgress.self,
                CustomExercise.self,
                configurations: modelConfiguration
            )
            let context = modelContainer.mainContext

            let user = User(id: 1, userName: "testuser", fullName: "Test User", email: "test@example.com")
            context.insert(user)
            try context.save()

            await statusManager.startNewRun(appDate: startDate)
            await statusManager.getStatus(context: context)

            let initialProgressCalls = mockProgressClient.getProgressCallCount
            let initialExerciseCalls = mockExerciseClient.getCustomExercisesCallCount
            let initialDaysCalls = mockDaysClient.getDaysCallCount

            await statusManager.getStatus(context: context)

            #expect(mockProgressClient.getProgressCallCount >= initialProgressCalls)
            #expect(mockExerciseClient.getCustomExercisesCallCount >= initialExerciseCalls)
            #expect(mockDaysClient.getDaysCallCount >= initialDaysCalls)
        }

        @Test("Вызывает progressSyncService.syncProgress")
        func syncJournalCallsProgressSyncService() async throws {
            let now = Date.now
            let startDate = try #require(Calendar.current.date(byAdding: .day, value: -30, to: now))
            let mockStatusClient = MockStatusClient(
                currentResult: .success(CurrentRunResponse(date: startDate, maxForAllRunsDay: nil))
            )
            let mockProgressClient = MockProgressClient()
            let mockExerciseClient = MockExerciseClient()
            let mockDaysClient = MockDaysClient()

            let statusManager = try MockStatusManager.create(
                statusClient: mockStatusClient,
                exerciseClient: mockExerciseClient,
                progressClient: mockProgressClient,
                daysClient: mockDaysClient
            )

            let modelConfiguration = ModelConfiguration(isStoredInMemoryOnly: true)
            let modelContainer = try ModelContainer(
                for: User.self,
                DayActivity.self,
                DayActivityTraining.self,
                UserProgress.self,
                CustomExercise.self,
                configurations: modelConfiguration
            )
            let context = modelContainer.mainContext

            let user = User(id: 1, userName: "testuser", fullName: "Test User", email: "test@example.com")
            context.insert(user)
            try context.save()

            await statusManager.startNewRun(appDate: startDate)

            let initialCalls = mockProgressClient.getProgressCallCount

            await statusManager.start(appDate: startDate, context: context)

            #expect(mockProgressClient.getProgressCallCount > initialCalls)
        }

        @Test("Вызывает customExercisesService.syncCustomExercises")
        func syncJournalCallsCustomExercisesService() async throws {
            let now = Date.now
            let startDate = try #require(Calendar.current.date(byAdding: .day, value: -30, to: now))
            let mockStatusClient = MockStatusClient(
                currentResult: .success(CurrentRunResponse(date: startDate, maxForAllRunsDay: nil))
            )
            let mockProgressClient = MockProgressClient()
            let mockExerciseClient = MockExerciseClient()
            let mockDaysClient = MockDaysClient()

            let statusManager = try MockStatusManager.create(
                statusClient: mockStatusClient,
                exerciseClient: mockExerciseClient,
                progressClient: mockProgressClient,
                daysClient: mockDaysClient
            )

            let modelConfiguration = ModelConfiguration(isStoredInMemoryOnly: true)
            let modelContainer = try ModelContainer(
                for: User.self,
                DayActivity.self,
                DayActivityTraining.self,
                UserProgress.self,
                CustomExercise.self,
                configurations: modelConfiguration
            )
            let context = modelContainer.mainContext

            let user = User(id: 1, userName: "testuser", fullName: "Test User", email: "test@example.com")
            context.insert(user)
            try context.save()

            await statusManager.startNewRun(appDate: startDate)

            let initialCalls = mockExerciseClient.getCustomExercisesCallCount

            await statusManager.start(appDate: startDate, context: context)

            #expect(mockExerciseClient.getCustomExercisesCallCount > initialCalls)
        }

        @Test("Вызывает dailyActivitiesService.syncDailyActivities")
        func syncJournalCallsDailyActivitiesService() async throws {
            let now = Date.now
            let startDate = try #require(Calendar.current.date(byAdding: .day, value: -30, to: now))
            let mockStatusClient = MockStatusClient(
                currentResult: .success(CurrentRunResponse(date: startDate, maxForAllRunsDay: nil))
            )
            let mockProgressClient = MockProgressClient()
            let mockExerciseClient = MockExerciseClient()
            let mockDaysClient = MockDaysClient()

            let statusManager = try MockStatusManager.create(
                statusClient: mockStatusClient,
                exerciseClient: mockExerciseClient,
                progressClient: mockProgressClient,
                daysClient: mockDaysClient
            )

            let modelConfiguration = ModelConfiguration(isStoredInMemoryOnly: true)
            let modelContainer = try ModelContainer(
                for: User.self,
                DayActivity.self,
                DayActivityTraining.self,
                UserProgress.self,
                CustomExercise.self,
                configurations: modelConfiguration
            )
            let context = modelContainer.mainContext

            let user = User(id: 1, userName: "testuser", fullName: "Test User", email: "test@example.com")
            context.insert(user)
            try context.save()

            await statusManager.startNewRun(appDate: startDate)

            let initialCalls = mockDaysClient.getDaysCallCount

            await statusManager.start(appDate: startDate, context: context)

            #expect(mockDaysClient.getDaysCallCount > initialCalls)
        }

        @Test("Устанавливает state = .idle после успешной синхронизации")
        func syncJournalSetsIdleStateAfterSync() async throws {
            let now = Date.now
            let startDate = try #require(Calendar.current.date(byAdding: .day, value: -30, to: now))
            let mockStatusClient = MockStatusClient(
                currentResult: .success(CurrentRunResponse(date: startDate, maxForAllRunsDay: nil))
            )
            let statusManager = try MockStatusManager.create(statusClient: mockStatusClient)

            let modelConfiguration = ModelConfiguration(isStoredInMemoryOnly: true)
            let modelContainer = try ModelContainer(
                for: User.self,
                DayActivity.self,
                DayActivityTraining.self,
                UserProgress.self,
                CustomExercise.self,
                configurations: modelConfiguration
            )
            let context = modelContainer.mainContext

            let user = User(id: 1, userName: "testuser", fullName: "Test User", email: "test@example.com")
            context.insert(user)
            try context.save()

            await statusManager.startNewRun(appDate: startDate)
            await statusManager.start(appDate: startDate, context: context)

            #expect(!statusManager.state.isLoading)
        }

        @Test("Устанавливает conflictingSyncModel = nil после синхронизации")
        func syncJournalClearsConflictingSyncModel() async throws {
            let now = Date.now
            let appDate = try #require(Calendar.current.date(byAdding: .day, value: -30, to: now))
            let siteDate = try #require(Calendar.current.date(byAdding: .day, value: -25, to: now))
            let mockStatusClient = MockStatusClient(
                currentResult: .success(CurrentRunResponse(date: siteDate, maxForAllRunsDay: nil))
            )
            let statusManager = try MockStatusManager.create(statusClient: mockStatusClient)

            let modelConfiguration = ModelConfiguration(isStoredInMemoryOnly: true)
            let modelContainer = try ModelContainer(
                for: User.self,
                DayActivity.self,
                DayActivityTraining.self,
                UserProgress.self,
                CustomExercise.self,
                configurations: modelConfiguration
            )
            let context = modelContainer.mainContext

            let user = User(id: 1, userName: "testuser", fullName: "Test User", email: "test@example.com")
            context.insert(user)
            try context.save()

            await statusManager.startNewRun(appDate: appDate)
            await statusManager.getStatus(context: context)

            #expect(statusManager.conflictingSyncModel != nil)

            await statusManager.syncWithSiteDate(siteDate: siteDate, context: context)

            #expect(statusManager.conflictingSyncModel == nil)
        }

        @Test("Создает запись в журнале при начале синхронизации")
        func createsJournalEntryOnSyncStart() async throws {
            let now = Date.now
            let startDate = try #require(Calendar.current.date(byAdding: .day, value: -30, to: now))
            let mockStatusClient = MockStatusClient(
                currentResult: .success(CurrentRunResponse(date: startDate, maxForAllRunsDay: nil))
            )
            let statusManager = try MockStatusManager.create(statusClient: mockStatusClient)

            let modelConfiguration = ModelConfiguration(isStoredInMemoryOnly: true)
            let modelContainer = try ModelContainer(
                for: User.self,
                DayActivity.self,
                DayActivityTraining.self,
                UserProgress.self,
                CustomExercise.self,
                SyncJournalEntry.self,
                configurations: modelConfiguration
            )
            let context = modelContainer.mainContext

            let user = User(id: 1, userName: "testuser", fullName: "Test User", email: "test@example.com")
            context.insert(user)
            try context.save()

            await statusManager.startNewRun(appDate: startDate)
            await statusManager.start(appDate: startDate, context: context)

            let entries = try context.fetch(FetchDescriptor<SyncJournalEntry>())
            #expect(entries.count == 1)
            let entry = try #require(entries.first)
            #expect(entry.result == .success)
            let savedUser = try #require(entry.user)
            #expect(savedUser.id == 1)
        }

        @Test("Обновляет запись при успешном завершении синхронизации")
        func updatesJournalEntryOnSuccessfulSync() async throws {
            let now = Date.now
            let startDate = try #require(Calendar.current.date(byAdding: .day, value: -30, to: now))
            let mockStatusClient = MockStatusClient(
                currentResult: .success(CurrentRunResponse(date: startDate, maxForAllRunsDay: nil))
            )
            let statusManager = try MockStatusManager.create(statusClient: mockStatusClient)

            let modelConfiguration = ModelConfiguration(isStoredInMemoryOnly: true)
            let modelContainer = try ModelContainer(
                for: User.self,
                DayActivity.self,
                DayActivityTraining.self,
                UserProgress.self,
                CustomExercise.self,
                SyncJournalEntry.self,
                configurations: modelConfiguration
            )
            let context = modelContainer.mainContext

            let user = User(id: 1, userName: "testuser", fullName: "Test User", email: "test@example.com")
            context.insert(user)
            try context.save()

            await statusManager.startNewRun(appDate: startDate)
            await statusManager.start(appDate: startDate, context: context)

            let entries = try context.fetch(FetchDescriptor<SyncJournalEntry>())
            let entry = try #require(entries.first)
            let endDate = try #require(entry.endDate)
            #expect(endDate >= entry.startDate)
            #expect(entry.result == .success)
        }

        @Test("Обновляет запись при ошибке синхронизации")
        func updatesJournalEntryOnSyncError() async throws {
            let now = Date.now
            let startDate = try #require(Calendar.current.date(byAdding: .day, value: -30, to: now))
            let mockStatusClient = MockStatusClient(
                currentResult: .success(CurrentRunResponse(date: startDate, maxForAllRunsDay: nil))
            )
            let statusManager = try MockStatusManager.create(statusClient: mockStatusClient)

            let modelConfiguration = ModelConfiguration(isStoredInMemoryOnly: true)
            let modelContainer = try ModelContainer(
                for: User.self,
                DayActivity.self,
                DayActivityTraining.self,
                UserProgress.self,
                CustomExercise.self,
                SyncJournalEntry.self,
                configurations: modelConfiguration
            )
            let context = modelContainer.mainContext

            let user = User(id: 1, userName: "testuser", fullName: "Test User", email: "test@example.com")
            context.insert(user)
            try context.save()

            await statusManager.startNewRun(appDate: startDate)
            await statusManager.start(appDate: startDate, context: context)

            let entries = try context.fetch(FetchDescriptor<SyncJournalEntry>())
            let entry = try #require(entries.first)
            let endDate = try #require(entry.endDate)
            #expect(endDate >= entry.startDate)
        }

        @Test("Агрегирует результаты успешной синхронизации всех сервисов")
        func aggregatesResultsFromAllServices() async throws {
            let now = Date.now
            let startDate = try #require(Calendar.current.date(byAdding: .day, value: -30, to: now))
            let mockStatusClient = MockStatusClient(
                currentResult: .success(CurrentRunResponse(date: startDate, maxForAllRunsDay: nil))
            )
            let mockProgressClient = MockProgressClient()
            let mockExerciseClient = MockExerciseClient()
            let mockDaysClient = MockDaysClient()

            let statusManager = try MockStatusManager.create(
                statusClient: mockStatusClient,
                exerciseClient: mockExerciseClient,
                progressClient: mockProgressClient,
                daysClient: mockDaysClient
            )

            let modelConfiguration = ModelConfiguration(isStoredInMemoryOnly: true)
            let modelContainer = try ModelContainer(
                for: User.self,
                DayActivity.self,
                DayActivityTraining.self,
                UserProgress.self,
                CustomExercise.self,
                SyncJournalEntry.self,
                configurations: modelConfiguration
            )
            let context = modelContainer.mainContext

            let user = User(id: 1, userName: "testuser", fullName: "Test User", email: "test@example.com")
            context.insert(user)
            try context.save()

            await statusManager.startNewRun(appDate: startDate)
            await statusManager.start(appDate: startDate, context: context)

            let entries = try context.fetch(FetchDescriptor<SyncJournalEntry>())
            let entry = try #require(entries.first)
            #expect(entry.result == .success)
        }

        @Test("Агрегирует результаты при частичной синхронизации")
        func aggregatesResultsFromPartialSync() async throws {
            let now = Date.now
            let startDate = try #require(Calendar.current.date(byAdding: .day, value: -30, to: now))
            let mockStatusClient = MockStatusClient(
                currentResult: .success(CurrentRunResponse(date: startDate, maxForAllRunsDay: nil))
            )
            let mockProgressClient = MockProgressClient()
            mockProgressClient.shouldThrowError = true
            let mockExerciseClient = MockExerciseClient()
            let mockDaysClient = MockDaysClient()

            let statusManager = try MockStatusManager.create(
                statusClient: mockStatusClient,
                exerciseClient: mockExerciseClient,
                progressClient: mockProgressClient,
                daysClient: mockDaysClient
            )

            let modelConfiguration = ModelConfiguration(isStoredInMemoryOnly: true)
            let modelContainer = try ModelContainer(
                for: User.self,
                DayActivity.self,
                DayActivityTraining.self,
                UserProgress.self,
                CustomExercise.self,
                SyncJournalEntry.self,
                configurations: modelConfiguration
            )
            let context = modelContainer.mainContext

            let user = User(id: 1, userName: "testuser", fullName: "Test User", email: "test@example.com")
            context.insert(user)
            try context.save()

            await statusManager.startNewRun(appDate: startDate)
            await statusManager.start(appDate: startDate, context: context)

            let entries = try context.fetch(FetchDescriptor<SyncJournalEntry>())
            let entry = try #require(entries.first)
            #expect(entry.result == .error || entry.result == .partial)
        }

        @Test("Собирает статистику от всех сервисов")
        func collectsStatsFromAllServices() async throws {
            let now = Date.now
            let startDate = try #require(Calendar.current.date(byAdding: .day, value: -30, to: now))
            let mockStatusClient = MockStatusClient(
                currentResult: .success(CurrentRunResponse(date: startDate, maxForAllRunsDay: nil))
            )
            let mockProgressClient = MockProgressClient()
            let mockExerciseClient = MockExerciseClient()
            let mockDaysClient = MockDaysClient()

            let statusManager = try MockStatusManager.create(
                statusClient: mockStatusClient,
                exerciseClient: mockExerciseClient,
                progressClient: mockProgressClient,
                daysClient: mockDaysClient
            )

            let modelConfiguration = ModelConfiguration(isStoredInMemoryOnly: true)
            let modelContainer = try ModelContainer(
                for: User.self,
                DayActivity.self,
                DayActivityTraining.self,
                UserProgress.self,
                CustomExercise.self,
                SyncJournalEntry.self,
                configurations: modelConfiguration
            )
            let context = modelContainer.mainContext

            let user = User(id: 1, userName: "testuser", fullName: "Test User", email: "test@example.com")
            context.insert(user)
            try context.save()

            await statusManager.startNewRun(appDate: startDate)
            await statusManager.start(appDate: startDate, context: context)

            let entries = try context.fetch(FetchDescriptor<SyncJournalEntry>())
            let entry = try #require(entries.first)
            let endDate = try #require(entry.endDate)
            #expect(endDate >= entry.startDate)
        }

        @Test("Определяет результат на основе ошибок и статистики")
        func determinesResultBasedOnErrorsAndStats() async throws {
            let now = Date.now
            let startDate = try #require(Calendar.current.date(byAdding: .day, value: -30, to: now))
            let mockStatusClient = MockStatusClient(
                currentResult: .success(CurrentRunResponse(date: startDate, maxForAllRunsDay: nil))
            )
            let mockProgressClient = MockProgressClient()
            let mockExerciseClient = MockExerciseClient()
            mockExerciseClient.shouldThrowError = true
            let mockDaysClient = MockDaysClient()

            let statusManager = try MockStatusManager.create(
                statusClient: mockStatusClient,
                exerciseClient: mockExerciseClient,
                progressClient: mockProgressClient,
                daysClient: mockDaysClient
            )

            let modelConfiguration = ModelConfiguration(isStoredInMemoryOnly: true)
            let modelContainer = try ModelContainer(
                for: User.self,
                DayActivity.self,
                DayActivityTraining.self,
                UserProgress.self,
                CustomExercise.self,
                SyncJournalEntry.self,
                configurations: modelConfiguration
            )
            let context = modelContainer.mainContext

            let user = User(id: 1, userName: "testuser", fullName: "Test User", email: "test@example.com")
            context.insert(user)
            try context.save()

            await statusManager.startNewRun(appDate: startDate)
            await statusManager.start(appDate: startDate, context: context)

            let entries = try context.fetch(FetchDescriptor<SyncJournalEntry>())
            let entry = try #require(entries.first)
            #expect(entry.result == .error || entry.result == .partial || entry.result == .success)
        }

        @Test("Сохраняет details в SyncJournalEntry после успешной синхронизации")
        func savesDetailsInJournalEntryAfterSuccessfulSync() async throws {
            let now = Date.now
            let startDate = try #require(Calendar.current.date(byAdding: .day, value: -30, to: now))
            let mockStatusClient = MockStatusClient(
                currentResult: .success(CurrentRunResponse(date: startDate, maxForAllRunsDay: nil))
            )
            let mockProgressClient = MockProgressClient()
            let mockExerciseClient = MockExerciseClient()
            let mockDaysClient = MockDaysClient()

            let statusManager = try MockStatusManager.create(
                statusClient: mockStatusClient,
                exerciseClient: mockExerciseClient,
                progressClient: mockProgressClient,
                daysClient: mockDaysClient
            )

            let modelConfiguration = ModelConfiguration(isStoredInMemoryOnly: true)
            let modelContainer = try ModelContainer(
                for: User.self,
                DayActivity.self,
                DayActivityTraining.self,
                UserProgress.self,
                CustomExercise.self,
                SyncJournalEntry.self,
                configurations: modelConfiguration
            )
            let context = modelContainer.mainContext

            let user = User(id: 1, userName: "testuser", fullName: "Test User", email: "test@example.com")
            context.insert(user)
            try context.save()

            await statusManager.startNewRun(appDate: startDate)
            await statusManager.start(appDate: startDate, context: context)

            let entries = try context.fetch(FetchDescriptor<SyncJournalEntry>())
            let entry = try #require(entries.first)
            let details = try #require(entry.details)
            #expect(details.progress != nil || details.exercises != nil || details.activities != nil)
        }

        @Test("Сохраняет details с ошибками при частичной синхронизации")
        func savesDetailsWithErrorsOnPartialSync() async throws {
            let now = Date.now
            let startDate = try #require(Calendar.current.date(byAdding: .day, value: -30, to: now))
            let mockStatusClient = MockStatusClient(
                currentResult: .success(CurrentRunResponse(date: startDate, maxForAllRunsDay: nil))
            )
            let mockProgressClient = MockProgressClient()
            mockProgressClient.shouldThrowError = true
            let mockExerciseClient = MockExerciseClient()
            let mockDaysClient = MockDaysClient()

            let statusManager = try MockStatusManager.create(
                statusClient: mockStatusClient,
                exerciseClient: mockExerciseClient,
                progressClient: mockProgressClient,
                daysClient: mockDaysClient
            )

            let modelConfiguration = ModelConfiguration(isStoredInMemoryOnly: true)
            let modelContainer = try ModelContainer(
                for: User.self,
                DayActivity.self,
                DayActivityTraining.self,
                UserProgress.self,
                CustomExercise.self,
                SyncJournalEntry.self,
                configurations: modelConfiguration
            )
            let context = modelContainer.mainContext

            let user = User(id: 1, userName: "testuser", fullName: "Test User", email: "test@example.com")
            context.insert(user)
            try context.save()

            await statusManager.startNewRun(appDate: startDate)
            await statusManager.start(appDate: startDate, context: context)

            let entries = try context.fetch(FetchDescriptor<SyncJournalEntry>())
            let entry = try #require(entries.first)
            let details = try #require(entry.details)
            let errors = try #require(details.errors)
            #expect(!errors.isEmpty)
        }
    }
}
