import Foundation
import SwiftData
@testable import SwiftUI_SotkaApp
import Testing
import UIKit

struct ProgressPhotoTests {
    // MARK: - Test Data

    private var testImageData: Data {
        // Создаем тестовые данные изображения (1x1 пиксель PNG)
        let testImage = UIImage(systemName: "photo") ?? UIImage()
        return testImage.pngData() ?? Data()
    }

    // MARK: - Photo Creation Tests

    @Test("Создание фото с данными")
    func photoCreationWithData() {
        let photo = ProgressPhoto(type: .front, data: testImageData)

        #expect(photo.type == .front)
        #expect(photo.data != nil)
        #expect(!photo.isSynced)
        #expect(!photo.isDeleted)
    }

    @Test("Создание фото с URL")
    func photoCreationWithURL() {
        let photo = ProgressPhoto(type: .back, urlString: "https://example.com/photo.jpg")

        #expect(photo.type == .back)
        #expect(photo.urlString == "https://example.com/photo.jpg")
        #expect(photo.data == nil)
        #expect(!photo.isSynced)
        #expect(!photo.isDeleted)
    }

    @Test("Создание фото без данных")
    func photoCreationWithoutData() {
        let photo = ProgressPhoto(type: .side)

        #expect(photo.type == .side)
        #expect(photo.data == nil)
        #expect(photo.urlString == nil)
        #expect(!photo.isSynced)
        #expect(!photo.isDeleted)
    }

    // MARK: - PhotoType Tests

    @Test("Локализованные названия типов фотографий", arguments: PhotoType.allCases)
    func photoTypeLocalizedTitles(photoType: PhotoType) {
        let photo = ProgressPhoto(type: photoType, data: testImageData)

        #expect(photo.type == photoType)
        #expect(!photo.type.localizedTitle.isEmpty)
    }

    @Test("Все типы фотографий доступны")
    func allPhotoTypesAvailable() {
        let allTypes = PhotoType.allCases
        #expect(allTypes.count == 3)
        #expect(allTypes.contains(.front))
        #expect(allTypes.contains(.back))
        #expect(allTypes.contains(.side))
    }

    // MARK: - Progress Relationship Tests

    @Test("Связь между прогрессом и фотографиями")
    func progressPhotoRelationship() {
        let progress = Progress(id: 1)
        let photo = ProgressPhoto(type: .front, data: testImageData)
        progress.photos.append(photo)

        #expect(progress.photos.count == 1)
        #expect(progress.getPhoto(.front) == photo)
        #expect(progress.getPhoto(.back) == nil)
    }

    @Test("Множественные фотографии для одного прогресса")
    func multiplePhotosForProgress() {
        let progress = Progress(id: 1)
        let frontPhoto = ProgressPhoto(type: .front, data: testImageData)
        let backPhoto = ProgressPhoto(type: .back, data: testImageData)
        let sidePhoto = ProgressPhoto(type: .side, data: testImageData)

        progress.photos.append(frontPhoto)
        progress.photos.append(backPhoto)
        progress.photos.append(sidePhoto)

        #expect(progress.photos.count == 3)
        #expect(progress.getPhoto(.front) == frontPhoto)
        #expect(progress.getPhoto(.back) == backPhoto)
        #expect(progress.getPhoto(.side) == sidePhoto)
    }

    // MARK: - Progress Photo Methods Tests

    @Test("hasPhotos возвращает true когда есть фотографии")
    func hasPhotosReturnsTrue() {
        let progress = Progress(id: 1)
        let photo = ProgressPhoto(type: .front, data: testImageData)
        progress.photos.append(photo)

        #expect(progress.hasPhotos)
    }

    @Test("hasPhotos возвращает false когда нет фотографий")
    func hasPhotosReturnsFalse() {
        let progress = Progress(id: 1)

        #expect(!progress.hasPhotos)
    }

    @Test("hasPhotos возвращает false когда все фотографии удалены")
    func hasPhotosReturnsFalseWhenAllDeleted() {
        let progress = Progress(id: 1)
        let photo = ProgressPhoto(type: .front, data: testImageData)
        photo.isDeleted = true
        progress.photos.append(photo)

        #expect(!progress.hasPhotos)
    }

    @Test("hasUnsyncedPhotos возвращает true когда есть несинхронизированные фотографии")
    func hasUnsyncedPhotosReturnsTrue() {
        let progress = Progress(id: 1)
        let photo = ProgressPhoto(type: .front, data: testImageData)
        photo.isSynced = false
        progress.photos.append(photo)

        #expect(progress.hasUnsyncedPhotos)
    }

    @Test("hasUnsyncedPhotos возвращает false когда все фотографии синхронизированы")
    func hasUnsyncedPhotosReturnsFalse() {
        let progress = Progress(id: 1)
        let photo = ProgressPhoto(type: .front, data: testImageData)
        photo.isSynced = true
        progress.photos.append(photo)

        #expect(!progress.hasUnsyncedPhotos)
    }

    @Test("hasPhotosToDelete возвращает true когда есть фотографии для удаления")
    func hasPhotosToDeleteReturnsTrue() {
        let progress = Progress(id: 1)
        let photo = ProgressPhoto(type: .front, data: testImageData)
        photo.isDeleted = true
        progress.photos.append(photo)

        #expect(progress.hasPhotosToDelete)
    }

    @Test("hasPhotosToDelete возвращает false когда нет фотографий для удаления")
    func hasPhotosToDeleteReturnsFalse() {
        let progress = Progress(id: 1)
        let photo = ProgressPhoto(type: .front, data: testImageData)
        photo.isDeleted = false
        progress.photos.append(photo)

        #expect(!progress.hasPhotosToDelete)
    }

    // MARK: - setPhoto Tests

    @Test("setPhoto создает новую фотографию")
    func setPhotoCreatesNewPhoto() throws {
        let progress = Progress(id: 1)
        let testData = testImageData

        progress.setPhoto(.front, data: testData)

        #expect(progress.photos.count == 1)
        let photo = try #require(progress.getPhoto(.front))
        #expect(photo.data == testData)
        #expect(photo.type == .front)
        #expect(!photo.isSynced)
    }

    @Test("setPhoto обновляет существующую фотографию")
    func setPhotoUpdatesExistingPhoto() throws {
        let progress = Progress(id: 1)
        let originalData = testImageData
        let newData = Data("new data".utf8)

        progress.setPhoto(.front, data: originalData)
        let originalPhoto = try #require(progress.getPhoto(.front))
        originalPhoto.isSynced = true

        progress.setPhoto(.front, data: newData)

        #expect(progress.photos.count == 1)
        let updatedPhoto = try #require(progress.getPhoto(.front))
        #expect(updatedPhoto.data == newData)
        #expect(updatedPhoto.type == .front)
        #expect(!updatedPhoto.isSynced, "Фотография должна быть помечена как несинхронизированная после обновления")
    }

    // MARK: - deletePhoto Tests

    @Test("deletePhoto помечает фотографию как удаленную")
    func deletePhotoMarksAsDeleted() throws {
        let progress = Progress(id: 1)
        let photo = ProgressPhoto(type: .front, data: testImageData)
        progress.photos.append(photo)

        try progress.deletePhoto(.front)

        #expect(progress.photos.count == 1)
        let deletedPhoto = try #require(progress.photos.first)
        #expect(deletedPhoto.isDeleted)
        #expect(!deletedPhoto.isSynced)
        #expect(progress.getPhoto(.front) == nil)
    }

    @Test("deletePhoto выбрасывает ошибку для несуществующей фотографии")
    func deletePhotoThrowsForNonExistentPhoto() {
        let progress = Progress(id: 1)

        #expect(throws: ProgressError.photoNotFound) {
            try progress.deletePhoto(.front)
        }
    }

    @Test("deletePhoto выбрасывает ошибку для уже удаленной фотографии")
    func deletePhotoThrowsForAlreadyDeletedPhoto() {
        let progress = Progress(id: 1)
        let photo = ProgressPhoto(type: .front, data: testImageData)
        photo.isDeleted = true
        progress.photos.append(photo)

        #expect(throws: ProgressError.photoNotFound) {
            try progress.deletePhoto(.front)
        }
    }
}
