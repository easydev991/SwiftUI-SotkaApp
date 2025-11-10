import Foundation
import SwiftData
@testable import SwiftUI_SotkaApp
import Testing

extension StatusManagerTests {
    @Suite("Интеграционные тесты")
    @MainActor
    struct IntegrationTests {
        @Test("Полный цикл синхронизации от getStatus до завершения")
        func fullSyncCycleFromGetStatus() async throws {
            let now = Date.now
            let startDate = try #require(Calendar.current.date(byAdding: .day, value: -30, to: now))
            let mockStatusClient = MockStatusClient(
                startResult: .success(CurrentRunResponse(date: nil, maxForAllRunsDay: nil)),
                currentResult: .success(CurrentRunResponse(date: startDate, maxForAllRunsDay: 50))
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
            await statusManager.getStatus(context: context)

            #expect(!statusManager.state.isLoading)
            #expect(statusManager.maxReadInfoPostDay == 50)
            let calculator = try #require(statusManager.currentDayCalculator)
            #expect(calculator.startDate.isTheSameDayIgnoringTime(startDate))
        }

        @Test("Первый запуск приложения: getStatus → нет даты → start → синхронизация")
        func firstAppLaunchScenario() async throws {
            let now = Date.now
            let mockStatusClient = MockStatusClient(
                startResult: .success(CurrentRunResponse(date: now, maxForAllRunsDay: nil)),
                currentResult: .success(CurrentRunResponse(date: nil, maxForAllRunsDay: nil))
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

            await statusManager.getStatus(context: context)

            #expect(!statusManager.state.isLoading)
            #expect(statusManager.currentDayCalculator != nil)
            #expect(mockStatusClient.startCallCount > 0)
        }

        @Test("Повторный запуск с синхронизацией: getStatus → даты совпадают → syncJournalAndProgress")
        func subsequentLaunchWithSyncScenario() async throws {
            let now = Date.now
            let startDate = try #require(Calendar.current.date(byAdding: .day, value: -30, to: now))
            let mockStatusClient = MockStatusClient(
                startResult: .success(CurrentRunResponse(date: nil, maxForAllRunsDay: nil)),
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

            let initialProgressCalls = mockProgressClient.getProgressCallCount
            let initialExerciseCalls = mockExerciseClient.getCustomExercisesCallCount
            let initialDaysCalls = mockDaysClient.getDaysCallCount

            await statusManager.getStatus(context: context)

            #expect(mockProgressClient.getProgressCallCount > initialProgressCalls)
            #expect(mockExerciseClient.getCustomExercisesCallCount > initialExerciseCalls)
            #expect(mockDaysClient.getDaysCallCount > initialDaysCalls)
            #expect(!statusManager.state.isLoading)
            #expect(statusManager.conflictingSyncModel == nil)
        }

        @Test("Конфликт дат и разрешение: getStatus → конфликт → установка conflictingSyncModel → разрешение → синхронизация")
        func dateConflictAndResolutionScenario() async throws {
            let now = Date.now
            let appDate = try #require(Calendar.current.date(byAdding: .day, value: -30, to: now))
            let siteDate = try #require(Calendar.current.date(byAdding: .day, value: -25, to: now))
            let mockStatusClient = MockStatusClient(
                startResult: .success(CurrentRunResponse(date: nil, maxForAllRunsDay: nil)),
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

            let conflictingModel = try #require(statusManager.conflictingSyncModel)
            #expect(conflictingModel.appDayCalculator.startDate.isTheSameDayIgnoringTime(appDate))
            #expect(conflictingModel.siteDayCalculator.startDate.isTheSameDayIgnoringTime(siteDate))

            await statusManager.syncWithSiteDate(siteDate: siteDate, context: context)

            #expect(statusManager.conflictingSyncModel == nil)
            #expect(!statusManager.state.isLoading)
            let calculator = try #require(statusManager.currentDayCalculator)
            #expect(calculator.startDate.isTheSameDayIgnoringTime(siteDate))
        }
    }
}
