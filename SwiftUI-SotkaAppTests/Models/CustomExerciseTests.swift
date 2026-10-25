import Foundation
import SwiftData
@testable import SwiftUI_SotkaApp
import Testing

@Suite("Тесты для CustomExercise")
struct CustomExerciseTests {
    // MARK: - fetch Tests

    @Test("fetch возвращает упражнение по существующему id")
    @MainActor
    func fetchWithExistingId() throws {
        let container = try ModelContainer(
            for: CustomExercise.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = container.mainContext

        let exercise = CustomExercise(
            id: "exercise-1",
            name: "Отжимания",
            imageId: 5,
            createDate: Date(),
            modifyDate: Date()
        )
        context.insert(exercise)
        try context.save()

        let fetched = CustomExercise.fetch(by: "exercise-1", in: context)
        let found = try #require(fetched)
        #expect(found.id == "exercise-1")
        #expect(found.name == "Отжимания")
        #expect(found.imageId == 5)
    }

    @Test("fetch возвращает nil для несуществующего id")
    @MainActor
    func fetchWithNonExistentId() throws {
        let container = try ModelContainer(
            for: CustomExercise.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = container.mainContext

        let exercise = CustomExercise(
            id: "exercise-1",
            name: "Отжимания",
            imageId: 5,
            createDate: Date(),
            modifyDate: Date()
        )
        context.insert(exercise)
        try context.save()

        let fetched = CustomExercise.fetch(by: "non-existent", in: context)
        #expect(fetched == nil)
    }

    @Test("fetch возвращает правильное упражнение среди нескольких")
    @MainActor
    func fetchWithMultipleExercises() throws {
        let container = try ModelContainer(
            for: CustomExercise.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = container.mainContext

        let exercise1 = CustomExercise(
            id: "exercise-1",
            name: "Отжимания",
            imageId: 5,
            createDate: Date(),
            modifyDate: Date()
        )
        let exercise2 = CustomExercise(
            id: "exercise-2",
            name: "Подтягивания",
            imageId: 3,
            createDate: Date(),
            modifyDate: Date()
        )
        let exercise3 = CustomExercise(
            id: "exercise-3",
            name: "Приседания",
            imageId: 7,
            createDate: Date(),
            modifyDate: Date()
        )
        context.insert(exercise1)
        context.insert(exercise2)
        context.insert(exercise3)
        try context.save()

        let fetched = CustomExercise.fetch(by: "exercise-2", in: context)
        let found = try #require(fetched)
        #expect(found.id == "exercise-2")
        #expect(found.name == "Подтягивания")
        #expect(found.imageId == 3)
    }

    @Test("fetch возвращает nil для пустого контекста")
    @MainActor
    func fetchWithEmptyContext() throws {
        let container = try ModelContainer(
            for: CustomExercise.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = container.mainContext

        let fetched = CustomExercise.fetch(by: "exercise-1", in: context)
        #expect(fetched == nil)
    }

    @Test("fetch чувствителен к регистру id")
    @MainActor
    func fetchCaseSensitive() throws {
        let container = try ModelContainer(
            for: CustomExercise.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = container.mainContext

        let exercise = CustomExercise(
            id: "exercise-1",
            name: "Отжимания",
            imageId: 5,
            createDate: Date(),
            modifyDate: Date()
        )
        context.insert(exercise)
        try context.save()

        let fetched = CustomExercise.fetch(by: "Exercise-1", in: context)
        #expect(fetched == nil)
    }
}
