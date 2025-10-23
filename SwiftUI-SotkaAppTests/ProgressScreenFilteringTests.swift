import SwiftData
import SwiftUI
@testable import SwiftUI_SotkaApp
import SWNetwork
import Testing

/// Тесты для проверки корректной фильтрации данных в ProgressScreen
/// В приложении может быть максимум один пользователь, поэтому тесты проверяют
/// корректную фильтрацию записей с shouldDelete=true и отображение серверных данных
struct ProgressScreenFilteringTests {
    @Test("Должен исключать записи с shouldDelete=true")
    @MainActor
    func progressScreenExcludesDeletedRecords() throws {
        // Arrange
        let container = try ModelContainer(
            for: UserProgress.self,
            User.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = container.mainContext

        // Создаем пользователя
        let user = User(id: 1, userName: "User", email: "user@example.com")
        context.insert(user)

        // Создаем активную запись
        let activeProgress = UserProgress(id: 1, pullUps: 10, pushUps: 20, squats: 30, weight: 70.0)
        activeProgress.user = user
        activeProgress.isSynced = true
        activeProgress.shouldDelete = false
        context.insert(activeProgress)

        // Создаем удаленную запись
        let deletedProgress = UserProgress(id: 2, pullUps: 15, pushUps: 25, squats: 35, weight: 80.0)
        deletedProgress.user = user
        deletedProgress.isSynced = true
        deletedProgress.shouldDelete = true
        context.insert(deletedProgress)

        try context.save()

        // Act
        let filteredProgress = try context.fetch(FetchDescriptor<UserProgress>())
            .filter { (progress: UserProgress) in progress.user?.id == user.id && !progress.shouldDelete }

        // Assert
        #expect(filteredProgress.count == 1)

        let progressItem = try #require(filteredProgress.first)
        #expect(progressItem.id == 1)
        #expect(progressItem.pullUps == 10)
        #expect(progressItem.shouldDelete == false)
    }

    @Test("Должен корректно обрабатывать серверные данные после синхронизации")
    @MainActor
    func progressScreenShowsServerDataAfterSync() async throws {
        // Arrange
        let container = try ModelContainer(
            for: UserProgress.self,
            User.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = container.mainContext

        // Создаем пользователя
        let user = User(id: 10367, userName: "Test User", email: "test@example.com")
        context.insert(user)
        try context.save()

        // Создаем мок клиента с серверными данными
        let mockClient = MockProgressClient()
        let serverResponse = ProgressResponse(
            id: 1,
            pullups: 1,
            pushups: 1,
            squats: 1,
            weight: 10.0,
            createDate: "2025-10-24T10:39:51+03:00",
            modifyDate: "2025-10-24T10:40:08+03:00",
            photoFront: "https://workout.su/uploads/userfiles/2025/10/2025-10-24-10-10-34-vsw.jpg",
            photoBack: "https://workout.su/uploads/userfiles/2025/10/2025-10-24-10-10-34-fbr.jpg"
        )
        mockClient.mockGetProgressResponse = [serverResponse]

        let syncService = ProgressSyncService(client: mockClient)

        // Act
        await syncService.syncProgress(context: context)

        // Assert
        let filteredProgress = try context.fetch(FetchDescriptor<UserProgress>())
            .filter { (progress: UserProgress) in progress.user?.id == user.id && !progress.shouldDelete }

        #expect(filteredProgress.count == 1)

        let progressItem = try #require(filteredProgress.first)
        #expect(progressItem.id == 1)
        #expect(progressItem.pullUps == 1)
        #expect(progressItem.pushUps == 1)
        #expect(progressItem.squats == 1)
        #expect(progressItem.weight == 10.0)
        #expect(progressItem.isSynced == true)
        #expect(progressItem.shouldDelete == false)
        #expect(progressItem.urlPhotoFront == "https://workout.su/uploads/userfiles/2025/10/2025-10-24-10-10-34-vsw.jpg")
        #expect(progressItem.urlPhotoBack == "https://workout.su/uploads/userfiles/2025/10/2025-10-24-10-10-34-fbr.jpg")
    }
}

/// Мок клиент для тестирования
private final class MockProgressClient: @unchecked Sendable, ProgressClient {
    var mockGetProgressResponse: [ProgressResponse] = []
    var mockGetProgressDayResponse: ProgressResponse?
    var mockCreateProgressResponse: ProgressResponse?
    var mockUpdateProgressResponse: ProgressResponse?
    var mockDeleteProgressError: Error?
    var mockDeletePhotoError: Error?

    func getProgress() async throws -> [ProgressResponse] {
        mockGetProgressResponse
    }

    func getProgress(day _: Int) async throws -> ProgressResponse {
        if let response = mockGetProgressDayResponse {
            return response
        }
        throw APIError.unknown
    }

    func createProgress(progress _: ProgressRequest) async throws -> ProgressResponse {
        if let response = mockCreateProgressResponse {
            return response
        }
        throw APIError.unknown
    }

    func updateProgress(day _: Int, progress _: ProgressRequest) async throws -> ProgressResponse {
        if let response = mockUpdateProgressResponse {
            return response
        }
        throw APIError.unknown
    }

    func deleteProgress(day _: Int) async throws {
        if let error = mockDeleteProgressError {
            throw error
        }
    }

    func deletePhoto(day _: Int, type _: String) async throws {
        if let error = mockDeletePhotoError {
            throw error
        }
    }
}
