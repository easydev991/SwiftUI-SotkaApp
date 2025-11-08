import Foundation
import SwiftData
@testable import SwiftUI_SotkaApp
import Testing

@Suite("Тесты для WorkoutPreviewTraining")
struct WorkoutPreviewTrainingTests {
    @Test("Должен инициализироваться с правильными параметрами")
    func initializesWithCorrectParameters() throws {
        let training = WorkoutPreviewTraining(
            count: 10,
            typeId: 0,
            customTypeId: nil,
            sortOrder: 0
        )

        let count = try #require(training.count)
        let typeId = try #require(training.typeId)
        let sortOrder = try #require(training.sortOrder)

        #expect(count == 10)
        #expect(typeId == 0)
        #expect(training.customTypeId == nil)
        #expect(sortOrder == 0)
    }

    @Test("Должен создаваться из DayActivityTraining через init(from:)")
    @MainActor
    func createsFromDayActivityTraining() throws {
        let container = try ModelContainer(
            for: DayActivityTraining.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = container.mainContext

        let dayActivityTraining = DayActivityTraining(
            count: 15,
            typeId: 3,
            customTypeId: "custom-123",
            sortOrder: 2
        )
        context.insert(dayActivityTraining)
        try context.save()

        let previewTraining = WorkoutPreviewTraining(from: dayActivityTraining)

        let count = try #require(previewTraining.count)
        let typeId = try #require(previewTraining.typeId)
        let customTypeId = try #require(previewTraining.customTypeId)
        let sortOrder = try #require(previewTraining.sortOrder)

        #expect(count == 15)
        #expect(typeId == 3)
        #expect(customTypeId == "custom-123")
        #expect(sortOrder == 2)
    }

    @Test("Должен правильно маппить все поля из DayActivityTraining")
    @MainActor
    func mapsAllFieldsFromDayActivityTraining() throws {
        let container = try ModelContainer(
            for: DayActivityTraining.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = container.mainContext

        let dayActivityTraining = DayActivityTraining(
            count: nil,
            typeId: nil,
            customTypeId: nil,
            sortOrder: nil
        )
        context.insert(dayActivityTraining)
        try context.save()

        let previewTraining = WorkoutPreviewTraining(from: dayActivityTraining)

        #expect(previewTraining.count == nil)
        #expect(previewTraining.typeId == nil)
        #expect(previewTraining.customTypeId == nil)
        #expect(previewTraining.sortOrder == nil)
    }

    @Test("Должен иметь уникальный id при создании")
    func hasUniqueIdWhenCreated() {
        let training1 = WorkoutPreviewTraining(
            count: 10,
            typeId: 0,
            customTypeId: nil,
            sortOrder: 0
        )
        let training2 = WorkoutPreviewTraining(
            count: 10,
            typeId: 0,
            customTypeId: nil,
            sortOrder: 0
        )

        #expect(training1.id != training2.id)
    }

    @Test("Должен сохранять id при создании из DayActivityTraining")
    @MainActor
    func preservesIdWhenCreatedFromDayActivityTraining() throws {
        let container = try ModelContainer(
            for: DayActivityTraining.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = container.mainContext

        let dayActivityTraining = DayActivityTraining(
            count: 15,
            typeId: 3,
            customTypeId: "custom-123",
            sortOrder: 2
        )
        context.insert(dayActivityTraining)
        try context.save()

        let previewTraining = WorkoutPreviewTraining(from: dayActivityTraining)

        #expect(!previewTraining.id.isEmpty)
    }

    @Test("Должен находить тренировку по id")
    func findsTrainingById() throws {
        let training1 = WorkoutPreviewTraining(
            count: 5,
            typeId: 0,
            customTypeId: nil,
            sortOrder: 0
        )
        let training2 = WorkoutPreviewTraining(
            count: 10,
            typeId: 1,
            customTypeId: nil,
            sortOrder: 1
        )
        let training3 = WorkoutPreviewTraining(
            count: 15,
            typeId: 2,
            customTypeId: nil,
            sortOrder: 2
        )

        let trainings = [training1, training2, training3]

        let foundTraining = trainings.first { $0.id == training1.id }

        let found = try #require(foundTraining)
        let foundCount = try #require(found.count)
        #expect(foundCount == 5)
    }

    @Test("Должен возвращать новую модель с обновленным count")
    func returnsNewModelWithUpdatedCount() throws {
        let training = WorkoutPreviewTraining(
            count: 5,
            typeId: 0,
            customTypeId: nil,
            sortOrder: 0
        )

        let updatedTraining = training.withCount(10)

        let originalCount = try #require(training.count)
        let updatedCount = try #require(updatedTraining.count)

        #expect(originalCount == 5)
        #expect(updatedCount == 10)
    }

    @Test("Должен сохранять все остальные поля при обновлении count")
    func preservesAllOtherFieldsWhenUpdatingCount() throws {
        let training = WorkoutPreviewTraining(
            count: 5,
            typeId: 3,
            customTypeId: "custom-123",
            sortOrder: 2
        )

        let updatedTraining = training.withCount(15)

        let originalTypeId = try #require(training.typeId)
        let originalCustomTypeId = try #require(training.customTypeId)
        let originalSortOrder = try #require(training.sortOrder)
        let updatedTypeId = try #require(updatedTraining.typeId)
        let updatedCustomTypeId = try #require(updatedTraining.customTypeId)
        let updatedSortOrder = try #require(updatedTraining.sortOrder)

        #expect(updatedTypeId == originalTypeId)
        #expect(updatedCustomTypeId == originalCustomTypeId)
        #expect(updatedSortOrder == originalSortOrder)
    }

    @Test("Должен сохранять id при обновлении count")
    func preservesIdWhenUpdatingCount() {
        let training = WorkoutPreviewTraining(
            count: 5,
            typeId: 0,
            customTypeId: nil,
            sortOrder: 0
        )

        let updatedTraining = training.withCount(20)

        #expect(training.id == updatedTraining.id)
    }

    @Test("Должен устанавливать count в nil")
    func setsCountToNil() {
        let training = WorkoutPreviewTraining(
            count: 5,
            typeId: 0,
            customTypeId: nil,
            sortOrder: 0
        )

        let updatedTraining = training.withCount(nil)

        #expect(updatedTraining.count == nil)
    }

    @Test("Должен определять стандартные упражнения как не турбо-упражнения")
    func identifiesStandardExercisesAsNonTurbo() {
        let pullups = WorkoutPreviewTraining(typeId: ExerciseType.pullups.rawValue)
        let pushups = WorkoutPreviewTraining(typeId: ExerciseType.pushups.rawValue)
        let squats = WorkoutPreviewTraining(typeId: ExerciseType.squats.rawValue)
        let lunges = WorkoutPreviewTraining(typeId: ExerciseType.lunges.rawValue)

        #expect(!pullups.isTurboExercise)
        #expect(!pushups.isTurboExercise)
        #expect(!squats.isTurboExercise)
        #expect(!lunges.isTurboExercise)
    }

    @Test("Должен определять турбо-упражнения как турбо-упражнения")
    func identifiesTurboExercisesAsTurbo() {
        let turbo93_1 = WorkoutPreviewTraining(typeId: ExerciseType.turbo93_1.rawValue)
        let turbo94Pushups = WorkoutPreviewTraining(typeId: ExerciseType.turbo94Pushups.rawValue)
        let turbo95_1 = WorkoutPreviewTraining(typeId: ExerciseType.turbo95_1.rawValue)
        let turbo96Pushups = WorkoutPreviewTraining(typeId: ExerciseType.turbo96Pushups.rawValue)
        let turbo97PushupsHigh = WorkoutPreviewTraining(typeId: ExerciseType.turbo97PushupsHigh.rawValue)
        let turbo98Pullups = WorkoutPreviewTraining(typeId: ExerciseType.turbo98Pullups.rawValue)

        #expect(turbo93_1.isTurboExercise)
        #expect(turbo94Pushups.isTurboExercise)
        #expect(turbo95_1.isTurboExercise)
        #expect(turbo96Pushups.isTurboExercise)
        #expect(turbo97PushupsHigh.isTurboExercise)
        #expect(turbo98Pullups.isTurboExercise)
    }

    @Test("Должен определять пользовательские упражнения как не турбо-упражнения")
    func identifiesCustomExercisesAsNonTurbo() {
        let customExercise = WorkoutPreviewTraining(
            typeId: nil,
            customTypeId: "custom-123"
        )

        #expect(!customExercise.isTurboExercise)
    }

    @Test("Должен определять упражнения без typeId и customTypeId как не турбо-упражнения")
    func identifiesExercisesWithoutTypeIdAsNonTurbo() {
        let exercise = WorkoutPreviewTraining(
            typeId: nil,
            customTypeId: nil
        )

        #expect(!exercise.isTurboExercise)
    }

    @Test("Должен определять упражнения с typeId меньше 93 как не турбо-упражнения")
    func identifiesExercisesWithTypeIdLessThan93AsNonTurbo() {
        let exercise = WorkoutPreviewTraining(typeId: 92)

        #expect(!exercise.isTurboExercise)
    }

    @Test("Должен определять упражнения с typeId равным 93 как турбо-упражнения")
    func identifiesExercisesWithTypeId93AsTurbo() {
        let exercise = WorkoutPreviewTraining(typeId: 93)

        #expect(exercise.isTurboExercise)
    }
}
