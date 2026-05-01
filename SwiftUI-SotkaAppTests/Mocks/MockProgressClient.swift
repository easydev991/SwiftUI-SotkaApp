import Foundation
@testable import SwiftUI_SotkaApp
import SWUtils

final class MockProgressClient: ProgressClient, @unchecked Sendable {
    // MARK: - Properties

    /// Список моковых ответов сервера
    var mockedProgressResponses: [ProgressResponse] = []

    /// Флаг для имитации ошибок
    var shouldThrowError = false

    /// Флаг для имитации ошибок только при вызове getProgress()
    var shouldThrowErrorOnGetProgress = false

    /// Кастомная ошибка для выброса
    var errorToThrow: Error = MockProgressClient.MockError.demoError

    /// Специфичные ошибки для deletePhoto
    var deletePhotoError: Error?

    /// Счетчики вызовов методов
    var updateProgressCallCount = 0
    var deletePhotoCallCount = 0
    var getProgressCallCount = 0

    /// Последние параметры deletePhoto
    var lastDeletePhotoDay: Int?
    var lastDeletePhotoType: String?

    /// Массивы для отслеживания всех вызовов
    var deletePhotoCalls: [(day: Int, type: String)] = []
    var updateProgressCalls: [(day: Int, progress: ProgressRequest)] = []

    // MARK: - Initialization

    init(mockedProgressResponses: [ProgressResponse] = []) {
        self.mockedProgressResponses = mockedProgressResponses
    }

    // MARK: - ProgressClient Implementation

    func getProgress() async throws -> [ProgressResponse] {
        getProgressCallCount += 1
        if shouldThrowError || shouldThrowErrorOnGetProgress {
            throw errorToThrow
        }
        return mockedProgressResponses
    }

    func updateProgress(day: Int, progress: ProgressRequest) async throws -> ProgressResponse {
        updateProgressCallCount += 1
        updateProgressCalls.append((day: day, progress: progress))

        if shouldThrowError {
            throw errorToThrow
        }

        // Для update ожидаем детерминированный ответ по дню, чтобы исключить flaky-поведение.
        if let matching = mockedProgressResponses.first(where: { $0.id == day }) {
            return matching
        }

        let response = ProgressResponse(
            id: progress.id,
            pullups: progress.pullups,
            pushups: progress.pushups,
            squats: progress.squats,
            weight: progress.weight,
            createDate: Date(),
            modifyDate: DateFormatterService.dateFromString(progress.modifyDate, format: .serverDateTimeSec),
            photoFront: progress.photos?["photo_front"] != nil ? "https://example.com/front.jpg" : nil,
            photoBack: progress.photos?["photo_back"] != nil ? "https://example.com/back.jpg" : nil,
            photoSide: progress.photos?["photo_side"] != nil ? "https://example.com/side.jpg" : nil
        )
        mockedProgressResponses.append(response)
        return response
    }

    func deleteProgress(day _: Int) async throws {
        if shouldThrowError {
            throw errorToThrow
        }
    }

    func deletePhoto(day: Int, type: String) async throws {
        deletePhotoCallCount += 1
        lastDeletePhotoDay = day
        lastDeletePhotoType = type
        deletePhotoCalls.append((day: day, type: type))

        if shouldThrowError {
            throw errorToThrow
        }
        if let error = deletePhotoError {
            throw error
        }
        // Имитируем успешное удаление фотографии
    }
}

extension MockProgressClient {
    /// Ошибка для тестирования
    enum MockError: Error {
        case demoError
    }
}

extension ProgressSyncService {
    static func makeMock(
        client: ProgressClient = MockProgressClient(),
        photoDownloadService: PhotoDownloadServiceProtocol = MockPhotoDownloadService()
    ) -> ProgressSyncService {
        ProgressSyncService(client: client, photoDownloadService: photoDownloadService)
    }
}
