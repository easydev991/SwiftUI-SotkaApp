import Foundation
import SwiftData
@testable import SwiftUI_SotkaApp
import Testing

extension StatusManagerTests {
    @Suite("Тесты офлайн-режима StatusManager")
    @MainActor
    struct OfflineTests {
        @Test("getStatus пропускает сетевой запрос для офлайн-пользователя")
        func getStatusSkipsNetworkForOfflineUser() async throws {
            let mockStatusClient = MockStatusClient()

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

            let offlineUser = User(id: -1, userName: "offline-user", fullName: nil, email: nil)
            context.insert(offlineUser)
            try context.save()

            let statusManager = try MockStatusManager.create(
                statusClient: mockStatusClient,
                modelContainer: modelContainer
            )

            await statusManager.getStatus()

            #expect(mockStatusClient.currentCallCount == 0)
            #expect(mockStatusClient.startCallCount == 0)
            #expect(statusManager.currentDayCalculator != nil)
            #expect(!statusManager.state.isLoading)
            #expect(!statusManager.state.isLoadingInitialData)
        }

        @Test("getStatus устанавливает startDate при первом входе офлайн-пользователя")
        func getStatusSetsStartDateForFirstTimeOfflineUser() async throws {
            let mockStatusClient = MockStatusClient()

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

            let offlineUser = User(id: -1, userName: "offline-user", fullName: nil, email: nil)
            context.insert(offlineUser)
            try context.save()

            let statusManager = try MockStatusManager.create(
                statusClient: mockStatusClient,
                modelContainer: modelContainer
            )

            await statusManager.getStatus()

            let calculator = try #require(statusManager.currentDayCalculator)
            #expect(calculator.currentDay == 1)
        }

        @Test("getStatus использует сохранённый startDate при повторном запуске")
        func getStatusUsesSavedStartDateOnRestart() async throws {
            let defaults = try MockUserDefaults.create()
            let now = Date.now
            let savedStartDate = try #require(Calendar.current.date(byAdding: .day, value: -10, to: now))

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

            let offlineUser = User(id: -1, userName: "offline-user", fullName: nil, email: nil)
            context.insert(offlineUser)
            try context.save()

            let mockStatusClient = MockStatusClient(
                startResult: .success(CurrentRunResponse(date: savedStartDate, maxForAllRunsDay: nil))
            )
            let statusManager = try MockStatusManager.create(
                statusClient: mockStatusClient,
                userDefaults: defaults,
                modelContainer: modelContainer
            )

            await statusManager.startNewRun(appDate: savedStartDate)
            await statusManager.getStatus()

            let calculator = try #require(statusManager.currentDayCalculator)
            #expect(calculator.currentDay == 11)
            #expect(mockStatusClient.currentCallCount == 0)
        }

        @Test("syncJournalAndProgress пропускает синхронизацию для офлайн-пользователя")
        func syncJournalAndProgressSkipsForOfflineUser() async throws {
            let mockStatusClient = MockStatusClient()
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

            let offlineUser = User(id: -1, userName: "offline-user", fullName: nil, email: nil)
            context.insert(offlineUser)
            try context.save()

            let statusManager = try MockStatusManager.create(
                statusClient: mockStatusClient,
                exerciseClient: mockExerciseClient,
                progressClient: mockProgressClient,
                daysClient: mockDaysClient,
                modelContainer: modelContainer
            )

            let now = Date.now
            let startDate = try #require(Calendar.current.date(byAdding: .day, value: -5, to: now))

            let initialProgressCalls = mockProgressClient.getProgressCallCount
            let initialExerciseCalls = mockExerciseClient.getCustomExercisesCallCount
            let initialDaysCalls = mockDaysClient.getDaysCallCount

            await statusManager.syncWithSiteDate(siteDate: startDate)

            #expect(mockProgressClient.getProgressCallCount == initialProgressCalls)
            #expect(mockExerciseClient.getCustomExercisesCallCount == initialExerciseCalls)
            #expect(mockDaysClient.getDaysCallCount == initialDaysCalls)
        }

        @Test("processAuthStatus(isAuthorized: false) удаляет данные офлайн-пользователя")
        func processAuthStatusLogoutClearsOfflineUserData() throws {
            let mockSession = MockWCSession(isReachable: true)
            let modelConfiguration = ModelConfiguration(isStoredInMemoryOnly: true)
            let modelContainer = try ModelContainer(
                for: User.self,
                DayActivity.self,
                configurations: modelConfiguration
            )
            let context = modelContainer.mainContext

            let offlineUser = User(id: -1, userName: "offline-user", fullName: nil, email: nil)
            context.insert(offlineUser)
            try context.save()

            let statusManager = try MockStatusManager.create(
                userDefaults: MockUserDefaults.create(),
                modelContainer: modelContainer,
                watchConnectivitySessionProtocol: mockSession
            )

            let usersBefore = try context.fetch(FetchDescriptor<User>())
            #expect(usersBefore.count == 1)

            statusManager.processAuthStatus(isAuthorized: false)

            let usersAfter = try context.fetch(FetchDescriptor<User>())
            #expect(usersAfter.isEmpty)
            #expect(statusManager.currentDayCalculator == nil)
        }

        @Test("didLogout сбрасывает didLoadInitialData для чистого состояния при повторном входе")
        func didLogoutResetsDidLoadInitialData() async throws {
            let mockStatusClient = MockStatusClient()

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

            let offlineUser = User(id: -1, userName: "offline-user", fullName: nil, email: nil)
            context.insert(offlineUser)
            try context.save()

            let statusManager = try MockStatusManager.create(
                statusClient: mockStatusClient,
                modelContainer: modelContainer
            )

            await statusManager.getStatus()

            statusManager.processAuthStatus(isAuthorized: false)

            let normalUser = User(id: 1, userName: "testuser", fullName: "Test", email: "t@t.com")
            context.insert(normalUser)
            try context.save()

            let gate = AsyncTestGate()
            mockStatusClient.currentGate = gate

            let task = Task {
                await statusManager.getStatus()
            }

            await gate.waitUntilArrived()

            #expect(statusManager.state.isLoadingInitialData)

            await gate.release()
            await task.value
        }

        @Test("getStatus для обычного пользователя выполняет сетевой запрос")
        func getStatusPerformsNetworkForNormalUser() async throws {
            let mockStatusClient = MockStatusClient(
                currentResult: .success(CurrentRunResponse(date: nil, maxForAllRunsDay: nil))
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

            let statusManager = try MockStatusManager.create(
                statusClient: mockStatusClient,
                modelContainer: modelContainer
            )

            await statusManager.getStatus()

            #expect(mockStatusClient.currentCallCount == 1)
        }

        @Test("startNewRun не вызывает statusClient.start для офлайн-пользователя")
        func startNewRunSkipsNetworkForOfflineUser() async throws {
            let mockStatusClient = MockStatusClient()

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

            let offlineUser = User(id: -1, userName: "offline-user", fullName: nil, email: nil)
            context.insert(offlineUser)
            try context.save()

            let statusManager = try MockStatusManager.create(
                statusClient: mockStatusClient,
                modelContainer: modelContainer
            )

            await statusManager.startNewRun(appDate: .now)

            #expect(mockStatusClient.startCallCount == 0)
            #expect(statusManager.currentDayCalculator != nil)
        }

        @Test("startNewRun устанавливает startDate локально для офлайн-пользователя")
        func startNewRunSetsStartDateLocallyForOfflineUser() async throws {
            let mockStatusClient = MockStatusClient()

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

            let offlineUser = User(id: -1, userName: "offline-user", fullName: nil, email: nil)
            context.insert(offlineUser)
            try context.save()

            let statusManager = try MockStatusManager.create(
                statusClient: mockStatusClient,
                modelContainer: modelContainer
            )

            let now = Date.now
            let tenDaysAgo = try #require(Calendar.current.date(byAdding: .day, value: -10, to: now))

            await statusManager.startNewRun(appDate: tenDaysAgo)

            #expect(mockStatusClient.startCallCount == 0)
            let calculator = try #require(statusManager.currentDayCalculator)
            #expect(calculator.currentDay == 11)
        }

        @Test("loadInfopostsWithUserGender пропускает syncReadPosts для офлайн-пользователя")
        func loadInfopostsSkipsSyncReadPostsForOfflineUser() async throws {
            let mockInfopostsClient = MockInfopostsClient(getReadPostsResult: .success([]))

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

            let offlineUser = User(id: -1, userName: "offline-user", fullName: nil, email: nil)
            context.insert(offlineUser)
            try context.save()

            let statusManager = try MockStatusManager.create(
                infopostsClient: mockInfopostsClient,
                modelContainer: modelContainer
            )

            await statusManager.getStatus()

            statusManager.loadInfopostsWithUserGender()

            if let task = statusManager.syncReadPostsTask {
                try? await task.value
            }

            #expect(statusManager.syncReadPostsTask == nil)
        }

        @Test("resetProgram не вызывает statusClient.start для офлайн-пользователя")
        func resetProgramSkipsNetworkForOfflineUser() async throws {
            let mockStatusClient = MockStatusClient()

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

            let offlineUser = User(id: -1, userName: "offline-user", fullName: nil, email: nil)
            context.insert(offlineUser)
            try context.save()

            let statusManager = try MockStatusManager.create(
                statusClient: mockStatusClient,
                modelContainer: modelContainer
            )

            await statusManager.getStatus()

            let initialCallCount = mockStatusClient.startCallCount
            await statusManager.resetProgram()

            #expect(mockStatusClient.startCallCount == initialCallCount)
            #expect(statusManager.currentDayCalculator != nil)
            #expect(!statusManager.state.isLoading)
        }
    }
}
