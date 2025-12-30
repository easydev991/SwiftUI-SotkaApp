import Foundation
import SwiftData
@testable import SwiftUI_SotkaApp
import Testing

extension StatusManagerTests {
    @Suite("Тесты для sendWorkoutDataToWatch")
    @MainActor
    struct SendWorkoutDataToWatchTests {
        @Test("Отправляет полные данные тренировки на часы при наличии активности workout")
        func sendsWorkoutDataWhenWorkoutActivityExists() throws {
            let mockSession = MockWCSession(isReachable: true)
            let modelConfiguration = ModelConfiguration(isStoredInMemoryOnly: true)
            let modelContainer = try ModelContainer(
                for: User.self,
                DayActivity.self,
                DayActivityTraining.self,
                configurations: modelConfiguration
            )
            let statusManager = try MockStatusManager.create(
                daysClient: MockDaysClient(),
                userDefaults: MockUserDefaults.create(),
                modelContainer: modelContainer,
                watchConnectivitySessionProtocol: mockSession
            )

            let context = statusManager.modelContainer.mainContext

            let user = User(id: 1, userName: "testuser", fullName: "Test User", email: "test@example.com")
            context.insert(user)
            let dayActivity = DayActivity(
                day: 42,
                activityTypeRaw: DayActivityType.workout.rawValue,
                count: 4,
                plannedCount: 3,
                executeTypeRaw: ExerciseExecutionType.cycles.rawValue,
                trainingTypeRaw: nil,
                duration: 1800,
                comment: "Отличная тренировка",
                createDate: .now,
                modifyDate: .now,
                user: user
            )
            dayActivity.trainings = [
                DayActivityTraining(
                    count: 5,
                    typeId: ExerciseType.pullups.rawValue,
                    sortOrder: 0
                ),
                DayActivityTraining(
                    count: 10,
                    typeId: ExerciseType.pushups.rawValue,
                    sortOrder: 1
                )
            ]
            context.insert(dayActivity)
            try context.save()

            statusManager.sendWorkoutDataToWatch(day: 42)

            #expect(mockSession.sentMessages.count == 1)
            let sentMessage = try #require(mockSession.sentMessages.first)
            let command = try #require(sentMessage["command"] as? String)
            #expect(command == Constants.WatchCommand.sendWorkoutData.rawValue)
            let day = try #require(sentMessage["day"] as? Int)
            #expect(day == 42)
            let executionType = try #require(sentMessage["executionType"] as? Int)
            #expect(executionType == ExerciseExecutionType.cycles.rawValue)
            let plannedCount = try #require(sentMessage["plannedCount"] as? Int)
            #expect(plannedCount == 3)
            let executionCount = try #require(sentMessage["executionCount"] as? Int)
            #expect(executionCount == 4)
            let comment = try #require(sentMessage["comment"] as? String)
            #expect(comment == "Отличная тренировка")
            let trainings = try #require(sentMessage["trainings"] as? [[String: Any]])
            #expect(trainings.count == 2)
        }

        @Test("Отправляет данные тренировки без executionCount и comment если они отсутствуют")
        func sendsWorkoutDataWithoutOptionalFields() throws {
            let mockSession = MockWCSession(isReachable: true)
            let modelConfiguration = ModelConfiguration(isStoredInMemoryOnly: true)
            let modelContainer = try ModelContainer(
                for: User.self,
                DayActivity.self,
                DayActivityTraining.self,
                configurations: modelConfiguration
            )
            let statusManager = try MockStatusManager.create(
                daysClient: MockDaysClient(),
                userDefaults: MockUserDefaults.create(),
                modelContainer: modelContainer,
                watchConnectivitySessionProtocol: mockSession
            )

            let context = statusManager.modelContainer.mainContext

            let user = User(id: 1, userName: "testuser", fullName: "Test User", email: "test@example.com")
            context.insert(user)
            let dayActivity = DayActivity(
                day: 42,
                activityTypeRaw: DayActivityType.workout.rawValue,
                count: nil,
                plannedCount: 3,
                executeTypeRaw: ExerciseExecutionType.cycles.rawValue,
                trainingTypeRaw: nil,
                duration: nil,
                comment: nil,
                createDate: .now,
                modifyDate: .now,
                user: user
            )
            dayActivity.trainings = [
                DayActivityTraining(
                    count: 5,
                    typeId: ExerciseType.pullups.rawValue,
                    sortOrder: 0
                )
            ]
            context.insert(dayActivity)
            try context.save()

            statusManager.sendWorkoutDataToWatch(day: 42)

            #expect(mockSession.sentMessages.count == 1)
            let sentMessage = try #require(mockSession.sentMessages.first)
            let command = try #require(sentMessage["command"] as? String)
            #expect(command == Constants.WatchCommand.sendWorkoutData.rawValue)
            #expect(sentMessage["executionCount"] == nil)
            #expect(sentMessage["comment"] == nil)
        }

        @Test("Создает данные тренировки через WorkoutProgramCreator если активность не найдена")
        func createsWorkoutDataViaCreatorWhenActivityNotFound() throws {
            let mockSession = MockWCSession(isReachable: true)
            let modelConfiguration = ModelConfiguration(isStoredInMemoryOnly: true)
            let modelContainer = try ModelContainer(
                for: User.self,
                DayActivity.self,
                DayActivityTraining.self,
                configurations: modelConfiguration
            )
            let statusManager = try MockStatusManager.create(
                daysClient: MockDaysClient(),
                userDefaults: MockUserDefaults.create(),
                modelContainer: modelContainer,
                watchConnectivitySessionProtocol: mockSession
            )

            statusManager.sendWorkoutDataToWatch(day: 42)

            #expect(mockSession.sentMessages.count == 1)
            let sentMessage = try #require(mockSession.sentMessages.first)
            let command = try #require(sentMessage["command"] as? String)
            #expect(command == Constants.WatchCommand.sendWorkoutData.rawValue)
            let day = try #require(sentMessage["day"] as? Int)
            #expect(day == 42)
        }

        @Test("Не отправляет данные если активность не является тренировкой")
        func doesNotSendDataWhenActivityIsNotWorkout() throws {
            let mockSession = MockWCSession(isReachable: true)
            let modelConfiguration = ModelConfiguration(isStoredInMemoryOnly: true)
            let modelContainer = try ModelContainer(
                for: User.self,
                DayActivity.self,
                configurations: modelConfiguration
            )
            let statusManager = try MockStatusManager.create(
                daysClient: MockDaysClient(),
                userDefaults: MockUserDefaults.create(),
                modelContainer: modelContainer,
                watchConnectivitySessionProtocol: mockSession
            )

            let context = statusManager.modelContainer.mainContext

            let user = User(id: 1, userName: "testuser", fullName: "Test User", email: "test@example.com")
            context.insert(user)
            let dayActivity = DayActivity(
                day: 42,
                activityTypeRaw: DayActivityType.rest.rawValue,
                count: nil,
                plannedCount: nil,
                executeTypeRaw: nil,
                trainingTypeRaw: nil,
                duration: nil,
                comment: nil,
                createDate: .now,
                modifyDate: .now,
                user: user
            )
            context.insert(dayActivity)
            try context.save()

            statusManager.sendWorkoutDataToWatch(day: 42)

            #expect(mockSession.sentMessages.isEmpty)
        }

        @Test("Не отправляет данные когда часы недоступны")
        func doesNotSendDataWhenWatchUnavailable() throws {
            let mockSession = MockWCSession(isReachable: false)
            let modelConfiguration = ModelConfiguration(isStoredInMemoryOnly: true)
            let modelContainer = try ModelContainer(
                for: User.self,
                DayActivity.self,
                DayActivityTraining.self,
                configurations: modelConfiguration
            )
            let statusManager = try MockStatusManager.create(
                daysClient: MockDaysClient(),
                userDefaults: MockUserDefaults.create(),
                modelContainer: modelContainer,
                watchConnectivitySessionProtocol: mockSession
            )

            let context = statusManager.modelContainer.mainContext

            let user = User(id: 1, userName: "testuser", fullName: "Test User", email: "test@example.com")
            context.insert(user)
            let dayActivity = DayActivity(
                day: 42,
                activityTypeRaw: DayActivityType.workout.rawValue,
                count: 4,
                plannedCount: 3,
                executeTypeRaw: ExerciseExecutionType.cycles.rawValue,
                trainingTypeRaw: nil,
                duration: nil,
                comment: nil,
                createDate: .now,
                modifyDate: .now,
                user: user
            )
            context.insert(dayActivity)
            try context.save()

            statusManager.sendWorkoutDataToWatch(day: 42)

            #expect(mockSession.sentMessages.isEmpty)
        }
    }
}
