import Foundation
import SwiftData
@testable import SwiftUI_SotkaApp
import Testing

@MainActor
struct PhotoDownloadServiceTests {
    private typealias PhotoType = ProgressPhotoType
    private typealias ProgressSUT = UserProgress

    // MARK: - PhotoDownloadService Tests

    @Test("Проверка начального состояния модели UserProgress")
    func initialProgressState() {
        let progress = ProgressSUT(id: 1, pullUps: 10, pushUps: 20, squats: 30, weight: 70.0)

        #expect(progress.urlPhotoFront == nil)
        #expect(progress.getPhotoData(.front) == nil)
        #expect(progress.getPhotoData(.back) == nil)
        #expect(progress.getPhotoData(.side) == nil)
    }

    @Test("Автоматическая загрузка всех фото не должна падать")
    func downloadAllPhotosDoesNotCrash() async {
        let progress = ProgressSUT(id: 1, pullUps: 10, pushUps: 20, squats: 30, weight: 70.0)
        progress.urlPhotoFront = "https://example.com/front.jpg"
        progress.urlPhotoBack = "https://example.com/back.jpg"
        progress.urlPhotoSide = "https://example.com/side.jpg"
        let service = PhotoDownloadService()

        await service.downloadAllPhotos(for: progress)

        #expect(progress.urlPhotoFront != nil)
        #expect(progress.urlPhotoBack != nil)
        #expect(progress.urlPhotoSide != nil)
    }

    @Test("Создание detached task для загрузки фото")
    func detachedTaskCreation() async {
        let progress = ProgressSUT(id: 1, pullUps: 10, pushUps: 20, squats: 30, weight: 70.0)
        progress.urlPhotoFront = "https://example.com/front.jpg"
        progress.urlPhotoBack = "https://example.com/back.jpg"
        progress.urlPhotoSide = "https://example.com/side.jpg"

        let task = Task {
            await PhotoDownloadService().downloadAllPhotos(for: progress)
        }

        await task.value

        #expect(progress.urlPhotoFront != nil)
        #expect(progress.urlPhotoBack != nil)
        #expect(progress.urlPhotoSide != nil)
    }

    @Test("Проверка методов hasPhoto и getPhotoURL")
    func photoURLMethods() {
        let progress = ProgressSUT(id: 1, pullUps: 10, pushUps: 20, squats: 30, weight: 70.0)

        #expect(!progress.hasPhoto(.front))
        #expect(!progress.hasPhoto(.back))
        #expect(!progress.hasPhoto(.side))
        #expect(progress.getPhotoURL(.front) == nil)
        #expect(progress.getPhotoURL(.back) == nil)
        #expect(progress.getPhotoURL(.side) == nil)

        progress.urlPhotoFront = "https://example.com/front.jpg"
        progress.urlPhotoBack = "https://example.com/back.jpg"
        progress.urlPhotoSide = "https://example.com/side.jpg"

        #expect(progress.hasPhoto(.front))
        #expect(progress.hasPhoto(.back))
        #expect(progress.hasPhoto(.side))
        #expect(progress.getPhotoURL(.front) == "https://example.com/front.jpg")
        #expect(progress.getPhotoURL(.back) == "https://example.com/back.jpg")
        #expect(progress.getPhotoURL(.side) == "https://example.com/side.jpg")
    }
}
