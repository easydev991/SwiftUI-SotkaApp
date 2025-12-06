import Foundation
@testable import SwiftUI_SotkaApp
import Testing

@Suite("Тесты для WorkoutData")
struct WorkoutDataTests {
    @Test("Должен создаваться с данными тренировки")
    func createsWithWorkoutData() throws {
        let trainings = [
            WorkoutPreviewTraining(
                id: "training-1",
                count: 10,
                typeId: 0,
                customTypeId: nil,
                sortOrder: 0
            ),
            WorkoutPreviewTraining(
                id: "training-2",
                count: 15,
                typeId: 1,
                customTypeId: nil,
                sortOrder: 1
            )
        ]

        let workoutData = WorkoutData(
            day: 5,
            executionType: 0,
            trainings: trainings,
            plannedCount: 4
        )

        #expect(workoutData.day == 5)
        #expect(workoutData.executionType == 0)
        let plannedCount = try #require(workoutData.plannedCount)
        #expect(plannedCount == 4)
        #expect(workoutData.trainings.count == 2)
    }

    @Test("Должен сериализоваться в JSON и десериализоваться обратно")
    func serializesAndDeserializesJSON() throws {
        let trainings = [
            WorkoutPreviewTraining(
                id: "training-1",
                count: 10,
                typeId: 0,
                customTypeId: nil,
                sortOrder: 0
            )
        ]

        let workoutData = WorkoutData(
            day: 10,
            executionType: 1,
            trainings: trainings,
            plannedCount: 5
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(workoutData)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(WorkoutData.self, from: data)

        #expect(decoded.day == 10)
        #expect(decoded.executionType == 1)
        let decodedPlannedCount = try #require(decoded.plannedCount)
        #expect(decodedPlannedCount == 5)
        #expect(decoded.trainings.count == 1)
    }

    @Test("Должен преобразовывать executionType в ExerciseExecutionType")
    func convertsExecutionTypeToExerciseExecutionType() throws {
        let workoutDataCycles = WorkoutData(
            day: 1,
            executionType: 0,
            trainings: [],
            plannedCount: nil
        )
        let executionTypeCycles = try #require(workoutDataCycles.exerciseExecutionType)
        #expect(executionTypeCycles == .cycles)

        let workoutDataSets = WorkoutData(
            day: 1,
            executionType: 1,
            trainings: [],
            plannedCount: nil
        )
        let executionTypeSets = try #require(workoutDataSets.exerciseExecutionType)
        #expect(executionTypeSets == .sets)

        let workoutDataTurbo = WorkoutData(
            day: 1,
            executionType: 2,
            trainings: [],
            plannedCount: nil
        )
        let executionTypeTurbo = try #require(workoutDataTurbo.exerciseExecutionType)
        #expect(executionTypeTurbo == .turbo)
    }

    @Test("Должен возвращать nil для невалидного executionType")
    func returnsNilForInvalidExecutionType() {
        let workoutData = WorkoutData(
            day: 1,
            executionType: 999,
            trainings: [],
            plannedCount: nil
        )

        #expect(workoutData.exerciseExecutionType == nil)
    }

    @Test("Должен обрабатывать пустой массив trainings")
    func handlesEmptyTrainingsArray() throws {
        let workoutData = WorkoutData(
            day: 1,
            executionType: 0,
            trainings: [],
            plannedCount: nil
        )

        #expect(workoutData.trainings.isEmpty)
        #expect(workoutData.day == 1)
        #expect(workoutData.executionType == 0)
    }

    @Test("Должен обрабатывать опциональный plannedCount")
    func handlesOptionalPlannedCount() throws {
        let workoutDataWithNil = WorkoutData(
            day: 1,
            executionType: 0,
            trainings: [],
            plannedCount: nil
        )

        #expect(workoutDataWithNil.plannedCount == nil)

        let workoutDataWithValue = WorkoutData(
            day: 1,
            executionType: 0,
            trainings: [],
            plannedCount: 3
        )

        let plannedCount = try #require(workoutDataWithValue.plannedCount)
        #expect(plannedCount == 3)
    }

    @Test("Должен корректно сериализовать и десериализовать все поля включая trainings")
    func serializesAndDeserializesAllFieldsIncludingTrainings() throws {
        let trainings = [
            WorkoutPreviewTraining(
                id: "training-1",
                count: 10,
                typeId: 0,
                customTypeId: "custom-123",
                sortOrder: 0
            ),
            WorkoutPreviewTraining(
                id: "training-2",
                count: nil,
                typeId: 1,
                customTypeId: nil,
                sortOrder: 1
            )
        ]

        let workoutData = WorkoutData(
            day: 25,
            executionType: 2,
            trainings: trainings,
            plannedCount: 6
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(workoutData)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(WorkoutData.self, from: data)

        #expect(decoded.day == 25)
        #expect(decoded.executionType == 2)
        let decodedPlannedCount = try #require(decoded.plannedCount)
        #expect(decodedPlannedCount == 6)
        #expect(decoded.trainings.count == 2)

        let firstTraining = decoded.trainings[0]
        #expect(firstTraining.id == "training-1")
        let firstCount = try #require(firstTraining.count)
        #expect(firstCount == 10)
        let firstTypeId = try #require(firstTraining.typeId)
        #expect(firstTypeId == 0)
        let firstCustomTypeId = try #require(firstTraining.customTypeId)
        #expect(firstCustomTypeId == "custom-123")

        let secondTraining = decoded.trainings[1]
        #expect(secondTraining.id == "training-2")
        #expect(secondTraining.count == nil)
        let secondTypeId = try #require(secondTraining.typeId)
        #expect(secondTypeId == 1)
        #expect(secondTraining.customTypeId == nil)
    }
}
