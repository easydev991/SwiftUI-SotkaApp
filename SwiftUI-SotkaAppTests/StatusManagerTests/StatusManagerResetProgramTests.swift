import Foundation
import SwiftData
@testable import SwiftUI_SotkaApp
import Testing

extension StatusManagerTests {
    @Suite("Тесты для resetProgram")
    @MainActor
    struct ResetProgramTests {
        @Test("Успешный сброс программы в офлайн режиме")
        func resetProgramOffline() async throws {
            let mockStatusClient = MockStatusClient()
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

            let activity = DayActivity(
                day: 1,
                activityTypeRaw: 1,
                count: 5,
                createDate: .now,
                modifyDate: .now,
                user: user
            )
            context.insert(activity)

            let progress = UserProgress(id: 1, pullUps: 10, pushUps: 20, squats: 30, weight: 70.0)
            progress.user = user
            context.insert(progress)

            let customExercise = CustomExercise(
                id: "test-exercise",
                name: "Test Exercise",
                imageId: 1,
                createDate: .now,
                modifyDate: .now,
                user: user
            )
            context.insert(customExercise)

            user.setFavoriteInfopostIds(["1", "2"])
            user.setReadInfopostDays([1, 2, 3])
            user.setUnsyncedReadInfopostDays([4, 5])

            try context.save()

            await statusManager.resetProgram(context: context)

            let users = try context.fetch(FetchDescriptor<User>())
            let savedUser = try #require(users.first)
            #expect(savedUser.dayActivities.isEmpty)
            #expect(savedUser.progressResults.isEmpty)

            let activities = try context.fetch(FetchDescriptor<DayActivity>())
            #expect(activities.isEmpty)

            let progressResults = try context.fetch(FetchDescriptor<UserProgress>())
            #expect(progressResults.isEmpty)

            let customExercises = try context.fetch(FetchDescriptor<CustomExercise>())
            #expect(customExercises.count == 1)

            #expect(users.count == 1)
            #expect(savedUser.favoriteInfopostIds.isEmpty)
            #expect(savedUser.readInfopostDays.isEmpty)
            #expect(savedUser.unsyncedReadInfopostDays.isEmpty)
        }

        @Test("Успешный сброс программы с синхронизацией на сервер")
        func resetProgramWithSync() async throws {
            let newStartDate = Date.now
            let mockStatusClient = MockStatusClient(
                startResult: .success(CurrentRunResponse(date: newStartDate, maxForAllRunsDay: nil))
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

            let activity = DayActivity(
                day: 1,
                activityTypeRaw: 1,
                count: 5,
                createDate: .now,
                modifyDate: .now,
                user: user
            )
            context.insert(activity)

            let progress = UserProgress(id: 1, pullUps: 10, pushUps: 20, squats: 30, weight: 70.0)
            progress.user = user
            context.insert(progress)
            try context.save()

            await statusManager.resetProgram(context: context)

            let users = try context.fetch(FetchDescriptor<User>())
            let savedUser = try #require(users.first)
            #expect(savedUser.dayActivities.isEmpty)
            #expect(savedUser.progressResults.isEmpty)

            #expect(mockStatusClient.startCallCount == 1)
            let activities = try context.fetch(FetchDescriptor<DayActivity>())
            #expect(activities.isEmpty)
            let progressResults = try context.fetch(FetchDescriptor<UserProgress>())
            #expect(progressResults.isEmpty)
            #expect(!statusManager.state.isLoading)
            #expect(statusManager.currentDayCalculator != nil)
        }

        @Test("Удаление всех DayActivity и DayActivityTraining через каскад")
        func resetProgramDeletesDayActivitiesAndTrainings() async throws {
            let mockStatusClient = MockStatusClient()
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

            let activity = DayActivity(
                day: 1,
                activityTypeRaw: 1,
                count: 5,
                createDate: .now,
                modifyDate: .now,
                user: user
            )
            context.insert(activity)

            let training = DayActivityTraining(
                count: 10,
                typeId: 1,
                customTypeId: nil,
                sortOrder: 0,
                dayActivity: activity
            )
            context.insert(training)
            try context.save()

            await statusManager.resetProgram(context: context)

            let users = try context.fetch(FetchDescriptor<User>())
            let savedUser = try #require(users.first)
            #expect(savedUser.dayActivities.isEmpty)

            let activities = try context.fetch(FetchDescriptor<DayActivity>())
            #expect(activities.isEmpty)

            let trainings = try context.fetch(FetchDescriptor<DayActivityTraining>())
            #expect(trainings.isEmpty)
        }

        @Test("Удаление всех UserProgress с локальными фото")
        func resetProgramDeletesUserProgressWithPhotos() async throws {
            let mockStatusClient = MockStatusClient()
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

            let progress = UserProgress(
                id: 1,
                pullUps: 10,
                pushUps: 20,
                squats: 30,
                weight: 70.0,
                dataPhotoFront: Data([1, 2, 3]),
                dataPhotoBack: Data([4, 5, 6]),
                dataPhotoSide: Data([7, 8, 9])
            )
            progress.user = user
            context.insert(progress)
            try context.save()

            await statusManager.resetProgram(context: context)

            let users = try context.fetch(FetchDescriptor<User>())
            let savedUser = try #require(users.first)
            #expect(savedUser.progressResults.isEmpty)

            let progressResults = try context.fetch(FetchDescriptor<UserProgress>())
            #expect(progressResults.isEmpty)
        }

        @Test("Сохранение CustomExercise при сбросе")
        func resetProgramPreservesCustomExercises() async throws {
            let mockStatusClient = MockStatusClient()
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

            let customExercise = CustomExercise(
                id: "test-exercise",
                name: "Test Exercise",
                imageId: 1,
                createDate: .now,
                modifyDate: .now,
                user: user
            )
            context.insert(customExercise)
            try context.save()

            await statusManager.resetProgram(context: context)

            let customExercises = try context.fetch(FetchDescriptor<CustomExercise>())
            #expect(customExercises.count == 1)
            let savedExercise = try #require(customExercises.first)
            #expect(savedExercise.id == "test-exercise")
            #expect(savedExercise.name == "Test Exercise")
        }

        @Test("Очистка данных инфопостов в User")
        func resetProgramClearsInfopostsData() async throws {
            let mockStatusClient = MockStatusClient()
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

            user.setFavoriteInfopostIds(["1", "2", "3"])
            user.setReadInfopostDays([1, 2, 3, 4, 5])
            user.setUnsyncedReadInfopostDays([6, 7, 8])
            try context.save()

            await statusManager.resetProgram(context: context)

            let users = try context.fetch(FetchDescriptor<User>())
            let savedUser = try #require(users.first)
            #expect(savedUser.favoriteInfopostIds.isEmpty)
            #expect(savedUser.readInfopostDays.isEmpty)
            #expect(savedUser.unsyncedReadInfopostDays.isEmpty)
        }

        @Test("Сохранение пользователя при сбросе")
        func resetProgramPreservesUser() async throws {
            let mockStatusClient = MockStatusClient()
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
            let originalUserId = user.id

            await statusManager.resetProgram(context: context)

            let users = try context.fetch(FetchDescriptor<User>())
            #expect(users.count == 1)
            let savedUser = try #require(users.first)
            #expect(savedUser.id == originalUserId)
        }

        @Test("Установка новой startDate из ответа сервера")
        func resetProgramSetsNewStartDateFromServer() async throws {
            let newStartDate = Date.now.addingTimeInterval(-86400)
            let mockStatusClient = MockStatusClient(
                startResult: .success(CurrentRunResponse(date: newStartDate, maxForAllRunsDay: nil))
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

            await statusManager.resetProgram(context: context)

            #expect(mockStatusClient.startCallCount == 1)
            let calculator = try #require(statusManager.currentDayCalculator)
            #expect(calculator.startDate.isTheSameDayIgnoringTime(newStartDate))
            #expect(!statusManager.state.isLoading)
        }

        @Test("Установка startDate = Date.now при ошибке API")
        func resetProgramSetsCurrentDateOnAPIError() async throws {
            let mockStatusClient = MockStatusClient(
                startResult: .failure(MockStatusClient.MockError.demoError)
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

            let beforeReset = Date.now

            await statusManager.resetProgram(context: context)

            let afterReset = Date.now

            #expect(mockStatusClient.startCallCount == 1)
            let calculator = try #require(statusManager.currentDayCalculator)
            #expect(calculator.startDate >= beforeReset)
            #expect(calculator.startDate <= afterReset)
            #expect(!statusManager.state.isLoading)
        }

        @Test("Обработка ошибки API с продолжением в офлайн режиме")
        func resetProgramContinuesOnAPIError() async throws {
            let mockStatusClient = MockStatusClient(
                startResult: .failure(MockStatusClient.MockError.demoError)
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

            let activity = DayActivity(
                day: 1,
                activityTypeRaw: 1,
                count: 5,
                createDate: .now,
                modifyDate: .now,
                user: user
            )
            context.insert(activity)

            let progress = UserProgress(id: 1, pullUps: 10, pushUps: 20, squats: 30, weight: 70.0)
            progress.user = user
            context.insert(progress)
            try context.save()

            await statusManager.resetProgram(context: context)

            let users = try context.fetch(FetchDescriptor<User>())
            let savedUser = try #require(users.first)
            #expect(savedUser.dayActivities.isEmpty)
            #expect(savedUser.progressResults.isEmpty)

            let activities = try context.fetch(FetchDescriptor<DayActivity>())
            #expect(activities.isEmpty)
            let progressResults = try context.fetch(FetchDescriptor<UserProgress>())
            #expect(progressResults.isEmpty)
            #expect(mockStatusClient.startCallCount == 1)
            #expect(!statusManager.state.isLoading)
            #expect(statusManager.currentDayCalculator != nil)
        }

        @Test("Перезапуск программы после сброса через startNewRun")
        func resetProgramRestartsProgramThroughStartNewRun() async throws {
            let newStartDate = Date.now
            let mockStatusClient = MockStatusClient(
                startResult: .success(CurrentRunResponse(date: newStartDate, maxForAllRunsDay: nil))
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

            let activity = DayActivity(
                day: 50,
                activityTypeRaw: 1,
                count: 5,
                createDate: .now,
                modifyDate: .now,
                user: user
            )
            context.insert(activity)

            let progress = UserProgress(id: 1, pullUps: 10, pushUps: 20, squats: 30, weight: 70.0)
            progress.user = user
            context.insert(progress)
            try context.save()

            await statusManager.resetProgram(context: context)

            let users = try context.fetch(FetchDescriptor<User>())
            let savedUser = try #require(users.first)
            #expect(savedUser.dayActivities.isEmpty)
            #expect(savedUser.progressResults.isEmpty)

            #expect(mockStatusClient.startCallCount == 1)
            let activities = try context.fetch(FetchDescriptor<DayActivity>())
            #expect(activities.isEmpty)
            let progressResults = try context.fetch(FetchDescriptor<UserProgress>())
            #expect(progressResults.isEmpty)
            let calculator = try #require(statusManager.currentDayCalculator)
            #expect(calculator.startDate.isTheSameDayIgnoringTime(newStartDate))
            #expect(!statusManager.state.isLoading)
        }

        @Test("Обработка ошибки при отсутствии пользователя")
        func resetProgramHandlesMissingUser() async throws {
            let mockStatusClient = MockStatusClient()
            let statusManager = try MockStatusManager.create(statusClient: mockStatusClient)

            let modelConfiguration = ModelConfiguration(isStoredInMemoryOnly: true)
            let modelContainer = try ModelContainer(
                for: User.self,
                configurations: modelConfiguration
            )
            let context = modelContainer.mainContext

            await statusManager.resetProgram(context: context)

            #expect(!statusManager.state.isLoading)
            #expect(mockStatusClient.startCallCount == 0)
        }
    }
}
