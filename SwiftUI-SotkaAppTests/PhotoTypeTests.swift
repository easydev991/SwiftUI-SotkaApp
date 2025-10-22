import Foundation
@testable import SwiftUI_SotkaApp
import Testing

struct PhotoTypeTests {
    // MARK: - deleteRequestName Tests

    @Test("deleteRequestName возвращает правильные названия для DELETE запросов")
    func deleteRequestNameReturnsCorrectNamesForDeleteRequests() {
        #expect(PhotoType.front.requestName == "front")
        #expect(PhotoType.back.requestName == "back")
        #expect(PhotoType.side.requestName == "side")
    }

    @Test("Параметризированный тест deleteRequestName", arguments: [
        (PhotoType.front, "front"),
        (PhotoType.back, "back"),
        (PhotoType.side, "side")
    ])
    func deleteRequestNameParameterized(photoType: PhotoType, expectedName: String) {
        #expect(photoType.requestName == expectedName)
    }

    // MARK: - localizedTitle Tests

    @Test("localizedTitle возвращает правильные названия")
    func localizedTitleReturnsCorrectNames() {
        #expect(PhotoType.front.localizedTitle == "Фото спереди")
        #expect(PhotoType.back.localizedTitle == "Фото сзади")
        #expect(PhotoType.side.localizedTitle == "Фото сбоку")
    }

    @Test("Параметризированный тест localizedTitle", arguments: [
        (PhotoType.front, "Фото спереди"),
        (PhotoType.back, "Фото сзади"),
        (PhotoType.side, "Фото сбоку")
    ])
    func localizedTitleParameterized(photoType: PhotoType, expectedTitle: String) {
        #expect(photoType.localizedTitle == expectedTitle)
    }

    // MARK: - allCases Tests

    @Test("allCases содержит все типы фотографий")
    func allCasesContainsAllPhotoTypes() {
        let allCases = PhotoType.allCases
        #expect(allCases.count == 3)
        #expect(allCases.contains(.front))
        #expect(allCases.contains(.back))
        #expect(allCases.contains(.side))
    }

    @Test("allCases содержит типы в правильном порядке")
    func allCasesContainsTypesInCorrectOrder() {
        let allCases = PhotoType.allCases
        #expect(allCases[0] == .front)
        #expect(allCases[1] == .back)
        #expect(allCases[2] == .side)
    }
}
