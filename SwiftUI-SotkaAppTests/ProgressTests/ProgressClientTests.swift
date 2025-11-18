import Foundation
@testable import SwiftUI_SotkaApp
import SWUtils
import Testing

extension AllProgressTests {
    struct ProgressClientTests {
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
            await #expect(throws: MockProgressClient.MockError.self) {
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

        @Test("deletePhoto работает с ProgressPhotoType.requestName")
        func deletePhotoWorksWithPhotoTyperequestName() async throws {
            // Arrange
            let mockClient = MockProgressClient()

            // Act
            try await mockClient.deletePhoto(day: 1, type: ProgressPhotoType.front.requestName)
            try await mockClient.deletePhoto(day: 49, type: ProgressPhotoType.back.requestName)
            try await mockClient.deletePhoto(day: 100, type: ProgressPhotoType.side.requestName)

            // Assert
            #expect(mockClient.deletePhotoCallCount == 3)
        }

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
            mockClient.errorToThrow = MockProgressClient.MockError.demoError

            // Act & Assert
            await #expect(throws: MockProgressClient.MockError.self) {
                try await mockClient.deletePhoto(day: 1, type: "front")
            }
        }

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
}
