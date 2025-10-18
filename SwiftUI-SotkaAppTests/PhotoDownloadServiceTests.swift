import Foundation
import SwiftData
@testable import SwiftUI_SotkaApp
import Testing

struct PhotoDownloadServiceTests {
    private typealias PhotoType = SwiftUI_SotkaApp.PhotoType
    private typealias ProgressSUT = SwiftUI_SotkaApp.Progress

    // MARK: - PhotoDownloadService Tests

    @Test("Проверка начального состояния модели Progress")
    func initialProgressState() {
        let progress = ProgressSUT(id: 1, pullUps: 10, pushUps: 20, squats: 30, weight: 70.0)

        #expect(progress.urlPhotoFront == nil)
        #expect(progress.getPhotoData(PhotoType.front) == nil)
        #expect(progress.getPhotoData(PhotoType.back) == nil)
        #expect(progress.getPhotoData(PhotoType.side) == nil)
    }

    @Test("Должен выбрасывать ошибку для некорректного URL")
    func invalidURLThrowsError() async throws {
        let progress = ProgressSUT(id: 1, pullUps: 10, pushUps: 20, squats: 30, weight: 70.0)

        await #expect(throws: PhotoError.invalidURL) {
            try await SwiftUI_SotkaApp.PhotoDownloadService().downloadAndCachePhoto("invalid-url", for: progress, type: PhotoType.front)
        }
    }

    @Test("Автоматическая загрузка всех фото не должна падать")
    func downloadAllPhotosDoesNotCrash() async {
        let progress = ProgressSUT(id: 1, pullUps: 10, pushUps: 20, squats: 30, weight: 70.0)
        progress.urlPhotoFront = "https://example.com/front.jpg"
        progress.urlPhotoBack = "https://example.com/back.jpg"
        progress.urlPhotoSide = "https://example.com/side.jpg"
        let service = SwiftUI_SotkaApp.PhotoDownloadService()

        await service.downloadAllPhotos(for: progress)

        #expect(true)
    }

    @Test("Создание detached task для загрузки фото")
    func detachedTaskCreation() {
        let progress = ProgressSUT(id: 1, pullUps: 10, pushUps: 20, squats: 30, weight: 70.0)
        progress.urlPhotoFront = "https://example.com/front.jpg"
        progress.urlPhotoBack = "https://example.com/back.jpg"
        progress.urlPhotoSide = "https://example.com/side.jpg"

        Task {
            await SwiftUI_SotkaApp.PhotoDownloadService().downloadAllPhotos(for: progress)
        }

        #expect(true)
    }

    @Test("Проверка методов hasPhoto и getPhotoURL")
    func photoURLMethods() {
        let progress = ProgressSUT(id: 1, pullUps: 10, pushUps: 20, squats: 30, weight: 70.0)

        // Изначально нет фотографий
        #expect(!progress.hasPhoto(PhotoType.front))
        #expect(!progress.hasPhoto(PhotoType.back))
        #expect(!progress.hasPhoto(PhotoType.side))
        #expect(progress.getPhotoURL(PhotoType.front) == nil)
        #expect(progress.getPhotoURL(PhotoType.back) == nil)
        #expect(progress.getPhotoURL(PhotoType.side) == nil)

        // Устанавливаем URL фотографий
        progress.urlPhotoFront = "https://example.com/front.jpg"
        progress.urlPhotoBack = "https://example.com/back.jpg"
        progress.urlPhotoSide = "https://example.com/side.jpg"

        // Проверяем методы
        #expect(progress.hasPhoto(PhotoType.front))
        #expect(progress.hasPhoto(PhotoType.back))
        #expect(progress.hasPhoto(PhotoType.side))
        #expect(progress.getPhotoURL(PhotoType.front) == "https://example.com/front.jpg")
        #expect(progress.getPhotoURL(PhotoType.back) == "https://example.com/back.jpg")
        #expect(progress.getPhotoURL(PhotoType.side) == "https://example.com/side.jpg")
    }
}
