import Foundation
import SwiftData
@testable import SwiftUI_SotkaApp
import SWUtils
import Testing
import UIKit

@MainActor
struct ProgressSyncServicePhotoTests {
    // MARK: - Test Data

    private var testImageData: Data {
        let testImage = UIImage(systemName: "photo") ?? UIImage()
        return testImage.pngData() ?? Data()
    }

    // MARK: - Mock Client

    private final class MockProgressClient: ProgressClient, @unchecked Sendable {
        var mockedProgressResponses: [ProgressResponse]
        var shouldThrowError = false
        var errorToThrow: Error = NSError(domain: "TestError", code: 1, userInfo: nil)

        init(mockedProgressResponses: [ProgressResponse] = []) {
            self.mockedProgressResponses = mockedProgressResponses
        }

        func getProgress() async throws -> [ProgressResponse] {
            if shouldThrowError {
                throw errorToThrow
            }
            return mockedProgressResponses
        }

        func createProgress(progress: ProgressRequest) async throws -> ProgressResponse {
            if shouldThrowError {
                throw errorToThrow
            }
            return mockedProgressResponses.first ?? ProgressResponse(
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
            return mockedProgressResponses.first ?? ProgressResponse(
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
            return mockedProgressResponses.first ?? ProgressResponse(
                id: day,
                pullups: 10,
                pushups: 20,
                squats: 30,
                weight: 70.0,
                createDate: DateFormatterService.stringFromFullDate(Date(), format: .serverDateTimeSec),
                modifyDate: DateFormatterService.stringFromFullDate(Date(), format: .serverDateTimeSec)
            )
        }
    }

    // MARK: - Progress Model Photo Tests

    @Test("Создание прогресса из ответа сервера с фотографиями")
    func createProgressFromServerResponseWithPhotos() {
        let user = User(id: 1, userName: "test", email: "test@test.com", cityID: nil)

        let serverResponse = ProgressResponse(
            id: 1,
            pullups: 10,
            pushups: 20,
            squats: 30,
            weight: 70.0,
            createDate: DateFormatterService.stringFromFullDate(Date(), format: .serverDateTimeSec),
            modifyDate: DateFormatterService.stringFromFullDate(Date(), format: .serverDateTimeSec),
            photoFront: "https://example.com/photo_front.jpg",
            photoBack: "https://example.com/photo_back.jpg",
            photoSide: "https://example.com/photo_side.jpg"
        )

        let progress = Progress(from: serverResponse, user: user)

        #expect(progress.urlPhotoFront == "https://example.com/photo_front.jpg")
        #expect(progress.urlPhotoBack == "https://example.com/photo_back.jpg")
        #expect(progress.urlPhotoSide == "https://example.com/photo_side.jpg")
        #expect(progress.isSynced)
    }

    @Test("Создание прогресса из ответа сервера с одной фотографией")
    func createProgressFromServerResponseWithSinglePhoto() {
        let user = User(id: 1, userName: "test", email: "test@test.com", cityID: nil)

        let serverResponse = ProgressResponse(
            id: 1,
            pullups: 10,
            pushups: 20,
            squats: 30,
            weight: 70.0,
            createDate: DateFormatterService.stringFromFullDate(Date(), format: .serverDateTimeSec),
            modifyDate: DateFormatterService.stringFromFullDate(Date(), format: .serverDateTimeSec),
            photoFront: "https://example.com/photo_front.jpg"
        )

        let progress = Progress(from: serverResponse, user: user)

        #expect(progress.urlPhotoFront == "https://example.com/photo_front.jpg")
        #expect(progress.urlPhotoBack == nil)
        #expect(progress.urlPhotoSide == nil)
        #expect(progress.isSynced)
    }

    @Test("Создание прогресса из ответа сервера без фотографий")
    func createProgressFromServerResponseWithoutPhotos() {
        let user = User(id: 1, userName: "test", email: "test@test.com", cityID: nil)

        let serverResponse = ProgressResponse(
            id: 1,
            pullups: 10,
            pushups: 20,
            squats: 30,
            weight: 70.0,
            createDate: DateFormatterService.stringFromFullDate(Date(), format: .serverDateTimeSec),
            modifyDate: DateFormatterService.stringFromFullDate(Date(), format: .serverDateTimeSec)
        )

        let progress = Progress(from: serverResponse, user: user)

        #expect(progress.urlPhotoFront == nil)
        #expect(progress.urlPhotoBack == nil)
        #expect(progress.urlPhotoSide == nil)
        #expect(progress.isSynced)
    }

    @Test("Создание прогресса из ответа сервера с обновлением lastModified")
    func createProgressFromServerResponseUpdatesLastModified() {
        let user = User(id: 1, userName: "test", email: "test@test.com", cityID: nil)
        let originalDate = Date()

        let serverResponse = ProgressResponse(
            id: 1,
            pullups: 10,
            pushups: 20,
            squats: 30,
            weight: 70.0,
            createDate: DateFormatterService.stringFromFullDate(originalDate, format: .serverDateTimeSec),
            modifyDate: DateFormatterService.stringFromFullDate(originalDate, format: .serverDateTimeSec),
            photoFront: "https://example.com/photo_front.jpg"
        )

        let progress = Progress(from: serverResponse, user: user)

        #expect(progress.lastModified >= originalDate)
        #expect(progress.isSynced)
    }

    // MARK: - Progress Data Tests

    @Test("Проверка работы с локальными данными фотографий")
    func progressPhotoDataHandling() {
        let progress = Progress(id: 1, pullUps: 10, pushUps: 20, squats: 30, weight: 70.0)

        progress.setPhotoData(.front, data: testImageData)
        progress.setPhotoData(.back, data: testImageData)
        progress.setPhotoData(.side, data: testImageData)

        #expect(progress.hasPhotoData(.front))
        #expect(progress.hasPhotoData(.back))
        #expect(progress.hasPhotoData(.side))
        #expect(progress.hasAnyPhotoData)
    }

    // MARK: - Integration Tests

    @Test("Полная интеграция создания прогресса с фотографиями")
    func fullProgressCreationIntegration() {
        let user = User(id: 1, userName: "test", email: "test@test.com", cityID: nil)

        let serverResponse = ProgressResponse(
            id: 1,
            pullups: 10,
            pushups: 20,
            squats: 30,
            weight: 70.0,
            createDate: DateFormatterService.stringFromFullDate(Date(), format: .serverDateTimeSec),
            modifyDate: DateFormatterService.stringFromFullDate(Date(), format: .serverDateTimeSec),
            photoFront: "https://example.com/photo_front.jpg",
            photoBack: "https://example.com/photo_back.jpg",
            photoSide: "https://example.com/photo_side.jpg"
        )

        let progress = Progress(from: serverResponse, user: user)

        #expect(progress.urlPhotoFront == "https://example.com/photo_front.jpg")
        #expect(progress.urlPhotoBack == "https://example.com/photo_back.jpg")
        #expect(progress.urlPhotoSide == "https://example.com/photo_side.jpg")
        #expect(progress.isSynced)
    }

    @Test("Создание прогресса с внутренним днем")
    func createProgressWithInternalDay() {
        let user = User(id: 1, userName: "test", email: "test@test.com", cityID: nil)

        let serverResponse = ProgressResponse(
            id: 1,
            pullups: 10,
            pushups: 20,
            squats: 30,
            weight: 70.0,
            createDate: DateFormatterService.stringFromFullDate(Date(), format: .serverDateTimeSec),
            modifyDate: DateFormatterService.stringFromFullDate(Date(), format: .serverDateTimeSec),
            photoFront: "https://example.com/photo_front.jpg"
        )

        let progress = Progress(from: serverResponse, user: user, internalDay: 100)

        #expect(progress.id == 100)
        #expect(progress.urlPhotoFront == "https://example.com/photo_front.jpg")
        #expect(progress.isSynced)
    }

    @Test("Параметризированный тест создания прогресса", arguments: [1, 49, 100])
    func parameterizedProgressCreation(dayId: Int) {
        let user = User(id: 1, userName: "test", email: "test@test.com", cityID: nil)

        let serverResponse = ProgressResponse(
            id: dayId,
            pullups: 10,
            pushups: 20,
            squats: 30,
            weight: 70.0,
            createDate: DateFormatterService.stringFromFullDate(Date(), format: .serverDateTimeSec),
            modifyDate: DateFormatterService.stringFromFullDate(Date(), format: .serverDateTimeSec),
            photoFront: "https://example.com/photo_front.jpg"
        )

        let progress = Progress(from: serverResponse, user: user)

        #expect(progress.id == dayId)
        #expect(progress.isSynced)
        #expect(progress.urlPhotoFront == "https://example.com/photo_front.jpg")
    }
}
