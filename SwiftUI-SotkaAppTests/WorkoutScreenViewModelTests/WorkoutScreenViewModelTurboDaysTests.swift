import Foundation
@testable import SwiftUI_SotkaApp
import Testing

extension WorkoutScreenViewModelTests {
    @Suite("Тесты для турбо-дней")
    struct TurboDaysTests {
        @Test("Должен возвращать cycles для турбо-дня 92")
        @MainActor
        func getEffectiveExecutionTypeForTurboDay92() {
            let viewModel = WorkoutScreenViewModel()
            viewModel.dayNumber = 92
            viewModel.executionType = .turbo
            let result = viewModel.getEffectiveExecutionType()
            #expect(result == .cycles)
        }

        @Test("Должен возвращать sets для турбо-дня 93")
        @MainActor
        func getEffectiveExecutionTypeForTurboDay93() {
            let viewModel = WorkoutScreenViewModel()
            viewModel.dayNumber = 93
            viewModel.executionType = .turbo
            let result = viewModel.getEffectiveExecutionType()
            #expect(result == .sets)
        }

        @Test("Должен возвращать cycles для турбо-дня 94")
        @MainActor
        func getEffectiveExecutionTypeForTurboDay94() {
            let viewModel = WorkoutScreenViewModel()
            viewModel.dayNumber = 94
            viewModel.executionType = .turbo
            let result = viewModel.getEffectiveExecutionType()
            #expect(result == .cycles)
        }

        @Test("Должен возвращать sets для турбо-дня 95")
        @MainActor
        func getEffectiveExecutionTypeForTurboDay95() {
            let viewModel = WorkoutScreenViewModel()
            viewModel.dayNumber = 95
            viewModel.executionType = .turbo
            let result = viewModel.getEffectiveExecutionType()
            #expect(result == .sets)
        }

        @Test("Должен возвращать cycles для турбо-дня 96")
        @MainActor
        func getEffectiveExecutionTypeForTurboDay96() {
            let viewModel = WorkoutScreenViewModel()
            viewModel.dayNumber = 96
            viewModel.executionType = .turbo
            let result = viewModel.getEffectiveExecutionType()
            #expect(result == .cycles)
        }

        @Test("Должен возвращать cycles для турбо-дня 97")
        @MainActor
        func getEffectiveExecutionTypeForTurboDay97() {
            let viewModel = WorkoutScreenViewModel()
            viewModel.dayNumber = 97
            viewModel.executionType = .turbo
            let result = viewModel.getEffectiveExecutionType()
            #expect(result == .cycles)
        }

        @Test("Должен возвращать sets для турбо-дня 98")
        @MainActor
        func getEffectiveExecutionTypeForTurboDay98() {
            let viewModel = WorkoutScreenViewModel()
            viewModel.dayNumber = 98
            viewModel.executionType = .turbo
            let result = viewModel.getEffectiveExecutionType()
            #expect(result == .sets)
        }

        @Test("Должен возвращать исходный тип для cycles")
        @MainActor
        func getEffectiveExecutionTypeForNonTurboCycles() {
            let viewModel = WorkoutScreenViewModel()
            viewModel.dayNumber = 1
            viewModel.executionType = .cycles
            let result = viewModel.getEffectiveExecutionType()
            #expect(result == .cycles)
        }

        @Test("Должен возвращать исходный тип для sets")
        @MainActor
        func getEffectiveExecutionTypeForNonTurboSets() {
            let viewModel = WorkoutScreenViewModel()
            viewModel.dayNumber = 50
            viewModel.executionType = .sets
            let result = viewModel.getEffectiveExecutionType()
            #expect(result == .sets)
        }

        @Test("Должен инициализировать этапы для турбо-дня 92 с кругами")
        @MainActor
        func initializeStepStatesForTurboDay92() {
            let viewModel = WorkoutScreenViewModel()
            let creator = WorkoutProgramCreator(day: 92, executionType: .turbo)
            viewModel.setupWorkoutData(
                dayNumber: 92,
                executionType: .turbo,
                trainings: creator.trainings,
                plannedCount: creator.plannedCount,
                restTime: 60
            )
            let cycleSteps = viewModel.stepStates.filter {
                if case .exercise(.cycles, _) = $0.step {
                    return true
                }
                return false
            }
            #expect(cycleSteps.count == 40)
            #expect(viewModel.stepStates.count == 42)
        }

        @Test("Должен инициализировать этапы для турбо-дня 93 с подходами")
        @MainActor
        func initializeStepStatesForTurboDay93() {
            let viewModel = WorkoutScreenViewModel()
            let creator = WorkoutProgramCreator(day: 93, executionType: .turbo)
            viewModel.setupWorkoutData(
                dayNumber: 93,
                executionType: .turbo,
                trainings: creator.trainings,
                plannedCount: creator.plannedCount,
                restTime: 60
            )
            let setSteps = viewModel.stepStates.filter {
                if case .exercise(.sets, _) = $0.step {
                    return true
                }
                return false
            }
            #expect(setSteps.count == 5)
            #expect(viewModel.stepStates.count == 7)
        }

        @Test("Должен инициализировать этапы для турбо-дня 94 с кругами")
        @MainActor
        func initializeStepStatesForTurboDay94() {
            let viewModel = WorkoutScreenViewModel()
            let creator = WorkoutProgramCreator(day: 94, executionType: .turbo)
            viewModel.setupWorkoutData(
                dayNumber: 94,
                executionType: .turbo,
                trainings: creator.trainings,
                plannedCount: creator.plannedCount,
                restTime: 60
            )
            let cycleSteps = viewModel.stepStates.filter {
                if case .exercise(.cycles, _) = $0.step {
                    return true
                }
                return false
            }
            #expect(cycleSteps.count == 5)
            #expect(viewModel.stepStates.count == 7)
        }

        @Test("Должен инициализировать этапы для турбо-дня 95 с подходами")
        @MainActor
        func initializeStepStatesForTurboDay95() {
            let viewModel = WorkoutScreenViewModel()
            let creator = WorkoutProgramCreator(day: 95, executionType: .turbo)
            viewModel.setupWorkoutData(
                dayNumber: 95,
                executionType: .turbo,
                trainings: creator.trainings,
                plannedCount: creator.plannedCount,
                restTime: 60
            )
            let setSteps = viewModel.stepStates.filter {
                if case .exercise(.sets, _) = $0.step {
                    return true
                }
                return false
            }
            #expect(setSteps.count == 5)
            #expect(viewModel.stepStates.count == 7)
        }

        @Test("Должен инициализировать этапы для турбо-дня 96 с кругами")
        @MainActor
        func initializeStepStatesForTurboDay96() {
            let viewModel = WorkoutScreenViewModel()
            let creator = WorkoutProgramCreator(day: 96, executionType: .turbo)
            viewModel.setupWorkoutData(
                dayNumber: 96,
                executionType: .turbo,
                trainings: creator.trainings,
                plannedCount: creator.plannedCount,
                restTime: 60
            )
            let cycleSteps = viewModel.stepStates.filter {
                if case .exercise(.cycles, _) = $0.step {
                    return true
                }
                return false
            }
            #expect(cycleSteps.count == 5)
            #expect(viewModel.stepStates.count == 7)
        }

        @Test("Должен инициализировать этапы для турбо-дня 97 с кругами")
        @MainActor
        func initializeStepStatesForTurboDay97() {
            let viewModel = WorkoutScreenViewModel()
            let creator = WorkoutProgramCreator(day: 97, executionType: .turbo)
            viewModel.setupWorkoutData(
                dayNumber: 97,
                executionType: .turbo,
                trainings: creator.trainings,
                plannedCount: creator.plannedCount,
                restTime: 60
            )
            let cycleSteps = viewModel.stepStates.filter {
                if case .exercise(.cycles, _) = $0.step {
                    return true
                }
                return false
            }
            #expect(cycleSteps.count == 5)
            #expect(viewModel.stepStates.count == 7)
        }

        @Test("Должен инициализировать этапы для турбо-дня 98 с подходами")
        @MainActor
        func initializeStepStatesForTurboDay98() {
            let viewModel = WorkoutScreenViewModel()
            let creator = WorkoutProgramCreator(day: 98, executionType: .turbo)
            viewModel.setupWorkoutData(
                dayNumber: 98,
                executionType: .turbo,
                trainings: creator.trainings,
                plannedCount: creator.plannedCount,
                restTime: 60
            )
            let setSteps = viewModel.stepStates.filter {
                if case .exercise(.sets, _) = $0.step {
                    return true
                }
                return false
            }
            #expect(setSteps.count == 3)
            #expect(viewModel.stepStates.count == 5)
        }

        @Test("Должен возвращать круги для турбо-дня 92")
        @MainActor
        func getCycleStepsForTurboDay92() {
            let viewModel = WorkoutScreenViewModel()
            let creator = WorkoutProgramCreator(day: 92, executionType: .turbo)
            viewModel.setupWorkoutData(
                dayNumber: 92,
                executionType: .turbo,
                trainings: creator.trainings,
                plannedCount: creator.plannedCount,
                restTime: 60
            )
            let cycleSteps = viewModel.getCycleSteps()
            #expect(cycleSteps.count == 40)
        }

        @Test("Должен возвращать пустой массив для турбо-дня 93")
        @MainActor
        func getCycleStepsForTurboDay93() {
            let viewModel = WorkoutScreenViewModel()
            let creator = WorkoutProgramCreator(day: 93, executionType: .turbo)
            viewModel.setupWorkoutData(
                dayNumber: 93,
                executionType: .turbo,
                trainings: creator.trainings,
                plannedCount: creator.plannedCount,
                restTime: 60
            )
            let cycleSteps = viewModel.getCycleSteps()
            #expect(cycleSteps.isEmpty)
        }

        @Test("Должен возвращать круги для турбо-дня 94")
        @MainActor
        func getCycleStepsForTurboDay94() {
            let viewModel = WorkoutScreenViewModel()
            let creator = WorkoutProgramCreator(day: 94, executionType: .turbo)
            viewModel.setupWorkoutData(
                dayNumber: 94,
                executionType: .turbo,
                trainings: creator.trainings,
                plannedCount: creator.plannedCount,
                restTime: 60
            )
            let cycleSteps = viewModel.getCycleSteps()
            #expect(cycleSteps.count == 5)
        }

        @Test("Должен возвращать пустой массив для турбо-дня 95")
        @MainActor
        func getCycleStepsForTurboDay95() {
            let viewModel = WorkoutScreenViewModel()
            let creator = WorkoutProgramCreator(day: 95, executionType: .turbo)
            viewModel.setupWorkoutData(
                dayNumber: 95,
                executionType: .turbo,
                trainings: creator.trainings,
                plannedCount: creator.plannedCount,
                restTime: 60
            )
            let cycleSteps = viewModel.getCycleSteps()
            #expect(cycleSteps.isEmpty)
        }

        @Test("Должен возвращать круги для турбо-дня 96")
        @MainActor
        func getCycleStepsForTurboDay96() {
            let viewModel = WorkoutScreenViewModel()
            let creator = WorkoutProgramCreator(day: 96, executionType: .turbo)
            viewModel.setupWorkoutData(
                dayNumber: 96,
                executionType: .turbo,
                trainings: creator.trainings,
                plannedCount: creator.plannedCount,
                restTime: 60
            )
            let cycleSteps = viewModel.getCycleSteps()
            #expect(cycleSteps.count == 5)
        }

        @Test("Должен возвращать круги для турбо-дня 97")
        @MainActor
        func getCycleStepsForTurboDay97() {
            let viewModel = WorkoutScreenViewModel()
            let creator = WorkoutProgramCreator(day: 97, executionType: .turbo)
            viewModel.setupWorkoutData(
                dayNumber: 97,
                executionType: .turbo,
                trainings: creator.trainings,
                plannedCount: creator.plannedCount,
                restTime: 60
            )
            let cycleSteps = viewModel.getCycleSteps()
            #expect(cycleSteps.count == 5)
        }

        @Test("Должен возвращать пустой массив для турбо-дня 98")
        @MainActor
        func getCycleStepsForTurboDay98() {
            let viewModel = WorkoutScreenViewModel()
            let creator = WorkoutProgramCreator(day: 98, executionType: .turbo)
            viewModel.setupWorkoutData(
                dayNumber: 98,
                executionType: .turbo,
                trainings: creator.trainings,
                plannedCount: creator.plannedCount,
                restTime: 60
            )
            let cycleSteps = viewModel.getCycleSteps()
            #expect(cycleSteps.isEmpty)
        }

        @Test("Должен возвращать пустой массив для getExerciseSteps турбо-дня 92")
        @MainActor
        func getExerciseStepsForTurboDay92() throws {
            let viewModel = WorkoutScreenViewModel()
            let creator = WorkoutProgramCreator(day: 92, executionType: .turbo)
            viewModel.setupWorkoutData(
                dayNumber: 92,
                executionType: .turbo,
                trainings: creator.trainings,
                plannedCount: creator.plannedCount,
                restTime: 60
            )
            let firstTraining = try #require(creator.trainings.first)
            let exerciseSteps = viewModel.getExerciseSteps(for: firstTraining.id)
            #expect(exerciseSteps.isEmpty)
        }

        @Test("Должен возвращать подходы для getExerciseSteps турбо-дня 93")
        @MainActor
        func getExerciseStepsForTurboDay93() throws {
            let viewModel = WorkoutScreenViewModel()
            let creator = WorkoutProgramCreator(day: 93, executionType: .turbo)
            viewModel.setupWorkoutData(
                dayNumber: 93,
                executionType: .turbo,
                trainings: creator.trainings,
                plannedCount: creator.plannedCount,
                restTime: 60
            )
            let firstTraining = try #require(creator.trainings.first)
            let exerciseSteps = viewModel.getExerciseSteps(for: firstTraining.id)
            #expect(exerciseSteps.count == 1)
        }

        @Test("Должен возвращать пустой массив для getExerciseSteps турбо-дня 94")
        @MainActor
        func getExerciseStepsForTurboDay94() throws {
            let viewModel = WorkoutScreenViewModel()
            let creator = WorkoutProgramCreator(day: 94, executionType: .turbo)
            viewModel.setupWorkoutData(
                dayNumber: 94,
                executionType: .turbo,
                trainings: creator.trainings,
                plannedCount: creator.plannedCount,
                restTime: 60
            )
            let firstTraining = try #require(creator.trainings.first)
            let exerciseSteps = viewModel.getExerciseSteps(for: firstTraining.id)
            #expect(exerciseSteps.isEmpty)
        }

        @Test("Должен возвращать подходы для getExerciseSteps турбо-дня 95")
        @MainActor
        func getExerciseStepsForTurboDay95() throws {
            let viewModel = WorkoutScreenViewModel()
            let creator = WorkoutProgramCreator(day: 95, executionType: .turbo)
            viewModel.setupWorkoutData(
                dayNumber: 95,
                executionType: .turbo,
                trainings: creator.trainings,
                plannedCount: creator.plannedCount,
                restTime: 60
            )
            let firstTraining = try #require(creator.trainings.first)
            let exerciseSteps = viewModel.getExerciseSteps(for: firstTraining.id)
            #expect(exerciseSteps.count == 1)
        }

        @Test("Должен возвращать пустой массив для getExerciseSteps турбо-дня 96")
        @MainActor
        func getExerciseStepsForTurboDay96() throws {
            let viewModel = WorkoutScreenViewModel()
            let creator = WorkoutProgramCreator(day: 96, executionType: .turbo)
            viewModel.setupWorkoutData(
                dayNumber: 96,
                executionType: .turbo,
                trainings: creator.trainings,
                plannedCount: creator.plannedCount,
                restTime: 60
            )
            let firstTraining = try #require(creator.trainings.first)
            let exerciseSteps = viewModel.getExerciseSteps(for: firstTraining.id)
            #expect(exerciseSteps.isEmpty)
        }

        @Test("Должен возвращать пустой массив для getExerciseSteps турбо-дня 97")
        @MainActor
        func getExerciseStepsForTurboDay97() throws {
            let viewModel = WorkoutScreenViewModel()
            let creator = WorkoutProgramCreator(day: 97, executionType: .turbo)
            viewModel.setupWorkoutData(
                dayNumber: 97,
                executionType: .turbo,
                trainings: creator.trainings,
                plannedCount: creator.plannedCount,
                restTime: 60
            )
            let firstTraining = try #require(creator.trainings.first)
            let exerciseSteps = viewModel.getExerciseSteps(for: firstTraining.id)
            #expect(exerciseSteps.isEmpty)
        }

        @Test("Должен возвращать подходы для getExerciseSteps турбо-дня 98")
        @MainActor
        func getExerciseStepsForTurboDay98() throws {
            let viewModel = WorkoutScreenViewModel()
            let creator = WorkoutProgramCreator(day: 98, executionType: .turbo)
            viewModel.setupWorkoutData(
                dayNumber: 98,
                executionType: .turbo,
                trainings: creator.trainings,
                plannedCount: creator.plannedCount,
                restTime: 60
            )
            let firstTraining = try #require(creator.trainings.first)
            let exerciseSteps = viewModel.getExerciseSteps(for: firstTraining.id)
            #expect(exerciseSteps.count == 1)
        }

        @Test("Должен возвращать true для shouldShowExercisesReminder при cycles")
        @MainActor
        func shouldShowExercisesReminderForCycles() {
            let viewModel = WorkoutScreenViewModel()
            viewModel.executionType = .cycles
            #expect(viewModel.shouldShowExercisesReminder)
        }

        @Test("Должен возвращать false для shouldShowExercisesReminder при sets")
        @MainActor
        func shouldShowExercisesReminderForSets() {
            let viewModel = WorkoutScreenViewModel()
            viewModel.executionType = .sets
            #expect(!viewModel.shouldShowExercisesReminder)
        }

        @Test("Должен возвращать true для shouldShowExercisesReminder при турбо-дне 92")
        @MainActor
        func shouldShowExercisesReminderForTurboDay92() {
            let viewModel = WorkoutScreenViewModel()
            viewModel.dayNumber = 92
            viewModel.executionType = .turbo
            #expect(viewModel.shouldShowExercisesReminder)
        }

        @Test("Должен возвращать false для shouldShowExercisesReminder при турбо-дне 93")
        @MainActor
        func shouldShowExercisesReminderForTurboDay93() {
            let viewModel = WorkoutScreenViewModel()
            viewModel.dayNumber = 93
            viewModel.executionType = .turbo
            #expect(!viewModel.shouldShowExercisesReminder)
        }

        @Test("Должен возвращать true для shouldShowExercisesReminder при турбо-дне 94")
        @MainActor
        func shouldShowExercisesReminderForTurboDay94() {
            let viewModel = WorkoutScreenViewModel()
            viewModel.dayNumber = 94
            viewModel.executionType = .turbo
            #expect(viewModel.shouldShowExercisesReminder)
        }

        @Test("Должен возвращать false для shouldShowExercisesReminder при турбо-дне 95")
        @MainActor
        func shouldShowExercisesReminderForTurboDay95() {
            let viewModel = WorkoutScreenViewModel()
            viewModel.dayNumber = 95
            viewModel.executionType = .turbo
            #expect(!viewModel.shouldShowExercisesReminder)
        }

        @Test("Должен возвращать true для shouldShowExercisesReminder при турбо-дне 96")
        @MainActor
        func shouldShowExercisesReminderForTurboDay96() {
            let viewModel = WorkoutScreenViewModel()
            viewModel.dayNumber = 96
            viewModel.executionType = .turbo
            #expect(viewModel.shouldShowExercisesReminder)
        }

        @Test("Должен возвращать true для shouldShowExercisesReminder при турбо-дне 97")
        @MainActor
        func shouldShowExercisesReminderForTurboDay97() {
            let viewModel = WorkoutScreenViewModel()
            viewModel.dayNumber = 97
            viewModel.executionType = .turbo
            #expect(viewModel.shouldShowExercisesReminder)
        }

        @Test("Должен возвращать false для shouldShowExercisesReminder при турбо-дне 98")
        @MainActor
        func shouldShowExercisesReminderForTurboDay98() {
            let viewModel = WorkoutScreenViewModel()
            viewModel.dayNumber = 98
            viewModel.executionType = .turbo
            #expect(!viewModel.shouldShowExercisesReminder)
        }
    }
}
