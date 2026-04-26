import Foundation
import SwiftData
@testable import SwiftUI_SotkaApp
import Testing

extension StatusManagerTests {
    @Suite("Интеграционные тесты офлайн-флоу")
    @MainActor
    struct OfflineIntegrationTests {
        private func makeContainer() throws -> ModelContainer {
            try ModelContainer(
                for: User.self,
                DayActivity.self,
                DayActivityTraining.self,
                UserProgress.self,
                CustomExercise.self,
                SyncJournalEntry.self,
                configurations: ModelConfiguration(isStoredInMemoryOnly: true)
            )
        }

        @Test("Полный офлайн-флоу: вход → getStatus → DayActivity → logout → данные удалены")
        func fullOfflineFlowFromLoginToLogout() async throws {
            let mockStatusClient = MockStatusClient()
            let mockProgressClient = MockProgressClient()
            let mockExerciseClient = MockExerciseClient()
            let mockDaysClient = MockDaysClient()
            let mockSession = MockWCSession(isReachable: true)

            let container = try makeContainer()
            let context = container.mainContext

            let offlineUser = User(offlineWithGenderCode: 1)
            context.insert(offlineUser)
            try context.save()

            #expect(offlineUser.isOfflineOnly)
            #expect(offlineUser.id == -1)
            #expect(offlineUser.genderCode == 1)

            let statusManager = try MockStatusManager.create(
                statusClient: mockStatusClient,
                exerciseClient: mockExerciseClient,
                progressClient: mockProgressClient,
                daysClient: mockDaysClient,
                modelContainer: container,
                watchConnectivitySessionProtocol: mockSession
            )

            await statusManager.getStatus()

            #expect(mockStatusClient.currentCallCount == 0)
            #expect(mockStatusClient.startCallCount == 0)
            #expect(statusManager.currentDayCalculator != nil)
            #expect(!statusManager.state.isLoading)

            let calculator = try #require(statusManager.currentDayCalculator)
            #expect(calculator.currentDay == 1)

            let dayActivity = DayActivity(
                day: 1,
                activityTypeRaw: DayActivityType.workout.rawValue,
                count: 10,
                createDate: .now,
                modifyDate: .now,
                user: offlineUser
            )
            context.insert(dayActivity)
            try context.save()

            let savedActivities = try context.fetch(FetchDescriptor<DayActivity>())
            #expect(savedActivities.count == 1)
            let firstActivity = try #require(savedActivities.first)
            #expect(firstActivity.day == 1)
            #expect(firstActivity.activityTypeRaw == DayActivityType.workout.rawValue)

            let userWithActivities = try #require(context.fetch(FetchDescriptor<User>()).first)
            #expect(userWithActivities.dayActivities.count == 1)

            await statusManager.syncWithSiteDate(siteDate: .now)

            #expect(mockProgressClient.getProgressCallCount == 0)
            #expect(mockExerciseClient.getCustomExercisesCallCount == 0)
            #expect(mockDaysClient.getDaysCallCount == 0)

            statusManager.loadInfopostsWithUserGender()
            if let task = statusManager.syncReadPostsTask {
                try? await task.value
            }
            #expect(statusManager.syncReadPostsTask == nil)

            statusManager.processAuthStatus(isAuthorized: false)

            let usersAfterLogout = try context.fetch(FetchDescriptor<User>())
            #expect(usersAfterLogout.isEmpty)

            let activitiesAfterLogout = try context.fetch(FetchDescriptor<DayActivity>())
            #expect(activitiesAfterLogout.isEmpty)

            #expect(statusManager.currentDayCalculator == nil)
        }

        @Test("Офлайн → онлайн: logout → обычный пользователь → сетевые запросы работают")
        func offlineToOnlineTransition() async throws {
            let now = Date.now
            let startDate = try #require(Calendar.current.date(byAdding: .day, value: -5, to: now))
            let mockStatusClient = MockStatusClient(
                startResult: .success(CurrentRunResponse(date: startDate, maxForAllRunsDay: nil)),
                currentResult: .success(CurrentRunResponse(date: startDate, maxForAllRunsDay: nil))
            )
            let mockProgressClient = MockProgressClient()
            let mockExerciseClient = MockExerciseClient()
            let mockDaysClient = MockDaysClient()

            let container = try makeContainer()
            let context = container.mainContext

            let offlineUser = User(offlineWithGenderCode: 2)
            context.insert(offlineUser)
            try context.save()

            let statusManager = try MockStatusManager.create(
                statusClient: mockStatusClient,
                exerciseClient: mockExerciseClient,
                progressClient: mockProgressClient,
                daysClient: mockDaysClient,
                modelContainer: container
            )

            await statusManager.getStatus()

            #expect(mockStatusClient.currentCallCount == 0)
            #expect(statusManager.currentDayCalculator != nil)

            let dayActivity = DayActivity(
                day: 1,
                activityTypeRaw: DayActivityType.rest.rawValue,
                createDate: .now,
                modifyDate: .now,
                user: offlineUser
            )
            context.insert(dayActivity)
            try context.save()

            let activitiesBeforeLogout = try context.fetch(FetchDescriptor<DayActivity>())
            #expect(activitiesBeforeLogout.count == 1)

            statusManager.processAuthStatus(isAuthorized: false)

            let usersAfterLogout = try context.fetch(FetchDescriptor<User>())
            #expect(usersAfterLogout.isEmpty)
            let activitiesAfterLogout = try context.fetch(FetchDescriptor<DayActivity>())
            #expect(activitiesAfterLogout.isEmpty)
            #expect(statusManager.currentDayCalculator == nil)

            let normalUser = User(id: 42, userName: "realuser", fullName: "Real User", email: "real@example.com")
            context.insert(normalUser)
            try context.save()

            #expect(!normalUser.isOfflineOnly)

            await statusManager.getStatus()

            #expect(mockStatusClient.currentCallCount == 1)

            let newCalculator = try #require(statusManager.currentDayCalculator)
            #expect(newCalculator.currentDay == 6)
        }

        @Test("Офлайн: resetProgram → startDate сбрасывается, данные очищаются")
        func offlineResetProgramClearsDataAndResetsStartDate() async throws {
            let mockStatusClient = MockStatusClient()
            let container = try makeContainer()
            let context = container.mainContext

            let offlineUser = User(offlineWithGenderCode: 1)
            context.insert(offlineUser)
            try context.save()

            let statusManager = try MockStatusManager.create(
                statusClient: mockStatusClient,
                modelContainer: container
            )

            await statusManager.getStatus()

            let calculatorBefore = try #require(statusManager.currentDayCalculator)
            #expect(calculatorBefore.currentDay == 1)

            let dayActivity = DayActivity(
                day: 1,
                activityTypeRaw: DayActivityType.workout.rawValue,
                count: 5,
                createDate: .now,
                modifyDate: .now,
                user: offlineUser
            )
            context.insert(dayActivity)
            try context.save()

            let activitiesBeforeReset = try context.fetch(FetchDescriptor<DayActivity>())
            #expect(activitiesBeforeReset.count == 1)

            await statusManager.resetProgram()

            #expect(mockStatusClient.startCallCount == 0)
            #expect(statusManager.currentDayCalculator != nil)

            let activitiesAfterReset = try context.fetch(FetchDescriptor<DayActivity>())
            #expect(activitiesAfterReset.isEmpty)
        }

        @Test("Офлайн: повторный вход после logout создаёт нового офлайн-пользователя")
        func offlineReLoginAfterLogoutCreatesNewUser() async throws {
            let mockStatusClient = MockStatusClient()
            let container = try makeContainer()
            let context = container.mainContext

            let offlineUser = User(offlineWithGenderCode: 1)
            context.insert(offlineUser)
            try context.save()

            let statusManager = try MockStatusManager.create(
                statusClient: mockStatusClient,
                modelContainer: container
            )

            await statusManager.getStatus()
            #expect(statusManager.currentDayCalculator != nil)

            statusManager.processAuthStatus(isAuthorized: false)

            let usersAfterLogout = try context.fetch(FetchDescriptor<User>())
            #expect(usersAfterLogout.isEmpty)

            let newOfflineUser = User(offlineWithGenderCode: 2)
            context.insert(newOfflineUser)
            try context.save()

            #expect(newOfflineUser.isOfflineOnly)
            #expect(newOfflineUser.genderCode == 2)

            await statusManager.getStatus()

            #expect(mockStatusClient.currentCallCount == 0)
            let calculator = try #require(statusManager.currentDayCalculator)
            #expect(calculator.currentDay == 1)

            let usersAfterRelogin = try context.fetch(FetchDescriptor<User>())
            #expect(usersAfterRelogin.count == 1)
            let reLoginUser = try #require(usersAfterRelogin.first)
            #expect(reLoginUser.genderCode == 2)
        }

        @Test("Офлайн: несколько DayActivity сохраняются и удаляются при logout")
        func offlineMultipleDayActivitiesPersistAndClearOnLogout() async throws {
            let mockStatusClient = MockStatusClient()
            let container = try makeContainer()
            let context = container.mainContext

            let offlineUser = User(offlineWithGenderCode: 1)
            context.insert(offlineUser)
            try context.save()

            let fiveDaysAgo = try #require(Calendar.current.date(byAdding: .day, value: -5, to: .now))

            let defaults = try MockUserDefaults.create()
            let smWithStartDate = try MockStatusManager.create(
                statusClient: mockStatusClient,
                userDefaults: defaults,
                modelContainer: container
            )
            await smWithStartDate.startNewRun(appDate: fiveDaysAgo)
            await smWithStartDate.getStatus()

            let calculator = try #require(smWithStartDate.currentDayCalculator)
            #expect(calculator.currentDay == 6)

            for day in 1 ... 5 {
                let activity = DayActivity(
                    day: day,
                    activityTypeRaw: day % 2 == 0 ? DayActivityType.rest.rawValue : DayActivityType.workout.rawValue,
                    count: day * 3,
                    createDate: .now,
                    modifyDate: .now,
                    user: offlineUser
                )
                context.insert(activity)
            }
            try context.save()

            let savedActivities = try context.fetch(FetchDescriptor<DayActivity>())
            #expect(savedActivities.count == 5)

            let userActivities = offlineUser.dayActivities
            #expect(userActivities.count == 5)
            #expect(offlineUser.activitiesByDay.count == 5)

            let progress = UserProgress(id: 1)
            progress.user = offlineUser
            context.insert(progress)
            try context.save()

            let savedProgress = try context.fetch(FetchDescriptor<UserProgress>())
            #expect(savedProgress.count == 1)

            smWithStartDate.processAuthStatus(isAuthorized: false)

            let usersAfter = try context.fetch(FetchDescriptor<User>())
            #expect(usersAfter.isEmpty)

            let activitiesAfter = try context.fetch(FetchDescriptor<DayActivity>())
            #expect(activitiesAfter.isEmpty)

            let progressAfter = try context.fetch(FetchDescriptor<UserProgress>())
            #expect(progressAfter.isEmpty)
        }
    }
}
