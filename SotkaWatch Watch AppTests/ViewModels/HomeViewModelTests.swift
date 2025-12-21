import Foundation
@testable import SotkaWatch_Watch_App
import Testing

@MainActor
struct HomeViewModelTests {
    @Test("Инициализирует ViewModel с начальными значениями")
    func initializesViewModelWithDefaultValues() {
        let authService = MockWatchAuthService()
        let connectivityService = MockWatchConnectivityService()

        let viewModel = HomeViewModel(
            authService: authService,
            connectivityService: connectivityService
        )

        #expect(!viewModel.isLoading)
        #expect(viewModel.error == nil)
        #expect(viewModel.currentDay == nil)
        #expect(viewModel.currentActivity == nil)
        #expect(!viewModel.isAuthorized)
    }

    @Test("Проверяет авторизацию при загрузке данных")
    func checksAuthorizationWhenLoadingData() async throws {
        let authService = MockWatchAuthService(isAuthorized: false)
        let connectivityService = MockWatchConnectivityService()

        let viewModel = HomeViewModel(
            authService: authService,
            connectivityService: connectivityService
        )

        await viewModel.loadData()

        #expect(!viewModel.isAuthorized)
        #expect(viewModel.currentDay == nil)
        #expect(viewModel.currentActivity == nil)
    }

    @Test("Проверяет авторизацию при смене scenePhase на active")
    func checksAuthorizationWhenScenePhaseBecomesActive() async throws {
        let authService = MockWatchAuthService(isAuthorized: true)
        let connectivityService = MockWatchConnectivityService()

        let viewModel = HomeViewModel(
            authService: authService,
            connectivityService: connectivityService
        )

        await viewModel.checkAuthStatusOnActivation()

        #expect(viewModel.isAuthorized)
    }

    @Test("Читает текущий день из WatchConnectivityService")
    func readsCurrentDayFromConnectivityService() async throws {
        let authService = MockWatchAuthService(isAuthorized: true)
        let connectivityService = MockWatchConnectivityService()
        connectivityService.currentDay = 5

        let viewModel = HomeViewModel(
            authService: authService,
            connectivityService: connectivityService
        )

        await viewModel.loadData()

        let currentDay = try #require(viewModel.currentDay)
        #expect(currentDay == 5)
    }

    @Test("Загружает текущую активность дня")
    func loadsCurrentActivityForDay() async throws {
        let authService = MockWatchAuthService(isAuthorized: true)
        let connectivityService = MockWatchConnectivityService()
        connectivityService.currentDay = 5
        connectivityService.mockCurrentActivity = .workout

        let viewModel = HomeViewModel(
            authService: authService,
            connectivityService: connectivityService
        )

        await viewModel.loadData()

        let currentActivity = try #require(viewModel.currentActivity)
        #expect(currentActivity == .workout)
    }

    @Test("Загружает данные тренировки при активности типа workout")
    func loadsWorkoutDataWhenActivityIsWorkout() async throws {
        let authService = MockWatchAuthService(isAuthorized: true)
        let connectivityService = MockWatchConnectivityService()
        connectivityService.mockCurrentActivity = .workout
        let workoutData = WorkoutData(
            day: 5,
            executionType: 0,
            trainings: [],
            plannedCount: 4
        )
        connectivityService.currentDay = 5
        connectivityService.mockWorkoutData = workoutData
        connectivityService.mockWorkoutExecutionCount = 3
        connectivityService.mockWorkoutComment = "Отличная тренировка!"

        let viewModel = HomeViewModel(
            authService: authService,
            connectivityService: connectivityService
        )

        await viewModel.loadData()

        let loadedWorkoutData = try #require(viewModel.workoutData)
        #expect(loadedWorkoutData.day == workoutData.day)
        let executionCount = try #require(viewModel.workoutExecutionCount)
        #expect(executionCount == 3)
        let comment = try #require(viewModel.workoutComment)
        #expect(comment == "Отличная тренировка!")
    }

    @Test("Не загружает данные тренировки при активности не типа workout")
    func doesNotLoadWorkoutDataWhenActivityIsNotWorkout() async throws {
        let authService = MockWatchAuthService(isAuthorized: true)
        let connectivityService = MockWatchConnectivityService()
        connectivityService.currentDay = 5
        connectivityService.mockCurrentActivity = .rest

        let viewModel = HomeViewModel(
            authService: authService,
            connectivityService: connectivityService
        )

        await viewModel.loadData()

        #expect(viewModel.workoutData == nil)
        #expect(viewModel.workoutExecutionCount == nil)
        #expect(viewModel.workoutComment == nil)
    }

    @Test("Обрабатывает ошибки при загрузке данных тренировки")
    func handlesErrorsWhenLoadingWorkoutData() async throws {
        let authService = MockWatchAuthService(isAuthorized: true)
        let connectivityService = MockWatchConnectivityService()
        connectivityService.currentDay = 5
        connectivityService.mockCurrentActivity = .workout
        connectivityService.shouldSucceed = false
        connectivityService.mockError = WatchConnectivityError.sessionUnavailable

        let viewModel = HomeViewModel(
            authService: authService,
            connectivityService: connectivityService
        )

        await viewModel.loadData()

        let error = try #require(viewModel.error)
        #expect(error is WatchConnectivityError)
        #expect(viewModel.workoutData == nil)
    }

    @Test("Отправляет тип активности на iPhone")
    func sendsActivityTypeToiPhone() async throws {
        let authService = MockWatchAuthService(isAuthorized: true)
        let connectivityService = MockWatchConnectivityService()
        connectivityService.currentDay = 5

        let viewModel = HomeViewModel(
            authService: authService,
            connectivityService: connectivityService
        )

        await viewModel.loadData()
        let currentDay = try #require(viewModel.currentDay)

        await viewModel.selectActivity(.stretch)

        let sentActivity = try #require(connectivityService.sentActivityType)
        #expect(sentActivity.day == currentDay)
        #expect(sentActivity.activityType == .stretch)
    }

    @Test("Запрашивает данные тренировки при начале тренировки")
    func requestsWorkoutDataWhenStartingWorkout() async throws {
        let authService = MockWatchAuthService(isAuthorized: true)
        let connectivityService = MockWatchConnectivityService()
        let workoutData = WorkoutData(
            day: 5,
            executionType: 0,
            trainings: [],
            plannedCount: 4
        )
        connectivityService.currentDay = 5
        connectivityService.mockWorkoutData = workoutData

        let viewModel = HomeViewModel(
            authService: authService,
            connectivityService: connectivityService
        )

        await viewModel.loadData()
        let currentDay = try #require(viewModel.currentDay)

        let result = await viewModel.startWorkout()

        let requestedDay = try #require(connectivityService.requestedWorkoutDataDay)
        #expect(requestedDay == currentDay)
        let requestedWorkoutData = try #require(result)
        #expect(requestedWorkoutData.day == workoutData.day)
    }

    @Test("Обрабатывает ошибки связи с iPhone")
    func handlesConnectivityErrors() async throws {
        let authService = MockWatchAuthService(isAuthorized: true)
        let connectivityService = MockWatchConnectivityService()
        connectivityService.currentDay = 5
        connectivityService.shouldSucceed = false
        connectivityService.mockError = WatchConnectivityError.sessionUnavailable

        let viewModel = HomeViewModel(
            authService: authService,
            connectivityService: connectivityService
        )

        await viewModel.loadData()

        await viewModel.selectActivity(.workout)

        let error = try #require(viewModel.error)
        #expect(error is WatchConnectivityError)
    }

    @Test("Обрабатывает случай когда currentDay отсутствует в WatchConnectivityService")
    func handlesMissingCurrentDayInConnectivityService() async throws {
        let authService = MockWatchAuthService(isAuthorized: true)
        let connectivityService = MockWatchConnectivityService()
        connectivityService.currentDay = nil

        let viewModel = HomeViewModel(
            authService: authService,
            connectivityService: connectivityService
        )

        await viewModel.loadData()

        #expect(viewModel.currentDay == nil)
        #expect(viewModel.currentActivity == nil)
    }

    @Test("Реагирует на изменения статуса авторизации через WatchAuthService")
    func reactsToAuthStatusChangesThroughWatchAuthService() async throws {
        let authService = MockWatchAuthService(isAuthorized: false)
        let connectivityService = MockWatchConnectivityService()

        let viewModel = HomeViewModel(
            authService: authService,
            connectivityService: connectivityService
        )

        #expect(!viewModel.isAuthorized)

        authService.updateAuthStatus(true)

        #expect(viewModel.isAuthorized)
    }

    @Test("Удаляет активность дня")
    func deletesActivityForDay() async throws {
        let authService = MockWatchAuthService(isAuthorized: true)
        let connectivityService = MockWatchConnectivityService()
        connectivityService.currentDay = 5
        connectivityService.mockCurrentActivity = .workout

        let viewModel = HomeViewModel(
            authService: authService,
            connectivityService: connectivityService
        )

        await viewModel.loadData()
        let currentDay = try #require(viewModel.currentDay)
        #expect(viewModel.currentActivity == .workout)

        await viewModel.deleteActivity(day: currentDay)

        let deletedDay = try #require(connectivityService.deletedActivityDay)
        #expect(deletedDay == currentDay)
        #expect(viewModel.currentActivity == nil)
    }

    @Test("Обновляет currentActivity на nil после успешного удаления текущего дня")
    func updatesCurrentActivityToNilAfterSuccessfulDeletionOfCurrentDay() async throws {
        let authService = MockWatchAuthService(isAuthorized: true)
        let connectivityService = MockWatchConnectivityService()
        connectivityService.currentDay = 5
        connectivityService.mockCurrentActivity = .rest

        let viewModel = HomeViewModel(
            authService: authService,
            connectivityService: connectivityService
        )

        await viewModel.loadData()
        let currentDay = try #require(viewModel.currentDay)
        #expect(viewModel.currentActivity == .rest)

        await viewModel.deleteActivity(day: currentDay)

        #expect(viewModel.currentActivity == nil)
    }

    @Test("Не обновляет currentActivity при удалении другого дня")
    func doesNotUpdateCurrentActivityWhenDeletingOtherDay() async throws {
        let authService = MockWatchAuthService(isAuthorized: true)
        let connectivityService = MockWatchConnectivityService()
        connectivityService.currentDay = 5
        connectivityService.mockCurrentActivity = .workout

        let viewModel = HomeViewModel(
            authService: authService,
            connectivityService: connectivityService
        )

        await viewModel.loadData()
        let currentDay = try #require(viewModel.currentDay)
        #expect(viewModel.currentActivity == .workout)

        let otherDay = currentDay + 1
        await viewModel.deleteActivity(day: otherDay)

        #expect(viewModel.currentActivity == .workout)
        let deletedDay = try #require(connectivityService.deletedActivityDay)
        #expect(deletedDay == otherDay)
    }

    @Test("Обрабатывает ошибки при удалении активности")
    func handlesErrorsWhenDeletingActivity() async throws {
        let authService = MockWatchAuthService(isAuthorized: true)
        let connectivityService = MockWatchConnectivityService()
        connectivityService.currentDay = 5
        connectivityService.shouldSucceed = false
        connectivityService.mockError = WatchConnectivityError.sessionUnavailable

        let viewModel = HomeViewModel(
            authService: authService,
            connectivityService: connectivityService
        )

        await viewModel.loadData()
        let currentDay = try #require(viewModel.currentDay)

        await viewModel.deleteActivity(day: currentDay)

        let error = try #require(viewModel.error)
        #expect(error is WatchConnectivityError)
    }

    @Test("Обновляет данные тренировки при получении обновленных данных через onWorkoutDataReceived")
    func updatesWorkoutDataWhenReceivingUpdatedDataThroughOnWorkoutDataReceived() async throws {
        let authService = MockWatchAuthService(isAuthorized: true)
        let connectivityService = MockWatchConnectivityService()
        connectivityService.currentDay = 5

        let viewModel = HomeViewModel(
            authService: authService,
            connectivityService: connectivityService
        )

        await viewModel.loadData()

        let initialWorkoutData = WorkoutData(
            day: 5,
            executionType: 0,
            trainings: [
                WorkoutPreviewTraining(count: 5, typeId: ExerciseType.pullups.rawValue, sortOrder: 0)
            ],
            plannedCount: 4
        )
        let initialResponse = WorkoutDataResponse(
            workoutData: initialWorkoutData,
            executionCount: nil,
            comment: nil
        )

        viewModel.updateWorkoutDataFromConnectivity(initialResponse)

        let initialData = try #require(viewModel.workoutData)
        #expect(initialData.day == 5)
        #expect(initialData.trainings.count == 1)

        let updatedWorkoutData = WorkoutData(
            day: 5,
            executionType: 0,
            trainings: [
                WorkoutPreviewTraining(count: 7, typeId: ExerciseType.pullups.rawValue, sortOrder: 0),
                WorkoutPreviewTraining(count: 10, typeId: ExerciseType.pushups.rawValue, sortOrder: 1)
            ],
            plannedCount: 5
        )
        let updatedResponse = WorkoutDataResponse(
            workoutData: updatedWorkoutData,
            executionCount: 5,
            comment: "Обновленный комментарий"
        )

        viewModel.updateWorkoutDataFromConnectivity(updatedResponse)

        let updatedData = try #require(viewModel.workoutData)
        #expect(updatedData.day == 5)
        #expect(updatedData.trainings.count == 2)
        #expect(updatedData.plannedCount == 5)
        let executionCount = try #require(viewModel.workoutExecutionCount)
        #expect(executionCount == 5)
        let comment = try #require(viewModel.workoutComment)
        #expect(comment == "Обновленный комментарий")
    }

    @Test("Обновляет данные тренировки при изменении currentActivity на workout")
    func updatesWorkoutDataWhenCurrentActivityChangesToWorkout() async throws {
        let authService = MockWatchAuthService(isAuthorized: true)
        let connectivityService = MockWatchConnectivityService()
        connectivityService.currentDay = 5
        connectivityService.mockCurrentActivity = .rest

        let viewModel = HomeViewModel(
            authService: authService,
            connectivityService: connectivityService
        )

        await viewModel.loadData()
        #expect(viewModel.currentActivity == .rest)
        #expect(viewModel.workoutData == nil)

        let workoutData = WorkoutData(
            day: 5,
            executionType: 0,
            trainings: [
                WorkoutPreviewTraining(count: 5, typeId: ExerciseType.pullups.rawValue, sortOrder: 0)
            ],
            plannedCount: 4
        )
        connectivityService.mockWorkoutData = workoutData
        connectivityService.mockWorkoutExecutionCount = 4
        connectivityService.mockWorkoutComment = "Новый комментарий"

        viewModel.updateCurrentActivityFromConnectivity(.workout)

        let loadedWorkoutData = try #require(viewModel.workoutData)
        #expect(loadedWorkoutData.day == 5)
        let executionCount = try #require(viewModel.workoutExecutionCount)
        #expect(executionCount == 4)
        let comment = try #require(viewModel.workoutComment)
        #expect(comment == "Новый комментарий")
    }

    @Test("Должен предотвращать параллельные вызовы loadData")
    func preventsConcurrentLoadDataCalls() async throws {
        let authService = MockWatchAuthService(isAuthorized: true)
        let connectivityService = MockWatchConnectivityService()
        connectivityService.currentDay = 5
        connectivityService.currentActivity = nil
        connectivityService.requestCurrentActivityDelay = 10_000_000

        let viewModel = HomeViewModel(
            authService: authService,
            connectivityService: connectivityService
        )

        let initialCallCount = connectivityService.requestedCurrentActivityCallCount

        let task1 = Task {
            await viewModel.loadData()
        }

        let task2 = Task {
            await viewModel.loadData()
        }

        await task1.value
        await task2.value

        let finalCallCount = connectivityService.requestedCurrentActivityCallCount
        let actualCalls = finalCallCount - initialCallCount
        #expect(actualCalls == 1)
    }
}
