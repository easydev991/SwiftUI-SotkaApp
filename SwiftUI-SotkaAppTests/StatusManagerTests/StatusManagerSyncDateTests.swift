import Foundation
import SwiftData
@testable import SwiftUI_SotkaApp
import Testing

extension StatusManagerTests {
    @Suite("Тесты для syncWithSiteDate")
    @MainActor
    struct SyncDateTests {
        @Test("Обновляет currentDayCalculator при синхронизации даты с сайта")
        func syncWithSiteDateUpdatesCurrentDayCalculator() async throws {
            let statusManager = try MockStatusManager.create()

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

            let now = Date.now
            let initialStartDate = try #require(Calendar.current.date(byAdding: .day, value: -100, to: now))
            let siteDate = try #require(Calendar.current.date(byAdding: .day, value: -99, to: now))

            await statusManager.startNewRun(appDate: initialStartDate)

            let initialCalculator = try #require(statusManager.currentDayCalculator)
            #expect(initialCalculator.currentDay == 1)

            await statusManager.syncWithSiteDate(siteDate: siteDate)

            let updatedCalculator = try #require(statusManager.currentDayCalculator)
            #expect(updatedCalculator.currentDay == 100)
            #expect(updatedCalculator.startDate.isTheSameDayIgnoringTime(siteDate))
        }

        @Test("Обновляет startDate при синхронизации даты с сайта")
        func syncWithSiteDateUpdatesStartDate() async throws {
            let statusManager = try MockStatusManager.create()

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

            let now = Date.now
            let initialStartDate = try #require(Calendar.current.date(byAdding: .day, value: -50, to: now))
            let siteDate = try #require(Calendar.current.date(byAdding: .day, value: -30, to: now))

            await statusManager.startNewRun(appDate: initialStartDate)

            await statusManager.syncWithSiteDate(siteDate: siteDate)

            let calculator = try #require(statusManager.currentDayCalculator)
            #expect(calculator.startDate.isTheSameDayIgnoringTime(siteDate))
        }

        @Test("Вызывает синхронизацию журнала и прогресса при синхронизации даты с сайта")
        func syncWithSiteDateCallsSyncJournalAndProgress() async throws {
            let mockProgressClient = MockProgressClient()
            let mockExerciseClient = MockExerciseClient()
            let mockDaysClient = MockDaysClient()

            let statusManager = try MockStatusManager.create(
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

            let now = Date.now
            let siteDate = try #require(Calendar.current.date(byAdding: .day, value: -25, to: now))

            let initialProgressCallCount = mockProgressClient.getProgressCallCount
            let initialExerciseCallCount = mockExerciseClient.getCustomExercisesCallCount
            let initialDaysCallCount = mockDaysClient.getDaysCallCount

            await statusManager.syncWithSiteDate(siteDate: siteDate)

            #expect(mockProgressClient.getProgressCallCount > initialProgressCallCount)
            #expect(mockExerciseClient.getCustomExercisesCallCount > initialExerciseCallCount)
            #expect(mockDaysClient.getDaysCallCount > initialDaysCallCount)
        }

        @Test("Обновляет currentDayCalculator при вызове start")
        func startUpdatesCurrentDayCalculator() async throws {
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

            let now = Date.now
            let newStartDate = try #require(Calendar.current.date(byAdding: .day, value: -99, to: now))
            let mockStatusClient = MockStatusClient(
                startResult: .success(CurrentRunResponse(date: newStartDate, maxForAllRunsDay: nil))
            )
            let statusManagerWithClient = try MockStatusManager.create(statusClient: mockStatusClient)

            await statusManagerWithClient.start(appDate: newStartDate)

            let calculator = try #require(statusManagerWithClient.currentDayCalculator)
            #expect(calculator.currentDay == 100)
            #expect(calculator.startDate.isTheSameDayIgnoringTime(newStartDate))
        }
    }
}
