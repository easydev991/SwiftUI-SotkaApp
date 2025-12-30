import Foundation
@testable import SotkaWatch_Watch_App
import Testing

@MainActor
struct WorkoutViewModelGetWorkoutResultTests {
    @Test("Для executionType = .sets и interrupt = true должен возвращать WorkoutResult с count = plannedCount")
    func getWorkoutResultForSetsWithInterruptShouldReturnPlannedCount() throws {
        let connectivityService = MockWatchConnectivityService()
        let viewModel = WorkoutViewModel(
            connectivityService: connectivityService
        )

        let trainings = [
            WorkoutPreviewTraining(count: 5, typeId: 0),
            WorkoutPreviewTraining(count: 10, typeId: 2)
        ]

        viewModel.setupWorkoutData(
            dayNumber: 1,
            executionType: .sets,
            trainings: trainings,
            plannedCount: 6,
            restTime: 60
        )

        // Завершаем warmUp и 2 подхода из 12 (6 подходов * 2 упражнения)
        viewModel.completeCurrentStep() // warmUp
        if viewModel.showTimer {
            viewModel.handleRestTimerFinish(force: false)
        }
        viewModel.completeCurrentStep() // подход 1
        if viewModel.showTimer {
            viewModel.handleRestTimerFinish(force: false)
        }
        viewModel.completeCurrentStep() // подход 2
        if viewModel.showTimer {
            viewModel.handleRestTimerFinish(force: false)
        }

        let result = viewModel.getWorkoutResult(interrupt: true)
        let workoutResult = try #require(result)

        // Для прерванной тренировки с подходами должен возвращать plannedCount
        #expect(workoutResult.count == 6)
    }

    @Test("Для executionType = .sets и interrupt = false должен возвращать WorkoutResult с count равным количеству всех этапов упражнений")
    func getWorkoutResultForSetsWithoutInterruptShouldReturnAllSteps() throws {
        let connectivityService = MockWatchConnectivityService()
        let viewModel = WorkoutViewModel(
            connectivityService: connectivityService
        )

        let trainings = [
            WorkoutPreviewTraining(count: 5, typeId: 0),
            WorkoutPreviewTraining(count: 10, typeId: 2)
        ]

        viewModel.setupWorkoutData(
            dayNumber: 1,
            executionType: .sets,
            trainings: trainings,
            plannedCount: 6,
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

        // Для завершенной тренировки с подходами должен возвращать количество всех этапов (6 подходов * 2 упражнения = 12)
        #expect(workoutResult.count == 12)
    }

    @Test("Для executionType = .cycles и interrupt = true должен возвращать WorkoutResult с count равным количеству завершенных этапов")
    func getWorkoutResultForCyclesWithInterruptShouldReturnCompletedSteps() throws {
        let connectivityService = MockWatchConnectivityService()
        let viewModel = WorkoutViewModel(
            connectivityService: connectivityService
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

        // Завершаем warmUp и 2 круга из 4
        viewModel.completeCurrentStep() // warmUp
        if viewModel.showTimer {
            viewModel.handleRestTimerFinish(force: false)
        }
        viewModel.completeCurrentStep() // круг 1
        if viewModel.showTimer {
            viewModel.handleRestTimerFinish(force: false)
        }
        viewModel.completeCurrentStep() // круг 2
        if viewModel.showTimer {
            viewModel.handleRestTimerFinish(force: false)
        }

        let result = viewModel.getWorkoutResult(interrupt: true)
        let workoutResult = try #require(result)

        // Для прерванной тренировки с кругами должен возвращать количество завершенных кругов (прежняя логика)
        #expect(workoutResult.count == 2)
    }

    @Test(
        "Для executionType = .cycles и interrupt = false должен возвращать WorkoutResult с count равным количеству всех этапов упражнений"
    )
    func getWorkoutResultForCyclesWithoutInterruptShouldReturnAllSteps() throws {
        let connectivityService = MockWatchConnectivityService()
        let viewModel = WorkoutViewModel(
            connectivityService: connectivityService
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

        // Для завершенной тренировки с кругами должен возвращать количество всех этапов
        #expect(workoutResult.count == 4)
    }

    @Test("Для executionType = .turbo с подходами и interrupt = true должен возвращать WorkoutResult с count = plannedCount")
    func getWorkoutResultForTurboWithSetsAndInterruptShouldReturnPlannedCount() throws {
        let connectivityService = MockWatchConnectivityService()
        let viewModel = WorkoutViewModel(
            connectivityService: connectivityService
        )

        let trainings = [
            WorkoutPreviewTraining(count: 5, typeId: 0),
            WorkoutPreviewTraining(count: 10, typeId: 2)
        ]

        // День 93 - турбо-день с подходами
        viewModel.setupWorkoutData(
            dayNumber: 93,
            executionType: .turbo,
            trainings: trainings,
            plannedCount: 1,
            restTime: 60
        )

        // Завершаем только 1 подход из 2 (1 подход * 2 упражнения)
        viewModel.completeCurrentStep() // warmUp
        if viewModel.showTimer {
            viewModel.handleRestTimerFinish(force: false)
        }
        viewModel.completeCurrentStep() // подход 1
        if viewModel.showTimer {
            viewModel.handleRestTimerFinish(force: false)
        }

        let result = viewModel.getWorkoutResult(interrupt: true)
        let workoutResult = try #require(result)

        // Для прерванной турбо-тренировки с подходами должен возвращать plannedCount
        #expect(workoutResult.count == 1)
    }

    @Test(
        "Для executionType = .turbo с кругами и interrupt = true должен возвращать WorkoutResult с count равным количеству завершенных этапов"
    )
    func getWorkoutResultForTurboWithCyclesAndInterruptShouldReturnCompletedSteps() throws {
        let connectivityService = MockWatchConnectivityService()
        let viewModel = WorkoutViewModel(
            connectivityService: connectivityService
        )

        let trainings = [
            WorkoutPreviewTraining(count: 5, typeId: 0)
        ]

        // День 1 - турбо-день с кругами
        viewModel.setupWorkoutData(
            dayNumber: 1,
            executionType: .turbo,
            trainings: trainings,
            plannedCount: 5,
            restTime: 60
        )

        // Завершаем warmUp и 2 круга из 5
        viewModel.completeCurrentStep() // warmUp
        if viewModel.showTimer {
            viewModel.handleRestTimerFinish(force: false)
        }
        viewModel.completeCurrentStep() // круг 1
        if viewModel.showTimer {
            viewModel.handleRestTimerFinish(force: false)
        }
        viewModel.completeCurrentStep() // круг 2
        if viewModel.showTimer {
            viewModel.handleRestTimerFinish(force: false)
        }

        let result = viewModel.getWorkoutResult(interrupt: true)
        let workoutResult = try #require(result)

        // Для прерванной турбо-тренировки с кругами должен возвращать количество завершенных кругов (прежняя логика)
        #expect(workoutResult.count == 2)
    }
}
