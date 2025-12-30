import Foundation
@testable import SotkaWatch_Watch_App
import Testing

@MainActor
struct WorkoutViewModelStepManagementTests {
    @Test("Должен завершать текущий этап и переходить к следующему")
    func completeCurrentStep() throws {
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

        let initialStepIndex = viewModel.currentStepIndex
        let initialStep = try #require(viewModel.currentStep)
        #expect(initialStep == .warmUp)

        viewModel.completeCurrentStep()

        #expect(viewModel.currentStepIndex == initialStepIndex + 1)
        #expect(viewModel.stepStates[initialStepIndex].state == .completed)
        let nextStep = try #require(viewModel.currentStep)
        if case let .exercise(.cycles, number) = nextStep {
            #expect(number == 1)
        } else {
            Issue.record("Ожидался этап с типом .exercise(.cycles, number: 1)")
        }
    }

    @Test("Должен показывать таймер отдыха после завершения круга")
    func showsRestTimerAfterCompletingCycle() throws {
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

        // Завершаем разминку (таймер не показывается)
        viewModel.completeCurrentStep()
        // Завершаем первый круг (теперь показывается таймер)
        viewModel.completeCurrentStep()

        #expect(viewModel.showTimer)
        #expect(viewModel.currentRestStartTime != nil)
    }

    @Test("Не должен показывать таймер отдыха после завершения разминки")
    func doesNotShowRestTimerAfterWarmUp() throws {
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

        let warmUpIndex = viewModel.currentStepIndex
        viewModel.completeCurrentStep()

        #expect(!viewModel.showTimer)
        #expect(viewModel.stepStates[warmUpIndex].state == .completed)
    }

    @Test("Должен обрабатывать завершение таймера отдыха")
    func handleRestTimerFinish() throws {
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

        // Завершаем разминку (таймер не показывается)
        viewModel.completeCurrentStep()
        // Завершаем первый круг (теперь показывается таймер)
        viewModel.completeCurrentStep()

        #expect(viewModel.showTimer)

        viewModel.handleRestTimerFinish(force: false)

        #expect(!viewModel.showTimer)
        #expect(viewModel.currentRestStartTime == nil)
        let currentStep = try #require(viewModel.currentStep)
        if case let .exercise(.cycles, number) = currentStep {
            #expect(number == 2)
        } else {
            Issue.record("Ожидался этап с типом .exercise(.cycles, number: 2)")
        }
    }

    @Test("Должен получать состояние этапа")
    func getStepState() throws {
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

        let warmUpState = viewModel.getStepState(for: .warmUp)
        #expect(warmUpState == .active)

        let coolDownState = viewModel.getStepState(for: .coolDown)
        #expect(coolDownState == .inactive)
    }

    @Test("Должен возвращать список кругов для типа .cycles")
    func getCycleSteps() throws {
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

        let cycleSteps = viewModel.getCycleSteps()
        #expect(cycleSteps.count == 4)

        let expectedNumbers = [1, 2, 3, 4]
        for (index, stepState) in cycleSteps.enumerated() {
            if case let .exercise(executionType, number) = stepState.step {
                #expect(executionType == .cycles)
                #expect(number == expectedNumbers[index])
            } else {
                Issue.record("Ожидался этап с типом .exercise(.cycles, number: ...)")
            }
        }
    }

    @Test("Должен возвращать список подходов для упражнения для типа .sets")
    func getExerciseSteps() throws {
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

        let firstTrainingId = trainings[0].id
        let firstExerciseSteps = viewModel.getExerciseSteps(for: firstTrainingId)
        #expect(firstExerciseSteps.count == 6)

        let expectedNumbers = [1, 2, 3, 4, 5, 6]
        for (index, stepState) in firstExerciseSteps.enumerated() {
            if case let .exercise(executionType, number) = stepState.step {
                #expect(executionType == .sets)
                #expect(number == expectedNumbers[index])
            } else {
                Issue.record("Ожидался этап с типом .exercise(.sets, number: ...)")
            }
        }
    }
}
