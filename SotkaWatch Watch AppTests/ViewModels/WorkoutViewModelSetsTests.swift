import Foundation
@testable import SotkaWatch_Watch_App
import Testing

@MainActor
struct WorkoutViewModelSetsTests {
    @Test("Должен создавать правильную последовательность этапов для типа .sets с несколькими упражнениями")
    func initializeStepStatesForSetsWithMultipleExercises() throws {
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
            plannedCount: 3,
            restTime: 60
        )

        // Должно быть: разминка + (3 подхода для упражнения 1) + (3 подхода для упражнения 2) + заминка = 8 этапов
        #expect(viewModel.stepStates.count == 8)
        #expect(viewModel.stepStates[0].step == .warmUp)

        // Проверяем подходы для первого упражнения (должны быть 1, 2, 3)
        if case let .exercise(.sets, number1) = viewModel.stepStates[1].step {
            #expect(number1 == 1)
        } else {
            Issue.record("Ожидался подход 1 для первого упражнения")
        }
        if case let .exercise(.sets, number2) = viewModel.stepStates[2].step {
            #expect(number2 == 2)
        } else {
            Issue.record("Ожидался подход 2 для первого упражнения")
        }
        if case let .exercise(.sets, number3) = viewModel.stepStates[3].step {
            #expect(number3 == 3)
        } else {
            Issue.record("Ожидался подход 3 для первого упражнения")
        }

        // Проверяем подходы для второго упражнения (должны быть 4, 5, 6)
        if case let .exercise(.sets, number4) = viewModel.stepStates[4].step {
            #expect(number4 == 4)
        } else {
            Issue.record("Ожидался подход 4 для второго упражнения")
        }
        if case let .exercise(.sets, number5) = viewModel.stepStates[5].step {
            #expect(number5 == 5)
        } else {
            Issue.record("Ожидался подход 5 для второго упражнения")
        }
        if case let .exercise(.sets, number6) = viewModel.stepStates[6].step {
            #expect(number6 == 6)
        } else {
            Issue.record("Ожидался подход 6 для второго упражнения")
        }

        #expect(viewModel.stepStates[7].step == .coolDown)
    }

    @Test("Должен последовательно переходить через все подходы для типа .sets")
    func completeStepsForSetsSequentially() throws {
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
            plannedCount: 2,
            restTime: 60
        )

        // Завершаем разминку
        viewModel.completeCurrentStep()
        let step1 = try #require(viewModel.currentStep)
        if case let .exercise(.sets, number1) = step1 {
            #expect(number1 == 1)
        } else {
            Issue.record("После разминки должен быть подход 1")
        }

        // Завершаем подход 1
        viewModel.completeCurrentStep()
        if viewModel.showTimer {
            viewModel.handleRestTimerFinish(force: false)
        }
        let step2 = try #require(viewModel.currentStep)
        if case let .exercise(.sets, number2) = step2 {
            #expect(number2 == 2)
        } else {
            Issue.record("После подхода 1 должен быть подход 2")
        }

        // Завершаем подход 2
        viewModel.completeCurrentStep()
        if viewModel.showTimer {
            viewModel.handleRestTimerFinish(force: false)
        }
        let step3 = try #require(viewModel.currentStep)
        if case let .exercise(.sets, number3) = step3 {
            #expect(number3 == 3)
        } else {
            Issue.record("После подхода 2 должен быть подход 3 (первый подход второго упражнения)")
        }

        // Завершаем подход 3
        viewModel.completeCurrentStep()
        if viewModel.showTimer {
            viewModel.handleRestTimerFinish(force: false)
        }
        let step4 = try #require(viewModel.currentStep)
        if case let .exercise(.sets, number4) = step4 {
            #expect(number4 == 4)
        } else {
            Issue.record("После подхода 3 должен быть подход 4 (второй подход второго упражнения)")
        }

        // Завершаем подход 4
        viewModel.completeCurrentStep()
        if viewModel.showTimer {
            viewModel.handleRestTimerFinish(force: false)
        }
        let step5 = try #require(viewModel.currentStep)
        #expect(step5 == .coolDown)
    }

    @Test("Должен создавать правильную последовательность для одного упражнения с несколькими подходами")
    func initializeStepStatesForSingleExerciseWithMultipleSets() throws {
        let connectivityService = MockWatchConnectivityService()
        let viewModel = WorkoutViewModel(
            connectivityService: connectivityService
        )

        let trainings = [
            WorkoutPreviewTraining(count: 5, typeId: 0)
        ]

        viewModel.setupWorkoutData(
            dayNumber: 1,
            executionType: .sets,
            trainings: trainings,
            plannedCount: 4,
            restTime: 60
        )

        // Должно быть: разминка + 4 подхода + заминка = 6 этапов
        #expect(viewModel.stepStates.count == 6)
        #expect(viewModel.stepStates[0].step == .warmUp)

        // Проверяем, что подходы имеют правильные номера (1, 2, 3, 4)
        for i in 1 ... 4 {
            if case let .exercise(.sets, number) = viewModel.stepStates[i].step {
                #expect(number == i)
            } else {
                Issue.record("Ожидался подход \(i)")
            }
        }

        #expect(viewModel.stepStates[5].step == .coolDown)
    }
}
