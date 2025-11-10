import Foundation
import SwiftData
@testable import SwiftUI_SotkaApp
import Testing

extension StatusManagerTests {
    @Suite("Тесты для didLogout")
    @MainActor
    struct LogoutTests {
        @Test("Устанавливает startDate = nil")
        func didLogoutSetsStartDateToNil() async throws {
            let now = Date.now
            let startDate = try #require(Calendar.current.date(byAdding: .day, value: -30, to: now))
            let mockStatusClient = MockStatusClient(
                startResult: .success(CurrentRunResponse(date: nil, maxForAllRunsDay: nil))
            )
            let statusManager = try MockStatusManager.create(statusClient: mockStatusClient)

            await statusManager.startNewRun(appDate: startDate)

            let calculatorBefore = try #require(statusManager.currentDayCalculator)
            #expect(calculatorBefore.startDate.isTheSameDayIgnoringTime(startDate))

            statusManager.didLogout()

            #expect(statusManager.currentDayCalculator == nil)
        }

        @Test("Устанавливает currentDayCalculator = nil")
        func didLogoutSetsCurrentDayCalculatorToNil() async throws {
            let now = Date.now
            let startDate = try #require(Calendar.current.date(byAdding: .day, value: -30, to: now))
            let mockStatusClient = MockStatusClient(
                startResult: .success(CurrentRunResponse(date: nil, maxForAllRunsDay: nil))
            )
            let statusManager = try MockStatusManager.create(statusClient: mockStatusClient)

            await statusManager.startNewRun(appDate: startDate)

            #expect(statusManager.currentDayCalculator != nil)

            statusManager.didLogout()

            #expect(statusManager.currentDayCalculator == nil)
        }

        @Test("Устанавливает maxReadInfoPostDay = 0")
        func didLogoutSetsMaxReadInfoPostDayToZero() async throws {
            let now = Date.now
            let startDate = try #require(Calendar.current.date(byAdding: .day, value: -30, to: now))
            let mockStatusClient = MockStatusClient(
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

            #expect(statusManager.maxReadInfoPostDay == 50)

            statusManager.didLogout()

            #expect(statusManager.maxReadInfoPostDay == 0)
        }

        @Test("Вызывает infopostsService.didLogout()")
        func didLogoutCallsInfopostsServiceDidLogout() throws {
            let statusManager = try MockStatusManager.create()

            statusManager.didLogout()

            #expect(statusManager.maxReadInfoPostDay == 0)
            #expect(statusManager.currentDayCalculator == nil)
        }

        @Test("Удаляет ключ startDate из UserDefaults")
        func didLogoutRemovesStartDateFromUserDefaults() async throws {
            let now = Date.now
            let startDate = try #require(Calendar.current.date(byAdding: .day, value: -30, to: now))
            let userDefaults = try MockUserDefaults.create()
            let mockStatusClient = MockStatusClient(
                startResult: .success(CurrentRunResponse(date: nil, maxForAllRunsDay: nil))
            )
            let statusManager = try MockStatusManager.create(
                statusClient: mockStatusClient,
                userDefaults: userDefaults
            )

            await statusManager.startNewRun(appDate: startDate)

            let key = "WorkoutStartDate"
            #expect(userDefaults.double(forKey: key) != 0)

            statusManager.didLogout()

            #expect(userDefaults.double(forKey: key) == 0)
        }

        @Test("Устанавливает maxReadInfoPostDay = 0 в UserDefaults")
        func didLogoutSetsMaxReadInfoPostDayToZeroInUserDefaults() async throws {
            let now = Date.now
            let startDate = try #require(Calendar.current.date(byAdding: .day, value: -30, to: now))
            let userDefaults = try MockUserDefaults.create()
            let mockStatusClient = MockStatusClient(
                currentResult: .success(CurrentRunResponse(date: startDate, maxForAllRunsDay: 50))
            )
            let statusManager = try MockStatusManager.create(
                statusClient: mockStatusClient,
                userDefaults: userDefaults
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

            let key = "WorkoutMaxReadInfoPostDay"
            #expect(userDefaults.integer(forKey: key) == 50)

            statusManager.didLogout()

            #expect(userDefaults.integer(forKey: key) == 0)
        }
    }
}
