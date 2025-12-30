import Foundation
@testable import SotkaWatch_Watch_App
import Testing

@MainActor
struct WorkoutViewModelSetupTests {
    @Test("Должен инициализировать данные тренировки для типа .cycles")
    func setupWorkoutDataForCycles() throws {
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

        #expect(viewModel.dayNumber == 1)
        #expect(viewModel.executionType == .cycles)
        #expect(viewModel.trainings.count == 1)
        #expect(viewModel.plannedCount == 4)
        #expect(viewModel.restTime == 60)
        #expect(viewModel.currentStepIndex == 0)
        #expect(viewModel.stepStates.count == 6)
        #expect(viewModel.stepStates[0].step == .warmUp)
        #expect(viewModel.stepStates[0].state == .active)
        #expect(viewModel.stepStates[5].step == .coolDown)
        #expect(viewModel.stepStates[5].state == .inactive)
    }

    @Test("Должен инициализировать данные тренировки для типа .sets")
    func setupWorkoutDataForSets() throws {
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

        #expect(viewModel.dayNumber == 1)
        #expect(viewModel.executionType == .sets)
        #expect(viewModel.trainings.count == 2)
        #expect(viewModel.plannedCount == 6)
        #expect(viewModel.restTime == 60)
        #expect(viewModel.currentStepIndex == 0)
        let warmUpStep = viewModel.stepStates[0]
        #expect(warmUpStep.step == .warmUp)
        #expect(warmUpStep.state == .active)
    }

    @Test("Должен возвращать текущий этап тренировки")
    func currentStep() throws {
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

        let currentStep = try #require(viewModel.currentStep)
        #expect(currentStep == .warmUp)
    }

    @Test("Должен возвращать nil для currentStep если этапы не инициализированы")
    func currentStepNilWhenNotInitialized() {
        let connectivityService = MockWatchConnectivityService()
        let viewModel = WorkoutViewModel(
            connectivityService: connectivityService
        )

        #expect(viewModel.currentStep == nil)
    }

    @Test("Должен определять завершенность тренировки")
    func isWorkoutCompleted() throws {
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
            plannedCount: 2,
            restTime: 60
        )

        #expect(!viewModel.isWorkoutCompleted)

        for i in 0 ..< viewModel.stepStates.count {
            viewModel.stepStates[i].state = .completed
        }

        #expect(viewModel.isWorkoutCompleted)
    }

    @Test("Должен определять нужно ли показывать напоминание об упражнениях для .cycles")
    func shouldShowExercisesReminderForCycles() throws {
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

        #expect(viewModel.shouldShowExercisesReminder)
    }

    @Test("Должен определять нужно ли показывать напоминание об упражнениях для .sets")
    func shouldShowExercisesReminderForSets() throws {
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
            plannedCount: 6,
            restTime: 60
        )

        #expect(!viewModel.shouldShowExercisesReminder)
    }
}
