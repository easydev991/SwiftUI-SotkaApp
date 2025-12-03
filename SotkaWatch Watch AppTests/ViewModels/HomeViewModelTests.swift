import Foundation
@testable import SotkaWatch_Watch_App
import Testing

@MainActor
struct HomeViewModelTests {
    @Test("Инициализирует ViewModel с начальными значениями")
    func initializesViewModelWithDefaultValues() {
        let authService = MockWatchAuthService()
        let connectivityService = MockWatchConnectivityService()
        let appGroupHelper = MockWatchAppGroupHelper()

        let viewModel = HomeViewModel(
            authService: authService,
            connectivityService: connectivityService,
            appGroupHelper: appGroupHelper
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
        let appGroupHelper = MockWatchAppGroupHelper(isAuthorized: false)

        let viewModel = HomeViewModel(
            authService: authService,
            connectivityService: connectivityService,
            appGroupHelper: appGroupHelper
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
        let appGroupHelper = MockWatchAppGroupHelper(isAuthorized: true)

        let viewModel = HomeViewModel(
            authService: authService,
            connectivityService: connectivityService,
            appGroupHelper: appGroupHelper
        )

        await viewModel.checkAuthStatusOnActivation()

        #expect(viewModel.isAuthorized)
    }

    @Test("Вычисляет текущий день из startDate")
    func calculatesCurrentDayFromStartDate() async throws {
        let startDate = Calendar.current.date(byAdding: .day, value: -5, to: Date.now) ?? Date.now
        let authService = MockWatchAuthService(isAuthorized: true)
        let connectivityService = MockWatchConnectivityService()
        let appGroupHelper = MockWatchAppGroupHelper(
            isAuthorized: true,
            startDate: startDate
        )

        let viewModel = HomeViewModel(
            authService: authService,
            connectivityService: connectivityService,
            appGroupHelper: appGroupHelper
        )

        await viewModel.loadData()

        let currentDay = try #require(viewModel.currentDay)
        #expect(currentDay > 0)
    }

    @Test("Загружает текущую активность дня")
    func loadsCurrentActivityForDay() async throws {
        let startDate = Calendar.current.date(byAdding: .day, value: -5, to: Date.now) ?? Date.now
        let authService = MockWatchAuthService(isAuthorized: true)
        let connectivityService = MockWatchConnectivityService()
        connectivityService.mockCurrentActivity = .workout
        let appGroupHelper = MockWatchAppGroupHelper(
            isAuthorized: true,
            startDate: startDate
        )

        let viewModel = HomeViewModel(
            authService: authService,
            connectivityService: connectivityService,
            appGroupHelper: appGroupHelper
        )

        await viewModel.loadData()

        let currentActivity = try #require(viewModel.currentActivity)
        #expect(currentActivity == .workout)
    }

    @Test("Отправляет тип активности на iPhone")
    func sendsActivityTypeToiPhone() async throws {
        let startDate = Calendar.current.date(byAdding: .day, value: -5, to: Date.now) ?? Date.now
        let authService = MockWatchAuthService(isAuthorized: true)
        let connectivityService = MockWatchConnectivityService()
        let appGroupHelper = MockWatchAppGroupHelper(
            isAuthorized: true,
            startDate: startDate
        )

        let viewModel = HomeViewModel(
            authService: authService,
            connectivityService: connectivityService,
            appGroupHelper: appGroupHelper
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
        let startDate = Calendar.current.date(byAdding: .day, value: -5, to: Date.now) ?? Date.now
        let authService = MockWatchAuthService(isAuthorized: true)
        let connectivityService = MockWatchConnectivityService()
        let workoutData = WorkoutData(
            day: 5,
            executionType: 0,
            trainings: [],
            plannedCount: 4
        )
        connectivityService.mockWorkoutData = workoutData
        let appGroupHelper = MockWatchAppGroupHelper(
            isAuthorized: true,
            startDate: startDate
        )

        let viewModel = HomeViewModel(
            authService: authService,
            connectivityService: connectivityService,
            appGroupHelper: appGroupHelper
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
        let startDate = Calendar.current.date(byAdding: .day, value: -5, to: Date.now) ?? Date.now
        let authService = MockWatchAuthService(isAuthorized: true)
        let connectivityService = MockWatchConnectivityService()
        connectivityService.shouldSucceed = false
        connectivityService.mockError = WatchConnectivityError.sessionUnavailable
        let appGroupHelper = MockWatchAppGroupHelper(
            isAuthorized: true,
            startDate: startDate
        )

        let viewModel = HomeViewModel(
            authService: authService,
            connectivityService: connectivityService,
            appGroupHelper: appGroupHelper
        )

        await viewModel.loadData()

        await viewModel.selectActivity(.workout)

        let error = try #require(viewModel.error)
        #expect(error is WatchConnectivityError)
    }

    @Test("Обрабатывает случай когда startDate отсутствует в App Group")
    func handlesMissingStartDateInAppGroup() async throws {
        let authService = MockWatchAuthService(isAuthorized: true)
        let connectivityService = MockWatchConnectivityService()
        let appGroupHelper = MockWatchAppGroupHelper(
            isAuthorized: true,
            startDate: nil
        )

        let viewModel = HomeViewModel(
            authService: authService,
            connectivityService: connectivityService,
            appGroupHelper: appGroupHelper
        )

        await viewModel.loadData()

        #expect(viewModel.currentDay == nil)
        #expect(viewModel.currentActivity == nil)
    }

    @Test("Читает актуальное значение startDate из App Group при каждом вычислении текущего дня")
    func readsActualStartDateFromAppGroupOnEachCalculation() async throws {
        let startDate1 = Calendar.current.date(byAdding: .day, value: -5, to: Date.now) ?? Date.now
        let authService = MockWatchAuthService(isAuthorized: true)
        let connectivityService = MockWatchConnectivityService()
        var appGroupHelper = MockWatchAppGroupHelper(
            isAuthorized: true,
            startDate: startDate1
        )

        let viewModel = HomeViewModel(
            authService: authService,
            connectivityService: connectivityService,
            appGroupHelper: appGroupHelper
        )

        await viewModel.loadData()
        let currentDay1 = try #require(viewModel.currentDay)

        let startDate2 = Calendar.current.date(byAdding: .day, value: -10, to: Date.now) ?? Date.now
        appGroupHelper = MockWatchAppGroupHelper(
            isAuthorized: true,
            startDate: startDate2
        )

        let viewModel2 = HomeViewModel(
            authService: authService,
            connectivityService: connectivityService,
            appGroupHelper: appGroupHelper
        )

        await viewModel2.loadData()
        let currentDay2 = try #require(viewModel2.currentDay)

        #expect(currentDay2 > currentDay1)
    }

    @Test("Реагирует на изменения статуса авторизации через WatchAuthService")
    func reactsToAuthStatusChangesThroughWatchAuthService() async throws {
        let authService = MockWatchAuthService(isAuthorized: false)
        let connectivityService = MockWatchConnectivityService()
        let appGroupHelper = MockWatchAppGroupHelper(isAuthorized: false)

        let viewModel = HomeViewModel(
            authService: authService,
            connectivityService: connectivityService,
            appGroupHelper: appGroupHelper
        )

        #expect(!viewModel.isAuthorized)

        authService.updateAuthStatus(true)

        #expect(viewModel.isAuthorized)
    }
}
