import Foundation
@testable import SwiftUI_SotkaApp
import Testing

extension WorkoutScreenViewModelTests {
    @Suite("Тесты для setupWorkoutData и initializeStepStates")
    struct SetupTests {
        @Test("Должен настраивать данные тренировки из переданных параметров")
        @MainActor
        func setupWorkoutData() throws {
            let viewModel = WorkoutScreenViewModel()
            let trainings = [
                WorkoutPreviewTraining(count: 5, typeId: 0),
                WorkoutPreviewTraining(count: 10, typeId: 2),
                WorkoutPreviewTraining(count: 15, typeId: 3)
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
            #expect(viewModel.trainings.count == 3)
            #expect(viewModel.plannedCount == 4)
            #expect(viewModel.restTime == 60)
            #expect(viewModel.stepStates.count == 6)
            #expect(viewModel.currentStepIndex == 0)

            let firstStep = try #require(viewModel.stepStates.first)
            #expect(firstStep.step.id == WorkoutStep.warmUp.id)
            #expect(firstStep.state == .active)

            let workoutStartTime = try #require(viewModel.workoutStartTime)
            #expect(workoutStartTime <= Date())
            #expect(viewModel.totalRestTime == 0)
        }

        @Test("Должен инициализировать этапы для типа выполнения 'круги'")
        @MainActor
        func initializeStepStatesForCycles() throws {
            let viewModel = WorkoutScreenViewModel()
            let trainings = [
                WorkoutPreviewTraining(count: 5, typeId: 0),
                WorkoutPreviewTraining(count: 10, typeId: 2),
                WorkoutPreviewTraining(count: 15, typeId: 3)
            ]

            viewModel.setupWorkoutData(
                dayNumber: 1,
                executionType: .cycles,
                trainings: trainings,
                plannedCount: 4,
                restTime: 60
            )

            #expect(viewModel.stepStates.count == 6)

            let warmUpStep = try #require(viewModel.stepStates.first)
            #expect(warmUpStep.step.id == WorkoutStep.warmUp.id)
            #expect(warmUpStep.state == .active)

            let cycleSteps = viewModel.stepStates.filter {
                if case .exercise(.cycles, _) = $0.step {
                    return true
                }
                return false
            }
            #expect(cycleSteps.count == 4)
            for (index, stepState) in cycleSteps.enumerated() {
                if case let .exercise(.cycles, number) = stepState.step {
                    #expect(number == index + 1)
                    #expect(stepState.state == .inactive)
                }
            }

            let coolDownStep = try #require(viewModel.stepStates.last)
            #expect(coolDownStep.step.id == WorkoutStep.coolDown.id)
            #expect(coolDownStep.state == .inactive)
        }

        @Test("Должен инициализировать этапы для типа выполнения 'подходы'")
        @MainActor
        func initializeStepStatesForSets() throws {
            let viewModel = WorkoutScreenViewModel()
            let trainings = [
                WorkoutPreviewTraining(count: 5, typeId: 0),
                WorkoutPreviewTraining(count: 10, typeId: 2),
                WorkoutPreviewTraining(count: 15, typeId: 3),
                WorkoutPreviewTraining(count: 20, typeId: 4)
            ]

            viewModel.setupWorkoutData(
                dayNumber: 1,
                executionType: .sets,
                trainings: trainings,
                plannedCount: 6,
                restTime: 60
            )

            #expect(viewModel.stepStates.count == 26)

            let warmUpStep = try #require(viewModel.stepStates.first)
            #expect(warmUpStep.step.id == WorkoutStep.warmUp.id)
            #expect(warmUpStep.state == .active)

            let setSteps = viewModel.stepStates.filter {
                if case .exercise(.sets, _) = $0.step {
                    return true
                }
                return false
            }
            #expect(setSteps.count == 24)

            let coolDownStep = try #require(viewModel.stepStates.last)
            #expect(coolDownStep.step.id == WorkoutStep.coolDown.id)
            #expect(coolDownStep.state == .inactive)
        }

        @Test("Должен инициализировать этапы для типа выполнения 'турбо' на день 1")
        @MainActor
        func initializeStepStatesForTurbo() throws {
            let viewModel = WorkoutScreenViewModel()
            let trainings = [
                WorkoutPreviewTraining(count: 5, typeId: 0)
            ]

            viewModel.setupWorkoutData(
                dayNumber: 1,
                executionType: .turbo,
                trainings: trainings,
                plannedCount: 5,
                restTime: 60
            )

            #expect(viewModel.stepStates.count == 7)

            let warmUpStep = try #require(viewModel.stepStates.first)
            #expect(warmUpStep.step.id == WorkoutStep.warmUp.id)
            #expect(warmUpStep.state == .active)

            let cycleSteps = viewModel.stepStates.filter {
                if case .exercise(.cycles, _) = $0.step {
                    return true
                }
                return false
            }
            #expect(cycleSteps.count == 5)

            let coolDownStep = try #require(viewModel.stepStates.last)
            #expect(coolDownStep.step.id == WorkoutStep.coolDown.id)
            #expect(coolDownStep.state == .inactive)
        }
    }
}
