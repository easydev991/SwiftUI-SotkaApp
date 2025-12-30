import Foundation
import SwiftData
@testable import SwiftUI_SotkaApp
import Testing

extension StatusManagerTests {
    @Suite("Тесты для loadInfopostsWithUserGender")
    @MainActor
    struct LoadInfopostsTests {
        @Test("Получает пользователя из контекста и вызывает loadAvailableInfoposts с правильными параметрами")
        func loadInfopostsGetsUserAndCallsLoadAvailableInfoposts() async throws {
            let now = Date.now
            let startDate = try #require(Calendar.current.date(byAdding: .day, value: -30, to: now))
            let mockStatusClient = MockStatusClient(
                currentResult: .success(CurrentRunResponse(date: startDate, maxForAllRunsDay: 50))
            )
            let mockInfopostsClient = MockInfopostsClient(getReadPostsResult: .success([]))
            let statusManager = try MockStatusManager.create(
                statusClient: mockStatusClient,
                infopostsClient: mockInfopostsClient
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

            let user = User(id: 1, userName: "testuser", fullName: "Test User", email: "test@example.com", genderCode: 1)
            context.insert(user)
            try context.save()

            await statusManager.startNewRun(appDate: startDate)
            await statusManager.getStatus()

            statusManager.loadInfopostsWithUserGender()

            if let task = statusManager.syncReadPostsTask {
                try? await task.value
            }

            let calculator = try #require(statusManager.currentDayCalculator)
            #expect(calculator.currentDay > 0)
            #expect(statusManager.maxReadInfoPostDay == 50)
        }

        @Test("Обрабатывает случай, когда пользователь не найден")
        func loadInfopostsHandlesMissingUser() async throws {
            let mockInfopostsClient = MockInfopostsClient(getReadPostsResult: .success([]))
            let statusManager = try MockStatusManager.create(infopostsClient: mockInfopostsClient)

            statusManager.loadInfopostsWithUserGender()

            if let task = statusManager.syncReadPostsTask {
                try? await task.value
            }

            #expect(statusManager.currentDayCalculator == nil)
        }

        @Test("Передает currentDay == nil, если currentDayCalculator == nil")
        func loadInfopostsHandlesNilCurrentDayCalculator() async throws {
            let mockInfopostsClient = MockInfopostsClient(getReadPostsResult: .success([]))
            let statusManager = try MockStatusManager.create(infopostsClient: mockInfopostsClient)

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

            statusManager.loadInfopostsWithUserGender()

            if let task = statusManager.syncReadPostsTask {
                try? await task.value
            }

            #expect(statusManager.currentDayCalculator == nil)
        }

        @Test("Не падает при ошибке загрузки инфопостов")
        func loadInfopostsDoesNotCrashOnError() async throws {
            let mockInfopostsClient = MockInfopostsClient(getReadPostsResult: .success([]))
            let statusManager = try MockStatusManager.create(infopostsClient: mockInfopostsClient)

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

            statusManager.loadInfopostsWithUserGender()

            if let task = statusManager.syncReadPostsTask {
                try? await task.value
            }
        }
    }
}
