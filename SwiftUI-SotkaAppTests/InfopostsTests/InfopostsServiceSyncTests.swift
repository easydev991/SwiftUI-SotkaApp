import Foundation
import SwiftData
@testable import SwiftUI_SotkaApp
import Testing

extension AllInfopostsTests {
    struct InfopostsServiceSyncTests {
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
            let unsyncedDays = [4, 6]
            let mockClient = MockInfopostsClient(getReadPostsResult: .success(serverReadDays))
            let service = createService(mockClient: mockClient)

            let modelContainer = try ModelContainer(for: User.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
            let modelContext = modelContainer.mainContext

            let user = createTestUser(
                modelContext: modelContext,
                readDays: [1, 2],
                unsyncedDays: unsyncedDays
            )
            try modelContext.save()

            // Act
            try await service.syncReadPosts(modelContext: modelContext)

            // Assert
            let expectedReadDays = Set(serverReadDays).union(Set(unsyncedDays)).sorted()
            #expect(
                Set(user.readInfopostDays) == Set(expectedReadDays),
                "user.readInfopostDays должен содержать объединение серверных данных и успешно синхронизированных локальных данных"
            )
            #expect(user.unsyncedReadInfopostDays.isEmpty, "unsyncedReadInfopostDays должен быть пустым после успешной синхронизации")
        }

        @Test
        @MainActor
        func syncReadPostsWithEmptyServerData() async throws {
            // Arrange
            let unsyncedDays = [3, 4]
            let mockClient = MockInfopostsClient(getReadPostsResult: .success([]))
            let service = createService(mockClient: mockClient)

            let modelContainer = try ModelContainer(for: User.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
            let modelContext = modelContainer.mainContext

            let user = createTestUser(
                modelContext: modelContext,
                readDays: [1, 2],
                unsyncedDays: unsyncedDays
            )
            try modelContext.save()

            // Act
            try await service.syncReadPosts(modelContext: modelContext)

            // Assert
            #expect(
                Set(user.readInfopostDays) == Set(unsyncedDays),
                "При пустых серверных данных, user.readInfopostDays должен содержать только успешно синхронизированные локальные данные"
            )
            #expect(user.unsyncedReadInfopostDays.isEmpty, "unsyncedReadInfopostDays должен быть пустым после успешной синхронизации")
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
            await #expect(throws: InfopostsService.ServiceError.userNotFound) {
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
            #expect(user.readInfopostDays.isEmpty, "readInfopostDays должен быть пустым при nil дне")
            #expect(user.unsyncedReadInfopostDays.isEmpty, "unsyncedReadInfopostDays должен быть пустым при nil дне")
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
            await #expect(throws: InfopostsService.ServiceError.userNotFound) {
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
            #expect(user.readInfopostDays.contains(5), "readInfopostDays должен содержать день 5 после успешной синхронизации")
            #expect(
                !user.unsyncedReadInfopostDays.contains(5),
                "unsyncedReadInfopostDays не должен содержать день 5 после успешной синхронизации"
            )
            #expect(user.unsyncedReadInfopostDays.count == 0, "unsyncedReadInfopostDays должен быть пустым после успешной синхронизации")
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

            // Создаем тестовые инфопосты
            let infopost1 = Infopost(filename: "d1", title: "Test 1", content: "Content 1", language: "ru")
            let infopost2 = Infopost(filename: "d2", title: "Test 2", content: "Content 2", language: "ru")
            let infopost3 = Infopost(filename: "d3", title: "Test 3", content: "Content 3", language: "ru")

            // Act & Assert
            let isRead1 = try service.isPostRead(infopost1, modelContext: modelContext)
            #expect(isRead1, "День 1 должен быть отмечен как прочитанный")

            let isRead2 = try service.isPostRead(infopost2, modelContext: modelContext)
            #expect(isRead2, "День 2 должен быть отмечен как прочитанный")

            let isRead3 = try service.isPostRead(infopost3, modelContext: modelContext)
            #expect(isRead3, "День 3 должен быть отмечен как прочитанный")
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

            // Создаем тестовые инфопосты
            let infopost4 = Infopost(filename: "d4", title: "Test 4", content: "Content 4", language: "ru")
            let infopost5 = Infopost(filename: "d5", title: "Test 5", content: "Content 5", language: "ru")
            let infopost6 = Infopost(filename: "d6", title: "Test 6", content: "Content 6", language: "ru")

            // Act & Assert
            let isRead4 = try service.isPostRead(infopost4, modelContext: modelContext)
            #expect(isRead4, "День 4 должен быть отмечен как прочитанный (несинхронизированный)")

            let isRead5 = try service.isPostRead(infopost5, modelContext: modelContext)
            #expect(isRead5, "День 5 должен быть отмечен как прочитанный (несинхронизированный)")

            let isRead6 = try service.isPostRead(infopost6, modelContext: modelContext)
            #expect(isRead6, "День 6 должен быть отмечен как прочитанный (несинхронизированный)")
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

            // Создаем тестовые инфопосты
            let infopost5 = Infopost(filename: "d5", title: "Test 5", content: "Content 5", language: "ru")
            let infopost6 = Infopost(filename: "d6", title: "Test 6", content: "Content 6", language: "ru")

            // Act & Assert
            let isRead5 = try service.isPostRead(infopost5, modelContext: modelContext)
            #expect(!isRead5, "День 5 не должен быть отмечен как прочитанный")

            let isRead6 = try service.isPostRead(infopost6, modelContext: modelContext)
            #expect(!isRead6, "День 6 не должен быть отмечен как прочитанный")
        }

        @Test
        @MainActor
        func isPostReadWhenUserNotFound() throws {
            // Arrange
            let mockClient = MockInfopostsClient()
            let service = createService(mockClient: mockClient)

            let modelContainer = try ModelContainer(for: User.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
            let modelContext = modelContainer.mainContext

            // Создаем тестовый инфопост
            let infopost1 = Infopost(filename: "d1", title: "Test 1", content: "Content 1", language: "ru")

            // Act
            let isRead = try service.isPostRead(infopost1, modelContext: modelContext)

            // Assert
            #expect(!isRead, "День 1 не должен быть отмечен как прочитанный, когда пользователь не найден")
        }

        @Test
        @MainActor
        func isPostReadWhenInfopostHasNoDayNumber() throws {
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

            // Создаем инфопост без номера дня (например, "about")
            let infopost = Infopost(
                id: "about",
                title: "About",
                content: "About content",
                section: .preparation,
                language: "ru",
                isFavoriteAvailable: false
            )

            // Act & Assert
            #expect(throws: InfopostsService.ServiceError.infopostCannotBeMarkedAsRead) {
                try service.isPostRead(infopost, modelContext: modelContext)
            }
        }

        // MARK: - Тесты обработки ошибок синхронизации

        @Test
        @MainActor
        func syncReadPostsWithPartialSyncFailure() async throws {
            // Arrange
            let serverReadDays = [1, 2, 3]
            let unsyncedDays = [4, 5, 6]
            let syncError = NSError(domain: "TestError", code: 500, userInfo: [NSLocalizedDescriptionKey: "Sync error"])

            // День 4 синхронизируется успешно, день 5 падает с ошибкой, день 6 синхронизируется успешно
            let setPostReadResultsByDay: [Int: Result<Void, Error>] = [
                4: .success(()),
                5: .failure(syncError),
                6: .success(())
            ]

            let mockClient = MockInfopostsClient(
                getReadPostsResult: .success(serverReadDays),
                setPostReadResultsByDay: setPostReadResultsByDay
            )
            let service = createService(mockClient: mockClient)

            let modelContainer = try ModelContainer(for: User.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
            let modelContext = modelContainer.mainContext

            let user = createTestUser(
                modelContext: modelContext,
                readDays: [1],
                unsyncedDays: unsyncedDays
            )
            try modelContext.save()

            // Act
            try await service.syncReadPosts(modelContext: modelContext)

            // Assert
            // user.readInfopostDays должен содержать серверные данные + успешно синхронизированные дни (4 и 6)
            let successfullySyncedDays = [4, 6] // Дни, которые синхронизировались успешно
            let expectedReadDays = Set(serverReadDays).union(Set(successfullySyncedDays)).sorted()
            #expect(
                Set(user.readInfopostDays) == Set(expectedReadDays),
                "user.readInfopostDays должен содержать объединение серверных данных и успешно синхронизированных локальных данных"
            )

            // unsyncedReadInfopostDays должен содержать только день 5, который не удалось синхронизировать
            #expect(
                user.unsyncedReadInfopostDays == [5],
                "unsyncedReadInfopostDays должен содержать только дни, которые не удалось синхронизировать"
            )
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
            let unsyncedDays = [101, 102, 103]
            let mockClient = MockInfopostsClient(getReadPostsResult: .success(serverReadDays))
            let service = createService(mockClient: mockClient)

            let modelContainer = try ModelContainer(for: User.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
            let modelContext = modelContainer.mainContext

            let user = createTestUser(
                modelContext: modelContext,
                readDays: [1, 2, 3],
                unsyncedDays: unsyncedDays
            )
            try modelContext.save()

            // Act
            try await service.syncReadPosts(modelContext: modelContext)

            // Assert
            let expectedReadDays = Set(serverReadDays).union(Set(unsyncedDays)).sorted()
            #expect(
                Set(user.readInfopostDays) == Set(expectedReadDays),
                "user.readInfopostDays должен содержать объединение серверных данных и успешно синхронизированных локальных данных"
            )
            #expect(user.unsyncedReadInfopostDays.isEmpty, "unsyncedReadInfopostDays должен быть пустым после успешной синхронизации")
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
}
