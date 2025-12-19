import Foundation
import SwiftData
@testable import SwiftUI_SotkaApp
import Testing

extension StatusManagerTests {
    @Suite("Тесты для start")
    @MainActor
    struct StartTests {
        @Test("Вызывает startNewRun с переданной датой")
        func startCallsStartNewRunWithDate() async throws {
            let now = Date.now
            let appDate = try #require(Calendar.current.date(byAdding: .day, value: -30, to: now))
            let mockStatusClient = MockStatusClient(
                startResult: .success(CurrentRunResponse(date: appDate, maxForAllRunsDay: nil))
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

            await statusManager.start(appDate: appDate)

            let calculator = try #require(statusManager.currentDayCalculator)
            #expect(calculator.startDate.isTheSameDayIgnoringTime(appDate))
            #expect(mockStatusClient.startCallCount == 1)
        }

        @Test("Вызывает syncJournalAndProgress после startNewRun")
        func startCallsSyncJournalAndProgress() async throws {
            let now = Date.now
            let appDate = try #require(Calendar.current.date(byAdding: .day, value: -30, to: now))
            let mockStatusClient = MockStatusClient(
                startResult: .success(CurrentRunResponse(date: appDate, maxForAllRunsDay: nil))
            )
            let mockProgressClient = MockProgressClient()
            let mockExerciseClient = MockExerciseClient()
            let mockDaysClient = MockDaysClient()

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

            let statusManager = try MockStatusManager.create(
                statusClient: mockStatusClient,
                exerciseClient: mockExerciseClient,
                progressClient: mockProgressClient,
                daysClient: mockDaysClient,
                modelContainer: modelContainer
            )

            let initialProgressCalls = mockProgressClient.getProgressCallCount
            let initialExerciseCalls = mockExerciseClient.getCustomExercisesCallCount
            let initialDaysCalls = mockDaysClient.getDaysCallCount

            await statusManager.start(appDate: appDate)

            #expect(mockProgressClient.getProgressCallCount > initialProgressCalls)
            #expect(mockExerciseClient.getCustomExercisesCallCount > initialExerciseCalls)
            #expect(mockDaysClient.getDaysCallCount > initialDaysCalls)
        }

        @Test("Корректно обрабатывает appDate == nil")
        func startHandlesNilAppDate() async throws {
            let now = Date.now
            let mockStatusClient = MockStatusClient(
                startResult: .success(CurrentRunResponse(date: now, maxForAllRunsDay: nil))
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

            await statusManager.start(appDate: nil)

            let calculator = try #require(statusManager.currentDayCalculator)
            #expect(calculator.startDate.isTheSameDayIgnoringTime(now))
        }
    }
}
