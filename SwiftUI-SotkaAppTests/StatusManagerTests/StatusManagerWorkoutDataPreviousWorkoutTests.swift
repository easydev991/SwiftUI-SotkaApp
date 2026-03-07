import Foundation
import SwiftData
@testable import SwiftUI_SotkaApp
import Testing

extension StatusManagerTests {
    @Suite("Тесты для handleGetWorkoutDataCommand с использованием предыдущей тренировки")
    @MainActor
    struct WorkoutDataPreviousWorkoutTests {
        private func createStatusManager(
            modelContainer: ModelContainer,
            mockSession: MockWCSession
        ) throws -> StatusManager {
            try MockStatusManager.create(
                daysClient: MockDaysClient(),
                userDefaults: MockUserDefaults.create(),
                modelContainer: modelContainer,
                watchConnectivitySessionProtocol: mockSession
            )
        }

        private func createContainer() throws -> ModelContainer {
            try ModelContainer(
                for: User.self,
                DayActivity.self,
                DayActivityTraining.self,
                configurations: ModelConfiguration(isStoredInMemoryOnly: true)
            )
        }

        private func createPassedWorkout(
            day: Int,
            count: Int?,
            plannedCount: Int?,
            executionType: ExerciseExecutionType = .cycles,
            trainings: [DayActivityTraining] = [],
            modifyDate: Date = .now,
            user: User,
            context: ModelContext
        ) {
            let activity = DayActivity(
                day: day,
                activityTypeRaw: DayActivityType.workout.rawValue,
                count: count,
                plannedCount: plannedCount,
                executeTypeRaw: executionType.rawValue,
                trainingTypeRaw: nil,
                createDate: .now,
                modifyDate: modifyDate,
                user: user
            )
            for training in trainings {
                training.dayActivity = activity
                activity.trainings.append(training)
            }
            context.insert(activity)
        }

        @Test("Новая тренировка использует plannedCount из последней пройденной")
        func handleGetWorkoutDataCommand_NewWorkout_UsesPlannedCountFromLastWorkout() throws {
            let mockSession = MockWCSession(isReachable: true)
            let container = try createContainer()
            let context = container.mainContext
            let statusManager = try createStatusManager(modelContainer: container, mockSession: mockSession)

            let user = User(id: 1, userName: "testuser", fullName: "Test User", email: "test@example.com")
            context.insert(user)
            createPassedWorkout(day: 5, count: 7, plannedCount: 6, user: user, context: context)
            try context.save()

            let message: [String: Any] = [
                "command": Constants.WatchCommand.getWorkoutData.rawValue,
                "day": 10
            ]

            var replyReceived: [String: Any]?
            statusManager.handleWatchCommand(message) { reply in
                replyReceived = reply
            }

            let reply = try #require(replyReceived)
            let plannedCount = try #require(reply["plannedCount"] as? Int)
            #expect(plannedCount == 7)
        }

        @Test("Приоритет count над plannedCount")
        func handleGetWorkoutDataCommand_NewWorkout_PrioritizesCountOverPlannedCount() throws {
            let mockSession = MockWCSession(isReachable: true)
            let container = try createContainer()
            let context = container.mainContext
            let statusManager = try createStatusManager(modelContainer: container, mockSession: mockSession)

            let user = User(id: 1, userName: "testuser", fullName: "Test User", email: "test@example.com")
            context.insert(user)
            createPassedWorkout(day: 5, count: 8, plannedCount: 6, user: user, context: context)
            try context.save()

            let message: [String: Any] = [
                "command": Constants.WatchCommand.getWorkoutData.rawValue,
                "day": 10
            ]

            var replyReceived: [String: Any]?
            statusManager.handleWatchCommand(message) { reply in
                replyReceived = reply
            }

            let reply = try #require(replyReceived)
            let plannedCount = try #require(reply["plannedCount"] as? Int)
            #expect(plannedCount == 8)
        }

        @Test("Fallback на plannedCount когда count = nil — активность не считается пройденной")
        func handleGetWorkoutDataCommand_NewWorkout_FallbackToPlannedCount() throws {
            let mockSession = MockWCSession(isReachable: true)
            let container = try createContainer()
            let context = container.mainContext
            let statusManager = try createStatusManager(modelContainer: container, mockSession: mockSession)

            let user = User(id: 1, userName: "testuser", fullName: "Test User", email: "test@example.com")
            context.insert(user)
            // Активность с count=nil не считается пройденной, поэтому используется дефолт
            createPassedWorkout(day: 5, count: nil, plannedCount: 5, user: user, context: context)
            try context.save()

            let message: [String: Any] = [
                "command": Constants.WatchCommand.getWorkoutData.rawValue,
                "day": 10
            ]

            var replyReceived: [String: Any]?
            statusManager.handleWatchCommand(message) { reply in
                replyReceived = reply
            }

            let reply = try #require(replyReceived)
            let plannedCount = try #require(reply["plannedCount"] as? Int)
            // Ожидается дефолтное значение для дня 10, а не plannedCount из непройденной активности
            let expectedCount = WorkoutProgramCreator.calculatePlannedCircles(for: 10, executionType: .cycles)
            #expect(plannedCount == expectedCount)
        }

        @Test("Fallback на дефолт когда нет предыдущей тренировки")
        func handleGetWorkoutDataCommand_NewWorkout_FallbackToDefault_WhenNoLastWorkout() throws {
            let mockSession = MockWCSession(isReachable: true)
            let container = try createContainer()
            let context = container.mainContext
            let statusManager = try createStatusManager(modelContainer: container, mockSession: mockSession)

            let user = User(id: 1, userName: "testuser", fullName: "Test User", email: "test@example.com")
            context.insert(user)
            try context.save()

            let message: [String: Any] = [
                "command": Constants.WatchCommand.getWorkoutData.rawValue,
                "day": 10
            ]

            var replyReceived: [String: Any]?
            statusManager.handleWatchCommand(message) { reply in
                replyReceived = reply
            }

            let reply = try #require(replyReceived)
            let plannedCount = try #require(reply["plannedCount"] as? Int)
            let expectedCount = WorkoutProgramCreator.calculatePlannedCircles(for: 10, executionType: .cycles)
            #expect(plannedCount == expectedCount)
        }

        @Test("Существующая активность использует свой plannedCount")
        func handleGetWorkoutDataCommand_ExistingActivity_UsesItsOwnPlannedCount() throws {
            let mockSession = MockWCSession(isReachable: true)
            let container = try createContainer()
            let context = container.mainContext
            let statusManager = try createStatusManager(modelContainer: container, mockSession: mockSession)

            let user = User(id: 1, userName: "testuser", fullName: "Test User", email: "test@example.com")
            context.insert(user)

            let existingActivity = DayActivity(
                day: 10,
                activityTypeRaw: DayActivityType.workout.rawValue,
                count: nil,
                plannedCount: 12,
                executeTypeRaw: ExerciseExecutionType.cycles.rawValue,
                trainingTypeRaw: nil,
                createDate: .now,
                modifyDate: .now,
                user: user
            )
            existingActivity.trainings = [
                DayActivityTraining(count: 5, typeId: ExerciseType.pullups.rawValue, sortOrder: 0)
            ]
            context.insert(existingActivity)

            createPassedWorkout(day: 5, count: 7, plannedCount: 6, user: user, context: context)
            try context.save()

            let message: [String: Any] = [
                "command": Constants.WatchCommand.getWorkoutData.rawValue,
                "day": 10
            ]

            var replyReceived: [String: Any]?
            statusManager.handleWatchCommand(message) { reply in
                replyReceived = reply
            }

            let reply = try #require(replyReceived)
            let plannedCount = try #require(reply["plannedCount"] as? Int)
            #expect(plannedCount == 12)
        }

        @Test("Работает с разными типами выполнения")
        func handleGetWorkoutDataCommand_NewWorkout_WorksWithDifferentExecutionTypes() throws {
            let mockSession = MockWCSession(isReachable: true)
            let container = try createContainer()
            let context = container.mainContext
            let statusManager = try createStatusManager(modelContainer: container, mockSession: mockSession)

            let user = User(id: 1, userName: "testuser", fullName: "Test User", email: "test@example.com")
            context.insert(user)

            let activity = DayActivity(
                day: 5,
                activityTypeRaw: DayActivityType.workout.rawValue,
                count: 4,
                plannedCount: 3,
                executeTypeRaw: ExerciseExecutionType.sets.rawValue,
                trainingTypeRaw: nil,
                createDate: .now,
                modifyDate: .now,
                user: user
            )
            context.insert(activity)
            try context.save()

            let message: [String: Any] = [
                "command": Constants.WatchCommand.getWorkoutData.rawValue,
                "day": 10
            ]

            var replyReceived: [String: Any]?
            statusManager.handleWatchCommand(message) { reply in
                replyReceived = reply
            }

            let reply = try #require(replyReceived)
            let plannedCount = try #require(reply["plannedCount"] as? Int)
            #expect(plannedCount == 4)
        }

        // MARK: - Новые тесты для executionType и повторов

        @Test("Подставляет executionType из предыдущей тренировки")
        func handleGetWorkoutDataCommand_NewWorkout_UsesExecutionTypeFromPreviousWorkout() throws {
            let mockSession = MockWCSession(isReachable: true)
            let container = try createContainer()
            let context = container.mainContext
            let statusManager = try createStatusManager(modelContainer: container, mockSession: mockSession)

            let user = User(id: 1, userName: "testuser", fullName: "Test User", email: "test@example.com")
            context.insert(user)

            // Предыдущая тренировка с sets
            createPassedWorkout(day: 5, count: 6, plannedCount: 5, executionType: .sets, user: user, context: context)
            try context.save()

            let message: [String: Any] = [
                "command": Constants.WatchCommand.getWorkoutData.rawValue,
                "day": 10
            ]

            var replyReceived: [String: Any]?
            statusManager.handleWatchCommand(message) { reply in
                replyReceived = reply
            }

            let reply = try #require(replyReceived)
            let executionType = try #require(reply["executionType"] as? Int)
            #expect(executionType == ExerciseExecutionType.sets.rawValue)
        }

        @Test("Подставляет повторы для каждого упражнения")
        func handleGetWorkoutDataCommand_NewWorkout_UsesExerciseCountsFromPreviousWorkout() throws {
            let mockSession = MockWCSession(isReachable: true)
            let container = try createContainer()
            let context = container.mainContext
            let statusManager = try createStatusManager(modelContainer: container, mockSession: mockSession)

            let user = User(id: 1, userName: "testuser", fullName: "Test User", email: "test@example.com")
            context.insert(user)

            // Предыдущая тренировка с упражнениями
            let previousTrainings = [
                DayActivityTraining(count: 10, typeId: ExerciseType.pullups.rawValue, sortOrder: 0),
                DayActivityTraining(count: 15, typeId: ExerciseType.squats.rawValue, sortOrder: 1),
                DayActivityTraining(count: 12, typeId: ExerciseType.pushups.rawValue, sortOrder: 2)
            ]
            createPassedWorkout(
                day: 5,
                count: 6,
                plannedCount: 5,
                executionType: .cycles,
                trainings: previousTrainings,
                user: user,
                context: context
            )
            try context.save()

            let message: [String: Any] = [
                "command": Constants.WatchCommand.getWorkoutData.rawValue,
                "day": 10
            ]

            var replyReceived: [String: Any]?
            statusManager.handleWatchCommand(message) { reply in
                replyReceived = reply
            }

            let reply = try #require(replyReceived)
            let trainingsArray = try #require(reply["trainings"] as? [[String: Any]])
            let trainingsData = try JSONSerialization.data(withJSONObject: trainingsArray)
            let trainings = try JSONDecoder().decode([WorkoutPreviewTraining].self, from: trainingsData)

            let pullups = trainings.first { $0.typeId == ExerciseType.pullups.rawValue }
            let squats = trainings.first { $0.typeId == ExerciseType.squats.rawValue }
            let pushups = trainings.first { $0.typeId == ExerciseType.pushups.rawValue }

            #expect(pullups?.count == 10)
            #expect(squats?.count == 15)
            #expect(pushups?.count == 12)
        }

        @Test("Приоритет count над дефолтом для упражнений")
        func handleGetWorkoutDataCommand_NewWorkout_PrioritizesCountOverDefaultForExercises() throws {
            let mockSession = MockWCSession(isReachable: true)
            let container = try createContainer()
            let context = container.mainContext
            let statusManager = try createStatusManager(modelContainer: container, mockSession: mockSession)

            let user = User(id: 1, userName: "testuser", fullName: "Test User", email: "test@example.com")
            context.insert(user)

            // Предыдущая тренировка с pullups=10 (дефолт=1)
            let previousTrainings = [
                DayActivityTraining(count: 10, typeId: ExerciseType.pullups.rawValue, sortOrder: 0)
            ]
            createPassedWorkout(
                day: 5,
                count: 6,
                plannedCount: 5,
                executionType: .cycles,
                trainings: previousTrainings,
                user: user,
                context: context
            )
            try context.save()

            let message: [String: Any] = [
                "command": Constants.WatchCommand.getWorkoutData.rawValue,
                "day": 10
            ]

            var replyReceived: [String: Any]?
            statusManager.handleWatchCommand(message) { reply in
                replyReceived = reply
            }

            let reply = try #require(replyReceived)
            let trainingsArray = try #require(reply["trainings"] as? [[String: Any]])
            let trainingsData = try JSONSerialization.data(withJSONObject: trainingsArray)
            let trainings = try JSONDecoder().decode([WorkoutPreviewTraining].self, from: trainingsData)

            let pullups = trainings.first { $0.typeId == ExerciseType.pullups.rawValue }
            #expect(pullups?.count == 10)
        }

        @Test("Использует дефолт для упражнений которых не было в предыдущей тренировке")
        func handleGetWorkoutDataCommand_NewWorkout_UsesDefaultForMissingExercises() throws {
            let mockSession = MockWCSession(isReachable: true)
            let container = try createContainer()
            let context = container.mainContext
            let statusManager = try createStatusManager(modelContainer: container, mockSession: mockSession)

            let user = User(id: 1, userName: "testuser", fullName: "Test User", email: "test@example.com")
            context.insert(user)

            // Предыдущая тренировка только с squats
            let previousTrainings = [
                DayActivityTraining(count: 15, typeId: ExerciseType.squats.rawValue, sortOrder: 0)
            ]
            createPassedWorkout(
                day: 5,
                count: 6,
                plannedCount: 5,
                executionType: .cycles,
                trainings: previousTrainings,
                user: user,
                context: context
            )
            try context.save()

            // Получаем дефолтное значение для pullups
            let defaultCreator = WorkoutProgramCreator(day: 10)
            let defaultPullups = defaultCreator.trainings.first { $0.typeId == ExerciseType.pullups.rawValue }?.count

            let message: [String: Any] = [
                "command": Constants.WatchCommand.getWorkoutData.rawValue,
                "day": 10
            ]

            var replyReceived: [String: Any]?
            statusManager.handleWatchCommand(message) { reply in
                replyReceived = reply
            }

            let reply = try #require(replyReceived)
            let trainingsArray = try #require(reply["trainings"] as? [[String: Any]])
            let trainingsData = try JSONSerialization.data(withJSONObject: trainingsArray)
            let trainings = try JSONDecoder().decode([WorkoutPreviewTraining].self, from: trainingsData)

            let pullups = trainings.first { $0.typeId == ExerciseType.pullups.rawValue }
            #expect(pullups?.count == defaultPullups)
        }

        @Test("getWorkoutData выбирает предыдущую тренировку по максимальному day")
        func handleGetWorkoutDataCommand_NewWorkout_UsesMaxDayNotModifyDate() throws {
            let mockSession = MockWCSession(isReachable: true)
            let container = try createContainer()
            let context = container.mainContext
            let statusManager = try createStatusManager(modelContainer: container, mockSession: mockSession)

            let user = User(id: 1, userName: "testuser", fullName: "Test User", email: "test@example.com")
            context.insert(user)

            createPassedWorkout(
                day: 4,
                count: 9,
                plannedCount: 7,
                modifyDate: .now,
                user: user,
                context: context
            )
            createPassedWorkout(
                day: 6,
                count: 5,
                plannedCount: 4,
                modifyDate: Date.now.addingTimeInterval(-86_400),
                user: user,
                context: context
            )
            try context.save()

            let message: [String: Any] = [
                "command": Constants.WatchCommand.getWorkoutData.rawValue,
                "day": 10
            ]

            var replyReceived: [String: Any]?
            statusManager.handleWatchCommand(message) { reply in
                replyReceived = reply
            }

            let reply = try #require(replyReceived)
            let plannedCount = try #require(reply["plannedCount"] as? Int)
            #expect(plannedCount == 5)
        }

        @Test("getWorkoutData игнорирует тренировки из дней >= текущего")
        func handleGetWorkoutDataCommand_NewWorkout_IgnoresDaysAfterOrEqualCurrentDay() throws {
            let mockSession = MockWCSession(isReachable: true)
            let container = try createContainer()
            let context = container.mainContext
            let statusManager = try createStatusManager(modelContainer: container, mockSession: mockSession)

            let user = User(id: 1, userName: "testuser", fullName: "Test User", email: "test@example.com")
            context.insert(user)

            createPassedWorkout(day: 8, count: 6, plannedCount: 5, user: user, context: context)
            createPassedWorkout(day: 11, count: 12, plannedCount: 11, user: user, context: context)
            createPassedWorkout(day: 12, count: 14, plannedCount: 13, user: user, context: context)
            try context.save()

            let message: [String: Any] = [
                "command": Constants.WatchCommand.getWorkoutData.rawValue,
                "day": 10
            ]

            var replyReceived: [String: Any]?
            statusManager.handleWatchCommand(message) { reply in
                replyReceived = reply
            }

            let reply = try #require(replyReceived)
            let plannedCount = try #require(reply["plannedCount"] as? Int)
            #expect(plannedCount == 6)
        }
    }
}
