import Foundation
import SwiftData
@testable import SwiftUI_SotkaApp
import Testing

extension WorkoutPreviewViewModelTests {
    @Suite("Тесты отправки review-события при сохранении тренировки", .serialized)
    @MainActor
    struct ReviewEventTests {
        private func makeViewModel() -> WorkoutPreviewViewModel {
            let viewModel = WorkoutPreviewViewModel()
            viewModel.dayNumber = 5
            viewModel.selectedExecutionType = .cycles
            viewModel.count = 10
            viewModel.trainings = [
                WorkoutPreviewTraining(count: 5, typeId: ExerciseType.pullups.rawValue, sortOrder: 0)
            ]
            return viewModel
        }

        private func makeContext() throws -> (ModelContainer, ModelContext) {
            let container = try ModelContainer(
                for: DayActivity.self,
                DayActivityTraining.self,
                User.self,
                configurations: ModelConfiguration(isStoredInMemoryOnly: true)
            )
            let context = container.mainContext
            let user = User(id: 1)
            context.insert(user)
            try context.save()
            return (container, context)
        }

        @Test("После успешного сохранения вызывает reviewEventReporter")
        func callsReviewReporterAfterSuccessfulSave() async throws {
            let testContext = try makeContext()
            let context = testContext.1
            let activitiesService = DailyActivitiesService(client: MockDaysClient())
            let viewModel = makeViewModel()
            let reporter = MockReviewEventReporter()

            viewModel.saveTrainingAsPassed(
                activitiesService: activitiesService,
                modelContext: context,
                reviewEventReporter: reporter
            )

            await reporter.waitForCallCount(1)
            #expect(reporter.callCount == 1)
            let reportedContext = try #require(reporter.reportedContexts.first)
            #expect(!reportedContext.hadRecentError)
        }

        @Test("При ошибке валидации не вызывает reviewEventReporter")
        func doesNotCallReporterWhenValidationFails() throws {
            let testContext = try makeContext()
            let context = testContext.1
            let activitiesService = DailyActivitiesService(client: MockDaysClient())
            let viewModel = WorkoutPreviewViewModel()
            viewModel.dayNumber = 5
            viewModel.selectedExecutionType = nil
            viewModel.trainings = []
            let reporter = MockReviewEventReporter()

            viewModel.saveTrainingAsPassed(
                activitiesService: activitiesService,
                modelContext: context,
                reviewEventReporter: reporter
            )

            #expect(reporter.callCount == 0)
        }

        @Test("Передаёт hadRecentError = true если есть ошибка в viewModel")
        func passesHadRecentErrorWhenViewModelHasError() async throws {
            let testContext = try makeContext()
            let context = testContext.1
            let activitiesService = DailyActivitiesService(client: MockDaysClient())
            let viewModel = makeViewModel()
            viewModel.error = .executionTypeNotSelected
            viewModel.selectedExecutionType = .cycles
            viewModel.trainings = [
                WorkoutPreviewTraining(count: 5, typeId: ExerciseType.pullups.rawValue, sortOrder: 0)
            ]
            let reporter = MockReviewEventReporter()

            viewModel.saveTrainingAsPassed(
                activitiesService: activitiesService,
                modelContext: context,
                reviewEventReporter: reporter
            )

            await reporter.waitForCallCount(1)
            #expect(reporter.callCount == 1)
            let reportedContext = try #require(reporter.reportedContexts.first)
            #expect(reportedContext.hadRecentError)
        }

        @Test("Без reporter сохранение работает корректно")
        func saveWorksCorrectlyWithoutReporter() throws {
            let testContext = try makeContext()
            let context = testContext.1
            let activitiesService = DailyActivitiesService(client: MockDaysClient())
            let viewModel = makeViewModel()

            viewModel.saveTrainingAsPassed(
                activitiesService: activitiesService,
                modelContext: context
            )

            let savedActivity = try #require(context.fetch(FetchDescriptor<DayActivity>()).first)
            #expect(savedActivity.day == 5)
        }

        @Test("Повторное сохранение дня не создает дубликат активности и отправляет событие")
        func repeatedSaveDoesNotDuplicateActivityAndSendsEvent() async throws {
            let testContext = try makeContext()
            let context = testContext.1
            let activitiesService = DailyActivitiesService(client: MockDaysClient())
            let viewModel = makeViewModel()
            let reporter = MockReviewEventReporter()

            viewModel.saveTrainingAsPassed(
                activitiesService: activitiesService,
                modelContext: context,
                reviewEventReporter: reporter
            )
            viewModel.saveTrainingAsPassed(
                activitiesService: activitiesService,
                modelContext: context,
                reviewEventReporter: reporter
            )

            await reporter.waitForCallCount(2)
            let activities = try context.fetch(FetchDescriptor<DayActivity>())
            let activeWorkouts = activities.filter { $0.day == 5 && !$0.shouldDelete && $0.activityType == .workout }

            #expect(activeWorkouts.count == 1)
            #expect(reporter.callCount == 2)
        }
    }
}
