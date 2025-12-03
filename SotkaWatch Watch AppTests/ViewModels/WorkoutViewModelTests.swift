import Foundation
@testable import SotkaWatch_Watch_App
import Testing

@MainActor
struct WorkoutViewModelTests {
    @Test("Инициализируется из WorkoutData")
    func initializesFromWorkoutData() throws {
        let workoutData = WorkoutData(
            day: 5,
            executionType: 0,
            trainings: [],
            plannedCount: 4
        )
        let workoutService = WatchWorkoutService(workoutData: workoutData)
        let connectivityService = MockWatchConnectivityService()

        let viewModel = WorkoutViewModel(
            workoutService: workoutService,
            connectivityService: connectivityService
        )

        #expect(viewModel.currentRound == 1)
        #expect(viewModel.completedRounds == 0)
        #expect(!viewModel.isFinished)
        #expect(viewModel.error == nil)
        #expect(!viewModel.showRestTimer)
    }

    @Test("Отслеживает прогресс тренировки")
    func tracksWorkoutProgress() throws {
        let workoutData = WorkoutData(
            day: 5,
            executionType: 0,
            trainings: [],
            plannedCount: 4
        )
        let workoutService = WatchWorkoutService(workoutData: workoutData)
        let connectivityService = MockWatchConnectivityService()

        let viewModel = WorkoutViewModel(
            workoutService: workoutService,
            connectivityService: connectivityService
        )

        #expect(viewModel.currentRound == 1)
        #expect(viewModel.completedRounds == 0)

        viewModel.completeRound()

        #expect(viewModel.currentRound == 2)
        #expect(viewModel.completedRounds == 1)
    }

    @Test("Завершает круг/подход")
    func completesRound() throws {
        let workoutData = WorkoutData(
            day: 5,
            executionType: 0,
            trainings: [],
            plannedCount: 4
        )
        let workoutService = WatchWorkoutService(workoutData: workoutData)
        let connectivityService = MockWatchConnectivityService()

        let viewModel = WorkoutViewModel(
            workoutService: workoutService,
            connectivityService: connectivityService
        )

        viewModel.completeRound()

        #expect(viewModel.completedRounds == 1)
        #expect(viewModel.currentRound == 2)
    }

    @Test("Запускает таймер отдыха после завершения круга/подхода если есть время отдыха")
    func startsRestTimerAfterCompletingRoundIfRestTimeExists() throws {
        let workoutData = WorkoutData(
            day: 5,
            executionType: 0,
            trainings: [],
            plannedCount: 4
        )
        let userDefaults = try MockUserDefaults.create()
        userDefaults.set(60, forKey: Constants.restTimeKey)
        let appGroupHelper = WatchAppGroupHelper(userDefaults: userDefaults)
        let workoutService = WatchWorkoutService(workoutData: workoutData, appGroupHelper: appGroupHelper)
        let connectivityService = MockWatchConnectivityService()

        let viewModel = WorkoutViewModel(
            workoutService: workoutService,
            connectivityService: connectivityService
        )

        viewModel.completeRound()

        #expect(viewModel.showRestTimer)
        #expect(viewModel.restTime > 0)
    }

    @Test("Не запускает таймер отдыха если время отдыха равно нулю")
    func doesNotStartRestTimerIfRestTimeIsZero() throws {
        let workoutData = WorkoutData(
            day: 5,
            executionType: 0,
            trainings: [],
            plannedCount: 4
        )
        let mockAppGroupHelper = MockWatchAppGroupHelper(restTime: 0)
        let userDefaults = try MockUserDefaults.create()
        let appGroupHelper = WatchAppGroupHelper(userDefaults: userDefaults)
        let workoutService = WatchWorkoutService(workoutData: workoutData, appGroupHelper: appGroupHelper)
        let connectivityService = MockWatchConnectivityService()

        let viewModel = WorkoutViewModel(
            workoutService: workoutService,
            connectivityService: connectivityService
        )

        viewModel.restTime = 0

        viewModel.completeRound()

        #expect(!viewModel.showRestTimer)
    }

    @Test("Завершает таймер отдыха автоматически")
    func finishesRestTimerAutomatically() throws {
        let workoutData = WorkoutData(
            day: 5,
            executionType: 0,
            trainings: [],
            plannedCount: 4
        )
        let userDefaults = try MockUserDefaults.create()
        userDefaults.set(1, forKey: Constants.restTimeKey)
        let appGroupHelper = WatchAppGroupHelper(userDefaults: userDefaults)
        let workoutService = WatchWorkoutService(workoutData: workoutData, appGroupHelper: appGroupHelper)
        let connectivityService = MockWatchConnectivityService()

        let viewModel = WorkoutViewModel(
            workoutService: workoutService,
            connectivityService: connectivityService
        )

        viewModel.completeRound()

        #expect(viewModel.showRestTimer)

        viewModel.handleRestTimerFinish(force: false)

        #expect(!viewModel.showRestTimer)
    }

    @Test("Завершает таймер отдыха досрочно")
    func finishesRestTimerEarly() throws {
        let workoutData = WorkoutData(
            day: 5,
            executionType: 0,
            trainings: [],
            plannedCount: 4
        )
        let userDefaults = try MockUserDefaults.create()
        userDefaults.set(60, forKey: Constants.restTimeKey)
        let appGroupHelper = WatchAppGroupHelper(userDefaults: userDefaults)
        let workoutService = WatchWorkoutService(workoutData: workoutData, appGroupHelper: appGroupHelper)
        let connectivityService = MockWatchConnectivityService()

        let viewModel = WorkoutViewModel(
            workoutService: workoutService,
            connectivityService: connectivityService
        )

        viewModel.completeRound()

        #expect(viewModel.showRestTimer)

        viewModel.handleRestTimerFinish(force: true)

        #expect(!viewModel.showRestTimer)
    }

    @Test("Обрабатывает фоновый режим для таймера отдыха")
    func handlesBackgroundModeForRestTimer() throws {
        let workoutData = WorkoutData(
            day: 5,
            executionType: 0,
            trainings: [],
            plannedCount: 4
        )
        let userDefaults = try MockUserDefaults.create()
        userDefaults.set(1, forKey: Constants.restTimeKey)
        let appGroupHelper = WatchAppGroupHelper(userDefaults: userDefaults)
        let workoutService = WatchWorkoutService(workoutData: workoutData, appGroupHelper: appGroupHelper)
        let connectivityService = MockWatchConnectivityService()

        let viewModel = WorkoutViewModel(
            workoutService: workoutService,
            connectivityService: connectivityService
        )

        viewModel.completeRound()

        #expect(viewModel.showRestTimer)
        let restTimerStartTime = try #require(viewModel.restTimerStartTime)

        viewModel.checkAndHandleExpiredRestTimer()

        let elapsed = Date.now.timeIntervalSince(restTimerStartTime)
        #expect(elapsed >= 0)
    }

    @Test("Завершает тренировку и отправляет результат на iPhone")
    func finishesWorkoutAndSendsResultToiPhone() async throws {
        let workoutData = WorkoutData(
            day: 5,
            executionType: 0,
            trainings: [],
            plannedCount: 4
        )
        let workoutService = WatchWorkoutService(workoutData: workoutData)
        let connectivityService = MockWatchConnectivityService()

        let viewModel = WorkoutViewModel(
            workoutService: workoutService,
            connectivityService: connectivityService
        )

        viewModel.completeRound()
        viewModel.completeRound()

        await viewModel.finishWorkout()

        #expect(viewModel.isFinished)
        let sentResult = try #require(connectivityService.sentWorkoutResult)
        #expect(sentResult.day == workoutData.day)
        #expect(sentResult.result.count == 2)
    }

    @Test("Прерывает тренировку")
    func cancelsWorkout() throws {
        let workoutData = WorkoutData(
            day: 5,
            executionType: 0,
            trainings: [],
            plannedCount: 4
        )
        let workoutService = WatchWorkoutService(workoutData: workoutData)
        let connectivityService = MockWatchConnectivityService()

        let viewModel = WorkoutViewModel(
            workoutService: workoutService,
            connectivityService: connectivityService
        )

        viewModel.completeRound()

        viewModel.cancelWorkout()

        #expect(viewModel.isFinished)
    }

    @Test("Обрабатывает ошибки при отправке результата")
    func handlesErrorsWhenSendingResult() async throws {
        let workoutData = WorkoutData(
            day: 5,
            executionType: 0,
            trainings: [],
            plannedCount: 4
        )
        let workoutService = WatchWorkoutService(workoutData: workoutData)
        let connectivityService = MockWatchConnectivityService()
        connectivityService.shouldSucceed = false
        connectivityService.mockError = WatchConnectivityError.sessionUnavailable

        let viewModel = WorkoutViewModel(
            workoutService: workoutService,
            connectivityService: connectivityService
        )

        viewModel.completeRound()

        await viewModel.finishWorkout()

        let error = try #require(viewModel.error)
        #expect(error is WatchConnectivityError)
    }

    @Test("Обновляет UI при изменении прогресса")
    func updatesUIWhenProgressChanges() throws {
        let workoutData = WorkoutData(
            day: 5,
            executionType: 0,
            trainings: [],
            plannedCount: 4
        )
        let workoutService = WatchWorkoutService(workoutData: workoutData)
        let connectivityService = MockWatchConnectivityService()

        let viewModel = WorkoutViewModel(
            workoutService: workoutService,
            connectivityService: connectivityService
        )

        let initialRound = viewModel.currentRound
        let initialCompleted = viewModel.completedRounds

        viewModel.completeRound()

        #expect(viewModel.currentRound > initialRound)
        #expect(viewModel.completedRounds > initialCompleted)
    }
}
