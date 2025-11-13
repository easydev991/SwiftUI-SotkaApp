import Foundation
@testable import SwiftUI_SotkaApp
import Testing

extension AllWorkoutProgramCreatorTests {
    // MARK: - getEffectiveExecutionType Tests

    @Test("Должен возвращать cycles для дня 92 с типом turbo")
    func getEffectiveExecutionTypeForTurboDay92() {
        let result = WorkoutProgramCreator.getEffectiveExecutionType(for: 92, executionType: .turbo)
        #expect(result == .cycles)
    }

    @Test("Должен возвращать sets для дня 93 с типом turbo")
    func getEffectiveExecutionTypeForTurboDay93() {
        let result = WorkoutProgramCreator.getEffectiveExecutionType(for: 93, executionType: .turbo)
        #expect(result == .sets)
    }

    @Test("Должен возвращать cycles для дня 94 с типом turbo")
    func getEffectiveExecutionTypeForTurboDay94() {
        let result = WorkoutProgramCreator.getEffectiveExecutionType(for: 94, executionType: .turbo)
        #expect(result == .cycles)
    }

    @Test("Должен возвращать sets для дня 95 с типом turbo")
    func getEffectiveExecutionTypeForTurboDay95() {
        let result = WorkoutProgramCreator.getEffectiveExecutionType(for: 95, executionType: .turbo)
        #expect(result == .sets)
    }

    @Test("Должен возвращать cycles для дня 96 с типом turbo")
    func getEffectiveExecutionTypeForTurboDay96() {
        let result = WorkoutProgramCreator.getEffectiveExecutionType(for: 96, executionType: .turbo)
        #expect(result == .cycles)
    }

    @Test("Должен возвращать cycles для дня 97 с типом turbo")
    func getEffectiveExecutionTypeForTurboDay97() {
        let result = WorkoutProgramCreator.getEffectiveExecutionType(for: 97, executionType: .turbo)
        #expect(result == .cycles)
    }

    @Test("Должен возвращать sets для дня 98 с типом turbo")
    func getEffectiveExecutionTypeForTurboDay98() {
        let result = WorkoutProgramCreator.getEffectiveExecutionType(for: 98, executionType: .turbo)
        #expect(result == .sets)
    }

    @Test("Должен возвращать исходный тип для не-turbo типов")
    func getEffectiveExecutionTypeForNonTurbo() {
        let cyclesResult = WorkoutProgramCreator.getEffectiveExecutionType(for: 50, executionType: .cycles)
        #expect(cyclesResult == .cycles)

        let setsResult = WorkoutProgramCreator.getEffectiveExecutionType(for: 50, executionType: .sets)
        #expect(setsResult == .sets)
    }

    // MARK: - calculatePlannedCircles Tests for Turbo Days

    @Test("Должен возвращать 40 для дня 92 с типом turbo")
    func calculatePlannedCirclesForTurboDay92() throws {
        let creator = WorkoutProgramCreator(day: 92, executionType: .turbo)
        let plannedCount = try #require(creator.plannedCount)
        #expect(plannedCount == 40)
    }

    @Test("Должен возвращать 5 для дня 93 с типом turbo")
    func calculatePlannedCirclesForTurboDay93() throws {
        let creator = WorkoutProgramCreator(day: 93, executionType: .turbo)
        let plannedCount = try #require(creator.plannedCount)
        #expect(plannedCount == 5)
    }

    @Test("Должен возвращать 5 для дня 94 с типом turbo")
    func calculatePlannedCirclesForTurboDay94() throws {
        let creator = WorkoutProgramCreator(day: 94, executionType: .turbo)
        let plannedCount = try #require(creator.plannedCount)
        #expect(plannedCount == 5)
    }

    @Test("Должен возвращать 5 для дня 95 с типом turbo")
    func calculatePlannedCirclesForTurboDay95() throws {
        let creator = WorkoutProgramCreator(day: 95, executionType: .turbo)
        let plannedCount = try #require(creator.plannedCount)
        #expect(plannedCount == 5)
    }

    @Test("Должен возвращать 5 для дня 96 с типом turbo")
    func calculatePlannedCirclesForTurboDay96() throws {
        let creator = WorkoutProgramCreator(day: 96, executionType: .turbo)
        let plannedCount = try #require(creator.plannedCount)
        #expect(plannedCount == 5)
    }

    @Test("Должен возвращать 5 для дня 97 с типом turbo")
    func calculatePlannedCirclesForTurboDay97() throws {
        let creator = WorkoutProgramCreator(day: 97, executionType: .turbo)
        let plannedCount = try #require(creator.plannedCount)
        #expect(plannedCount == 5)
    }

    @Test("Должен возвращать 3 для дня 98 с типом turbo")
    func calculatePlannedCirclesForTurboDay98() throws {
        let creator = WorkoutProgramCreator(day: 98, executionType: .turbo)
        let plannedCount = try #require(creator.plannedCount)
        #expect(plannedCount == 3)
    }

    // MARK: - isTurboWithSets Tests

    @Test("Должен возвращать true для турбо дней с подходами", arguments: [93, 95, 98])
    func isTurboWithSetsForSetsDays(day: Int) {
        let result = WorkoutProgramCreator.isTurboWithSets(day: day, executionType: .turbo)
        #expect(result)
    }

    @Test("Должен возвращать false для других турбо дней", arguments: [92, 94, 96, 97])
    func isTurboWithSetsForOtherTurboDays(day: Int) {
        let result = WorkoutProgramCreator.isTurboWithSets(day: day, executionType: .turbo)
        #expect(!result)
    }

    @Test("Должен возвращать false для типа cycles")
    func isTurboWithSetsForCycles() {
        let result = WorkoutProgramCreator.isTurboWithSets(day: 50, executionType: .cycles)
        #expect(!result)
    }

    @Test("Должен возвращать false для типа sets")
    func isTurboWithSetsForSets() {
        let result = WorkoutProgramCreator.isTurboWithSets(day: 50, executionType: .sets)
        #expect(!result)
    }
}
