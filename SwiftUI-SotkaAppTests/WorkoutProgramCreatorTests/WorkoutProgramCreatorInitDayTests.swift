import Foundation
@testable import SwiftUI_SotkaApp
import Testing

extension AllWorkoutProgramCreatorTests {
    // MARK: - init(day:) Tests

    @Test("Должен создавать WorkoutProgramCreator для нового дня с дефолтными значениями")
    func createsForNewDayWithDefaultValues() throws {
        let creator = WorkoutProgramCreator(day: 1)

        #expect(creator.day == 1)
        #expect(creator.executionType == .cycles)
        #expect(creator.count == nil)
        #expect(creator.comment == nil)
        let plannedCount = try #require(creator.plannedCount)
        #expect(plannedCount == 4)
        #expect(creator.trainings.count == 4)
    }

    @Test("Должен генерировать базовый набор упражнений для дня 1")
    func generatesBasicExercisesForDay1() throws {
        let creator = WorkoutProgramCreator(day: 1)

        #expect(creator.trainings.count == 4)
        let firstTraining = try #require(creator.trainings.first)
        let firstTypeId = try #require(firstTraining.typeId)
        #expect(firstTypeId == ExerciseType.pullups.rawValue)
        let firstCount = try #require(firstTraining.count)
        #expect(firstCount == 1)
    }

    @Test("Должен генерировать упражнения для типа cycles")
    func generatesExercisesForCyclesType() {
        let creator = WorkoutProgramCreator(day: 1, executionType: .cycles)

        #expect(creator.executionType == .cycles)
        #expect(creator.trainings.count == 4)
    }

    @Test("Должен генерировать упражнения для типа sets")
    func generatesExercisesForSetsType() {
        let creator = WorkoutProgramCreator(day: 50, executionType: .sets)

        #expect(creator.executionType == .sets)
        #expect(creator.trainings.count == 4)
    }

    @Test("Должен генерировать упражнения для типа turbo")
    func generatesExercisesForTurboType() {
        let creator = WorkoutProgramCreator(day: 92, executionType: .turbo)

        #expect(creator.executionType == .turbo)
        #expect(creator.trainings.count == 3)
    }

    @Test("Должен заменять SQUATS на LUNGES для дней 29-49")
    func replacesSquatsWithLungesForDays29To49() throws {
        let creator = WorkoutProgramCreator(day: 30)

        let fourthTraining = creator.trainings[3]
        let fourthTypeId = try #require(fourthTraining.typeId)
        #expect(fourthTypeId == ExerciseType.lunges.rawValue)
    }

    @Test("Должен генерировать 5 упражнений для дней 93, 95, 97 в турбо-режиме")
    func generates5ExercisesForDays939597InTurboMode() {
        let creator93 = WorkoutProgramCreator(day: 93, executionType: .turbo)
        #expect(creator93.trainings.count == 5)

        let creator95 = WorkoutProgramCreator(day: 95, executionType: .turbo)
        #expect(creator95.trainings.count == 5)

        let creator97 = WorkoutProgramCreator(day: 97, executionType: .turbo)
        #expect(creator97.trainings.count == 5)
    }

    @Test("Должен генерировать 3 упражнения для турбо-дней 94, 96, 98")
    func generates3ExercisesForTurboDays949698() {
        let creator94 = WorkoutProgramCreator(day: 94, executionType: .turbo)
        #expect(creator94.trainings.count == 3)

        let creator96 = WorkoutProgramCreator(day: 96, executionType: .turbo)
        #expect(creator96.trainings.count == 3)

        let creator98 = WorkoutProgramCreator(day: 98, executionType: .turbo)
        #expect(creator98.trainings.count == 3)
    }

    @Test("Должен генерировать правильные количества упражнений для дня 98 в турбо-режиме")
    func generatesCorrectCountsForDay98InTurboMode() throws {
        let creator = WorkoutProgramCreator(day: 98, executionType: .turbo)

        #expect(creator.trainings.count == 3)

        let pullUpsTraining = creator.trainings.first { training in
            training.typeId == ExerciseType.turbo98Pullups.rawValue
        }
        let pullUpsCount = try #require(pullUpsTraining?.count)
        #expect(pullUpsCount == 10)

        let pushUpsTraining = creator.trainings.first { training in
            training.typeId == ExerciseType.turbo98Pushups.rawValue
        }
        let pushUpsCount = try #require(pushUpsTraining?.count)
        #expect(pushUpsCount == 20)

        let squatsTraining = creator.trainings.first { training in
            training.typeId == ExerciseType.turbo98Squats.rawValue
        }
        let squatsCount = try #require(squatsTraining?.count)
        #expect(squatsCount == 30)
    }

    @Test("Должен вычислять плановое количество кругов для типа cycles")
    func calculatesPlannedCirclesForCyclesType() throws {
        let creator = WorkoutProgramCreator(day: 1)

        let plannedCount = try #require(creator.plannedCount)
        #expect(plannedCount == 4)
    }

    @Test("Должен увеличивать круги на день 22 для типа cycles")
    func increasesCirclesOnDay22ForCyclesType() throws {
        let creator21 = WorkoutProgramCreator(day: 21)
        let creator22 = WorkoutProgramCreator(day: 22)

        let plannedCount21 = try #require(creator21.plannedCount)
        let plannedCount22 = try #require(creator22.plannedCount)
        #expect(plannedCount22 == plannedCount21 + 1)
    }

    @Test("Должен увеличивать круги на день 43 для типа cycles")
    func increasesCirclesOnDay43ForCyclesType() throws {
        let creator42 = WorkoutProgramCreator(day: 42)
        let creator43 = WorkoutProgramCreator(day: 43)

        let plannedCount42 = try #require(creator42.plannedCount)
        let plannedCount43 = try #require(creator43.plannedCount)
        #expect(plannedCount43 == plannedCount42 + 1)
    }

    @Test("Должен возвращать 6 для типа sets")
    func returns6ForSetsType() throws {
        let creator = WorkoutProgramCreator(day: 50, executionType: .sets)

        let plannedCount = try #require(creator.plannedCount)
        #expect(plannedCount == 6)
    }

    @Test("Должен возвращать 40 для дня 92 в турбо-режиме")
    func returns40ForDay92InTurboMode() throws {
        let creator = WorkoutProgramCreator(day: 92, executionType: .turbo)

        let plannedCount = try #require(creator.plannedCount)
        #expect(plannedCount == 40)
    }

    @Test("Должен возвращать 1 для дней 93, 95, 98 в турбо-режиме")
    func returns1ForDays939598InTurboMode() throws {
        let creator93 = WorkoutProgramCreator(day: 93, executionType: .turbo)
        let plannedCount93 = try #require(creator93.plannedCount)
        #expect(plannedCount93 == 1)

        let creator95 = WorkoutProgramCreator(day: 95, executionType: .turbo)
        let plannedCount95 = try #require(creator95.plannedCount)
        #expect(plannedCount95 == 1)

        let creator98 = WorkoutProgramCreator(day: 98, executionType: .turbo)
        let plannedCount98 = try #require(creator98.plannedCount)
        #expect(plannedCount98 == 1)
    }

    @Test("Должен возвращать 5 для остальных турбо-дней")
    func returns5ForOtherTurboDays() throws {
        let creator94 = WorkoutProgramCreator(day: 94, executionType: .turbo)
        let plannedCount94 = try #require(creator94.plannedCount)
        #expect(plannedCount94 == 5)

        let creator96 = WorkoutProgramCreator(day: 96, executionType: .turbo)
        let plannedCount96 = try #require(creator96.plannedCount)
        #expect(plannedCount96 == 5)

        let creator97 = WorkoutProgramCreator(day: 97, executionType: .turbo)
        let plannedCount97 = try #require(creator97.plannedCount)
        #expect(plannedCount97 == 5)
    }

    @Test("Должен генерировать правильные количества упражнений для дня 93 в турбо-режиме")
    func generatesCorrectCountsForDay93InTurboMode() throws {
        let creator = WorkoutProgramCreator(day: 93, executionType: .turbo)

        #expect(creator.trainings.count == 5)

        let count0 = try #require(creator.trainings[0].count)
        #expect(count0 == 3)

        let count1 = try #require(creator.trainings[1].count)
        #expect(count1 == 3)

        let count2 = try #require(creator.trainings[2].count)
        #expect(count2 == 2)

        let count3 = try #require(creator.trainings[3].count)
        #expect(count3 == 3)

        let count4 = try #require(creator.trainings[4].count)
        #expect(count4 == 10)
    }

    @Test("Должен генерировать правильные количества упражнений для дня 95 в турбо-режиме")
    func generatesCorrectCountsForDay95InTurboMode() throws {
        let creator = WorkoutProgramCreator(day: 95, executionType: .turbo)

        #expect(creator.trainings.count == 5)

        let count0 = try #require(creator.trainings[0].count)
        #expect(count0 == 3)

        let count1 = try #require(creator.trainings[1].count)
        #expect(count1 == 2)

        let count2 = try #require(creator.trainings[2].count)
        #expect(count2 == 1)

        let count3 = try #require(creator.trainings[3].count)
        #expect(count3 == 2)

        let count4 = try #require(creator.trainings[4].count)
        #expect(count4 == 3)
    }

    @Test("Должен генерировать правильные количества упражнений для дня 97 в турбо-режиме")
    func generatesCorrectCountsForDay97InTurboMode() throws {
        let creator = WorkoutProgramCreator(day: 97, executionType: .turbo)

        #expect(creator.trainings.count == 5)

        for i in 0 ..< 5 {
            let count = try #require(creator.trainings[i].count)
            #expect(count == 5)
        }
    }

    @Test("Должен генерировать 3 упражнения для дня 92 в турбо-режиме")
    func generates3ExercisesForDay92InTurboMode() {
        let creator = WorkoutProgramCreator(day: 92, executionType: .turbo)

        #expect(creator.trainings.count == 3)
    }

    @Test("Должен генерировать правильные количества упражнений для дня 92 в турбо-режиме")
    func generatesCorrectCountsForDay92InTurboMode() throws {
        let creator = WorkoutProgramCreator(day: 92, executionType: .turbo)

        #expect(creator.trainings.count == 3)

        let pushUpsTraining = creator.trainings.first { training in
            training.typeId == ExerciseType.pushups.rawValue
        }
        let pushUpsCount = try #require(pushUpsTraining?.count)
        #expect(pushUpsCount == 4)

        let lungesTraining = creator.trainings.first { training in
            training.typeId == ExerciseType.lunges.rawValue
        }
        let lungesCount = try #require(lungesTraining?.count)
        #expect(lungesCount == 2)

        let pullUpsTraining = creator.trainings.first { training in
            training.typeId == ExerciseType.pullups.rawValue
        }
        let pullUpsCount = try #require(pullUpsTraining?.count)
        #expect(pullUpsCount == 1)
    }

    @Test("Должен генерировать правильные количества упражнений для дня 92 в режиме cycles")
    func generatesCorrectCountsForDay92InCyclesMode() throws {
        let creator = WorkoutProgramCreator(day: 92, executionType: .cycles)

        #expect(creator.trainings.count == 4)

        let pullUpsTraining = creator.trainings.first { training in
            training.typeId == ExerciseType.pullups.rawValue
        }
        let pullUpsCount = try #require(pullUpsTraining?.count)
        #expect(pullUpsCount == 1)

        let squatsTraining = creator.trainings.first { training in
            training.typeId == ExerciseType.squats.rawValue
        }
        let squatsCount = try #require(squatsTraining?.count)
        #expect(squatsCount == 2)

        let pushUpsTraining = creator.trainings.first { training in
            training.typeId == ExerciseType.pushups.rawValue
        }
        let pushUpsCount = try #require(pushUpsTraining?.count)
        #expect(pushUpsCount == 2)

        let lungesTraining = creator.trainings.first { training in
            training.typeId == ExerciseType.lunges.rawValue
        }
        let lungesCount = try #require(lungesTraining?.count)
        #expect(lungesCount == 2)
    }

    @Test("Должен генерировать правильные количества упражнений для дня 92 в режиме sets")
    func generatesCorrectCountsForDay92InSetsMode() throws {
        let creator = WorkoutProgramCreator(day: 92, executionType: .sets)

        #expect(creator.trainings.count == 4)

        let pullUpsTraining = creator.trainings.first { training in
            training.typeId == ExerciseType.pullups.rawValue
        }
        let pullUpsCount = try #require(pullUpsTraining?.count)
        #expect(pullUpsCount == 1)

        let squatsTraining = creator.trainings.first { training in
            training.typeId == ExerciseType.squats.rawValue
        }
        let squatsCount = try #require(squatsTraining?.count)
        #expect(squatsCount == 2)

        let pushUpsTraining = creator.trainings.first { training in
            training.typeId == ExerciseType.pushups.rawValue
        }
        let pushUpsCount = try #require(pushUpsTraining?.count)
        #expect(pushUpsCount == 2)

        let lungesTraining = creator.trainings.first { training in
            training.typeId == ExerciseType.lunges.rawValue
        }
        let lungesCount = try #require(lungesTraining?.count)
        #expect(lungesCount == 2)
    }

    @Test("Должен возвращать cycles для дня 50")
    func returnsCyclesForDay50() {
        let creator = WorkoutProgramCreator(day: 50)

        #expect(creator.defaultExecutionType == .cycles)
    }

    @Test("Должен возвращать turbo для дня 92")
    func returnsTurboForDay92() {
        let creator = WorkoutProgramCreator(day: 92)

        #expect(creator.defaultExecutionType == .turbo)
    }

    @Test("Должен возвращать cycles для дней 99-100")
    func returnsCyclesForDays99To100() {
        let creator99 = WorkoutProgramCreator(day: 99)
        #expect(creator99.defaultExecutionType == .cycles)

        let creator100 = WorkoutProgramCreator(day: 100)
        #expect(creator100.defaultExecutionType == .cycles)
    }

    @Test("Должен возвращать cycles для дней 1-49")
    func returnsCyclesForDays1To49() {
        let creator1 = WorkoutProgramCreator(day: 1)
        #expect(creator1.defaultExecutionType == .cycles)

        let creator49 = WorkoutProgramCreator(day: 49)
        #expect(creator49.defaultExecutionType == .cycles)
    }

    @Test("Должен возвращать cycles для дней 50-91")
    func returnsCyclesForDays50To91() {
        let creator50 = WorkoutProgramCreator(day: 50)
        #expect(creator50.defaultExecutionType == .cycles)

        let creator91 = WorkoutProgramCreator(day: 91)
        #expect(creator91.defaultExecutionType == .cycles)
    }

    @Test("Должен возвращать только cycles для дней 1-49")
    func returnsOnlyCyclesForDays1To49() {
        let creator = WorkoutProgramCreator(day: 1)

        #expect(creator.availableExecutionTypes == [.cycles])
    }

    @Test("Должен возвращать cycles и sets для дней 50-91")
    func returnsCyclesAndSetsForDays50To91() {
        let creator = WorkoutProgramCreator(day: 50)

        #expect(creator.availableExecutionTypes == [.cycles, .sets])
    }

    @Test("Должен возвращать все три типа для дней 92-98")
    func returnsAllThreeTypesForDays92To98() {
        let creator = WorkoutProgramCreator(day: 92)

        #expect(creator.availableExecutionTypes == [.cycles, .sets, .turbo])
    }

    @Test("Должен возвращать cycles и sets для дней 99-100")
    func returnsCyclesAndSetsForDays99To100() {
        let creator = WorkoutProgramCreator(day: 99)

        #expect(creator.availableExecutionTypes == [.cycles, .sets])
    }
}
