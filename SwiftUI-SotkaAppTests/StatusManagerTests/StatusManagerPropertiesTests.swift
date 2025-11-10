import Foundation
import SwiftData
@testable import SwiftUI_SotkaApp
import Testing

extension StatusManagerTests {
    @Suite("Тесты для свойств StatusManager")
    @MainActor
    struct PropertiesTests {
        @Test("maxReadInfoPostDay читает значение из UserDefaults")
        func maxReadInfoPostDayReadsFromUserDefaults() throws {
            let userDefaults = try MockUserDefaults.create()
            let key = "WorkoutMaxReadInfoPostDay"
            userDefaults.set(50, forKey: key)

            let statusManager = try MockStatusManager.create(userDefaults: userDefaults)

            #expect(statusManager.maxReadInfoPostDay == 50)
        }

        @Test("maxReadInfoPostDay записывает значение в UserDefaults")
        func maxReadInfoPostDayWritesToUserDefaults() async throws {
            let now = Date.now
            let startDate = try #require(Calendar.current.date(byAdding: .day, value: -30, to: now))
            let userDefaults = try MockUserDefaults.create()
            let mockStatusClient = MockStatusClient(
                currentResult: .success(CurrentRunResponse(date: startDate, maxForAllRunsDay: 75))
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
            #expect(userDefaults.integer(forKey: key) == 75)
        }

        @Test("startDate сохраняет значение в UserDefaults")
        func startDateSavesToUserDefaults() async throws {
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
            let storedTime = userDefaults.double(forKey: key)
            let storedDate = Date(timeIntervalSinceReferenceDate: storedTime)
            #expect(storedDate.isTheSameDayIgnoringTime(startDate))
        }

        @Test("startDate удаляет ключ из UserDefaults при установке nil")
        func startDateRemovesKeyFromUserDefaults() async throws {
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

        @Test("startDate возвращает nil, если значение не установлено")
        func startDateReturnsNilWhenNotSet() throws {
            let statusManager = try MockStatusManager.create()

            #expect(statusManager.currentDayCalculator == nil)
        }

        @Test("conflictingSyncModel устанавливается при конфликте дат в getStatus")
        func conflictingSyncModelSetOnDateConflict() async throws {
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
        }

        @Test("conflictingSyncModel очищается при вызове syncJournalAndProgress")
        func conflictingSyncModelClearedOnSync() async throws {
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
    }
}
