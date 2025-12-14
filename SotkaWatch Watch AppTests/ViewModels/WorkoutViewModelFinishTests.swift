import Foundation
@testable import SotkaWatch_Watch_App
import Testing

@MainActor
struct WorkoutViewModelFinishTests {
    @Test("Должен завершать тренировку и отправлять результат на iPhone")
    func finishWorkout() async throws {
        let connectivityService = MockWatchConnectivityService()
        let appGroupHelper = MockWatchAppGroupHelper(restTime: 60)
        let viewModel = WorkoutViewModel(
            connectivityService: connectivityService,
            appGroupHelper: appGroupHelper
        )

        let trainings = [
            WorkoutPreviewTraining(count: 5, typeId: 0)
        ]

        viewModel.setupWorkoutData(
            dayNumber: 1,
            executionType: .cycles,
            trainings: trainings,
            plannedCount: 2,
            restTime: 60
        )

        for _ in 0 ..< viewModel.stepStates.count {
            if viewModel.currentStep != nil {
                viewModel.completeCurrentStep()
                if viewModel.showTimer {
                    viewModel.handleRestTimerFinish(force: false)
                }
            }
        }

        await viewModel.finishWorkout()

        let sentResult = try #require(connectivityService.sentWorkoutResult)
        #expect(sentResult.day == 1)
        #expect(sentResult.result.count == 2)
        #expect(sentResult.executionType == .cycles)
    }

    @Test("Должен прерывать тренировку и создавать результат с interrupt")
    func cancelWorkout() throws {
        let connectivityService = MockWatchConnectivityService()
        let appGroupHelper = MockWatchAppGroupHelper(restTime: 60)
        let viewModel = WorkoutViewModel(
            connectivityService: connectivityService,
            appGroupHelper: appGroupHelper
        )

        let trainings = [
            WorkoutPreviewTraining(count: 5, typeId: 0)
        ]

        viewModel.setupWorkoutData(
            dayNumber: 1,
            executionType: .cycles,
            trainings: trainings,
            plannedCount: 4,
            restTime: 60
        )

        // Завершаем разминку
        viewModel.completeCurrentStep()
        // Завершаем первый круг
        viewModel.completeCurrentStep()
        if viewModel.showTimer {
            viewModel.handleRestTimerFinish(force: false)
        }

        viewModel.cancelWorkout()

        let result = viewModel.getWorkoutResult(interrupt: true)
        let workoutResult = try #require(result)
        #expect(workoutResult.count == 1)
    }

    @Test("Должен получать результат тренировки")
    func getWorkoutResult() throws {
        let connectivityService = MockWatchConnectivityService()
        let appGroupHelper = MockWatchAppGroupHelper(restTime: 60)
        let viewModel = WorkoutViewModel(
            connectivityService: connectivityService,
            appGroupHelper: appGroupHelper
        )

        let trainings = [
            WorkoutPreviewTraining(count: 5, typeId: 0)
        ]

        viewModel.setupWorkoutData(
            dayNumber: 1,
            executionType: .cycles,
            trainings: trainings,
            plannedCount: 2,
            restTime: 60
        )

        // Завершаем все этапы тренировки
        for _ in 0 ..< viewModel.stepStates.count {
            if viewModel.currentStep != nil {
                viewModel.completeCurrentStep()
                if viewModel.showTimer {
                    viewModel.handleRestTimerFinish(force: false)
                }
            }
        }

        let result = viewModel.getWorkoutResult(interrupt: false)
        let workoutResult = try #require(result)
        #expect(workoutResult.count == 2)
        #expect(workoutResult.duration != nil)
    }

    @Test("Должен обрабатывать ошибки при отправке результата")
    func handlesErrorsWhenSendingResult() async throws {
        let connectivityService = MockWatchConnectivityService()
        connectivityService.shouldSucceed = false
        connectivityService.mockError = WatchConnectivityError.sessionUnavailable
        let appGroupHelper = MockWatchAppGroupHelper(restTime: 60)
        let viewModel = WorkoutViewModel(
            connectivityService: connectivityService,
            appGroupHelper: appGroupHelper
        )

        let trainings = [
            WorkoutPreviewTraining(count: 5, typeId: 0)
        ]

        viewModel.setupWorkoutData(
            dayNumber: 1,
            executionType: .cycles,
            trainings: trainings,
            plannedCount: 2,
            restTime: 60
        )

        for _ in 0 ..< viewModel.stepStates.count {
            if viewModel.currentStep != nil {
                viewModel.completeCurrentStep()
                if viewModel.showTimer {
                    viewModel.handleRestTimerFinish(force: false)
                }
            }
        }

        await viewModel.finishWorkout()

        let error = try #require(viewModel.error)
        #expect(error is WatchConnectivityError)
    }

    @Test("Должен проверять и обрабатывать истекший таймер отдыха")
    func checkAndHandleExpiredRestTimer() async throws {
        let connectivityService = MockWatchConnectivityService()
        let appGroupHelper = MockWatchAppGroupHelper(restTime: 1)
        let viewModel = WorkoutViewModel(
            connectivityService: connectivityService,
            appGroupHelper: appGroupHelper
        )

        let trainings = [
            WorkoutPreviewTraining(count: 5, typeId: 0)
        ]

        viewModel.setupWorkoutData(
            dayNumber: 1,
            executionType: .cycles,
            trainings: trainings,
            plannedCount: 4,
            restTime: 1
        )

        // Завершаем разминку (таймер не показывается)
        viewModel.completeCurrentStep()
        // Завершаем первый круг (теперь показывается таймер)
        viewModel.completeCurrentStep()

        #expect(viewModel.showTimer)

        try await Task.sleep(nanoseconds: 1_100_000_000)

        viewModel.checkAndHandleExpiredRestTimer()

        #expect(!viewModel.showTimer)
    }
}
