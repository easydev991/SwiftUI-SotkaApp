import Foundation
import SwiftData
@testable import SwiftUI_SotkaApp
import SWUtils
import Testing

@MainActor
struct CustomExercisesServiceTests {
    @Test
    func conflictResolutionServerNewer() async throws {
        // Arrange
        let mockClient = MockSWClient()
        let service = CustomExercisesService(client: mockClient)
        let container = try ModelContainer(
            for: CustomExercise.self,
            User.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = container.mainContext

        // Создаем пользователя
        let user = User(id: 1, userName: "testuser", fullName: "Test User", email: "test@example.com")
        context.insert(user)
        try context.save()

        // Создаем локальное упражнение
        let localExercise = CustomExercise(
            id: "test-exercise",
            name: "Локальное название",
            imageId: 1,
            createDate: Date(),
            modifyDate: Date().addingTimeInterval(-3600), // 1 час назад
            user: user
        )
        context.insert(localExercise)
        try context.save()

        // Мокаем серверный ответ, который новее локального
        let serverModifyDate = Date().addingTimeInterval(-1800) // Полчаса назад, новее локального
        let serverExerciseResponse = CustomExerciseResponse(
            id: "test-exercise",
            name: "Серверное название",
            imageId: 2,
            createDate: DateFormatterService.stringFromFullDate(Date().addingTimeInterval(-7200), format: .serverDateTimeSec),
            modifyDate: DateFormatterService.stringFromFullDate(serverModifyDate, format: .serverDateTimeSec)
        )
        mockClient.mockedCustomExercises = [serverExerciseResponse]

        // Act
        await service.syncCustomExercises(context: context)

        // Assert
        let updatedExercise = try #require(context.fetch(FetchDescriptor<CustomExercise>()).first)
        #expect(updatedExercise.name == "Серверное название")
        #expect(updatedExercise.imageId == 2)
        #expect(updatedExercise.isSynced)
    }

    @Test
    func conflictResolutionLocalNewer() async throws {
        // Arrange
        let mockClient = MockSWClient()
        let service = CustomExercisesService(client: mockClient)
        let container = try ModelContainer(
            for: CustomExercise.self,
            User.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = container.mainContext

        // Создаем пользователя
        let user = User(id: 1, userName: "testuser", fullName: "Test User", email: "test@example.com")
        context.insert(user)
        try context.save()

        // Создаем локальное упражнение с более новой датой
        let localExercise = CustomExercise(
            id: "test-exercise",
            name: "Локальное название",
            imageId: 1,
            createDate: Date(),
            modifyDate: Date(), // Текущее время - новее серверного
            user: user
        )
        context.insert(localExercise)
        try context.save()

        // Act
        await service.syncCustomExercises(context: context)

        // Assert
        let updatedExercise = try #require(context.fetch(FetchDescriptor<CustomExercise>()).first)
        #expect(updatedExercise.name == "Локальное название") // Должно остаться локальное
        #expect(updatedExercise.imageId == 1)
    }

    @Test
    func deletedElementRestoration() async throws {
        // Arrange
        let mockClient = MockSWClient()
        let service = CustomExercisesService(client: mockClient)
        let container = try ModelContainer(
            for: CustomExercise.self,
            User.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = container.mainContext

        // Создаем пользователя
        let user = User(id: 1, userName: "testuser", fullName: "Test User", email: "test@example.com")
        context.insert(user)
        try context.save()

        // Создаем локальное упражнение, помеченное на удаление
        let localExercise = CustomExercise(
            id: "test-exercise",
            name: "Локальное название",
            imageId: 1,
            createDate: Date(),
            modifyDate: Date(),
            user: user
        )
        localExercise.shouldDelete = true
        context.insert(localExercise)
        try context.save()

        // Act
        await service.syncCustomExercises(context: context)

        // Assert
        let exercises = try context.fetch(FetchDescriptor<CustomExercise>())
        #expect(exercises.isEmpty) // Упражнение должно быть удалено
    }

    @Test
    func newExerciseFromServer() async throws {
        // Arrange
        let mockClient = MockSWClient()
        let service = CustomExercisesService(client: mockClient)
        let container = try ModelContainer(
            for: CustomExercise.self,
            User.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = container.mainContext

        // Создаем пользователя
        let user = User(id: 1, userName: "testuser", fullName: "Test User", email: "test@example.com")
        context.insert(user)
        try context.save()

        // Мокаем серверный ответ с новым упражнением
        let serverExerciseResponse = CustomExerciseResponse(
            id: "new-exercise",
            name: "Серверное название",
            imageId: 2,
            createDate: DateFormatterService.stringFromFullDate(Date().addingTimeInterval(-3600), format: .serverDateTimeSec),
            modifyDate: DateFormatterService.stringFromFullDate(Date().addingTimeInterval(-1800), format: .serverDateTimeSec)
        )
        mockClient.mockedCustomExercises = [serverExerciseResponse]

        // Act
        await service.syncCustomExercises(context: context)

        // Assert
        let exercises = try context.fetch(FetchDescriptor<CustomExercise>())
        #expect(exercises.count == 1)
        let newExercise = try #require(exercises.first)
        #expect(newExercise.name == "Серверное название")
        #expect(newExercise.imageId == 2)
        #expect(newExercise.isSynced)
    }

    @Test
    func nameConflictResolution() async throws {
        // Arrange
        let mockClient = MockSWClient()
        let service = CustomExercisesService(client: mockClient)
        let container = try ModelContainer(
            for: CustomExercise.self,
            User.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = container.mainContext

        // Создаем пользователя
        let user = User(id: 1, userName: "testuser", fullName: "Test User", email: "test@example.com")
        context.insert(user)
        try context.save()

        // Создаем существующее упражнение с тем же именем
        let existingExercise = CustomExercise(
            id: "existing-exercise",
            name: "Тестовое упражнение",
            imageId: 1,
            createDate: Date(),
            modifyDate: Date(),
            user: user
        )
        context.insert(existingExercise)
        try context.save()

        // Act
        service.createCustomExercise(
            name: "Тестовое упражнение",
            imageId: 2,
            context: context
        )

        // Assert
        let exercises = try context.fetch(FetchDescriptor<CustomExercise>())
        #expect(exercises.count == 2)

        let newExercise = try #require(exercises.first { $0.id != "existing-exercise" })
        #expect(newExercise.name.hasPrefix("Тестовое упражнение"))
        #expect(newExercise.name != "Тестовое упражнение") // Должно быть изменено
    }

    @Test
    func unsyncedLocalChangesNotOverwritten() async throws {
        // Arrange
        let mockClient = MockSWClient()
        let service = CustomExercisesService(client: mockClient)
        let container = try ModelContainer(
            for: CustomExercise.self,
            User.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = container.mainContext

        // Создаем пользователя
        let user = User(id: 1, userName: "testuser", fullName: "Test User", email: "test@example.com")
        context.insert(user)
        try context.save()

        // Создаем локальное упражнение с более новой датой модификации
        let localModifyDate = Date()
        let localExercise = CustomExercise(
            id: "test-exercise",
            name: "Локальное название (изменено)",
            imageId: 1,
            createDate: Date().addingTimeInterval(-3600), // 1 час назад
            modifyDate: localModifyDate,
            user: user
        )
        localExercise.isSynced = false // Ключевой момент - не синхронизировано
        context.insert(localExercise)
        try context.save()

        // Мокаем ошибку при отправке на сервер - это ключевой момент!
        mockClient.shouldThrowError = true

        // Мокаем серверный ответ с более старой версией
        let serverModifyDate = localModifyDate.addingTimeInterval(-1800) // 30 минут назад
        let serverExerciseResponse = CustomExerciseResponse(
            id: "test-exercise",
            name: "Серверное название (старое)",
            imageId: 2,
            createDate: DateFormatterService.stringFromFullDate(Date().addingTimeInterval(-7200), format: .serverDateTimeSec),
            modifyDate: DateFormatterService.stringFromFullDate(serverModifyDate, format: .serverDateTimeSec)
        )
        mockClient.mockedCustomExercises = [serverExerciseResponse]

        // Act - синхронизируем, но локальные изменения должны сохраниться
        await service.syncCustomExercises(context: context)

        // Assert
        let updatedExercise = try #require(context.fetch(FetchDescriptor<CustomExercise>()).first)
        #expect(updatedExercise.name == "Локальное название (изменено)") // Локальные изменения должны сохраниться
        #expect(updatedExercise.imageId == 1) // Локальные изменения должны сохраниться
        #expect(!updatedExercise.isSynced) // Должно остаться несинхронизированным
    }

    @Test
    func localSoftDeleteMarksFlags() async throws {
        // Arrange
        let mockClient = MockSWClient()
        let service = CustomExercisesService(client: mockClient)
        let container = try ModelContainer(
            for: CustomExercise.self,
            User.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = container.mainContext

        let user = User(id: 1)
        context.insert(user)
        try context.save()

        let exercise = CustomExercise(id: "e1", name: "To delete", imageId: 1, createDate: .now, modifyDate: .now, user: user)
        context.insert(exercise)
        try context.save()

        // Act
        try service.deleteCustomExercise(exercise, context: context)

        // Assert
        #expect(exercise.shouldDelete)
        #expect(!exercise.isSynced)
    }
}

// MARK: - Mock клиенты

@MainActor
private class MockSWClient: ExerciseClient {
    var mockedCustomExercises: [CustomExerciseResponse] = []
    var shouldThrowError = false

    func getCustomExercises() async throws -> [CustomExerciseResponse] {
        if shouldThrowError {
            throw NSError(domain: "TestError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Test error"])
        }
        return mockedCustomExercises
    }

    func saveCustomExercise(id: String, exercise: CustomExerciseRequest) async throws -> CustomExerciseResponse {
        if shouldThrowError {
            throw NSError(domain: "TestError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Test error"])
        }
        return CustomExerciseResponse(
            id: id,
            name: exercise.name,
            imageId: exercise.imageId,
            createDate: exercise.createDate,
            modifyDate: exercise.modifyDate ?? ""
        )
    }

    func deleteCustomExercise(id _: String) async throws {
        if shouldThrowError {
            throw NSError(domain: "TestError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Test error"])
        }
    }
}
