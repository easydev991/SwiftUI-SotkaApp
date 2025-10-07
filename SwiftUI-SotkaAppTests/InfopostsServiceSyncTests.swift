import Foundation
import SwiftData
@testable import SwiftUI_SotkaApp
import Testing

struct InfopostsServiceSyncTests {
    // MARK: - Mock InfopostsClient

    /// Mock клиент для тестирования синхронизации
    private struct MockInfopostsClient: InfopostsClient {
        let getReadPostsResult: Result<[Int], Error>
        let setPostReadResult: Result<Void, Error>
        let deleteAllReadPostsResult: Result<Void, Error>

        init(
            getReadPostsResult: Result<[Int], Error> = .success([]),
            setPostReadResult: Result<Void, Error> = .success(()),
            deleteAllReadPostsResult: Result<Void, Error> = .success(())
        ) {
            self.getReadPostsResult = getReadPostsResult
            self.setPostReadResult = setPostReadResult
            self.deleteAllReadPostsResult = deleteAllReadPostsResult
        }

        func getReadPosts() async throws -> [Int] {
            switch getReadPostsResult {
            case let .success(days):
                return days
            case let .failure(error):
                throw error
            }
        }

        func setPostRead(day _: Int) async throws {
            switch setPostReadResult {
            case .success:
                return
            case let .failure(error):
                throw error
            }
        }

        func deleteAllReadPosts() async throws {
            switch deleteAllReadPostsResult {
            case .success:
                return
            case let .failure(error):
                throw error
            }
        }
    }

    // MARK: - Private Methods

    /// Создает InfopostsService с MockInfopostsClient для тестирования
    /// - Parameters:
    ///   - language: Язык для сервиса
    ///   - mockClient: Mock клиент
    /// - Returns: Настроенный сервис для тестов
    @MainActor
    private func createService(
        language: String = "ru",
        mockClient: MockInfopostsClient
    ) -> InfopostsService {
        InfopostsService(language: language, infopostsClient: mockClient)
    }

    /// Создает тестового пользователя с заданными прочитанными днями
    /// - Parameters:
    ///   - modelContext: Контекст модели данных
    ///   - readDays: Синхронизированные прочитанные дни
    ///   - unsyncedDays: Несинхронизированные прочитанные дни
    /// - Returns: Созданный пользователь
    @MainActor
    private func createTestUser(
        modelContext: ModelContext,
        readDays: [Int] = [],
        unsyncedDays: [Int] = []
    ) -> User {
        let user = User(id: 1)
        user.readInfopostDays = readDays
        user.unsyncedReadInfopostDays = unsyncedDays
        modelContext.insert(user)
        return user
    }

    // MARK: - Тесты синхронизации прочитанных постов

    @Test
    @MainActor
    func syncReadPostsSuccess() async throws {
        // Arrange
        let serverReadDays = [1, 2, 3, 5]
        let mockClient = MockInfopostsClient(getReadPostsResult: .success(serverReadDays))
        let service = createService(mockClient: mockClient)

        let modelContainer = try ModelContainer(for: User.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let modelContext = modelContainer.mainContext

        let user = createTestUser(
            modelContext: modelContext,
            readDays: [1, 2],
            unsyncedDays: [4, 6]
        )
        try modelContext.save()

        // Act
        try await service.syncReadPosts(modelContext: modelContext)

        // Assert
        #expect(user.readInfopostDays == serverReadDays)
        #expect(user.unsyncedReadInfopostDays.isEmpty)
    }

    @Test
    @MainActor
    func syncReadPostsWithEmptyServerData() async throws {
        // Arrange
        let mockClient = MockInfopostsClient(getReadPostsResult: .success([]))
        let service = createService(mockClient: mockClient)

        let modelContainer = try ModelContainer(for: User.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let modelContext = modelContainer.mainContext

        let user = createTestUser(
            modelContext: modelContext,
            readDays: [1, 2],
            unsyncedDays: [3, 4]
        )
        try modelContext.save()

        // Act
        try await service.syncReadPosts(modelContext: modelContext)

        // Assert
        #expect(user.readInfopostDays.isEmpty)
        #expect(user.unsyncedReadInfopostDays.isEmpty)
    }

    @Test
    @MainActor
    func syncReadPostsWhenUserNotFound() async throws {
        // Arrange
        let mockClient = MockInfopostsClient()
        let service = createService(mockClient: mockClient)

        let modelContainer = try ModelContainer(for: User.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let modelContext = modelContainer.mainContext

        // Act & Assert
        await #expect(throws: InfopostsServiceError.userNotFound) {
            try await service.syncReadPosts(modelContext: modelContext)
        }
    }

    @Test
    @MainActor
    func syncReadPostsWithServerError() async throws {
        // Arrange
        let serverError = NSError(domain: "TestError", code: 500, userInfo: [NSLocalizedDescriptionKey: "Server error"])
        let mockClient = MockInfopostsClient(getReadPostsResult: .failure(serverError))
        let service = createService(mockClient: mockClient)

        let modelContainer = try ModelContainer(for: User.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let modelContext = modelContainer.mainContext

        _ = createTestUser(
            modelContext: modelContext,
            readDays: [1, 2],
            unsyncedDays: [3, 4]
        )
        try modelContext.save()

        // Act & Assert
        await #expect(throws: NSError.self) {
            try await service.syncReadPosts(modelContext: modelContext)
        }
    }

    // MARK: - Тесты отметки поста как прочитанного

    @Test
    @MainActor
    func markPostAsReadSuccess() async throws {
        // Arrange
        let mockClient = MockInfopostsClient(setPostReadResult: .success(()))
        let service = createService(mockClient: mockClient)

        let modelContainer = try ModelContainer(for: User.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let modelContext = modelContainer.mainContext

        let user = createTestUser(modelContext: modelContext)
        try modelContext.save()

        // Act
        try await service.markPostAsRead(day: 5, modelContext: modelContext)

        // Assert
        #expect(user.readInfopostDays.contains(5))
        #expect(!user.unsyncedReadInfopostDays.contains(5))
    }

    @Test
    @MainActor
    func markPostAsReadWithSyncError() async throws {
        // Arrange
        let syncError = NSError(domain: "TestError", code: 500, userInfo: [NSLocalizedDescriptionKey: "Sync error"])
        let mockClient = MockInfopostsClient(setPostReadResult: .failure(syncError))
        let service = createService(mockClient: mockClient)

        let modelContainer = try ModelContainer(for: User.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let modelContext = modelContainer.mainContext

        let user = createTestUser(modelContext: modelContext)
        try modelContext.save()

        // Act
        try await service.markPostAsRead(day: 5, modelContext: modelContext)

        // Assert
        #expect(!user.readInfopostDays.contains(5))
        #expect(user.unsyncedReadInfopostDays.contains(5))
    }

    @Test
    @MainActor
    func markPostAsReadWithNilDay() async throws {
        // Arrange
        let mockClient = MockInfopostsClient()
        let service = createService(mockClient: mockClient)

        let modelContainer = try ModelContainer(for: User.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let modelContext = modelContainer.mainContext

        let user = createTestUser(modelContext: modelContext)
        try modelContext.save()

        // Act
        try await service.markPostAsRead(day: nil, modelContext: modelContext)

        // Assert
        #expect(user.readInfopostDays.isEmpty)
        #expect(user.unsyncedReadInfopostDays.isEmpty)
    }

    @Test
    @MainActor
    func markPostAsReadWhenUserNotFound() async throws {
        // Arrange
        let mockClient = MockInfopostsClient()
        let service = createService(mockClient: mockClient)

        let modelContainer = try ModelContainer(for: User.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let modelContext = modelContainer.mainContext

        // Act & Assert
        await #expect(throws: InfopostsServiceError.userNotFound) {
            try await service.markPostAsRead(day: 5, modelContext: modelContext)
        }
    }

    @Test
    @MainActor
    func markPostAsReadDuplicateDay() async throws {
        // Arrange
        let mockClient = MockInfopostsClient(setPostReadResult: .success(()))
        let service = createService(mockClient: mockClient)

        let modelContainer = try ModelContainer(for: User.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let modelContext = modelContainer.mainContext

        let user = createTestUser(
            modelContext: modelContext,
            unsyncedDays: [5]
        )
        try modelContext.save()

        // Act
        try await service.markPostAsRead(day: 5, modelContext: modelContext)

        // Assert
        #expect(user.readInfopostDays.contains(5))
        #expect(!user.unsyncedReadInfopostDays.contains(5))
        #expect(user.unsyncedReadInfopostDays.count == 0)
    }

    // MARK: - Тесты проверки статуса прочитанного

    @Test
    @MainActor
    func isPostReadWhenRead() throws {
        // Arrange
        let mockClient = MockInfopostsClient()
        let service = createService(mockClient: mockClient)

        let modelContainer = try ModelContainer(for: User.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let modelContext = modelContainer.mainContext

        _ = createTestUser(
            modelContext: modelContext,
            readDays: [1, 2, 3]
        )
        try modelContext.save()

        // Act & Assert
        let isRead1 = try service.isPostRead(day: 1, modelContext: modelContext)
        #expect(isRead1)

        let isRead2 = try service.isPostRead(day: 2, modelContext: modelContext)
        #expect(isRead2)

        let isRead3 = try service.isPostRead(day: 3, modelContext: modelContext)
        #expect(isRead3)
    }

    @Test
    @MainActor
    func isPostReadWhenUnsynced() throws {
        // Arrange
        let mockClient = MockInfopostsClient()
        let service = createService(mockClient: mockClient)

        let modelContainer = try ModelContainer(for: User.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let modelContext = modelContainer.mainContext

        _ = createTestUser(
            modelContext: modelContext,
            unsyncedDays: [4, 5, 6]
        )
        try modelContext.save()

        // Act & Assert
        let isRead4 = try service.isPostRead(day: 4, modelContext: modelContext)
        #expect(isRead4)

        let isRead5 = try service.isPostRead(day: 5, modelContext: modelContext)
        #expect(isRead5)

        let isRead6 = try service.isPostRead(day: 6, modelContext: modelContext)
        #expect(isRead6)
    }

    @Test
    @MainActor
    func isPostReadWhenNotRead() throws {
        // Arrange
        let mockClient = MockInfopostsClient()
        let service = createService(mockClient: mockClient)

        let modelContainer = try ModelContainer(for: User.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let modelContext = modelContainer.mainContext

        _ = createTestUser(
            modelContext: modelContext,
            readDays: [1, 2],
            unsyncedDays: [3, 4]
        )
        try modelContext.save()

        // Act & Assert
        let isRead5 = try service.isPostRead(day: 5, modelContext: modelContext)
        #expect(!isRead5)

        let isRead6 = try service.isPostRead(day: 6, modelContext: modelContext)
        #expect(!isRead6)
    }

    @Test
    @MainActor
    func isPostReadWhenUserNotFound() throws {
        // Arrange
        let mockClient = MockInfopostsClient()
        let service = createService(mockClient: mockClient)

        let modelContainer = try ModelContainer(for: User.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let modelContext = modelContainer.mainContext

        // Act
        let isRead = try service.isPostRead(day: 1, modelContext: modelContext)

        // Assert
        #expect(!isRead)
    }

    // MARK: - Тесты обработки ошибок синхронизации

    @Test
    @MainActor
    func syncReadPostsWithPartialSyncFailure() async throws {
        // Arrange
        let serverReadDays = [1, 2, 3]
        let mockClient = MockInfopostsClient(getReadPostsResult: .success(serverReadDays))
        let service = createService(mockClient: mockClient)

        let modelContainer = try ModelContainer(for: User.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let modelContext = modelContainer.mainContext

        let user = createTestUser(
            modelContext: modelContext,
            readDays: [1],
            unsyncedDays: [4, 5, 6]
        )
        try modelContext.save()

        // Act
        try await service.syncReadPosts(modelContext: modelContext)

        // Assert
        #expect(user.readInfopostDays == serverReadDays)
        #expect(user.unsyncedReadInfopostDays.isEmpty)
    }

    @Test
    @MainActor
    func markPostAsReadWithNetworkError() async throws {
        // Arrange
        let networkError = NSError(domain: "NetworkError", code: -1009, userInfo: [NSLocalizedDescriptionKey: "No internet connection"])
        let mockClient = MockInfopostsClient(setPostReadResult: .failure(networkError))
        let service = createService(mockClient: mockClient)

        let modelContainer = try ModelContainer(for: User.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let modelContext = modelContainer.mainContext

        let user = createTestUser(modelContext: modelContext)
        try modelContext.save()

        // Act
        try await service.markPostAsRead(day: 10, modelContext: modelContext)

        // Assert
        #expect(!user.readInfopostDays.contains(10))
        #expect(user.unsyncedReadInfopostDays.contains(10))
    }

    // MARK: - Тесты граничных случаев

    @Test
    @MainActor
    func syncReadPostsWithLargeDataSet() async throws {
        // Arrange
        let serverReadDays = Array(1 ... 100)
        let mockClient = MockInfopostsClient(getReadPostsResult: .success(serverReadDays))
        let service = createService(mockClient: mockClient)

        let modelContainer = try ModelContainer(for: User.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let modelContext = modelContainer.mainContext

        let user = createTestUser(
            modelContext: modelContext,
            readDays: [1, 2, 3],
            unsyncedDays: [101, 102, 103]
        )
        try modelContext.save()

        // Act
        try await service.syncReadPosts(modelContext: modelContext)

        // Assert
        #expect(user.readInfopostDays == serverReadDays)
        #expect(user.unsyncedReadInfopostDays.isEmpty)
    }

    @Test
    @MainActor
    func markPostAsReadWithZeroDay() async throws {
        // Arrange
        let mockClient = MockInfopostsClient(setPostReadResult: .success(()))
        let service = createService(mockClient: mockClient)

        let modelContainer = try ModelContainer(for: User.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let modelContext = modelContainer.mainContext

        let user = createTestUser(modelContext: modelContext)
        try modelContext.save()

        // Act
        try await service.markPostAsRead(day: 0, modelContext: modelContext)

        // Assert
        #expect(user.readInfopostDays.contains(0))
        #expect(!user.unsyncedReadInfopostDays.contains(0))
    }

    @Test
    @MainActor
    func markPostAsReadWithNegativeDay() async throws {
        // Arrange
        let mockClient = MockInfopostsClient(setPostReadResult: .success(()))
        let service = createService(mockClient: mockClient)

        let modelContainer = try ModelContainer(for: User.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let modelContext = modelContainer.mainContext

        let user = createTestUser(modelContext: modelContext)
        try modelContext.save()

        // Act
        try await service.markPostAsRead(day: -1, modelContext: modelContext)

        // Assert
        #expect(user.readInfopostDays.contains(-1))
        #expect(!user.unsyncedReadInfopostDays.contains(-1))
    }
}
