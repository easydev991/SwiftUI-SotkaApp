import Foundation
@testable import SwiftUI_SotkaApp
import Testing

extension WorkoutScreenViewModelTests {
    @Suite("Тесты для турбо-дней")
    @MainActor
    struct TurboDaysTests {
        @Test("Должен возвращать cycles для турбо-дня 92")
        func getEffectiveExecutionTypeForTurboDay92() {
            let viewModel = WorkoutScreenViewModel()
            viewModel.dayNumber = 92
            viewModel.executionType = .turbo
            let result = viewModel.getEffectiveExecutionType()
            #expect(result == .cycles)
        }

        @Test("Должен возвращать sets для турбо-дня 93")
        func getEffectiveExecutionTypeForTurboDay93() {
            let viewModel = WorkoutScreenViewModel()
            viewModel.dayNumber = 93
            viewModel.executionType = .turbo
            let result = viewModel.getEffectiveExecutionType()
            #expect(result == .sets)
        }

        @Test("Должен возвращать cycles для турбо-дня 94")
        func getEffectiveExecutionTypeForTurboDay94() {
            let viewModel = WorkoutScreenViewModel()
            viewModel.dayNumber = 94
            viewModel.executionType = .turbo
            let result = viewModel.getEffectiveExecutionType()
            #expect(result == .cycles)
        }

        @Test("Должен возвращать sets для турбо-дня 95")
        func getEffectiveExecutionTypeForTurboDay95() {
            let viewModel = WorkoutScreenViewModel()
            viewModel.dayNumber = 95
            viewModel.executionType = .turbo
            let result = viewModel.getEffectiveExecutionType()
            #expect(result == .sets)
        }

        @Test("Должен возвращать cycles для турбо-дня 96")
        func getEffectiveExecutionTypeForTurboDay96() {
            let viewModel = WorkoutScreenViewModel()
            viewModel.dayNumber = 96
            viewModel.executionType = .turbo
            let result = viewModel.getEffectiveExecutionType()
            #expect(result == .cycles)
        }

        @Test("Должен возвращать cycles для турбо-дня 97")
        func getEffectiveExecutionTypeForTurboDay97() {
            let viewModel = WorkoutScreenViewModel()
            viewModel.dayNumber = 97
            viewModel.executionType = .turbo
            let result = viewModel.getEffectiveExecutionType()
            #expect(result == .cycles)
        }

        @Test("Должен возвращать sets для турбо-дня 98")
        func getEffectiveExecutionTypeForTurboDay98() {
            let viewModel = WorkoutScreenViewModel()
            viewModel.dayNumber = 98
            viewModel.executionType = .turbo
            let result = viewModel.getEffectiveExecutionType()
            #expect(result == .sets)
        }

        @Test("Должен возвращать исходный тип для cycles")
        func getEffectiveExecutionTypeForNonTurboCycles() {
            let viewModel = WorkoutScreenViewModel()
            viewModel.dayNumber = 1
            viewModel.executionType = .cycles
            let result = viewModel.getEffectiveExecutionType()
            #expect(result == .cycles)
        }

        @Test("Должен возвращать исходный тип для sets")
        func getEffectiveExecutionTypeForNonTurboSets() {
            let viewModel = WorkoutScreenViewModel()
            viewModel.dayNumber = 50
            viewModel.executionType = .sets
            let result = viewModel.getEffectiveExecutionType()
            #expect(result == .sets)
        }

        @Test("Должен инициализировать этапы для турбо-дня 92 с кругами")
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
        func shouldShowExercisesReminderForCycles() {
            let viewModel = WorkoutScreenViewModel()
            viewModel.executionType = .cycles
            #expect(viewModel.shouldShowExercisesReminder)
        }

        @Test("Должен возвращать false для shouldShowExercisesReminder при sets")
        func shouldShowExercisesReminderForSets() {
            let viewModel = WorkoutScreenViewModel()
            viewModel.executionType = .sets
            #expect(!viewModel.shouldShowExercisesReminder)
        }

        @Test("Должен возвращать true для shouldShowExercisesReminder при турбо-дне 92")
        func shouldShowExercisesReminderForTurboDay92() {
            let viewModel = WorkoutScreenViewModel()
            viewModel.dayNumber = 92
            viewModel.executionType = .turbo
            #expect(viewModel.shouldShowExercisesReminder)
        }

        @Test("Должен возвращать false для shouldShowExercisesReminder при турбо-дне 93")
        func shouldShowExercisesReminderForTurboDay93() {
            let viewModel = WorkoutScreenViewModel()
            viewModel.dayNumber = 93
            viewModel.executionType = .turbo
            #expect(!viewModel.shouldShowExercisesReminder)
        }

        @Test("Должен возвращать true для shouldShowExercisesReminder при турбо-дне 94")
        func shouldShowExercisesReminderForTurboDay94() {
            let viewModel = WorkoutScreenViewModel()
            viewModel.dayNumber = 94
            viewModel.executionType = .turbo
            #expect(viewModel.shouldShowExercisesReminder)
        }

        @Test("Должен возвращать false для shouldShowExercisesReminder при турбо-дне 95")
        func shouldShowExercisesReminderForTurboDay95() {
            let viewModel = WorkoutScreenViewModel()
            viewModel.dayNumber = 95
            viewModel.executionType = .turbo
            #expect(!viewModel.shouldShowExercisesReminder)
        }

        @Test("Должен возвращать true для shouldShowExercisesReminder при турбо-дне 96")
        func shouldShowExercisesReminderForTurboDay96() {
            let viewModel = WorkoutScreenViewModel()
            viewModel.dayNumber = 96
            viewModel.executionType = .turbo
            #expect(viewModel.shouldShowExercisesReminder)
        }

        @Test("Должен возвращать true для shouldShowExercisesReminder при турбо-дне 97")
        func shouldShowExercisesReminderForTurboDay97() {
            let viewModel = WorkoutScreenViewModel()
            viewModel.dayNumber = 97
            viewModel.executionType = .turbo
            #expect(viewModel.shouldShowExercisesReminder)
        }

        @Test("Должен возвращать false для shouldShowExercisesReminder при турбо-дне 98")
        func shouldShowExercisesReminderForTurboDay98() {
            let viewModel = WorkoutScreenViewModel()
            viewModel.dayNumber = 98
            viewModel.executionType = .turbo
            #expect(!viewModel.shouldShowExercisesReminder)
        }
    }
}
