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
    func showsRestTimerAfterCompletingCycle() {
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
    func doesNotShowRestTimerAfterWarmUp() {
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
}
