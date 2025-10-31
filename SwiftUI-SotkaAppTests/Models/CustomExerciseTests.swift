import Foundation
import SwiftData
@testable import SwiftUI_SotkaApp
import Testing

@Suite("Тесты для CustomExercise")
struct CustomExerciseTests {
    // MARK: - exerciseSnapshot Tests

    @Test("exerciseSnapshot корректно копирует все поля с пользователем")
    @MainActor
    func exerciseSnapshotWithUser() throws {
        let container = try ModelContainer(
            for: CustomExercise.self,
            User.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = container.mainContext

        let user = User(id: 123)
        context.insert(user)

        let createDate = Date(timeIntervalSince1970: 1700000000)
        let modifyDate = Date(timeIntervalSince1970: 1700100000)

        let exercise = CustomExercise(
            id: "exercise-1",
            name: "Отжимания",
            imageId: 5,
            createDate: createDate,
            modifyDate: modifyDate,
            user: user
        )
        exercise.isSynced = true
        exercise.shouldDelete = false
        context.insert(exercise)
        try context.save()

        let snapshot = exercise.exerciseSnapshot

        #expect(snapshot.id == "exercise-1")
        #expect(snapshot.name == "Отжимания")
        #expect(snapshot.imageId == 5)
        #expect(snapshot.createDate == createDate)
        #expect(snapshot.modifyDate == modifyDate)
        #expect(snapshot.isSynced)
        #expect(!snapshot.shouldDelete)
        let userId = try #require(snapshot.userId)
        #expect(userId == 123)
    }

    @Test("exerciseSnapshot корректно обрабатывает отсутствие пользователя")
    @MainActor
    func exerciseSnapshotWithoutUser() throws {
        let container = try ModelContainer(
            for: CustomExercise.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = container.mainContext

        let createDate = Date(timeIntervalSince1970: 1700000000)
        let modifyDate = Date(timeIntervalSince1970: 1700100000)

        let exercise = CustomExercise(
            id: "exercise-2",
            name: "Подтягивания",
            imageId: 3,
            createDate: createDate,
            modifyDate: modifyDate,
            user: nil
        )
        exercise.isSynced = false
        exercise.shouldDelete = false
        context.insert(exercise)
        try context.save()

        let snapshot = exercise.exerciseSnapshot

        #expect(snapshot.id == "exercise-2")
        #expect(snapshot.name == "Подтягивания")
        #expect(snapshot.imageId == 3)
        #expect(snapshot.createDate == createDate)
        #expect(snapshot.modifyDate == modifyDate)
        #expect(!snapshot.isSynced)
        #expect(!snapshot.shouldDelete)
        #expect(snapshot.userId == nil)
    }

    @Test("exerciseSnapshot корректно копирует флаг shouldDelete")
    @MainActor
    func exerciseSnapshotWithShouldDelete() throws {
        let container = try ModelContainer(
            for: CustomExercise.self,
            User.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = container.mainContext

        let user = User(id: 456)
        context.insert(user)

        let exercise = CustomExercise(
            id: "exercise-3",
            name: "Приседания",
            imageId: 7,
            createDate: Date(),
            modifyDate: Date(),
            user: user
        )
        exercise.isSynced = false
        exercise.shouldDelete = true
        context.insert(exercise)
        try context.save()

        let snapshot = exercise.exerciseSnapshot

        #expect(snapshot.shouldDelete)
        #expect(!snapshot.isSynced)
        let userId = try #require(snapshot.userId)
        #expect(userId == 456)
    }

    @Test("exerciseSnapshot корректно копирует флаг isSynced")
    @MainActor
    func exerciseSnapshotWithIsSynced() throws {
        let container = try ModelContainer(
            for: CustomExercise.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = container.mainContext

        let exercise = CustomExercise(
            id: "exercise-4",
            name: "Выпады",
            imageId: 9,
            createDate: Date(),
            modifyDate: Date(),
            user: nil
        )
        exercise.isSynced = true
        exercise.shouldDelete = false
        context.insert(exercise)
        try context.save()

        let snapshot = exercise.exerciseSnapshot

        #expect(snapshot.isSynced)
        #expect(!snapshot.shouldDelete)
    }

    @Test("exerciseSnapshot возвращает разные экземпляры при повторном вызове")
    @MainActor
    func exerciseSnapshotReturnsNewInstances() throws {
        let container = try ModelContainer(
            for: CustomExercise.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = container.mainContext

        let exercise = CustomExercise(
            id: "exercise-5",
            name: "Планка",
            imageId: 11,
            createDate: Date(),
            modifyDate: Date(),
            user: nil
        )
        context.insert(exercise)
        try context.save()

        let snapshot1 = exercise.exerciseSnapshot
        let snapshot2 = exercise.exerciseSnapshot

        #expect(snapshot1.id == snapshot2.id)
        #expect(snapshot1.name == snapshot2.name)
        #expect(snapshot1.imageId == snapshot2.imageId)
    }
}
