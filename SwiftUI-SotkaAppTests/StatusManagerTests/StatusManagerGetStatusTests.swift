import Foundation
import SwiftData
@testable import SwiftUI_SotkaApp
import Testing

extension StatusManagerTests {
    @Suite("Тесты для getStatus")
    @MainActor
    struct GetStatusTests {
        @Test("Обновляет currentDayCalculator в начале метода")
        func getStatusUpdatesCurrentDayCalculatorAtStart() async throws {
            let now = Date.now
            let startDate = try #require(Calendar.current.date(byAdding: .day, value: -50, to: now))
            let mockStatusClient = MockStatusClient(
                startResult: .success(CurrentRunResponse(date: nil, maxForAllRunsDay: nil)),
                currentResult: .success(CurrentRunResponse(date: startDate, maxForAllRunsDay: nil))
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

            let calculator = try #require(statusManager.currentDayCalculator)
            #expect(calculator.startDate.isTheSameDayIgnoringTime(startDate))
        }

        @Test("Не выполняет синхронизацию, если state.isLoading == true")
        func getStatusSkipsSyncWhenLoading() async throws {
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

            let task1 = Task {
                await statusManager.getStatus(context: context)
            }

            try await Task.sleep(nanoseconds: 10_000_000)

            let callCountDuringLoading = mockStatusClient.currentCallCount

            let task2 = Task {
                await statusManager.getStatus(context: context)
            }

            try await Task.sleep(nanoseconds: 10_000_000)

            #expect(mockStatusClient.currentCallCount == callCountDuringLoading)

            await task1.value
            await task2.value
        }

        @Test("Устанавливает maxReadInfoPostDay из ответа сервера")
        func getStatusSetsMaxReadInfoPostDayFromServer() async throws {
            let maxDay = 75
            let mockStatusClient = MockStatusClient(
                currentResult: .success(CurrentRunResponse(date: nil, maxForAllRunsDay: maxDay))
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

            await statusManager.getStatus(context: context)

            #expect(statusManager.maxReadInfoPostDay == maxDay)
        }

        @Test("Устанавливает maxReadInfoPostDay = 0, если maxForAllRunsDay == nil")
        func getStatusSetsMaxReadInfoPostDayToZeroWhenNil() async throws {
            let mockStatusClient = MockStatusClient(
                currentResult: .success(CurrentRunResponse(date: nil, maxForAllRunsDay: nil))
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

            await statusManager.getStatus(context: context)

            #expect(statusManager.maxReadInfoPostDay == 0)
        }

        @Test("Вызывает start при отсутствии даты ни в приложении, ни на сайте")
        func getStatusCallsStartWhenNoDates() async throws {
            let mockStatusClient = MockStatusClient(
                startResult: .success(CurrentRunResponse(date: Date.now, maxForAllRunsDay: nil)),
                currentResult: .success(CurrentRunResponse(date: nil, maxForAllRunsDay: nil))
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

            await statusManager.getStatus(context: context)

            #expect(mockStatusClient.startCallCount > 0)
            #expect(!statusManager.state.isLoading)
        }

        @Test("Вызывает start с датой из приложения, если дата есть только в приложении")
        func getStatusCallsStartWithAppDate() async throws {
            let now = Date.now
            let appDate = try #require(Calendar.current.date(byAdding: .day, value: -30, to: now))
            let mockStatusClient = MockStatusClient(
                startResult: .success(CurrentRunResponse(date: nil, maxForAllRunsDay: nil)),
                currentResult: .success(CurrentRunResponse(date: nil, maxForAllRunsDay: nil))
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

            #expect(!statusManager.state.isLoading)
            let calculator = try #require(statusManager.currentDayCalculator)
            #expect(calculator.startDate.isTheSameDayIgnoringTime(appDate))
        }

        @Test("Вызывает syncWithSiteDate с датой с сайта, если дата есть только на сайте")
        func getStatusCallsSyncWithSiteDate() async throws {
            let now = Date.now
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

            await statusManager.getStatus(context: context)

            #expect(!statusManager.state.isLoading)
            let calculator = try #require(statusManager.currentDayCalculator)
            #expect(calculator.startDate.isTheSameDayIgnoringTime(siteDate))
        }

        @Test("Вызывает syncJournalAndProgress, если даты совпадают")
        func getStatusCallsSyncJournalWhenDatesMatch() async throws {
            let now = Date.now
            let startDate = try #require(Calendar.current.date(byAdding: .day, value: -20, to: now))
            let mockStatusClient = MockStatusClient(
                startResult: .success(CurrentRunResponse(date: nil, maxForAllRunsDay: nil)),
                currentResult: .success(CurrentRunResponse(date: startDate, maxForAllRunsDay: nil))
            )
            let mockProgressClient = MockProgressClient()
            let mockExerciseClient = MockExerciseClient()
            let mockDaysClient = MockDaysClient()

            let statusManager = try MockStatusManager.create(
                statusClient: mockStatusClient,
                exerciseClient: mockExerciseClient,
                progressClient: mockProgressClient,
                daysClient: mockDaysClient
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

            let initialProgressCalls = mockProgressClient.getProgressCallCount
            let initialExerciseCalls = mockExerciseClient.getCustomExercisesCallCount
            let initialDaysCalls = mockDaysClient.getDaysCallCount

            await statusManager.getStatus(context: context)

            #expect(mockProgressClient.getProgressCallCount > initialProgressCalls)
            #expect(mockExerciseClient.getCustomExercisesCallCount > initialExerciseCalls)
            #expect(mockDaysClient.getDaysCallCount > initialDaysCalls)
            #expect(statusManager.conflictingSyncModel == nil)
            #expect(!statusManager.state.isLoading)
        }

        @Test("Устанавливает conflictingSyncModel, если даты не совпадают")
        func getStatusSetsConflictingSyncModelWhenDatesDiffer() async throws {
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
            #expect(!statusManager.state.isLoading)
        }

        @Test("Устанавливает state = .error при ошибке при первичной загрузке")
        func getStatusSetsErrorStateOnInitialLoadError() async throws {
            let error = MockStatusClient.MockError.demoError
            let mockStatusClient = MockStatusClient(
                currentResult: .failure(error)
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

            await statusManager.getStatus(context: context)

            #expect(!statusManager.state.isLoadingInitialData)
            #expect(!statusManager.state.isSyncing)
        }

        @Test("Не изменяет state при ошибке при повторной загрузке")
        func getStatusDoesNotChangeStateOnSubsequentLoadError() async throws {
            let now = Date.now
            let startDate = try #require(Calendar.current.date(byAdding: .day, value: -20, to: now))
            let mockStatusClient = MockStatusClient(
                startResult: .success(CurrentRunResponse(date: nil, maxForAllRunsDay: nil)),
                currentResult: .success(CurrentRunResponse(date: startDate, maxForAllRunsDay: nil))
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

            #expect(!statusManager.state.isLoading)

            let error = MockStatusClient.MockError.demoError
            mockStatusClient.currentResult = .failure(error)

            await statusManager.getStatus(context: context)

            #expect(!statusManager.state.isLoadingInitialData)
            #expect(!statusManager.state.isError)
        }

        @Test("Устанавливает state = .isLoadingInitialData, если didLoadInitialData == false")
        func getStatusSetsLoadingInitialDataState() async throws {
            let mockStatusClient = MockStatusClient(
                startResult: .success(CurrentRunResponse(date: Date.now, maxForAllRunsDay: nil)),
                currentResult: .success(CurrentRunResponse(date: nil, maxForAllRunsDay: nil))
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

            let task = Task {
                await statusManager.getStatus(context: context)
            }

            try await Task.sleep(nanoseconds: 10_000_000)

            #expect(statusManager.state.isLoadingInitialData)

            await task.value
        }

        @Test("Устанавливает state = .isSynchronizingData, если didLoadInitialData == true")
        func getStatusSetsSynchronizingDataState() async throws {
            let now = Date.now
            let startDate = try #require(Calendar.current.date(byAdding: .day, value: -20, to: now))
            let mockStatusClient = MockStatusClient(
                startResult: .success(CurrentRunResponse(date: nil, maxForAllRunsDay: nil)),
                currentResult: .success(CurrentRunResponse(date: startDate, maxForAllRunsDay: nil))
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

            let task = Task {
                await statusManager.getStatus(context: context)
            }

            try await Task.sleep(nanoseconds: 10_000_000)

            #expect(statusManager.state.isSyncing)

            await task.value
        }

        @Test("Обновляет currentDayCalculator в конце метода после синхронизации")
        func getStatusUpdatesCurrentDayCalculatorAtEnd() async throws {
            let now = Date.now
            let startDate = try #require(Calendar.current.date(byAdding: .day, value: -20, to: now))
            let mockStatusClient = MockStatusClient(
                startResult: .success(CurrentRunResponse(date: nil, maxForAllRunsDay: nil)),
                currentResult: .success(CurrentRunResponse(date: startDate, maxForAllRunsDay: nil))
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

            let calculator = try #require(statusManager.currentDayCalculator)
            #expect(calculator.startDate.isTheSameDayIgnoringTime(startDate))
        }
    }
}

extension StatusManager.State {
    var isError: Bool {
        if case .error = self { true } else { false }
    }
}
