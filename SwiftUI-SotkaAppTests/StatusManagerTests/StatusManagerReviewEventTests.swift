import Foundation
import SwiftData
@testable import SwiftUI_SotkaApp
import Testing

extension StatusManagerTests {
    @Suite("Тесты отправки review-события при сохранении тренировки с часов", .serialized)
    @MainActor
    struct ReviewEventTests {
        private func makeSaveWorkoutMessage(
            day: Int = 42,
            count: Int = 5,
            duration: Int = 2000,
            executionType: Int = ExerciseExecutionType.cycles.rawValue,
            comment: String? = nil
        ) -> [String: Any] {
            let resultDict: [String: Any] = ["count": count, "duration": duration]
            var message: [String: Any] = [
                "command": Constants.WatchCommand.saveWorkout.rawValue,
                "day": day,
                "result": resultDict,
                "executionType": executionType
            ]
            if let comment {
                message["comment"] = comment
            }
            return message
        }

        @Test("После успешного сохранения с часов вызывает reviewEventReporter")
        func callsReviewReporterAfterWatchSave() async throws {
            let mockSession = MockWCSession(isReachable: true)
            let reporter = MockReviewEventReporter()
            let statusManager = try MockStatusManager.create(
                daysClient: MockDaysClient(),
                userDefaults: MockUserDefaults.create(),
                modelContainer: ModelContainer(
                    for: User.self, DayActivity.self, DayActivityTraining.self,
                    configurations: ModelConfiguration(isStoredInMemoryOnly: true)
                ),
                watchConnectivitySessionProtocol: mockSession,
                reviewEventReporter: reporter
            )

            let context = statusManager.modelContainer.mainContext
            let user = User(id: 1)
            context.insert(user)
            try context.save()

            let message = makeSaveWorkoutMessage()
            statusManager.handleWatchCommand(message) { _ in }

            await reporter.waitForCallCount(1)
            #expect(reporter.callCount == 1)
            let reportedContext = try #require(reporter.reportedContexts.first)
            #expect(!reportedContext.hadRecentError)
        }

        @Test("При ошибке декодирования не вызывает reviewEventReporter")
        func doesNotCallReporterWhenDecodingFails() throws {
            let mockSession = MockWCSession(isReachable: true)
            let reporter = MockReviewEventReporter()
            let statusManager = try MockStatusManager.create(
                daysClient: MockDaysClient(),
                userDefaults: MockUserDefaults.create(),
                watchConnectivitySessionProtocol: mockSession,
                reviewEventReporter: reporter
            )

            let message: [String: Any] = [
                "command": Constants.WatchCommand.saveWorkout.rawValue
            ]
            statusManager.handleWatchCommand(message) { _ in }

            #expect(reporter.callCount == 0)
        }

        @Test("Без reporter сохранение с часов работает корректно")
        func watchSaveWorksCorrectlyWithoutReporter() throws {
            let mockSession = MockWCSession(isReachable: true)
            let statusManager = try MockStatusManager.create(
                daysClient: MockDaysClient(),
                userDefaults: MockUserDefaults.create(),
                modelContainer: ModelContainer(
                    for: User.self, DayActivity.self, DayActivityTraining.self,
                    configurations: ModelConfiguration(isStoredInMemoryOnly: true)
                ),
                watchConnectivitySessionProtocol: mockSession
            )

            let context = statusManager.modelContainer.mainContext
            let user = User(id: 1)
            context.insert(user)
            try context.save()

            let message = makeSaveWorkoutMessage()
            statusManager.handleWatchCommand(message) { _ in }

            let activity = statusManager.dailyActivitiesService.getActivity(dayNumber: 42, context: context)
            let activityType = try #require(activity?.activityType)
            #expect(activityType == .workout)
        }

        @Test("Повторное сохранение с часов не создает дубликат и отправляет событие")
        func repeatedWatchSaveDoesNotDuplicateActivityAndSendsEvent() async throws {
            let mockSession = MockWCSession(isReachable: true)
            let reporter = MockReviewEventReporter()
            let statusManager = try MockStatusManager.create(
                daysClient: MockDaysClient(),
                userDefaults: MockUserDefaults.create(),
                modelContainer: ModelContainer(
                    for: User.self, DayActivity.self, DayActivityTraining.self,
                    configurations: ModelConfiguration(isStoredInMemoryOnly: true)
                ),
                watchConnectivitySessionProtocol: mockSession,
                reviewEventReporter: reporter
            )

            let context = statusManager.modelContainer.mainContext
            let user = User(id: 1)
            context.insert(user)
            try context.save()

            let message = makeSaveWorkoutMessage()
            statusManager.handleWatchCommand(message) { _ in }
            statusManager.handleWatchCommand(message) { _ in }

            await reporter.waitForCallCount(2)
            let activities = try context.fetch(FetchDescriptor<DayActivity>())
            let activeWorkouts = activities.filter { $0.day == 42 && !$0.shouldDelete && $0.activityType == .workout }

            #expect(activeWorkouts.count == 1)
            #expect(reporter.callCount == 2)
        }
    }
}
