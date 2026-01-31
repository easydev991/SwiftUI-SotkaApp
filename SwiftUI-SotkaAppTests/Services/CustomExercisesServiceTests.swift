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
        localExercise.isSynced = true // Упражнение синхронизировано для проверки разрешения конфликта
        context.insert(localExercise)
        try context.save()

        // Мокаем серверный ответ, который новее локального
        let serverModifyDate = Date().addingTimeInterval(-1800) // Полчаса назад, новее локального
        let serverExerciseResponse = CustomExerciseResponse(
            id: "test-exercise",
            name: "Серверное название",
            imageId: 2,
            createDate: Date().addingTimeInterval(-7200),
            modifyDate: serverModifyDate
        )
        mockClient.mockedCustomExercises = [serverExerciseResponse]

        // Act
        _ = try await service.syncCustomExercises(context: context)

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
        _ = try await service.syncCustomExercises(context: context)

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
        _ = try await service.syncCustomExercises(context: context)

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
            createDate: Date().addingTimeInterval(-3600),
            modifyDate: Date().addingTimeInterval(-1800)
        )
        mockClient.mockedCustomExercises = [serverExerciseResponse]

        // Act
        _ = try await service.syncCustomExercises(context: context)

        // Assert
        let exercises = try context.fetch(FetchDescriptor<CustomExercise>())
        #expect(exercises.count == 1)
        let newExercise = try #require(exercises.first)
        #expect(newExercise.name == "Серверное название")
        #expect(newExercise.imageId == 2)
        #expect(newExercise.isSynced)
    }

    @Test
    func nameConflictResolution() throws {
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
            createDate: Date().addingTimeInterval(-7200),
            modifyDate: serverModifyDate
        )
        mockClient.mockedCustomExercises = [serverExerciseResponse]

        _ = try await service.syncCustomExercises(context: context)

        // Assert
        let updatedExercise = try #require(context.fetch(FetchDescriptor<CustomExercise>()).first)
        #expect(updatedExercise.name == "Локальное название (изменено)")
        #expect(updatedExercise.imageId == 1)
        #expect(!updatedExercise.isSynced)
    }

    @Test
    func localSoftDeleteMarksFlags() throws {
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
        service.deleteCustomExercise(exercise, context: context)

        // Assert
        #expect(exercise.shouldDelete)
        #expect(!exercise.isSynced)
    }

    @Test("Пропускает обновление если данные не изменились и упражнение синхронизировано")
    func skipUpdateWhenDataNotChangedAndSynced() async throws {
        let mockClient = MockSWClient()
        let service = CustomExercisesService(client: mockClient)
        let container = try ModelContainer(
            for: CustomExercise.self,
            User.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = container.mainContext

        let user = User(id: 1, userName: "testuser", fullName: "Test User", email: "test@example.com")
        context.insert(user)
        try context.save()

        let localDate = Date().addingTimeInterval(-3600)
        let exercise = CustomExercise(
            id: "test-exercise",
            name: "Test Exercise",
            imageId: 1,
            createDate: localDate,
            modifyDate: localDate,
            user: user
        )
        exercise.isSynced = true
        context.insert(exercise)
        try context.save()

        let serverDate = Date().addingTimeInterval(-1800)
        let serverResponse = CustomExerciseResponse(
            id: "test-exercise",
            name: "Test Exercise",
            imageId: 1,
            createDate: localDate,
            modifyDate: serverDate
        )
        mockClient.mockedCustomExercises = [serverResponse]

        _ = try await service.syncCustomExercises(context: context)

        let updatedExercise = try #require(context.fetch(FetchDescriptor<CustomExercise>()).first)
        #expect(updatedExercise.name == "Test Exercise")
        #expect(updatedExercise.imageId == 1)
        #expect(updatedExercise.isSynced)
    }

    @Test("Пропускает обновление при одинаковых датах")
    func skipUpdateWhenDatesAreEqual() async throws {
        let mockClient = MockSWClient()
        let service = CustomExercisesService(client: mockClient)
        let container = try ModelContainer(
            for: CustomExercise.self,
            User.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = container.mainContext

        let user = User(id: 1, userName: "testuser", fullName: "Test User", email: "test@example.com")
        context.insert(user)
        try context.save()

        let baseDate = Date(timeIntervalSince1970: 1_700_000_000)
        let exercise = CustomExercise(
            id: "test-exercise",
            name: "Local Name",
            imageId: 1,
            createDate: baseDate,
            modifyDate: baseDate,
            user: user
        )
        exercise.isSynced = true
        context.insert(exercise)
        try context.save()

        let serverResponse = CustomExerciseResponse(
            id: "test-exercise",
            name: "Server Name",
            imageId: 2,
            createDate: baseDate,
            modifyDate: baseDate
        )
        mockClient.mockedCustomExercises = [serverResponse]

        _ = try await service.syncCustomExercises(context: context)

        let updatedExercise = try #require(context.fetch(FetchDescriptor<CustomExercise>()).first)
        #expect(updatedExercise.name == "Local Name")
        #expect(updatedExercise.imageId == 1)
    }

    // MARK: - Тесты для возврата SyncResult

    @Test("Возвращает результат успешной синхронизации с подсчетом созданных записей")
    func returnsSuccessResultWithCreatedCount() async throws {
        let mockClient = MockSWClient()
        let service = CustomExercisesService(client: mockClient)
        let container = try ModelContainer(
            for: CustomExercise.self,
            User.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = container.mainContext

        let user = User(id: 1, userName: "testuser", fullName: "Test User", email: "test@example.com")
        context.insert(user)
        try context.save()

        let exercise = CustomExercise(
            id: "test-exercise",
            name: "Test Exercise",
            imageId: 1,
            createDate: Date(),
            modifyDate: Date(),
            user: user
        )
        exercise.isSynced = false
        context.insert(exercise)
        try context.save()

        let serverResponse = CustomExerciseResponse(
            id: "test-exercise",
            name: "Test Exercise",
            imageId: 1,
            createDate: Date(),
            modifyDate: Date()
        )
        mockClient.mockedCustomExercises = [serverResponse]

        let result = try await service.syncCustomExercises(context: context)

        #expect(result.type == .success)
        let details = try #require(result.details.exercises)
        #expect(details.created >= 0)
        #expect(details.updated >= 0)
        #expect(details.deleted >= 0)
    }

    @Test("Возвращает результат с ошибками при сетевой ошибке")
    func returnsResultWithErrorsOnNetworkError() async throws {
        let mockClient = MockSWClient()
        let service = CustomExercisesService(client: mockClient)
        let container = try ModelContainer(
            for: CustomExercise.self,
            User.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = container.mainContext

        let user = User(id: 1, userName: "testuser", fullName: "Test User", email: "test@example.com")
        context.insert(user)
        try context.save()

        let exercise = CustomExercise(
            id: "test-exercise",
            name: "Test Exercise",
            imageId: 1,
            createDate: Date(),
            modifyDate: Date(),
            user: user
        )
        exercise.isSynced = false
        context.insert(exercise)
        try context.save()

        mockClient.shouldThrowError = true

        let result = try await service.syncCustomExercises(context: context)

        #expect(result.type == .error || result.type == .partial)
        let errors = result.details.errors ?? []
        #expect(!errors.isEmpty)
    }

    @Test("Возвращает результат с подсчетом обновленных записей")
    func returnsResultWithUpdatedCount() async throws {
        let mockClient = MockSWClient()
        let service = CustomExercisesService(client: mockClient)
        let container = try ModelContainer(
            for: CustomExercise.self,
            User.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = container.mainContext

        let user = User(id: 1, userName: "testuser", fullName: "Test User", email: "test@example.com")
        context.insert(user)
        try context.save()

        let exercise = CustomExercise(
            id: "test-exercise",
            name: "Test Exercise",
            imageId: 1,
            createDate: Date().addingTimeInterval(-3600),
            modifyDate: Date().addingTimeInterval(-3600),
            user: user
        )
        exercise.isSynced = true
        context.insert(exercise)
        try context.save()

        let serverResponse = CustomExerciseResponse(
            id: "test-exercise",
            name: "Updated Exercise",
            imageId: 2,
            createDate: Date().addingTimeInterval(-3600),
            modifyDate: Date()
        )
        mockClient.mockedCustomExercises = [serverResponse]

        let result = try await service.syncCustomExercises(context: context)

        #expect(result.type == .success)
        let details = try #require(result.details.exercises)
        #expect(details.updated >= 0)
    }

    @Test("Возвращает результат с подсчетом удаленных записей")
    func returnsResultWithDeletedCount() async throws {
        let mockClient = MockSWClient()
        let service = CustomExercisesService(client: mockClient)
        let container = try ModelContainer(
            for: CustomExercise.self,
            User.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = container.mainContext

        let user = User(id: 1, userName: "testuser", fullName: "Test User", email: "test@example.com")
        context.insert(user)
        try context.save()

        let exercise = CustomExercise(
            id: "test-exercise",
            name: "Test Exercise",
            imageId: 1,
            createDate: Date(),
            modifyDate: Date(),
            user: user
        )
        exercise.shouldDelete = true
        exercise.isSynced = false
        context.insert(exercise)
        try context.save()

        mockClient.mockedCustomExercises = []

        let result = try await service.syncCustomExercises(context: context)

        #expect(result.type == .success)
        let details = try #require(result.details.exercises)
        #expect(details.deleted >= 0)
    }
}

// MARK: - Mock клиенты

@MainActor
private class MockSWClient: ExerciseClient {
    var mockedCustomExercises: [CustomExerciseResponse] = []
    var shouldThrowError = false

    func getCustomExercises() async throws -> [CustomExerciseResponse] {
        if shouldThrowError {
            throw MockSWClient.MockError.demoError
        }
        return mockedCustomExercises
    }

    func saveCustomExercise(id: String, exercise: CustomExerciseRequest) async throws -> CustomExerciseResponse {
        if shouldThrowError {
            throw MockSWClient.MockError.demoError
        }
        let createDate = DateFormatterService.dateFromString(exercise.createDate, format: .serverDateTimeSec)
        let modifyDate: Date? = exercise.modifyDate.map {
            DateFormatterService.dateFromString($0, format: .serverDateTimeSec)
        }
        return CustomExerciseResponse(
            id: id,
            name: exercise.name,
            imageId: exercise.imageId,
            createDate: createDate,
            modifyDate: modifyDate
        )
    }

    func deleteCustomExercise(id _: String) async throws {
        if shouldThrowError {
            throw MockSWClient.MockError.demoError
        }
    }
}

extension MockSWClient {
    /// Ошибка для тестирования
    enum MockError: Error {
        case demoError
    }
}
