import Foundation
@testable import SwiftUI_SotkaApp
import SWUtils
import Testing

struct ProgressClientTests {
    // MARK: - Mock ProgressClient

    private final class MockProgressClient: ProgressClient, @unchecked Sendable {
        var shouldThrowError = false
        var errorToThrow: Error = NSError(domain: "TestError", code: 1, userInfo: nil)
        var deletePhotoCallCount = 0
        var lastDeletePhotoDay: Int?
        var lastDeletePhotoType: String?

        func getProgress() async throws -> [ProgressResponse] {
            if shouldThrowError {
                throw errorToThrow
            }
            return []
        }

        func createProgress(progress: ProgressRequest) async throws -> ProgressResponse {
            if shouldThrowError {
                throw errorToThrow
            }
            return ProgressResponse(
                id: progress.id,
                pullups: progress.pullups,
                pushups: progress.pushups,
                squats: progress.squats,
                weight: progress.weight,
                createDate: DateFormatterService.stringFromFullDate(Date(), format: .serverDateTimeSec),
                modifyDate: progress.modifyDate
            )
        }

        func updateProgress(day: Int, progress: ProgressRequest) async throws -> ProgressResponse {
            if shouldThrowError {
                throw errorToThrow
            }
            return ProgressResponse(
                id: day,
                pullups: progress.pullups,
                pushups: progress.pushups,
                squats: progress.squats,
                weight: progress.weight,
                createDate: DateFormatterService.stringFromFullDate(Date(), format: .serverDateTimeSec),
                modifyDate: progress.modifyDate
            )
        }

        func deleteProgress(day _: Int) async throws {
            if shouldThrowError {
                throw errorToThrow
            }
        }

        func getProgress(day: Int) async throws -> ProgressResponse {
            if shouldThrowError {
                throw errorToThrow
            }
            return ProgressResponse(
                id: day,
                pullups: 10,
                pushups: 20,
                squats: 30,
                weight: 70.0,
                createDate: DateFormatterService.stringFromFullDate(Date(), format: .serverDateTimeSec),
                modifyDate: DateFormatterService.stringFromFullDate(Date(), format: .serverDateTimeSec)
            )
        }

        func deletePhoto(day: Int, type: String) async throws {
            if shouldThrowError {
                throw errorToThrow
            }
            deletePhotoCallCount += 1
            lastDeletePhotoDay = day
            lastDeletePhotoType = type
        }
    }

    // MARK: - deletePhoto Tests

    @Test("deletePhoto вызывает правильный API endpoint")
    func deletePhotoCallsCorrectAPIEndpoint() async throws {
        // Arrange
        let mockClient = MockProgressClient()

        // Act
        try await mockClient.deletePhoto(day: 1, type: "front")

        // Assert
        #expect(mockClient.deletePhotoCallCount == 1)
        #expect(mockClient.lastDeletePhotoDay == 1)
        #expect(mockClient.lastDeletePhotoType == "front")
    }

    @Test("deletePhoto с разными параметрами")
    func deletePhotoWithDifferentParameters() async throws {
        // Arrange
        let mockClient = MockProgressClient()

        // Act
        try await mockClient.deletePhoto(day: 49, type: "back")
        try await mockClient.deletePhoto(day: 100, type: "side")

        // Assert
        #expect(mockClient.deletePhotoCallCount == 2)
        #expect(mockClient.lastDeletePhotoDay == 100)
        #expect(mockClient.lastDeletePhotoType == "side")
    }

    @Test("deletePhoto выбрасывает ошибку когда shouldThrowError = true")
    func deletePhotoThrowsErrorWhenShouldThrowErrorIsTrue() async {
        // Arrange
        let mockClient = MockProgressClient()
        mockClient.shouldThrowError = true

        // Act & Assert
        await #expect(throws: NSError.self) {
            try await mockClient.deletePhoto(day: 1, type: "front")
        }
    }

    @Test("Параметризированный тест deletePhoto", arguments: [
        (1, "front"),
        (49, "back"),
        (100, "side"),
        (25, "front"),
        (75, "back")
    ])
    func deletePhotoParameterized(day: Int, type: String) async throws {
        // Arrange
        let mockClient = MockProgressClient()

        // Act
        try await mockClient.deletePhoto(day: day, type: type)

        // Assert
        #expect(mockClient.lastDeletePhotoDay == day)
        #expect(mockClient.lastDeletePhotoType == type)
    }

    // MARK: - Integration with PhotoType Tests

    @Test("deletePhoto работает с PhotoType.deleteRequestName")
    func deletePhotoWorksWithPhotoTypeDeleteRequestName() async throws {
        // Arrange
        let mockClient = MockProgressClient()

        // Act
        try await mockClient.deletePhoto(day: 1, type: PhotoType.front.deleteRequestName)
        try await mockClient.deletePhoto(day: 49, type: PhotoType.back.deleteRequestName)
        try await mockClient.deletePhoto(day: 100, type: PhotoType.side.deleteRequestName)

        // Assert
        #expect(mockClient.deletePhotoCallCount == 3)
    }

    // MARK: - Error Handling Tests

    @Test("deletePhoto обрабатывает сетевые ошибки")
    func deletePhotoHandlesNetworkErrors() async {
        // Arrange
        let mockClient = MockProgressClient()
        mockClient.shouldThrowError = true
        mockClient.errorToThrow = URLError(.notConnectedToInternet)

        // Act & Assert
        await #expect(throws: URLError.self) {
            try await mockClient.deletePhoto(day: 1, type: "front")
        }
    }

    @Test("deletePhoto обрабатывает серверные ошибки")
    func deletePhotoHandlesServerErrors() async {
        // Arrange
        let mockClient = MockProgressClient()
        mockClient.shouldThrowError = true
        mockClient.errorToThrow = NSError(domain: "ServerError", code: 500, userInfo: [NSLocalizedDescriptionKey: "Internal Server Error"])

        // Act & Assert
        await #expect(throws: NSError.self) {
            try await mockClient.deletePhoto(day: 1, type: "front")
        }
    }

    // MARK: - Call Count Tests

    @Test("deletePhoto увеличивает счетчик вызовов")
    func deletePhotoIncrementsCallCount() async throws {
        // Arrange
        let mockClient = MockProgressClient()

        // Act
        try await mockClient.deletePhoto(day: 1, type: "front")
        try await mockClient.deletePhoto(day: 2, type: "back")
        try await mockClient.deletePhoto(day: 3, type: "side")

        // Assert
        #expect(mockClient.deletePhotoCallCount == 3)
    }

    @Test("deletePhoto сохраняет последние параметры")
    func deletePhotoSavesLastParameters() async throws {
        // Arrange
        let mockClient = MockProgressClient()

        // Act
        try await mockClient.deletePhoto(day: 10, type: "front")
        try await mockClient.deletePhoto(day: 20, type: "back")

        // Assert
        #expect(mockClient.lastDeletePhotoDay == 20)
        #expect(mockClient.lastDeletePhotoType == "back")
    }
}
