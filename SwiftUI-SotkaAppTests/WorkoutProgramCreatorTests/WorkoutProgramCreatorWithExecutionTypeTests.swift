import Foundation
@testable import SwiftUI_SotkaApp
import Testing

extension AllWorkoutProgramCreatorTests {
    // MARK: - withExecutionType Tests

    @Test("Должен использовать метод withExecutionType для обновления")
    func usesWithExecutionTypeMethodForUpdate() {
        let creator = WorkoutProgramCreator(day: 1)
        let updatedCreator = creator.withExecutionType(.sets)

        #expect(updatedCreator.executionType == .sets)
        #expect(creator.executionType == .cycles)
    }

    @Test("Должен создавать новый экземпляр WorkoutProgramCreator при изменении типа")
    func createsNewInstanceWhenChangingType() {
        let creator = WorkoutProgramCreator(day: 50)
        let updatedCreator = creator.withExecutionType(.turbo)

        #expect(updatedCreator.executionType == .turbo)
        #expect(creator.executionType == .cycles)
        #expect(updatedCreator.day == creator.day)
    }

    @Test("Должен обновлять упражнения при изменении типа выполнения")
    func updatesExercisesWhenChangingExecutionType() {
        let creator = WorkoutProgramCreator(day: 50, executionType: .cycles)
        let updatedCreator = creator.withExecutionType(.sets)

        #expect(updatedCreator.trainings.count == 4)
    }

    @Test("Должен пересчитывать количество кругов при изменении типа")
    func recalculatesCirclesWhenChangingType() throws {
        let creator = WorkoutProgramCreator(day: 50, executionType: .cycles)
        let updatedCreator = creator.withExecutionType(.sets)

        _ = try #require(creator.plannedCount)
        let plannedCountSets = try #require(updatedCreator.plannedCount)
        #expect(plannedCountSets == 6)
    }

    @Test("Должен сохранять plannedCount установленный пользователем при смене типа выполнения")
    func preservesUserSetPlannedCountWhenChangingExecutionType() throws {
        let creator = WorkoutProgramCreator(
            day: 50,
            executionType: .cycles,
            count: nil,
            plannedCount: 10,
            trainings: [],
            comment: nil
        )
        let updatedCreator = creator.withExecutionType(.sets)

        let preservedPlannedCount = try #require(updatedCreator.plannedCount)
        #expect(preservedPlannedCount == 10)
    }

    @Test("Должен пересчитывать plannedCount если он равен дефолтному значению при смене типа")
    func recalculatesPlannedCountIfEqualToDefaultWhenChangingType() throws {
        let creator = WorkoutProgramCreator(day: 1, executionType: .cycles)
        let defaultPlannedCount = try #require(creator.plannedCount)
        #expect(defaultPlannedCount == 4)
        let updatedCreator = creator.withExecutionType(.sets)

        let newPlannedCount = try #require(updatedCreator.plannedCount)
        #expect(newPlannedCount == 6)
        #expect(newPlannedCount != defaultPlannedCount)
    }

    @Test("Должен пересчитывать plannedCount если он равен nil при смене типа")
    func recalculatesPlannedCountIfNilWhenChangingType() throws {
        let creator = WorkoutProgramCreator(
            day: 50,
            executionType: .cycles,
            count: nil,
            plannedCount: nil,
            trainings: [],
            comment: nil
        )
        let updatedCreator = creator.withExecutionType(.sets)

        let newPlannedCount = try #require(updatedCreator.plannedCount)
        #expect(newPlannedCount == 6)
    }

    @Test("Должен сохранять count для упражнений которые остаются в новом наборе при смене типа")
    func preservesCountForExercisesThatRemainInNewSetWhenChangingType() throws {
        let trainings = [
            WorkoutPreviewTraining(count: 7, typeId: ExerciseType.pullups.rawValue, sortOrder: 0),
            WorkoutPreviewTraining(count: 5, typeId: ExerciseType.pushups.rawValue, sortOrder: 1),
            WorkoutPreviewTraining(count: 3, typeId: ExerciseType.squats.rawValue, sortOrder: 2),
            WorkoutPreviewTraining(count: 2, typeId: ExerciseType.lunges.rawValue, sortOrder: 3)
        ]
        let creator = WorkoutProgramCreator(
            day: 50,
            executionType: .cycles,
            count: nil,
            plannedCount: nil,
            trainings: trainings,
            comment: nil
        )
        let updatedCreator = creator.withExecutionType(.sets)

        let pullupsTraining = updatedCreator.trainings.first { training in
            training.typeId == ExerciseType.pullups.rawValue
        }
        let pullupsCount = try #require(pullupsTraining?.count)
        #expect(pullupsCount == 7)

        let pushupsTraining = updatedCreator.trainings.first { training in
            training.typeId == ExerciseType.pushups.rawValue
        }
        let pushupsCount = try #require(pushupsTraining?.count)
        #expect(pushupsCount == 5)

        let squatsTraining = updatedCreator.trainings.first { training in
            training.typeId == ExerciseType.squats.rawValue
        }
        let squatsCount = try #require(squatsTraining?.count)
        #expect(squatsCount == 3)

        let lungesTraining = updatedCreator.trainings.first { training in
            training.typeId == ExerciseType.lunges.rawValue
        }
        let lungesCount = try #require(lungesTraining?.count)
        #expect(lungesCount == 2)
    }

    @Test("Должен использовать дефолтный count для новых упражнений при смене типа")
    func usesDefaultCountForNewExercisesWhenChangingType() throws {
        let creator = WorkoutProgramCreator(day: 1, executionType: .cycles)
        let updatedCreator = creator.withExecutionType(.sets)

        let defaultCreator = WorkoutProgramCreator(day: 1, executionType: .sets)
        #expect(updatedCreator.trainings.count == defaultCreator.trainings.count)

        for (index, training) in updatedCreator.trainings.enumerated() {
            let defaultTraining = defaultCreator.trainings[index]
            let trainingTypeId = try #require(training.typeId)
            let defaultTypeId = try #require(defaultTraining.typeId)
            #expect(trainingTypeId == defaultTypeId)
            let trainingCount = try #require(training.count)
            let defaultCount = try #require(defaultTraining.count)
            #expect(trainingCount == defaultCount)
        }
    }

    @Test("Должен сохранять count для упражнений с customTypeId при смене типа")
    func preservesCountForExercisesWithCustomTypeIdWhenChangingType() throws {
        let trainings = [
            WorkoutPreviewTraining(
                count: 10,
                typeId: nil,
                customTypeId: "custom-123",
                sortOrder: 0
            )
        ]
        let creator = WorkoutProgramCreator(
            day: 50,
            executionType: .cycles,
            count: nil,
            plannedCount: nil,
            trainings: trainings,
            comment: nil
        )
        let updatedCreator = creator.withExecutionType(.sets)

        let customTraining = updatedCreator.trainings.first { training in
            training.customTypeId == "custom-123"
        }
        if let customTraining {
            let customCount = try #require(customTraining.count)
            #expect(customCount == 10)
        }
    }

    @Test("Должен использовать дефолтные значения при переходе с cycles на turbo")
    func usesDefaultValuesWhenTransitioningFromCyclesToTurbo() throws {
        let trainings = [
            WorkoutPreviewTraining(count: 7, typeId: ExerciseType.pullups.rawValue, sortOrder: 0),
            WorkoutPreviewTraining(count: 5, typeId: ExerciseType.pushups.rawValue, sortOrder: 1)
        ]
        let creator = WorkoutProgramCreator(
            day: 92,
            executionType: .cycles,
            count: nil,
            plannedCount: 10,
            trainings: trainings,
            comment: nil
        )
        let updatedCreator = creator.withExecutionType(.turbo)

        let defaultCreator = WorkoutProgramCreator(day: 92, executionType: .turbo)
        let defaultPlannedCount = try #require(defaultCreator.plannedCount)
        let updatedPlannedCount = try #require(updatedCreator.plannedCount)
        #expect(updatedPlannedCount == defaultPlannedCount)
        #expect(updatedCreator.trainings.count == defaultCreator.trainings.count)
    }

    @Test("Должен использовать дефолтные значения pushUps=2 при переходе с turbo на sets для дня 92")
    func usesDefaultPushUpsCountWhenTransitioningFromTurboToSetsForDay92() throws {
        let creator = WorkoutProgramCreator(day: 92, executionType: .turbo)
        let updatedCreator = creator.withExecutionType(.sets)

        let pushUpsTraining = updatedCreator.trainings.first { training in
            training.typeId == ExerciseType.pushups.rawValue
        }
        let pushUpsCount = try #require(pushUpsTraining?.count)
        #expect(pushUpsCount == 2)
    }

    @Test("Должен использовать дефолтные значения pushUps=2 при переходе с turbo на cycles для дня 92")
    func usesDefaultPushUpsCountWhenTransitioningFromTurboToCyclesForDay92() throws {
        let creator = WorkoutProgramCreator(day: 92, executionType: .turbo)
        let updatedCreator = creator.withExecutionType(.cycles)

        let pushUpsTraining = updatedCreator.trainings.first { training in
            training.typeId == ExerciseType.pushups.rawValue
        }
        let pushUpsCount = try #require(pushUpsTraining?.count)
        #expect(pushUpsCount == 2)
    }
}
