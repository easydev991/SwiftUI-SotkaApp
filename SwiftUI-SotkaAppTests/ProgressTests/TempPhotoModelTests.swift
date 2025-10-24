import Foundation
@testable import SwiftUI_SotkaApp
import Testing

extension AllProgressTests {
    struct TempPhotoModelTests {
        @Test("Инициализация с обычными данными")
        func initWithNormalData() {
            let testData = Data("test image data".utf8)
            let model = TempPhotoModel(
                type: .front,
                urlString: "https://example.com/photo.jpg",
                data: testData
            )

            #expect(model.id == "front")
            #expect(model.type == .front)
            #expect(model.urlString == "https://example.com/photo.jpg")
            #expect(model.data == testData)
            #expect(model.canBeDeleted)
            #expect(!model.isMarkedForDeletion)
        }

        @Test("Инициализация с nil данными")
        func initWithNilData() {
            let model = TempPhotoModel(
                type: .back,
                urlString: nil,
                data: nil
            )

            #expect(model.id == "back")
            #expect(model.type == .back)
            #expect(model.urlString == nil)
            #expect(model.data == nil)
            #expect(!model.canBeDeleted)
            #expect(!model.isMarkedForDeletion)
        }

        @Test("Инициализация с данными для удаления")
        func initWithDeletedData() {
            let model = TempPhotoModel(
                type: .side,
                urlString: "https://example.com/photo.jpg",
                data: UserProgress.DELETED_DATA
            )

            #expect(model.id == "side")
            #expect(model.type == .side)
            #expect(model.urlString == nil)
            #expect(model.data == UserProgress.DELETED_DATA)
            #expect(!model.canBeDeleted)
            #expect(model.isMarkedForDeletion)
        }

        @Test("Инициализация только с URL без данных")
        func initWithOnlyURL() {
            let model = TempPhotoModel(
                type: .front,
                urlString: "https://example.com/photo.jpg",
                data: nil
            )

            #expect(model.id == "front")
            #expect(model.type == .front)
            #expect(model.urlString == "https://example.com/photo.jpg")
            #expect(model.data == nil)
            #expect(model.canBeDeleted)
            #expect(!model.isMarkedForDeletion)
        }

        @Test("Инициализация только с данными без URL")
        func initWithOnlyData() {
            let testData = Data("test image data".utf8)
            let model = TempPhotoModel(
                type: .back,
                urlString: nil,
                data: testData
            )

            #expect(model.id == "back")
            #expect(model.type == .back)
            #expect(model.urlString == nil)
            #expect(model.data == testData)
            #expect(model.canBeDeleted)
            #expect(!model.isMarkedForDeletion)
        }

        @Test("Параметризированный тест инициализации для всех типов фотографий", arguments: [
            ProgressPhotoType.front,
            ProgressPhotoType.back,
            ProgressPhotoType.side
        ])
        func initWithAllPhotoTypes(photoType: ProgressPhotoType) {
            let testData = Data("test image data".utf8)
            let model = TempPhotoModel(
                type: photoType,
                urlString: "https://example.com/photo.jpg",
                data: testData
            )

            #expect(model.id == photoType.requestName)
            #expect(model.type == photoType)
            #expect(model.urlString == "https://example.com/photo.jpg")
            #expect(model.data == testData)
            #expect(model.canBeDeleted)
            #expect(!model.isMarkedForDeletion)
        }

        @Test("Параметризированный тест canBeDeleted для разных сценариев", arguments: [
            (true, "https://example.com/photo.jpg", Data("test".utf8)),
            (true, "https://example.com/photo.jpg", nil),
            (true, nil, Data("test".utf8)),
            (false, nil, nil),
            (false, "https://example.com/photo.jpg", UserProgress.DELETED_DATA),
            (false, nil, UserProgress.DELETED_DATA)
        ])
        func canBeDeletedParameterized(expectedCanBeDeleted: Bool, urlString: String?, data: Data?) {
            let model = TempPhotoModel(
                type: .front,
                urlString: urlString,
                data: data
            )

            #expect(model.canBeDeleted == expectedCanBeDeleted)
        }

        @Test("Параметризированный тест isMarkedForDeletion", arguments: [
            (true, UserProgress.DELETED_DATA),
            (false, Data("test".utf8)),
            (false, nil)
        ])
        func isMarkedForDeletionParameterized(expectedIsMarked: Bool, data: Data?) {
            let model = TempPhotoModel(
                type: .front,
                urlString: "https://example.com/photo.jpg",
                data: data
            )

            #expect(model.isMarkedForDeletion == expectedIsMarked)
        }

        @Test("Проверка Equatable протокола - одинаковые модели")
        func equatableSameModels() {
            let testData = Data("test image data".utf8)
            let model1 = TempPhotoModel(
                type: .front,
                urlString: "https://example.com/photo.jpg",
                data: testData
            )
            let model2 = TempPhotoModel(
                type: .front,
                urlString: "https://example.com/photo.jpg",
                data: testData
            )

            #expect(model1 == model2)
        }

        @Test("Проверка Equatable протокола - разные типы")
        func equatableDifferentTypes() {
            let testData = Data("test image data".utf8)
            let model1 = TempPhotoModel(
                type: .front,
                urlString: "https://example.com/photo.jpg",
                data: testData
            )
            let model2 = TempPhotoModel(
                type: .back,
                urlString: "https://example.com/photo.jpg",
                data: testData
            )

            #expect(model1 != model2)
        }

        @Test("Проверка Equatable протокола - разные URL")
        func equatableDifferentURLs() {
            let testData = Data("test image data".utf8)
            let model1 = TempPhotoModel(
                type: .front,
                urlString: "https://example.com/photo1.jpg",
                data: testData
            )
            let model2 = TempPhotoModel(
                type: .front,
                urlString: "https://example.com/photo2.jpg",
                data: testData
            )

            #expect(model1 != model2)
        }

        @Test("Проверка Equatable протокола - разные данные")
        func equatableDifferentData() {
            let testData1 = Data("test image data 1".utf8)
            let testData2 = Data("test image data 2".utf8)
            let model1 = TempPhotoModel(
                type: .front,
                urlString: "https://example.com/photo.jpg",
                data: testData1
            )
            let model2 = TempPhotoModel(
                type: .front,
                urlString: "https://example.com/photo.jpg",
                data: testData2
            )

            #expect(model1 != model2)
        }

        @Test("Проверка Equatable протокола - одна с URL, другая с данными")
        func equatableURLvsData() {
            let testData = Data("test image data".utf8)
            let model1 = TempPhotoModel(
                type: .front,
                urlString: "https://example.com/photo.jpg",
                data: nil
            )
            let model2 = TempPhotoModel(
                type: .front,
                urlString: nil,
                data: testData
            )

            #expect(model1 != model2)
        }

        @Test("Проверка Equatable протокола - одна помечена на удаление")
        func equatableOneMarkedForDeletion() {
            let testData = Data("test image data".utf8)
            let model1 = TempPhotoModel(
                type: .front,
                urlString: "https://example.com/photo.jpg",
                data: testData
            )
            let model2 = TempPhotoModel(
                type: .front,
                urlString: "https://example.com/photo.jpg",
                data: UserProgress.DELETED_DATA
            )

            #expect(model1 != model2)
        }

        @Test("CustomStringConvertible description с обычными данными")
        func customStringConvertibleWithNormalData() {
            let testData = Data("test image data".utf8)
            let model = TempPhotoModel(
                type: .front,
                urlString: "https://example.com/photo.jpg",
                data: testData
            )

            let description = model.description
            #expect(description.contains("Тип фотографии: photo_front"))
            #expect(description.contains("ссылка: https://example.com/photo.jpg"))
            #expect(description.contains("данные для картинки есть"))
            #expect(description.contains("картинка не помечена на удаление"))
        }

        @Test("CustomStringConvertible description с nil данными")
        func customStringConvertibleWithNilData() {
            let model = TempPhotoModel(
                type: .back,
                urlString: nil,
                data: nil
            )

            let description = model.description
            #expect(description.contains("Тип фотографии: photo_back"))
            #expect(description.contains("ссылка: отсутствует"))
            #expect(description.contains("нет данных для картинки"))
            #expect(description.contains("картинка не помечена на удаление"))
        }

        @Test("CustomStringConvertible description с данными для удаления")
        func customStringConvertibleWithDeletedData() {
            let model = TempPhotoModel(
                type: .side,
                urlString: "https://example.com/photo.jpg",
                data: UserProgress.DELETED_DATA
            )

            let description = model.description
            #expect(description.contains("Тип фотографии: photo_side"))
            #expect(description.contains("ссылка: отсутствует"))
            #expect(description.contains("нет данных для картинки"))
            #expect(description.contains("картинка помечена на удаление"))
        }

        @Test("Параметризированный тест CustomStringConvertible description", arguments: [
            ProgressPhotoType.front,
            ProgressPhotoType.back,
            ProgressPhotoType.side
        ])
        func customStringConvertibleParameterized(photoType: ProgressPhotoType) {
            let testData = Data("test image data".utf8)
            let model = TempPhotoModel(
                type: photoType,
                urlString: "https://example.com/photo.jpg",
                data: testData
            )

            let description = model.description
            #expect(description.contains("Тип фотографии: photo_\(photoType.requestName)"))
            #expect(description.contains("ссылка: https://example.com/photo.jpg"))
            #expect(description.contains("данные для картинки есть"))
            #expect(description.contains("картинка не помечена на удаление"))
        }

        @Test("Проверка Identifiable протокола")
        func identifiableProtocol() {
            let testData = Data("test image data".utf8)
            let model = TempPhotoModel(
                type: .front,
                urlString: "https://example.com/photo.jpg",
                data: testData
            )

            #expect(model.id == "front")
            #expect(model.id == model.type.requestName)
        }

        @Test("Проверка работы с пустыми данными")
        func emptyDataHandling() {
            let emptyData = Data()
            let model = TempPhotoModel(
                type: .front,
                urlString: "https://example.com/photo.jpg",
                data: emptyData
            )

            #expect(model.data == emptyData)
            #expect(model.canBeDeleted)
            #expect(!model.isMarkedForDeletion)
        }

        @Test("Проверка работы с большими данными")
        func largeDataHandling() {
            let largeData = Data(repeating: 0x42, count: 1024 * 1024) // 1MB
            let model = TempPhotoModel(
                type: .back,
                urlString: nil,
                data: largeData
            )

            #expect(model.data == largeData)
            #expect(model.canBeDeleted)
            #expect(!model.isMarkedForDeletion)
        }

        @Test("Проверка работы с URL без протокола")
        func urlWithoutProtocol() {
            let model = TempPhotoModel(
                type: .side,
                urlString: "example.com/photo.jpg",
                data: nil
            )

            #expect(model.urlString == "example.com/photo.jpg")
            #expect(model.canBeDeleted)
            #expect(!model.isMarkedForDeletion)
        }

        @Test("Проверка работы с пустой строкой URL")
        func emptyStringURL() {
            let model = TempPhotoModel(
                type: .front,
                urlString: "",
                data: nil
            )

            #expect(model.urlString == "")
            #expect(model.canBeDeleted)
            #expect(!model.isMarkedForDeletion)
        }
    }
}
