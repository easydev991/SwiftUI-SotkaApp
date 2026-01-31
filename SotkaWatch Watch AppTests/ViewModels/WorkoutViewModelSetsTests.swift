import Foundation
@testable import SotkaWatch_Watch_App
import Testing

@MainActor
struct WorkoutViewModelSetsTests {
    @Test("Должен создавать правильную последовательность этапов для типа .sets с несколькими упражнениями")
    func initializeStepStatesForSetsWithMultipleExercises() {
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
    func initializeStepStatesForSingleExerciseWithMultipleSets() {
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

    @Test("Должен создавать правильное количество подходов для турбо-дня 93 с подходами")
    func initializeStepStatesForTurboDay93WithSets() {
        let connectivityService = MockWatchConnectivityService()
        let viewModel = WorkoutViewModel(
            connectivityService: connectivityService
        )

        let trainings = [
            WorkoutPreviewTraining(count: 3, typeId: ExerciseType.turbo93_1.rawValue, sortOrder: 0),
            WorkoutPreviewTraining(count: 3, typeId: ExerciseType.turbo93_2.rawValue, sortOrder: 1),
            WorkoutPreviewTraining(count: 2, typeId: ExerciseType.turbo93_3.rawValue, sortOrder: 2),
            WorkoutPreviewTraining(count: 3, typeId: ExerciseType.turbo93_4.rawValue, sortOrder: 3),
            WorkoutPreviewTraining(count: 10, typeId: ExerciseType.turbo93_5.rawValue, sortOrder: 4)
        ]

        viewModel.setupWorkoutData(
            dayNumber: 93,
            executionType: .turbo,
            trainings: trainings,
            plannedCount: 5,
            restTime: 60
        )

        let setSteps = viewModel.stepStates.filter { stepState in
            if case .exercise(.sets, _) = stepState.step {
                return true
            }
            return false
        }

        #expect(setSteps.count == 5)

        // Для турбо-дней с подходами каждый подход имеет порядковый номер подхода турбо-дня (1, 2, 3, 4, 5)
        for (index, stepState) in setSteps.enumerated() {
            if case let .exercise(.sets, number) = stepState.step {
                #expect(number == index + 1)
            } else {
                Issue.record("Ожидался подход с номером \(index + 1) для турбо-дня 93")
            }
        }
    }

    @Test("Должен создавать правильное количество подходов для турбо-дня 95 с подходами")
    func initializeStepStatesForTurboDay95WithSets() {
        let connectivityService = MockWatchConnectivityService()
        let viewModel = WorkoutViewModel(
            connectivityService: connectivityService
        )

        let trainings = [
            WorkoutPreviewTraining(count: 3, typeId: ExerciseType.turbo95_1.rawValue, sortOrder: 0),
            WorkoutPreviewTraining(count: 2, typeId: ExerciseType.turbo95_2.rawValue, sortOrder: 1),
            WorkoutPreviewTraining(count: 1, typeId: ExerciseType.turbo95_3.rawValue, sortOrder: 2),
            WorkoutPreviewTraining(count: 2, typeId: ExerciseType.turbo95_4.rawValue, sortOrder: 3),
            WorkoutPreviewTraining(count: 3, typeId: ExerciseType.turbo95_5.rawValue, sortOrder: 4)
        ]

        viewModel.setupWorkoutData(
            dayNumber: 95,
            executionType: .turbo,
            trainings: trainings,
            plannedCount: 5,
            restTime: 60
        )

        let setSteps = viewModel.stepStates.filter { stepState in
            if case .exercise(.sets, _) = stepState.step {
                return true
            }
            return false
        }

        #expect(setSteps.count == 5)

        // Для турбо-дней с подходами каждый подход имеет порядковый номер подхода турбо-дня (1, 2, 3, 4, 5)
        for (index, stepState) in setSteps.enumerated() {
            if case let .exercise(.sets, number) = stepState.step {
                #expect(number == index + 1)
            } else {
                Issue.record("Ожидался подход с номером \(index + 1) для турбо-дня 95")
            }
        }
    }

    @Test("Должен создавать правильное количество подходов для турбо-дня 98 с подходами")
    func initializeStepStatesForTurboDay98WithSets() {
        let connectivityService = MockWatchConnectivityService()
        let viewModel = WorkoutViewModel(
            connectivityService: connectivityService
        )

        let trainings = [
            WorkoutPreviewTraining(count: 10, typeId: ExerciseType.turbo98Pullups.rawValue, sortOrder: 0),
            WorkoutPreviewTraining(count: 20, typeId: ExerciseType.turbo98Pushups.rawValue, sortOrder: 1),
            WorkoutPreviewTraining(count: 30, typeId: ExerciseType.turbo98Squats.rawValue, sortOrder: 2)
        ]

        viewModel.setupWorkoutData(
            dayNumber: 98,
            executionType: .turbo,
            trainings: trainings,
            plannedCount: 3,
            restTime: 60
        )

        let setSteps = viewModel.stepStates.filter { stepState in
            if case .exercise(.sets, _) = stepState.step {
                return true
            }
            return false
        }

        #expect(setSteps.count == 3)

        // Для турбо-дней с подходами каждый подход имеет порядковый номер подхода турбо-дня (1, 2, 3)
        for (index, stepState) in setSteps.enumerated() {
            if case let .exercise(.sets, number) = stepState.step {
                #expect(number == index + 1)
            } else {
                Issue.record("Ожидался подход с номером \(index + 1) для турбо-дня 98")
            }
        }
    }

    @Test("Должен возвращать правильное количество подходов для каждого упражнения в турбо-дне 93")
    func getExerciseStepsForTurboDay93() {
        let connectivityService = MockWatchConnectivityService()
        let viewModel = WorkoutViewModel(
            connectivityService: connectivityService
        )

        let trainings = [
            WorkoutPreviewTraining(count: 3, typeId: ExerciseType.turbo93_1.rawValue, sortOrder: 0),
            WorkoutPreviewTraining(count: 3, typeId: ExerciseType.turbo93_2.rawValue, sortOrder: 1),
            WorkoutPreviewTraining(count: 2, typeId: ExerciseType.turbo93_3.rawValue, sortOrder: 2),
            WorkoutPreviewTraining(count: 3, typeId: ExerciseType.turbo93_4.rawValue, sortOrder: 3),
            WorkoutPreviewTraining(count: 10, typeId: ExerciseType.turbo93_5.rawValue, sortOrder: 4)
        ]

        viewModel.setupWorkoutData(
            dayNumber: 93,
            executionType: .turbo,
            trainings: trainings,
            plannedCount: 5,
            restTime: 60
        )

        for training in trainings {
            let exerciseSteps = viewModel.getExerciseSteps(for: training.id)
            #expect(exerciseSteps.count == 1)
        }
    }

    @Test("Должен сохранять правильную логику для обычных дней с подходами")
    func initializeStepStatesForRegularDaysWithSets() {
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

        let setSteps = viewModel.stepStates.filter { stepState in
            if case .exercise(.sets, _) = stepState.step {
                return true
            }
            return false
        }

        #expect(setSteps.count == 12)

        let setNumbers = setSteps.compactMap { stepState -> Int? in
            if case let .exercise(.sets, number) = stepState.step {
                return number
            }
            return nil
        }

        #expect(setNumbers.count == 12)
        #expect(setNumbers[0] == 1)
        #expect(setNumbers[5] == 6)
        #expect(setNumbers[6] == 7)
        #expect(setNumbers[11] == 12)
    }

    @Test("Должен возвращать правильный индекс упражнения для турбо-дня 93")
    func getCurrentExerciseIndexForTurboDay93() throws {
        let connectivityService = MockWatchConnectivityService()
        let viewModel = WorkoutViewModel(
            connectivityService: connectivityService
        )

        let trainings = [
            WorkoutPreviewTraining(count: 3, typeId: ExerciseType.turbo93_1.rawValue, sortOrder: 0),
            WorkoutPreviewTraining(count: 3, typeId: ExerciseType.turbo93_2.rawValue, sortOrder: 1),
            WorkoutPreviewTraining(count: 2, typeId: ExerciseType.turbo93_3.rawValue, sortOrder: 2),
            WorkoutPreviewTraining(count: 3, typeId: ExerciseType.turbo93_4.rawValue, sortOrder: 3),
            WorkoutPreviewTraining(count: 10, typeId: ExerciseType.turbo93_5.rawValue, sortOrder: 4)
        ]

        viewModel.setupWorkoutData(
            dayNumber: 93,
            executionType: .turbo,
            trainings: trainings,
            plannedCount: 5,
            restTime: 60
        )

        let exerciseIndex1 = try #require(viewModel.getCurrentExerciseIndex(for: 1))
        #expect(exerciseIndex1 == 0)

        let exerciseIndex3 = try #require(viewModel.getCurrentExerciseIndex(for: 3))
        #expect(exerciseIndex3 == 2)

        let exerciseIndex5 = try #require(viewModel.getCurrentExerciseIndex(for: 5))
        #expect(exerciseIndex5 == 4)
    }

    @Test("Должен возвращать правильный индекс упражнения для обычных дней с подходами")
    func getCurrentExerciseIndexForRegularDays() throws {
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

        let exerciseIndex1 = try #require(viewModel.getCurrentExerciseIndex(for: 1))
        #expect(exerciseIndex1 == 0)

        let exerciseIndex6 = try #require(viewModel.getCurrentExerciseIndex(for: 6))
        #expect(exerciseIndex6 == 0)

        let exerciseIndex7 = try #require(viewModel.getCurrentExerciseIndex(for: 7))
        #expect(exerciseIndex7 == 1)

        let exerciseIndex12 = try #require(viewModel.getCurrentExerciseIndex(for: 12))
        #expect(exerciseIndex12 == 1)
    }

    @Test("Должен возвращать nil для getCurrentExerciseIndex когда effectiveType == .cycles")
    func getCurrentExerciseIndexReturnsNilForCycles() {
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

        #expect(viewModel.getCurrentExerciseIndex(for: 1) == nil)
    }
}
