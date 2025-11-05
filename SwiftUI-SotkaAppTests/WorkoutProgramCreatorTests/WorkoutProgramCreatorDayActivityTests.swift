import Foundation
@testable import SwiftUI_SotkaApp
import Testing

extension AllWorkoutProgramCreatorTests {
    // MARK: - dayActivity Tests

    @Test("Должен создавать DayActivity с правильными базовыми параметрами")
    @MainActor
    func createsDayActivityWithCorrectBasicParameters() {
        let creator = WorkoutProgramCreator(
            day: 5,
            executionType: .cycles,
            count: 10,
            plannedCount: 8,
            trainings: [],
            comment: "Test comment"
        )

        let dayActivity = creator.dayActivity

        #expect(dayActivity.day == 5)
        #expect(dayActivity.activityType == .workout)
        #expect(!dayActivity.isSynced)
        #expect(!dayActivity.shouldDelete)
    }

    @Test("Должен устанавливать правильные параметры тренировки")
    @MainActor
    func setsCorrectTrainingParameters() throws {
        let creator = WorkoutProgramCreator(
            day: 5,
            executionType: .sets,
            count: 10,
            plannedCount: 8,
            trainings: [],
            comment: "Test comment"
        )

        let dayActivity = creator.dayActivity

        let count = try #require(dayActivity.count)
        #expect(count == 10)
        let plannedCount = try #require(dayActivity.plannedCount)
        #expect(plannedCount == 8)
        let executeType = try #require(dayActivity.executeType)
        #expect(executeType == .sets)
        let comment = try #require(dayActivity.comment)
        #expect(comment == "Test comment")
    }

    @Test("Должен преобразовывать WorkoutPreviewTraining в DayActivityTraining")
    @MainActor
    func convertsWorkoutPreviewTrainingToDayActivityTraining() throws {
        let trainings = [
            WorkoutPreviewTraining(count: 5, typeId: ExerciseType.pullups.rawValue, sortOrder: 0),
            WorkoutPreviewTraining(count: 10, typeId: ExerciseType.pushups.rawValue, sortOrder: 1)
        ]

        let creator = WorkoutProgramCreator(
            day: 1,
            executionType: .cycles,
            count: nil,
            plannedCount: 4,
            trainings: trainings,
            comment: nil
        )

        let dayActivity = creator.dayActivity

        #expect(dayActivity.trainings.count == 2)
        let firstTraining = try #require(dayActivity.trainings.first)
        let firstCount = try #require(firstTraining.count)
        #expect(firstCount == 5)
        let firstTypeId = try #require(firstTraining.typeId)
        #expect(firstTypeId == ExerciseType.pullups.rawValue)
    }

    @Test("Должен устанавливать правильные связи между DayActivity и DayActivityTraining")
    @MainActor
    func setsCorrectRelationshipsBetweenDayActivityAndDayActivityTraining() throws {
        let trainings = [
            WorkoutPreviewTraining(count: 5, typeId: ExerciseType.pullups.rawValue, sortOrder: 0)
        ]

        let creator = WorkoutProgramCreator(
            day: 1,
            executionType: .cycles,
            count: nil,
            plannedCount: 4,
            trainings: trainings,
            comment: nil
        )

        let dayActivity = creator.dayActivity

        let training = try #require(dayActivity.trainings.first)
        let dayActivityFromTraining = try #require(training.dayActivity)
        #expect(dayActivityFromTraining.day == dayActivity.day)
    }

    @Test("Должен устанавливать правильные даты создания и изменения")
    @MainActor
    func setsCorrectCreationAndModificationDates() {
        let beforeCreation = Date()
        let creator = WorkoutProgramCreator(day: 1)
        let dayActivity = creator.dayActivity
        let afterCreation = Date()

        #expect(dayActivity.createDate >= beforeCreation)
        #expect(dayActivity.createDate <= afterCreation)
        #expect(dayActivity.modifyDate >= beforeCreation)
        #expect(dayActivity.modifyDate <= afterCreation)
    }

    @Test("Должен устанавливать правильные флаги синхронизации")
    @MainActor
    func setsCorrectSyncFlags() {
        let creator = WorkoutProgramCreator(day: 1)
        let dayActivity = creator.dayActivity

        #expect(!dayActivity.isSynced)
        #expect(!dayActivity.shouldDelete)
    }
}
